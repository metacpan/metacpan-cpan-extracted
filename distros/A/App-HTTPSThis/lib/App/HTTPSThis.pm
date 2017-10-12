package App::HTTPSThis;

our $DATE = '2017-10-11'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use File::chdir;
use Getopt::Long;
use Plack::App::Directory;
use Plack::Runner;
use Pod::Usage;

sub new {
    my $class = shift;
    my $self = bless {port => 8443, root => '.'}, $class;

    GetOptions($self, "help", "man", "port=i", "name=s",
               "ssl-cert=s", "ssl-key=s") || pod2usage(2);
    pod2usage(1) if $self->{help};
    pod2usage(-verbose => 2) if $self->{man};

    unless (defined $self->{'ssl-cert'}) {
        require AppLib::CreateSelfSignedSSLCert;
        require File::Temp;
        my $dir = File::Temp::tempdir(CLEANUP => 1);
        local $CWD = $dir;
        my $res = AppLib::CreateSelfSignedSSLCert::create_self_signed_ssl_cert(
            hostname => 'localhost',
            interactive => 0,
        );
        die "Can't create self-signed SSL certificate: $res->[0] - $res->[1]"
            unless $res->[0] == 200;
        $self->{'ssl-cert'} = "$dir/localhost.crt";
        $self->{'ssl-key'}  = "$dir/localhost.key";
    }

    if (@ARGV > 1) {
        pod2usage("$0: Too many roots, only single root supported");
    } elsif (@ARGV) {
        $self->{root} = shift @ARGV;
    }

    return $self;
}

sub run {
    my ($self) = @_;

    my $runner = Plack::Runner->new;
    $runner->parse_options(
        '--server'       => 'Starman',
        '--port'         => $self->{port},
        '--env'          => 'production',
        '--enable-ssl',
        '--ssl-cert'     => $self->{'ssl-cert'},
        '--ssl-key'      => $self->{'ssl-key'},
        '--server_ready' => sub { $self->_server_ready(@_) },
    );

    eval {
        $runner->run(
            Plack::App::Directory->new(
                {root => $self->{root}})->to_app);
    };
    if (my $e = $@) {
        die "FATAL: port $self->{port} is already in use, try another one\n"
            if $e =~ /failed to listen to port/;
        die "FATAL: internal error - $e\n";
    }
}

sub _server_ready {
    my ($self, $args) = @_;

    my $host  = $args->{host}  || '127.0.0.1';
    my $proto = $args->{proto} || 'https';
    my $port  = $args->{port};

    print "Exporting '$self->{root}', available at:\n";
    print "   $proto://$host:$port/\n";

    return unless my $name = $self->{name};

    eval {
        require Net::Rendezvous::Publish;
        Net::Rendezvous::Publish->new->publish(
            name   => $name,
            type   => '_https._tcp',
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
# ABSTRACT: Export the current directory over HTTPS

__END__

=pod

=encoding UTF-8

=head1 NAME

App::HTTPSThis - Export the current directory over HTTPS

=head1 VERSION

This document describes version 0.001 of App::HTTPSThis (from Perl distribution App-HTTPSThis), released on 2017-10-11.

=head1 SYNOPSIS

 # Not to be used directly, see https_this command

=head1 DESCRIPTION

This is a fork of L<App::HTTPThis> for HTTPS version instead of HTTP.

This class implements all the logic of the L<https_this> command.

Actually, this is just a very thin wrapper around
L<Plack::App::Directory>, that is where the magic really is.

=head1 METHODS

=head2 new

Creates a new App::HTTPSThis object, parsing the command line arguments into
object attribute values.

=head2 run

Start the HTTPS server.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-HTTPSThis>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-HTTPSThis>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-HTTPSThis>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::HTTPThis>

L<https_this>, L<Plack>, L<Plack::App::Directory>, and
L<Net::Rendezvous::Publish>.

L<Starman>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
