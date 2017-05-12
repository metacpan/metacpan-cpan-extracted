package AnyEvent::Groonga;
use strict;
use warnings;
use Carp;
use AnyEvent;
use AnyEvent::Util qw(run_cmd);
use AnyEvent::HTTP;
use AnyEvent::Groonga::Result;
use File::Which qw(which);
use List::MoreUtils qw(any);
use URI;
use URI::Escape;
use JSON;
use Try::Tiny;
use Encode;
use base qw(Class::Accessor::Fast);

our $VERSION = '0.08';

__PACKAGE__->mk_accessors($_)
    for qw( protocol host port groonga_path database_path command_list debug);

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(
        {   protocol      => 'gqtp',
            host          => 'localhost',
            port          => '10041',
            groonga_path  => which("groonga") || undef,
            database_path => undef,
            command_list  => [
                qw(
                    cache_limit
                    check
                    clearlock
                    column_create
                    column_list
                    column_remove
                    define_selector
                    defrag
                    delete
                    dump
                    load
                    log_level
                    log_put
                    log_reopen
                    quit
                    select
                    shutdown
                    status
                    suggest
                    table_create
                    table_list
                    table_remove
                    view_add
                    )
            ],
            @_
        }
    );
    return $self;
}

sub call {
    my $self     = shift;
    my $command  = shift;
    my $args_ref = shift;

    croak( $command . " is not supported command" )
        unless any { $command eq $_ } @{ $self->{command_list} };

    if ( $self->protocol eq 'http' ) {
        return $self->_post_to_http_server( $command, $args_ref );
    }
    elsif ( $self->protocol eq 'gqtp' ) {
        croak("can not find gronnga_path")
            if !$self->groonga_path
                or !-e $self->groonga_path;
        return $self->_post_to_gqtp_server( $command, $args_ref );
    }
    elsif ( $self->protocol eq 'local_db' ) {
        croak("can not find gronnga_path")
            if !$self->groonga_path
                or !-e $self->groonga_path;
        croak("can not find database_path")
            if !$self->database_path
                or !-e $self->database_path;
        return $self->_post_to_local_db( $command, $args_ref );
    }
    else {
        croak( $self->protocol . " is not supported protocol" );
        return undef;
    }
}

sub _set_timeout {
    my $self    = shift;
    my $cv      = shift;
    my $timeout = shift;
    AnyEvent->now_update;
    my $timer;
    $timer = AnyEvent->timer(
        after => $timeout,
        cb    => sub {
            my $data = [ [ 0, undef, undef, ], ['timeout'] ];
            my $result = AnyEvent::Groonga::Result->new( data => $data );
            $cv->send($result);
            undef $timer;
        },
    );
}

sub _post_to_http_server {
    my $self     = shift;
    my $command  = shift;
    my $args_ref = shift;

    my $url = $self->_generate_groonga_url( $command, $args_ref );

    my $cv = AnyEvent->condvar;

    $self->_set_timeout( $cv, $args_ref->{timeout} ) if $args_ref->{timeout};

    http_get(
        $url,
        sub {
            my $json = shift;
            my $result;
            try {
                my $data = JSON->new->utf8->decode($json);
                $result = AnyEvent::Groonga::Result->new(
                    posted_command => $command,
                    data           => $data
                );
            }
            catch {
                $result = $_;
            };
            $cv->send($result);
        }
    );

    return $cv;
}

sub _post_to_gqtp_server {
    my $self     = shift;
    my $command  = shift;
    my $args_ref = shift;

    my $groonga_command
        = $self->_generate_groonga_command( $command, $args_ref );

    my $cv = AnyEvent->condvar;

    $self->_set_timeout( $cv, $args_ref->{timeout} ) if $args_ref->{timeout};

    my $cmd_cv = run_cmd $groonga_command,
        '>'  => \my $stdout,
        '2>' => \my $stderr;

    $cmd_cv->cb(
        sub {
            my $json = $stdout;
            my $result;
            try {
                my $data = JSON->new->utf8->decode($json);
                $result = AnyEvent::Groonga::Result->new(
                    posted_command => $command,
                    data           => $data
                );
            }
            catch {
                $result = $_;
            };
            $cv->send($result);
        }
    );

    return $cv;
}

sub _post_to_local_db {
    my $self     = shift;
    my $command  = shift;
    my $args_ref = shift;

    # just a proxy!
    return $self->_post_to_gqtp_server( $command, $args_ref );
}

sub _generate_groonga_url {
    my $self     = shift;
    my $command  = shift;
    my $args_ref = shift;

    my $uri = URI->new;
    $uri->scheme("http");
    $uri->host( $self->host );
    $uri->port( $self->port );
    $uri->path( "d/" . $command );

    my @array;
    while ( my ( $key, $value ) = each %$args_ref ) {
        if ( $command eq 'load' && $key eq 'values' ) {
            $value = $self->_load_filter($value);
        }
        elsif ( ref $value eq 'ARRAY' ) {
            $value = join( ",", @$value );
        }
        $key   = uri_escape($key);
        $value = uri_escape($value);
        push @array, $key . '=' . $value;
    }
    $uri->query( join( "&", @array ) );

    return $uri->as_string;
}

