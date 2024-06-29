package CGI::Application::Plugin::Authentication::Display::Classic;
$CGI::Application::Plugin::Authentication::Display::Classic::VERSION = '0.25';
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
    my $credentials = $self->_cgiapp->authen->credentials;
    my $runmode     = $self->_cgiapp->get_current_runmode;
    my $destination = $self->_cgiapp->authen->_detaint_destination || $self->_cgiapp->authen->_detaint_selfurl;
    my $action      = $self->_cgiapp->authen->_detaint_url;
    my $username    = $credentials->[0];
    my $password    = $credentials->[1];
    my $login_form  = $self->_cgiapp->authen->_config->{LOGIN_FORM} || {};
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
        INCLUDE_STYLESHEET      => 1,
        FORM_SUBMIT_METHOD      => 'post',
        %$login_form,
    );

    my $messages = '';
    if ( my $attempts = $self->_cgiapp->authen->login_attempts ) {
        $messages .= '<li class="warning">' . sprintf($options{INVALIDPASSWORD_MESSAGE}, $attempts) . '</li>';
    } elsif ($options{COMMENT}) {
        $messages .= "<li>$options{COMMENT}</li>";
    }

    my $tabindex = 3;
    my ($rememberuser, $username_value, $register, $forgotpassword, $javascript, $style) = ('','','','','','');
    if ($options{FOCUS_FORM_ONLOAD}) {
        $javascript .= "document.loginform.${username}.focus();\n";
    }
    if ($options{REMEMBERUSER_OPTION}) {
        $rememberuser = qq[<input id="authen_rememberuserfield" tabindex="$tabindex" type="checkbox" name="authen_rememberuser" value="1" />$options{REMEMBERUSER_LABEL}<br />];
        $tabindex++;
        $username_value = $self->_cgiapp->authen->_detaint_username($username, $options{REMEMBERUSER_COOKIENAME});
        $javascript .= "document.loginform.${username}.select();\n" if $username_value;
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
    if ($options{INCLUDE_STYLESHEET}) {
        my $login_styles = $self->_login_styles;
        $style = <<EOS;
<style type="text/css">
<!--/* <![CDATA[ */
$login_styles
/* ]]> */-->
</style>
EOS
    }
    if ($javascript) {
        $javascript = qq[<script type="text/javascript" language="JavaScript">$javascript</script>];
    }

    my $html .= <<END;
$style
<form name="loginform" method="$options{FORM_SUBMIT_METHOD}" action="${action}">
  <div class="login">
    <div class="login_header">
      $options{TITLE}
    </div>
    <div class="login_content">
      <ul class="message">
${messages}
      </ul>
      <fieldset>
        <label for="${username}">$options{USERNAME_LABEL}</label>
        <input id="authen_loginfield" tabindex="1" type="text" name="${username}" size="20" value="$username_value" /><br />
        <label for="${password}">$options{PASSWORD_LABEL}</label>
        <input id="authen_passwordfield" tabindex="2" type="password" name="${password}" size="20" /><br />
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
$javascript
END

    return $html;
}

