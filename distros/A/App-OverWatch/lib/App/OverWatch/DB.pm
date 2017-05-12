package App::OverWatch::DB;
# ABSTRACT: Database connector base class

use strict;
use warnings;
use utf8;

use App::OverWatch::Config;

use DBIx::Connector;
use Try::Tiny;
use Module::Load qw( load );

sub new {
    my $class = shift;
    my $Config = shift || die "Error: require 'Config' arg";

    my $type = $Config->db_type();

    my $subclass = $class . '::' . $type;
    load($subclass);

    my $self = bless( {}, $subclass );

    $self->{Config} = $Config;

    return $self;
}

sub type {
    my $self = shift;
    return $self->{Config}->db_type();
}

sub dbix_run {
    my ($self, $sql, @bind_values) = @_;

    my $conn = $self->_dbix_conn();

    return $conn->run(
        ping => sub {
            my $ret = 0;
            try {
                $ret = $_->do( $sql, {}, @bind_values);
            } catch {
                warn "Caught exception: $_\n";
                $ret = 0;
            };
            $ret;
        });
}

sub dbix_select {
    my ($self, $sql, @bind_values) = @_;

    my $conn = $self->_dbix_conn();

    return $conn->run( ping => sub {
                                   my $sth = undef;
                                   try {
                                       $sth = $_->prepare( $sql );
                                       $sth->execute( @bind_values );
                                   } catch {
                                       warn "Caught exception: $_\n";
                                       $sth = undef;
                                   };
                                   $sth;
                               });
}

## Private

sub _dbix_conn {
    my $self = shift;

    my $DBIx_conn = $self->{_conn};
    return $DBIx_conn if (defined($DBIx_conn) && $DBIx_conn->connected());

    ## Not connected - try full connect
    my $ret = undef;
    my $conn = undef;
    try {
        $conn = $self->connect();
    } catch {
        warn "Caught exception: $_\n";
    };
    $self->{_conn} = $conn;
    return $conn;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::OverWatch::DB - Database connector base class

=head1 VERSION

version 0.1

=head1 NAME

App::OverWatch::DB - DB backend for App::OverWatch

=head2 new

Create an App::OverWatch::DB object.

=head2 type

Returns the DB type: mysql, postgres, sqlite.

=head2 dbix_run

Run a SQL command with DBIx::Connector run().

=head2 dbix_select

Run a SQL select with DBIx::Connector run().

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