sub _generate_groonga_command {
    my $self     = shift;
    my $command  = shift;
    my $args_ref = shift;

    my $groonga_command;

    if ( $self->protocol eq 'gqtp' ) {
        $groonga_command = join( " ",
            $self->groonga_path, '-p', $self->port, '-c', $self->host );
    }
    else {
        $groonga_command
            = join( " ", $self->groonga_path, $self->database_path );
    }

    $groonga_command .= ' "' . $command . ' ';

    my @array;
    while ( my ( $key, $value ) = each %$args_ref ) {
        if ( $command eq 'load' && $key eq 'values' ) {
            $value = $self->_load_filter($value);
        }
        elsif (
            $command eq 'select'
            && (   $key eq 'query'
                || $key eq 'filter'
                || $key eq 'sortby'
                || $key eq 'scorer' )
            )
        {
            if ( ref $value eq 'ARRAY' ) {
                $value = join( ",", @$value );
            }
            $value = $self->_select_filter($value);
        }
        elsif ( ref $value eq 'ARRAY' ) {
            $value = join( ",", @$value );
        }
        $key = '--' . $key;
        push @array, ( $key, $value );
    }
    $groonga_command .= join( " ", @array ) . '"';
    warn($groonga_command) if $self->debug;
    return $groonga_command;
}

sub _select_filter {
    my $self = shift;
    my $data = shift;
    $data = decode( "utf8", $data ) unless utf8::is_utf8($data);
    $data =~ /(^|[^\\])"|'/;
    if ($1) {
        $data =~ s/(^|[^\\])"|'/$1\\"/g;
    }
    else {
        $data =~ s/(^|[^\\])"|'/\\"/g;
    }
    return '\'' . $data . '\'';
}

sub _load_filter {
    my $self = shift;
    my $data = shift;
    my $json = JSON->new->latin1->encode($data);
    if ( $self->protocol ne 'http' ) {
        $json =~ s/\\/\\\\\\\\/g;
        $json =~ s/'/\\'/g;
        $json =~ s/"/\\"/g;
    }
    if ( ref $data ne 'ARRAY' ) {
        $json = '[' . $json . ']';
    }
    $json = '\'' . $json . '\'' if $self->protocol ne 'http';
    return $json;
}

1;
__END__

=head1 NAME

AnyEvent::Groonga - Groonga client for AnyEvent

=head1 SYNOPSIS

  use AnyEvent::Groonga;

  my $groonga = AnyEvent::Groonga->new(
    protocol => 'http',
    host     => 'localhost,
    port     => '10041',
  );

  # blocking interface
  my $result = $groonga->call(select => {
    table          => "Site",
    query          => 'title:@test',
    output_columns => [qw(_id _score title)],
    sortby         => '_score',
  })->recv;

  # result is AnyEvent::Groonga::Result::Select object
  print $result->dump;

  # non-blocking interface
  $groonga->call(select => {
    table          => "Site",
    query          => 'title:@test',
    output_columns => [qw(_id _score title)],
    sortby         => '_score',
  })->cb(
    sub {
      my $result = $_[0]->recv; 
    }
  );

  print Dumper $result->items;


=head1 DESCRIPTION

This is groonga client module for AnyEvent applications.

groonga is an open-source fulltext search engine and column store.

=head1 SEE ALSO

L<http://groonga.org/>

=head1 METHOD

=head2 new (%options)

Create groonga client object.

  my $groonga = AnyEvent::Groonga->new(
    protocol => 'http',
    host     => 'localhost,
    port     => '10041',
  );

Available options are:

=over 4

=item protocol => 'http|gqtp|local_db'

groonga-server speaks http and gqtp protocol (groonga original protocol).

And it works for local database file, too.

=item host

=item port

=item groonga_path

It is necessary if you set the protocol as gqtp or local_db.

=item database_path

It is necessary if you set the protocol as local_db.

=back

=head2 call ($command => \%args)

Call groonga command named $command with %args parameters.

It returns AnyEvent condvar object for response.

  # blocking interface
  my $result = $groonga->call(select => {
    table          => "Site",
    query          => 'title:@test',
    output_columns => [qw(_id _score title)],
    sortby         => '_score',
  })->recv;

  # result is AnyEvent::Groonga::Result::Select object
  print $result->dump;

  # non-blocking interface
  $groonga->call(select => {
    table          => "Site",
    query          => 'title:@test',
    output_columns => [qw(_id _score title)],
    sortby         => '_score',
  })->cb(
    sub {
      my $result = $_[0]->recv; 
    }
  );

Available commands are:

=over 4

=item cache_limit

=item check

=item clearlock

=item column_create

=item column_list

=item column_remove

=item define_selector

=item defrag

=item delete

=item dump

=item load

=item log_level

=item log_put

=item log_reopen

=item quit

=item select

=item shutdown

=item status

=item suggest

=item table_create

=item table_list

=item table_remove

=item view_add

See Groonga's official site.
L<http://groonga.org/>

=back

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
