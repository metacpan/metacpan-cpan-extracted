#!/usr/bin/perl 

use strict;
use warnings;

=head1 NAME

cmis_test_server.pl - Standalone server for CPAN::Mini::Inject::Server

=head1 SYNOPSIS

cmis_test_server.pl [options]

 Options:
    -help       brief help message
    -man        full documentation
    -port       Port to run the server on

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-port>

The port on which the server will be run. Defaults to 9000.

=back

=head1 DESCRIPTION

Test dev server for CPAN::Mini::Inject::Server

=cut

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Carp;
use Getopt::Long;
use Pod::Usage;
use CGI::Application::Dispatch::Server;

my ($help, $man);
my $port = 9000;

GetOptions(
    'help|?' => \$help,
    'man' => \$man,
    'port=i' => \$port,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $server = CGI::Application::Dispatch::Server->new(
    class => 'CPAN::Mini::Inject::Server::Dispatch',
    port => $port,
);

$server->run;

=head1 AUTHOR

Christopher Mckay (cmckay), C<< <cmckay@iseek.com.au> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc cmis_test_server.pl


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 iseek Communications, all rights reserved.

This program is released under the following license: restrictive


=cut

# End of cmis_test_server.pl

