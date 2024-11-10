package App::CGIThis;

# DATE
# VERSION

use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;
use Plack::Runner;
use Plack::App::CGIBin;
use Plack::Builder;
use File::Find::Rule;

sub new {
    my $class = shift;
    my $self = bless { port => 3000, root => '.' }, $class;

    GetOptions( $self, "help", "man", "port=i", "host=s", "name=s", "cgi-bin" ) || pod2usage(2);
    pod2usage(1) if $self->{help};
    pod2usage( -verbose => 2 ) if $self->{man};

    if ( @ARGV > 1 ) {
        pod2usage("$0: Too many roots, only single root supported");
    }
    elsif (@ARGV) {
        $self->{root} = shift @ARGV;
    }

    return $self;
}

sub run {
    my ($self) = @_;

    my $runner = Plack::Runner->new;
    $runner->parse_options(
        '--port'         => $self->{port},
        '--host'         => $self->{host},
        '--env'          => 'production',
        '--server_ready' => sub { $self->_server_ready(@_) },
    );

    eval {
        $runner->run(
            builder {
                mount + ( $self->{"cgi-bin"} ? "/cgi-bin" : "/" ) => Plack::App::CGIBin->new(
                    root    => $self->{root},
                    exec_cb => sub {1},
                )->to_app;
            }
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

    print "Exporting '$self->{root}', available at:\n";
    print "   $proto://$host:$port/\n";

    my @files =
        map { s{^\Q$self->{root}\E/?}{}; $_ } File::Find::Rule->file->name('*.pl','*.cgi')->in( $self->{root} );

    if (@files) {
        print "\nFound the following scripts:\n";
        print "    $proto://$host:$port/" . ( $self->{"cgi-bin"} ? "cgi-bin/" : "" ) . "$_\n"
            for @files;
    }

    return unless my $name = $self->{name};

    eval {
        require Net::Rendezvous::Publish;
        Net::Rendezvous::Publish->new->publish(
            name   => $name,
            type   => '_http._tcp',
            port   => $port,
            domain => 'local',
        );
    };
    if ($@) {
        print "\nWARNING: your server will not be published over Bonjour\n";
        print "    Install one of the Net::Rendezvous::Publish::Backend\n";
        print "    modules from CPAN\n";
    }
}

1;

# ABSTRACT: Export the current directory like a cgi-bin

__END__

=pod

=encoding UTF-8

=head1 NAME

App::CGIThis - Export the current directory like a cgi-bin

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    # Do not use directly. See the cgi_this command!

=head1 DESCRIPTION

This is a fork of L<App::HTTPThis> and L<App::HTTPSThis> to turn a directory of
CGI scripts into a webserver that behaves like a C<cgi-bin> folder.

This class implements all logic for the L<cgi_this> command.

Actually, this is just a thin wrapper around L<Plack::App::CGIBin>,
that is where the magic really is.

=head1 METHODS

=head2 new

Creates a new L<App::CGIThis> object, parsing the command line arguments
into object attribute values.

=head2 run

Start the HTTP server.

=head1 SEE ALSO

=over 4

=item * L<App::HTTPThis>, L<http_this>

=item * L<App::HTTPSThis>, L<https_this>

=item * L<Plack>, L<Plack::App::CGIBin> and L<Net::Rendezvous::Publish>

=back

=head1 AUTHOR

simbabque <simbabque@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by simbabque.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
