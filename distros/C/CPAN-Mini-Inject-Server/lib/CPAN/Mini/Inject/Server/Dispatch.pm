package CPAN::Mini::Inject::Server::Dispatch;

use strict;
use warnings;
use base 'CGI::Application::Dispatch';

=head1 NAME

CPAN::Mini::Inject::Server::Dispatch - Dispatch table for CPAN::Mini::Inject::Server

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

USING TEST SERVER

use CGI::Application::Dispatch::Server;
my $server = CGI::Application::Dispatch::Server->new(
    class => 'CPAN::Mini::Inject::Server::Dispatch',
    port => '9000'
);

$server->run;


OR UNDER APACHE MOD PERL

<location /app>
    SetHandler perl-script
    PerlHandler CPAN::Mini::Inject::Server::Dispatch
</location>
        
        
OR UNDER CGI
        
#!/usr/bin/perl
use FindBin '$Bin';
use lib "$Bin/../../rel/path/to/my/perllib";
use CPAN::Mini::Inject::Server::Dispatch
CPAN::Mini::Inject::Server::Dispatch->dispatch();

=cut

=head1 DESCRIPTION

=cut

=head1 FUNCTIONS

=cut


=head2 dispatch_args

Dispatch urls for CPAN::Mini::Inject::Server

=cut

sub dispatch_args {
    return {
        prefix => 'CPAN::Mini::Inject',
        table => [
            'add[post]' => {app => 'Server', rm => 'add'},
            'update[post]' => {app => 'Server', rm => 'update'},
            'inject[post]' => {app => 'Server', rm => 'inject'},
        ],
    }
} # end of subroutine dispatch_args



=head1 AUTHOR

Christopher Mckay, C<< <potatohead at potatolan.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-cpan-mini-inject-server at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CPAN-Mini-Inject-Server>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CPAN::Mini::Inject::Server::Dispatch


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=CPAN-Mini-Inject-Server>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/CPAN-Mini-Inject-Server>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/CPAN-Mini-Inject-Server>

=item * Search CPAN

L<http://search.cpan.org/dist/CPAN-Mini-Inject-Server/>

perldoc CPAN::Mini::Inject::Server::Dispatch

=back

=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Christopher Mckay.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of CPAN::Mini::Inject::Server::Dispatch
