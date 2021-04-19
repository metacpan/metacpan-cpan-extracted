package App::ProxyThat;

# DATE
# VERSION

use strict;
use warnings;
use Getopt::Long qw(:config pass_through);
use Pod::Usage;
use Plack::App::Proxy;
use Plack::Builder;
use Plack::Runner;
use File::chdir;

sub new {
    my $class = shift;
    my $self = bless { port => 3080 }, $class;

    GetOptions( $self, "help", "man", "port=i", "ssl" ) || pod2usage(2);
    pod2usage(1) if $self->{help};
    pod2usage( -verbose => 2 ) if $self->{man};

    $self->{url} = $ARGV[0]
        or pod2usage(2);

    if ( $self->{ssl} ) {
        require AppLib::CreateSelfSignedSSLCert;
        require File::Temp;
        my $dir = File::Temp::tempdir( CLEANUP => 1 );
        local $CWD = $dir;
        my $res = AppLib::CreateSelfSignedSSLCert::create_self_signed_ssl_cert(
            hostname    => 'localhost',
            interactive => 0,
        );
        die "Can't create self-signed SSL certificate: $res->[0] - $res->[1]"
            unless $res->[0] == 200;
        $self->{'ssl-cert'} = "$dir/localhost.crt";
        $self->{'ssl-key'}  = "$dir/localhost.key";
    }

    return $self;
}

sub run {
    my ($self) = @_;
    my $runner = Plack::Runner->new;
    $runner->parse_options(
        '--server' => 'Starman',
        '--port'   => $self->{port},
        '--env'    => 'production',
        (
            $self->{ssl}
            ? (
                '--enable-ssl',
                '--ssl-cert' => $self->{'ssl-cert'},
                '--ssl-key'  => $self->{'ssl-key'},
                )
            : ()
        ),
        '--server_ready' => sub { $self->_server_ready(@_) },
    );

    eval {
        $runner->run(
            Plack::App::Proxy->new(
                remote => $self->{url},

                #backend => 'LWP'           ## TODO as arg
            )->to_app
        );
    };
    if ( my $e = $@ ) {
        die "FATAL: port $self->{port} is already in use, try another one\n"
            if $e =~ m/failed to listen to port/;
        die "FATAL: internal error - $e\n";
    }

}

sub _server_ready {
    my ( $self, $args ) = @_;

    my $host  = $args->{host}  || '127.0.0.1';
    my $proto = $args->{proto} || 'http';
    my $port  = $args->{port};

    print "Providing a proxy for '$self->{'url'}' at:\n";
    print "   $proto://$host:$port/\n";
}

1;

# ABSTRACT: Proxy an URL from the command line

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ProxyThat - Proxy an URL from the command line

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    # Do not use directly. See the proxy_that command!

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Creates a new L<App::ProxyThat> object, parsing the command line arguments
into object attribute values.

=head2 run

Start the HTTP server.

=head1 SEE ALSO

=over 4

=item * L<Plack>, L<Plack::App::Proxy> 

=back

=head1 AUTHOR

simbabque <simbabque@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by simbabque.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
