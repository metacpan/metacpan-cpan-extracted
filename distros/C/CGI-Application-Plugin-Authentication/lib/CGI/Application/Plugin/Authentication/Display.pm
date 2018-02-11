package CGI::Application::Plugin::Authentication::Display;
$CGI::Application::Plugin::Authentication::Display::VERSION = '0.22';
use 5.006;
use strict;
use warnings;
use Carp;

sub new {
    my $class = shift;
    my $self = {};
    $self->{cgiapp} = shift;
    bless $self, $class;
    return $self;
}

sub _cgiapp {
    my $self = shift;
    return $self->{cgiapp};    
}

sub login_box {
    my $self = shift;
    croak "not implemented in base class";
}

sub logout_form {
    my $self = shift;
    return '<a id="authen_logout_link" href="?authen_logout=1">Logout</a>'
         if $self->_cgiapp->authen->is_authenticated;
    return '';
}

sub enforce_protection {
    my $self = shift;
    croak "Attempt to bypass authentication on protected template"
        if !$self->_cgiapp->authen->is_authenticated;
    return "<!-- AUTHENTICATED -->\n";
}

sub  is_authenticated {
    my $self = shift;
    return $self->_cgiapp->authen->is_authenticated;
}

sub  username {
    my $self = shift;
    return $self->_cgiapp->authen->username;
} 

sub  last_login {
    my $self = shift;
    return $self->_cgiapp->authen->last_login;
}

sub  last_access {
    my $self = shift;
	return $self->_cgiapp->authen->last_access;
}

sub  is_login_timeout  {
    my $self = shift;
	return $self->_cgiapp->authen->is_login_timeout;
}

sub  login_attempts {
    my $self = shift;
    return $self->_cgiapp->authen->login_attempts;
}

sub login_title {
     my $self = shift;
     my $login_options = $self->_cgiapp->authen->_config->{LOGIN_FORM} || {};
     return $login_options->{TITLE} || 'Sign In';
}


1; 

=head1 NAME

CGI::Application::Plugin::Authentication::Display - Generate bits of HTML needed for authentication

=head1 DESCRIPTION

The purpose of this code is to keep display code away from the back-end of
authentication management. It is an abstract base class and must be used 
in conjunction with derived classes. Those derived classes can be used
in an number of ways:

=over

=item

The subclass L<CGI::Application::Plugin::Authentication::Display::Classic>
is provided to ensure backwards compatibility with the old code. It has 
the advantage of working out of the box but still retaining flexibility.

=item

The subclass L<CGI::Application::Plugin::Authentication::Display::Basic>
is provided to ensure XHTML compliance and to leave styling to CSS style-sheets.

=item

You can handle all the HTML side yourself in which case this code is not even loaded.

=item 

You can use derived classes in templates that have dot support, which keeps
the display code close to the templates. This has other advantages. For example
one can use the C<enforce_protection> method to mark a template as being 
only viewable after authentication. A number of other methods can be called 
from the template that provide information about the authentication status.

=back

=head1 METHODS

=head2 new 

The constructor must be passed the L<CGI::Application> object as the first
non-object argument.  This allows derived modules to access the
authentication information.

=head2 login_box

This method will return the HTML for a login box that can be
embedded into another page.  This is the same login box that is used
in the default authen_login runmode that the plugin provides.

This function is not implemented in this module. One must use a derived class
with an appropriate implementation of this function.

=head2 logout_form

This returns the simple bit of HTML need to have a logout button. The form
has '/?authen_logout=1' as the action but of course this can be changed in
derived modules.

=head2 enforce_protection

This method is useful when the class is being used in templates to mark a
certain template as for authenticated eyes only. So in
L<HTML::Template::Plugin::Dot> one might have

    <TMPL_VAR NAME="authen.enforce_protection">
    
and one must set C<authen> to one of these objects via the
C<HTML::Template::param> method. If authenticated it will resolve to a 
simple string, otherwise it will croak.

=head2 login_title

This returns the I<TITLE> parameter from the I<LOGIN_FORM> section of the config.

=head2 is_authenticated 

=head2 username 

=head2 last_login

=head2 last_access

=head2 is_login_timeout

=head2 login_attempts

These methods all provide access to the cognate methods on the authentication
object. They are provided as templates might find them expressive. 

=head1 BUGS

This is alpha software and as such, the features and interface
are subject to change.  So please check the Changes file when upgrading.

=head1 SEE ALSO

L<CGI::Application>, perl(1)

=head1 AUTHOR

Author: Cees Hek <ceeshek@gmail.com>; Co-maintainer: Nicholas Bamber <nicholas@periapt.co.uk>.

=head1 CREDITS

Thanks to SiteSuite (http://www.sitesuite.com.au) for funding the 
development of this plugin and for releasing it to the world.

Thanks to Christian Walde for suggesting changes to fix the incompatibility
with L<CGI::Application::Plugin::ActionDispatch> and for help with github.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.
Copyright (c) 2010, Nicholas Bamber. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