sub _login_styles {
    my $self = shift;
    my $login_form  = $self->_cgiapp->authen->_config->{LOGIN_FORM} || {};
    my %colour = ();

    $colour{base}    = $login_form->{BASE_COLOUR} || '#445588';
    $colour{lighter} = $login_form->{LIGHTER_COLOUR} if $login_form->{LIGHTER_COLOUR};
    $colour{light}   = $login_form->{LIGHT_COLOUR} if $login_form->{LIGHT_COLOUR};
    $colour{dark}    = $login_form->{DARK_COLOUR} if $login_form->{DARK_COLOUR};
    $colour{darker}  = $login_form->{DARKER_COLOUR} if $login_form->{DARKER_COLOUR};
    $colour{grey}    = $login_form->{GREY_COLOUR} if $login_form->{GREY_COLOUR};
    
    my @undefined_colours =  grep { ! defined $colour{$_} || index($colour{$_}, '%') >= 0 } qw(lighter light dark darker);
    if (@undefined_colours) {
        eval { require Color::Calc };
        if ($@ && $login_form->{BASE_COLOUR}) {
            warn "Color::Calc is required when specifying a custom BASE_COLOUR, and leaving LIGHTER_COLOUR, LIGHT_COLOUR, DARK_COLOUR or DARKER_COLOUR blank or when providing percentage based colour";
        }
        if ($@) {
            $colour{base}    = '#445588';
            $colour{lighter} = '#d0d5e1';
            $colour{light}   = '#a2aac4';
            $colour{dark}    = '#303c5f';
            $colour{darker}  = '#1b2236';
            $colour{grey}    = '#565656';
        } else {
            $colour{lighter} = !$colour{lighter}
                                    ? Color::Calc::light_html($colour{base}, 0.75)
                             : $colour{lighter} =~ m#(\d{2})%#
                                    ? Color::Calc::light_html($colour{base}, $1 / 100)
                             : $colour{lighter};
            $colour{light}   = !$colour{light}
                                    ? Color::Calc::light_html($colour{base}, 0.5)
                             : $colour{light} =~ m#(\d{2})%#
                                    ? Color::Calc::light_html($colour{base}, $1 / 100)
                             : $colour{light};
            $colour{dark}    = !$colour{dark}
                                    ? Color::Calc::dark_html($colour{base}, 0.3)
                             : $colour{dark} =~ m#(\d{2})%#
                                    ? Color::Calc::dark_html($colour{base}, $1 / 100)
                             : $colour{dark};
            $colour{darker}  = !$colour{darker}
                                    ? Color::Calc::dark_html($colour{base}, 0.6)
                             : $colour{darker} =~ m#(\d{2})%#
                                    ? Color::Calc::dark_html($colour{base}, $1 / 100)
                             : $colour{darker};
            #$colour{grey}    ||= Color::Calc::bw_html($colour{base});
            if (!$colour{grey}) {
                $colour{grey} = Color::Calc::bw_html($colour{base});
            }
        }
    }
    $colour{grey} ||= '#565656';
    return <<END;
div.login {
  width: 25em;
  margin: auto;
  padding: 3px;
  font-weight: bold;
  border: 2px solid $colour{base};
  color: $colour{dark};
  font-family: sans-serif;
}
div.login div {
  margin: 0;
  padding: 0;
  border: none;
}
div.login .login_header {
  background: $colour{base};
  border-bottom: 1px solid $colour{darker};
  height: 1.5em;
  padding: 0.45em;
  text-align: left;
  color: #fff;
  font-size: 100%;
  font-weight: bold;
}
div.login .login_content {
  background: $colour{lighter};
  padding: 0.8em;
  border-top: 1px solid white;
  border-bottom: 1px solid $colour{grey};
  font-size: 80%;
}
div.login .login_footer {
  background: $colour{light};
  border-top: 1px solid white;
  border-bottom: 1px solid white;
  text-align: left;
  padding: 0;
  margin: 0;
  min-height: 2.8em;
}
div.login fieldset {
  margin: 0;
  padding: 0;
  border: none;
  width: 100%;
}
div.login label {
  clear: left;
  float: left;
  padding: 0.6em 1em 0.6em 0;
  width: 8em;
  text-align: right;
}
/* image courtesy of http://www.famfamfam.com/lab/icons/silk/  */
#authen_loginfield {
  background: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAG5SURBVHjaYvz//z8DJQAggFiIVfh0twHn9w8KD9+/ZBT+9/cfExfvwwc87GxWAAFEtAFf3yl++/9XikHXL56BkYmJ4dKmcoUPT99PBQggRmK8ALT9v4BUBQMLrxxQMztY7N+PjwyXtk76BxBATMRoFjGewsDCx8jw9Oxyht9vboIxCDAxs/wCCCC8LoBrZv/A8PPpVoZ/39gZ7p57xcDLJ8Xw5tkdBrO8DYwAAcRElOYXaxn+/73DwC4vzyAmzsLw58kJsGaQOoAAYiJK868nDGwSXgxvjp1n+Hz7HoNawRFGmFqAAMIw4MBEDaI1gwBAAKEYsKtL/b9x2HSiNYMAQACBA3FmiqKCohrbfQ2nLobn97Yz6Br/JEozCAAEEDgh/eb6d98yYhEDBxsnw5VNZxnOffjLIKltw/D52B6GH89fMVjUnGbEFdgAAQRPiexMzAyfDk9gMJbmYbh17irDueMrGbjExBi8Oy8z4ksnAAEENuDY1S8MjjsnMSgaezJ8Z2Bm+P95PgPX6ycENYMAQACBwyDSUeQ/GzB926kLMEjwsjOwifKvcy05EkxMHgEIIEZKszNAgAEA+j3MEVmacXUAAAAASUVORK5CYII=') no-repeat 0 1px;
  background-color: #fff;
  border-top: solid 1px $colour{grey};
  border-left: solid 1px $colour{grey};
  border-bottom: solid 1px $colour{light};
  border-right: solid 1px $colour{light};
  padding: 2px 0 2px 18px;
  margin: 0.3em 0;
  width: 12em;
}
/* image courtesy of http://www.famfamfam.com/lab/icons/silk/  */
#authen_passwordfield {
  background: url('data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABGdBTUEAAK/INwWK6QAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAKbSURBVHjaYvz//z8DPvBko+s0IJUJ5U6X8d+dhSwPEEAMIANw4ccbXKYB8f8/P+6BMYgNEkNWAxBAhDV/Pff/5+t5/39/2gcU/gc25P5qpzkwdQABxIjNCzBnS7p2Mfz5tJ+BkVWE4dWRxWA5oBcYHiyyYnj5heGAedYxR4AAwmXAf0mPWQx/3q9n+P/3I9AAMaCoBsPr4x0MDH/+MUgHrGG4P8eF4fVf9gMAAcSEK/D+/3oA1gxm/3kLJG8wSDhWMAjoeTJ8fxjNoJDQzyD0+7sDQACx4DKAkVWcgZGZG2jIV6AJfxn+/37F8OfPO6BhRxl+f/nIwC7xluHPm58MAAHEhMX5ILHp787OYvj/7zvDr7f7Gf59vw804DUwPM4x/P3+loFb0ZfhVlc1wxMu7psAAcSCEd9MjAzswoYMAppmDD9e9DKwcIkwMHFyMPx+dZnh7+9vDDxqwQx3Ji1jeMrJc9W1/JQOQAAheyFT2mctw9+vpxh+fz7A8O1JDQMrEz/QK2YMb47uZpD0SmEAmsRwu7eJ4QUX1wWXklOGIE0AAcQIim9YShOzSmf49W4xw5+PdxlYeIUYWLh9GS6vXPH+3U/Gd3K/vikzcTAzvOTkOmNXeNIUZitAALFAbF4D9N8Bhl+vJjP8/vCUgY1fkoGZ24PhysoV7178Y9vmW3M8FqZBHS3MAAIIZMDnP59P835/3Mnw98t7Bg5xNQZGNnOgzSvfv2ZgX+dbfiwVX14BCCCQAbyMrNwMDKxcDOxi/Az/WU0YLi1b8/E9K8cqr6JjGQwEAEAAMf378+/cn+//GFi5bRiYuMOBzt7w4RMH50IPIjSDAEAAsbz8+Gfdh9VFEr9//WX7//s/009uzlmuWUcqGYgEAAEGAIZWUhP4bjW1AAAAAElFTkSuQmCC') no-repeat 0 1px;
  background-color: #fff;
  border-top: solid 1px $colour{grey};
  border-left: solid 1px $colour{grey};
  border-bottom: solid 1px $colour{light};
  border-right: solid 1px $colour{light};
  padding: 2px 0 2px 18px;
  margin: 0.3em 0;
  width: 12em;
}
#authen_rememberuserfield {
  clear: left;
  margin-left: 8em;
}
#authen_loginfield:focus {
  background-color: #ffc;
  color: #000;
}
#authen_passwordfield:focus {
  background-color: #ffc;
  color: #000;
}
div.login a {
  font-size: 80%;
  color: $colour{dark};
}
div.login div.buttons input {
  border-top: solid 2px $colour{light};
  border-left: solid 2px $colour{light};
  border-bottom: solid 2px $colour{grey};
  border-right: solid 2px $colour{grey};
  background-color: $colour{lighter};
  padding: .2em 1em ;
  font-size: 80%;
  font-weight: bold;
  color: $colour{dark};
}
div.login div.buttons {
  display: block;
  margin: 8px 4px;
  width: 100%;
}
#authen_loginbutton {
  float: right;
  margin-right: 1em;
}
#authen_registerlink {
  display: block;
}
#authen_forgotpasswordlink {
  display: block;
}
ul.message {
  margin-top: 0;
  margin-bottom: 0;
  list-style: none;
}
ul.message li {
  text-indent: -2em;
  padding: 0px;
  margin: 0px;
  font-style: italic;
}
ul.message li.warning {
  color: red;
}
END
}

