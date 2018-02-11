package CGI::Application::Plugin::Authentication::Display::Basic;
$CGI::Application::Plugin::Authentication::Display::Basic::VERSION = '0.22';
use base qw(CGI::Application::Plugin::Authentication::Display);

use 5.006;
use strict;
use warnings;
use Carp;

sub new {
    my $class = shift;
    my $cgiapp = shift;
    my $self = CGI::Application::Plugin::Authentication::Display->new($cgiapp);
    bless $self, $class;
    return $self;
}

sub login_box {
    my $self        = shift;
    croak "already authenticated" if $self->_cgiapp->authen->is_authenticated;
    my $credentials = $self->_cgiapp->authen->credentials;
    my $runmode     = $self->_cgiapp->get_current_runmode;
    my $destination = $self->_cgiapp->authen->_detaint_destination || $self->_cgiapp->authen->_detaint_selfurl;
    my $action      = $self->_cgiapp->authen->_detaint_url;
    my $username    = $credentials->[0];
    my $password    = $credentials->[1];
    my $login_form  = $self->_cgiapp->authen->_config->{LOGIN_FORM};
    my %options = (
        TITLE                   => 'Sign In',
        USERNAME_LABEL          => 'User Name',
        PASSWORD_LABEL          => 'Password',
        SUBMIT_LABEL            => 'Sign In',
        COMMENT                 => 'Please enter your username and password in the fields below.',
        REMEMBERUSER_OPTION     => 1,
        REMEMBERUSER_LABEL      => 'Remember User Name',
        REMEMBERUSER_COOKIENAME => 'CAPAUTHTOKEN',
        REGISTER_URL            => '',
        REGISTER_LABEL          => 'Register Now!',
        FORGOTPASSWORD_URL      => '',
        FORGOTPASSWORD_LABEL    => 'Forgot Password?',
        INVALIDPASSWORD_MESSAGE => 'Invalid username or password<br />(login attempt %d)',
        FORM_SUBMIT_METHOD      => 'post',
        %$login_form,
    );

    my $messages = '';
    if ( my $attempts = $self->_cgiapp->authen->login_attempts ) {
        $messages .= '<li class="warning">' . sprintf($options{INVALIDPASSWORD_MESSAGE}, $attempts) . '</li>';
    } else {
        $messages .= "<li>$options{COMMENT}</li>";
    }

    my $tabindex = 3;
    my ($rememberuser, $username_value, $register, $forgotpassword) = ('','','','');
    if ($options{REMEMBERUSER_OPTION}) {
        $rememberuser = <<END;
<label for="authen_rememberuserfield" id="authen_rememberuserfield_label" class="authen_label">$options{REMEMBERUSER_LABEL}
    <input id="authen_rememberuserfield" class="authen_input" tabindex="$tabindex" type="checkbox" name="authen_rememberuser" value="1" />
</label>
END
        $tabindex++;
        $username_value = $self->_cgiapp->authen->_detaint_username($username, $options{REMEMBERUSER_COOKIENAME});
    }
    my $submit_tabindex = $tabindex++;
    if ($options{REGISTER_URL}) {
        $register = qq[<a href="$options{REGISTER_URL}" id="authen_registerlink" tabindex="$tabindex">$options{REGISTER_LABEL}</a>];
        $tabindex++;
    }
    if ($options{FORGOTPASSWORD_URL}) {
        $forgotpassword = qq[<a href="$options{FORGOTPASSWORD_URL}" id="authen_forgotpasswordlink" tabindex="$tabindex">$options{FORGOTPASSWORD_LABEL}</a>];
        $tabindex++;
    }

    my $html .= <<END;
<form id="loginform" method="$options{FORM_SUBMIT_METHOD}" action="${action}">
  <div class="login">
    <div class="login_header">
      $options{TITLE}
    </div>
    <div class="login_content">
      <ul class="message">
${messages}
      </ul>
      <fieldset>
        <label for="authen_loginfield" id="authen_loginfield_label" class="authen_label">$options{USERNAME_LABEL}
            <input id="authen_loginfield" class="authen_input" tabindex="1" type="text" name="${username}" size="20" value="$username_value" />
        </label>    
        <label for="authen_passwordfield" id="authen_passwordfield_label" class="authen_label">$options{PASSWORD_LABEL}
            <input id="authen_passwordfield" class="authen_input" tabindex="2" type="password" name="${password}" size="20" />
        </label>
        ${rememberuser}
      </fieldset>
    </div>
    <div class="login_footer">
      <div class="buttons">
        <input id="authen_loginbutton" tabindex="${submit_tabindex}" type="submit" name="authen_loginbutton" value="$options{SUBMIT_LABEL}" class="button" />
        ${register}
        ${forgotpassword}
      </div>
    </div>
  </div>
  <input type="hidden" name="destination" value="${destination}" />
  <input type="hidden" name="rm" value="${runmode}" />
</form>
END

    return $html;
}

=head1 NAME

CGI::Application::Plugin::Authentication::Display::Basic - XHTML compliant no frills login display driver

=head1 DESCRIPTION 

This module provides a login box that works out of the box but which can be 
configured to modify the styling.

=head1 METHODS

=head2 new 

The constructor must be passed the L<CGI::Application> object as the first
non-object argument.

=head2 login_box

This method will return the HTML for a login box that can be
embedded into another page.  This is the same login box that is used
in the default authen_login runmode that the plugin provides.
Note that if somehow this method is run, whilst the user is authenticated, 
it will croak.

You can set this option to customize the login form that is created when a user
needs to be authenticated.  If you wish to replace the entire login form with a
completely custom version, then just set LOGIN_RUNMODE to point to your custom
runmode.

All of the parameters listed below are optional, and a reasonable default will
be used if left blank:

=over 4

=item TITLE (default: Sign In)

the heading at the top of the login box 

=item USERNAME_LABEL (default: User Name)

the label for the user name input

=item PASSWORD_LABEL (default: Password)

the label for the password input

=item SUBMIT_LABEL (default: Sign In)

the label for the submit button

=item COMMENT (default: Please enter your username and password in the fields below.)

a message provided on the first login attempt

=item REMEMBERUSER_OPTION (default: 1)

provide a checkbox to offer to remember the users name in a cookie so that
their user name will be pre-filled the next time they log in

=item REMEMBERUSER_LABEL (default: Remember User Name)

the label for the remember user name checkbox

=item REMEMBERUSER_COOKIENAME (default: CAPAUTHTOKEN)

the name of the cookie where the user name will be saved

=item REGISTER_URL (default: <none>)

the URL for the register new account link

=item REGISTER_LABEL (default: Register Now!)

the label for the register new account link

=item FORGOTPASSWORD_URL (default: <none>)

the URL for the forgot password link

=item FORGOTPASSWORD_LABEL (default: Forgot Password?)

the label for the forgot password link

=item INVALIDPASSWORD_MESSAGE (default: Invalid username or password<br />(login attempt %d)

a message given when a login failed

=item FORM_SUBMIT_METHOD (default: post)

use this to get the form to submit using 'get' instead of 'post'

=back

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

Thanks to Christian Walde for suggesting changes to fix the incompatibility with 
L<CGI::Application::Plugin::ActionDispatch> and for help with github.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, SiteSuite. All rights reserved.
Copyright (c) 2010, Nicholas Bamber.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
