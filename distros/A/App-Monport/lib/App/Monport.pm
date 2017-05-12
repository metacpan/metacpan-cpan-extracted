# ABSTRACT: Monitor network ports for changes
package App::Monport;
$App::Monport::VERSION = '1.10';
use strict;
use warnings;
use IO::Socket;
use List::Util qw(shuffle);
use Nmap::Parser;
use Exporter qw(import);
use YAML::Tiny;

our @EXPORT = qw(scan_ports create_config compare_config nmap_path);

=for HTML <a href="https://travis-ci.org/jreisinger/App-Monport"><img src="https://travis-ci.org/jreisinger/App-Monport.svg?branch=master"></a>

=head1 NAME

App::Monport - Monitor network ports for changes

=head1 SYNOPSIS

 # generate the configuration file
 $ monport localhost scanme.nmap.org

 # review/edit the configuration file
 $ vi $HOME/.monport.yml

 # compare against the configuration file
 $ monport

=head1 DESCRIPTION

Use this module to find out whether some new ports have been opened or
existing ones have been closed. New open ports mean bigger attack surface and
consequently higher security risk. On the other hand if a port gets closed it
might indicate a problem with a network service.

The application works by comparing the actual state of ports (open or closed)
with the expected state defined in the configuration file.

=head1 FUNCTIONS

See F<bin/monport> for how to use these functions.

=head2 create_config($conf_file, @hosts)

Create configuration file F<$HOME/.monport.yml> containing hosts with
corresponding open ports. This file will be used as the expected list of
open ports in the consequent scans.

=cut

sub create_config {
    my $args = shift;
    my $conf_file = $args->{conf_file};
    my @hosts     = @{$args->{hosts}};
    my $verbose   = $args->{verbose};

    my $yaml;
    die "'$conf_file' already exists. You can remove it or edit it.\n"
      if -e $conf_file;
    $yaml = YAML::Tiny->new();
    for my $host (@hosts) {
        my $open_ports = scan_ports($host, $verbose);
        push @$yaml, { $host => $open_ports };
        $yaml->write($conf_file);
    }
}

=head2 compare_config($conf_file)

Compare list of open ports defined in the F<$conf_file> with the current list
of open ports. Print newly opened or closed ports.

=cut

sub compare_config {
    my $args = shift;
    my $conf_file = $args->{conf_file};
    my $verbose   = $args->{verbose};

    my $yaml = YAML::Tiny->read($conf_file);
    for my $hashref (@$yaml) {
        for my $host ( sort keys %$hashref ) {

            my $open = scan_ports($host, $verbose);
            my $expected_open = $hashref->{$host} // [];

            my @report_closed;
            for my $port ( sort @$open ) {
                push @report_closed, $port
                  unless grep $port == $_, @$expected_open;
            }

            my @report_open;
            for my $port ( sort @$expected_open ) {
                push @report_open, $port
                  unless grep $port == $_, @$open;
            }

            # print report
            print "$host\n" if @report_open or @report_closed;
            print "  $_ open\n" for @report_closed;
            print "  $_ closed\n" for @report_open;
        }
    }
}

=head2 scan_ports($host, $verbose)

Return an array reference containing list of ports open on $host.

=cut

sub scan_ports {
    my ($host, $verbose) = @_;

    print "--> scanning $host ...\n" if $verbose;
    my $np = new Nmap::Parser;

    #runs the nmap command with hosts and parses it automagically
    my $nmap = nmap_path();
    $np->parsescan( $nmap, '', $host );

    my ($h) = $np->all_hosts();
    my @ports = $h->tcp_ports(q(open));

    return \@ports;
}

#sub scan_ports {
#    my $host = shift;
#    my @open;
#    print "scanning $host: \n";
#    my $ports = default_ports();
#    for my $port (@$ports) {
#        my $socket = IO::Socket::INET->new(
#            PeerAddr => $host,
#            PeerPort => $port,
#            Proto    => 'tcp',
#            Type     => SOCK_STREAM,
#            Timeout  => 1,
#        );
#
#        if ($socket) {
#            push @open, $port;
#            shutdown( $socket, 2 );
#        }
#    }
#
#    return \@open;
#}

=head2 nmap_path()

Return absolute path to nmap executable or die.

=cut

sub nmap_path {
    my @paths = qw(
      /usr/bin/nmap
      /usr/local/bin/nmap
    );
    for my $p (@paths) {
        return $p if -x $p;
    }
    die "can't find exacutable nmap; searched @paths\n";
}

=head1 INSTALLATION

To install this module run:

 $ cpan App::Monport

or

 $ cpanm App::Monport

when using L<App::cpanminus>.

To install manually clone the L</"SOURCE REPOSITORY"> and then run (on Unix):

 perl Build.PL
 ./Build
 ./Build test
 ./Build install

For more see L<StackOverflow|http://stackoverflow.com/questions/65865/whats-the-easiest-way-to-install-a-missing-perl-module>
or L<CPAN|http://www.cpan.org/modules/INSTALL.html> instructions.

=head1 SOURCE REPOSITORY

L<http://github.com/jreisinger/App-Monport>

=head1 AUTHOR

Jozef Reisinger, E<lt>reisinge@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015-2016 by Jozef Reisinger.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