=head1 NAME

CGI::Application::Plugin::Authentication::Display::Classic - login box that works out of the box

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

=item INCLUDE_STYLESHEET (default: 1)

use this to disable the built in style-sheet for the login box so you can provide your own custom styles

=item FORM_SUBMIT_METHOD (default: post)

use this to get the form to submit using 'get' instead of 'post'

=item FOCUS_FORM_ONLOAD (default: 1)

use this to automatically focus the login form when the page loads so a user can start typing right away.

=item BASE_COLOUR (default: #445588)

This is the base colour that will be used in the included login box.  All other
colours are automatically calculated based on this colour (unless you hardcode
the colour values).  In order to calculate other colours, you will need the
Color::Calc module.  If you do not have the Color::Calc module, then you will
need to use fixed values for all of the colour options.  All colour values
besides the BASE_COLOUR can be simple percentage values (including the % sign).
For example if you set the LIGHTER_COLOUR option to 80%, then the calculated
colour will be 80% lighter than the BASE_COLOUR.

=item LIGHT_COLOUR (default: 50% or #a2aac4)

A colour that is lighter than the base colour.

=item LIGHTER_COLOUR (default: 75% or #d0d5e1)

A colour that is another step lighter than the light colour.

=item DARK_COLOUR (default: 30% or #303c5f)

A colour that is darker than the base colour.

=item DARKER_COLOUR (default: 60% or #1b2236)

A colour that is another step darker than the dark colour.

=item GREY_COLOUR (default: #565656)

A grey colour that is calculated by desaturating the base colour.


=back

  LOGIN_FORM => {
    TITLE              => 'Login',
    SUBMIT_LABEL       => 'Login',
    REMEMBERUSER_LABEL => 1,
    BASE_COLOUR        => '#0099FF',
    LIGHTER_COLOUR     => '#AAFFFF',
    DARK_COLOUR        => '50%',
  }

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
Copyright (c) 2010, Nicholas Bamber. All rights reserved.

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

=cut

1;
