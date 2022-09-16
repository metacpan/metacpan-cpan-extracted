package Apache::Tika::Server;
use strict;
use Carp qw(croak);
use Moo 2;
use Apache::Tika::DocInfo;
use Data::Dumper;
use Future;
# Consider if we really want/need it, instead of simply staying
# callback-based
#use Future::AsyncAwait;

#use Filter::signatures;
use feature 'signatures';
no warnings 'experimental::signatures';

=head1 NAME

Apache::Tika::Server - Fire up/stop a Tika instance

=head1 SYNOPSIS

  use Apache::Tika::Server;

  # Launch our own Apache Tika instance
  my $tika= Apache::Tika::Server->new(
      jarfile => $tika_path,
  );
  $tika->launch;

  my $fn= shift;

  use Data::Dumper;
  my $info = $tika->get_all( $fn );
  print Dumper $info->meta($fn);
  print $info->content($fn);
  # <html><body>...
  print $info->meta->{"meta:language"};
  # en

=cut

our $VERSION = '0.11';

extends 'Apache::Tika::Async';

sub load_module {
    my( $module ) = @_;
    $module =~ s!::!/!g;
    require "$module.pm"
}

has pid => (
    is => 'rw',
    #isa => 'Int',
);

has host => (
    is => 'ro',

    # this should be 127.0.0.1 or [::1] , depending on whether we
    # are IPv4 or IPv6 ...
    default => sub { 'localhost' },
);

has port => (
    is => 'ro',
    #isa => 'Int',
    default => sub { 9998 },
);

has loglevel => (
    is => 'ro',
    #isa => 'Int',
    default => sub { 'info' },
);

has connection_class => (
    is => 'ro',
    default => 'Apache::Tika::Connection::Future',
);

has ua => (
    is => 'ro',
    #isa => 'Str',
    default => sub { load_module( $_[0]->connection_class ); $_[0]->connection_class->new },
);

sub cmdline {
    my( $self )= @_;
    $self->java,
    @{$self->java_args},
    '-jar',
    $self->jarfile,
    #'--port', $self->port,
    '--config', $self->tika_config_temp_file,
    @{$self->tika_args},
};

sub spawn_child_win32( $self, @cmd ) {
    system(1, @cmd)
}

sub spawn_child_posix( $self, @cmd ) {
    require POSIX;
    POSIX->import("setsid");

    # daemonize
    defined(my $pid = fork())   || die "can't fork: $!";
    if( $pid ) {    # non-zero now means I am the parent
        return $pid;
    };

    # We are the child, close about everything, then exec
    chdir("/")                  || die "can't chdir to /: $!";
    (setsid() != -1)            || die "Can't start a new session: $!";
    open(STDERR, ">&STDOUT")    || die "can't dup stdout: $!";
    open(STDIN,  "< /dev/null") || die "can't read /dev/null: $!";
    open(STDOUT, "> /dev/null") || die "can't write to /dev/null: $!";
    exec @cmd;
    exit 1;
}

sub spawn_child( $self, @cmd ) {
    my ($pid);
    if( $^O =~ /mswin/i ) {
        $pid = $self->spawn_child_win32(@cmd)
    } else {
        $pid = $self->spawn_child_posix(@cmd)
    };

    return $pid
}

sub launch( $self ) {
    if( !$self->pid ) {
        my $cmdline= join " ", $self->cmdline; # well, for Windows...
        #warn $cmdline;
        my $pid= $self->spawn_child( $self->cmdline )
            or croak "Couldn't launch [$cmdline]: $!/$^E";
        $self->pid( $pid );
        sleep 2; # Java...
    };
}

sub url {
    # Should return URI instead
    my( $self, $type )= @_;
    $type||= 'text';

    my $url= {
        text => 'rmeta',
        test => 'tika', # but GET instead of PUT
        meta => 'rmeta',
        #all => 'all',
        language => 'language/string',
        all => 'rmeta',
        # unpack
    }->{ $type };

    sprintf
        'http://%s:%s/%s',
        $self->host,
        $self->port,
        $url
};

# /rmeta
# /unpacker
# /all
# /tika
# /language
#    hello world
sub fetch {
    my( $self, %options )= @_;
    $options{ type }||= 'text';
    my $url= $self->url( $options{ type } );

    if(! $options{ content } and $options{ filename }) {
        # read $options{ filename }
        open my $fh, '<', $options{ filename }
            or croak "Couldn't read '$options{ filename }': $!";
        binmode $fh;
        local $/;
        $options{ content } = <$fh>;
    };

    my $method;
    if( 'test' eq $options{ type } ) {
        $method= 'get';

    } else {
        $method= 'put';
        ;
    };

    my $headers = $options{ headers } || {};

    #my ($code,$res) = await
    #    $self->ua->request( $method, $url, $options{ content }, %$headers );
    return $self->ua->request( $method, $url, $options{ content }, %$headers )
    ->then(sub( $code, $res ) {
        my $info;
        if(    'all' eq $options{ type }
            or 'text' eq $options{ type }
            or 'meta' eq $options{ type } ) {
            if( $code !~ /^2..$/ ) {
                croak "Got HTTP error code $code for '$options{ filename }'";
            };
            my $item = $res->[0];
            # Should/could this be lazy?
            my $c = delete $item->{'X-TIKA:content'};
            # Ghetto-strip HTML we don't want:
            if( $c =~ m!<body>(.*)</body>!s or $c =~ m!<body\s*/>!) {
                $c = $1;

                if( $item->{"Content-Type"} and $item->{"Content-Type"} =~ m!^text/plain\b!) {
                    # Also strip the enclosing <p>..</p>
                    $c =~ s!\A\s*<p>(.*)\s*</p>\s*\z!$1!s;
                };
            } else {
                warn "Couldn't find HTML body in response: $c";
            };

            $info= Apache::Tika::DocInfo->new({
                content => $c,
                meta => $item,
            });

            if( ! defined $info->{meta}->{"meta:language"} ) {
                # Yay. Two requests.
                my $lang_meta = $self->fetch(%options, type => 'language', 'Content-Type' => $item->{'Content-Type'})->get;
                $info->{meta}->{"meta:language"} = $lang_meta->meta->{"info"};
            };

        } else {
            # Must be '/language'
            if( $code !~ /^2..$/ ) {
                croak "Got HTTP error code $code";
            };
            if( ref $res ) {
                $res = $res->[0];
            } else {
                $res = { info => $res };
            };

            my $c = delete $res->{'X-TIKA:content'};
            $info= Apache::Tika::DocInfo->new({
                meta => $res,
                content => undef,
            });
        };
        return Future->done($info)
    })
}

sub DEMOLISH {
    kill -9 => $_[0]->pid
        if( $_[0] and $_[0]->pid );
}

#__PACKAGE__->meta->make_immutable;

1;

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Apache-Tika-Async>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Apache-Tika-Async>
or via mail to L<apache-tika-async-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2014-2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
