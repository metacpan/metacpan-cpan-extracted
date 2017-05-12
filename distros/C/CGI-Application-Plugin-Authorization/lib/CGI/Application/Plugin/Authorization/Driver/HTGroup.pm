package CGI::Application::Plugin::Authorization::Driver::HTGroup;

use strict;
use warnings;

use base qw(CGI::Application::Plugin::Authorization::Driver);
use Apache::Htgroup;


=head1 NAME

CGI::Application::Plugin::Authorization::Driver::HTGroup - HTGroup Authorization driver


=head1 SYNOPSIS

 use base qw(CGI::Application);
 use CGI::Application::Plugin::Authorization;

 __PACKAGE__->authz->config(
     DRIVER => [ 'HTGroup', '/etc/apache/myapp/htgroup', '/etc/apache/htgroup' ],
 );


=head1 METHODS

=head2 authorize_user

This method accepts a username followed by a list of group names and will return
true if the user belongs to at least one of the groups.

=cut

sub authorize_user {
    my $self     = shift;
    my $username = shift;
    my @groups   = @_;

    # verify that all the options are OK
    my @files = $self->options;
    die "The HTGroup driver requires at least one htgroup file" unless @files;

    foreach my $file (@files) {
        my $htgroup = Apache::Htgroup->load($file); #dies if it can't load the file
        foreach my $group (@groups) {
            return 1 if $htgroup->ismember($username, $group);
        }
    }
    return 0;
}


=head1 SEE ALSO

L<CGI::Application::Plugin::Authorization::Driver>, L<CGI::Application::Plugin::Authorization>, perl(1)


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
