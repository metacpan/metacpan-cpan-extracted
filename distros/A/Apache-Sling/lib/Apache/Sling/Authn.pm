#!/usr/bin/perl -w

package Apache::Sling::Authn;

use 5.008001;
use strict;
use warnings;
use Carp;
use LWP::UserAgent ();
use Apache::Sling::AuthnUtil;
use Apache::Sling::Print;
use Apache::Sling::Request;
use Apache::Sling::URL;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.27';

#{{{sub new
sub new {
    my ( $class, $sling ) = @_;
    my $url = Apache::Sling::URL::url_input_sanitize( ${$sling}->{'URL'} );
    my $verbose =
      ( defined ${$sling}->{'Verbose'} ? ${$sling}->{'Verbose'} : 0 );

    my $lwp_user_agent = $class->user_agent( ${$sling}->{'Referer'} );

    my $response;
    my $authn = {
        BaseURL  => "$url",
        LWP      => $lwp_user_agent,
        Type     => ${$sling}->{'Auth'},
        Username => ${$sling}->{'User'},
        Password => ${$sling}->{'Pass'},
        Message  => q{},
        Response => \$response,
        Verbose  => $verbose,
        Log      => ${$sling}->{'Log'}
    };

 # Authn references itself to be compatible with Apache::Sling::Request::request
    $authn->{'Authn'} = \$authn;

  # Add a reference to the authn object to the sling object to make it easier to
  # pass a subclassed authn object through:
    ${$sling}->{'Authn'} = \$authn;
    bless $authn, $class;
    return $authn;
}

#}}}

#{{{sub set_results
sub set_results {
    my ( $class, $message, $response ) = @_;
    $class->{'Message'}  = $message;
    $class->{'Response'} = $response;
    return 1;
}

#}}}

#{{{sub basic_login
sub basic_login {
    my ($authn) = @_;
    my $res =
      Apache::Sling::Request::request( \$authn,
        Apache::Sling::AuthnUtil::basic_login_setup( $authn->{'BaseURL'} ) );
    my $success = Apache::Sling::AuthnUtil::basic_login_eval($res);
    my $message = 'Basic auth log in ';
    $message .= ( $success ? 'succeeded!' : 'failed!' );
    $authn->set_results( "$message", $res );
    return $success;
}

#}}}

#{{{sub login_user
sub login_user {
    my ($authn) = @_;
    $authn->{'Type'} =
      ( defined $authn->{'Type'} ? $authn->{'Type'} : 'basic' );

    # Apply basic authentication to the user agent if url, username and
    # password are supplied:
    if (   defined $authn->{'BaseURL'}
        && defined $authn->{'Username'}
        && defined $authn->{'Password'} )
    {
        if ( $authn->{'Type'} eq 'basic' ) {
            my $success = $authn->basic_login();
            if ( !$success ) {
                if ( $authn->{'Verbose'} >= 1 ) {
                    Apache::Sling::Print::print_result($authn);
                }
                croak 'Basic Auth log in for user "'
                  . $authn->{'Username'}
                  . '" at URL "'
                  . $authn->{'BaseURL'}
                  . "\" was unsuccessful\n";
            }
        }
        else {
            croak 'Unsupported auth type: "' . $authn->{'Type'} . "\"\n";
        }
        if ( $authn->{'Verbose'} >= 1 ) {
            Apache::Sling::Print::print_result($authn);
        }
    }
    return 1;
}

#}}}

#{{{sub switch_user
sub switch_user {
    my ( $authn, $new_username, $new_password, $type, $check_basic ) = @_;
    if ( !defined $new_username ) {
        croak 'New username to switch to not defined';
    }
    if ( !defined $new_password ) {
        croak 'New password to use in switch not defined';
    }
    if (   ( $authn->{'Username'} !~ /^$new_username$/msx )
        || ( $authn->{'Password'} !~ /^$new_password$/msx ) )
    {
        my $old_username = $authn->{'Username'};
        my $old_password = $authn->{'Password'};
        my $old_type     = $authn->{'Type'};
        $authn->{'Username'} = $new_username;
        $authn->{'Password'} = $new_password;
        if ( defined $type ) {
            $authn->{'Type'} = $type;
        }
        $check_basic = ( defined $check_basic ? $check_basic : 0 );
        if ( $authn->{'Type'} eq 'basic' ) {
            if ($check_basic) {
                my $success = $authn->basic_login();
                if ( !$success ) {

                    # Reset credentials:
                    $authn->{'Username'} = $old_username;
                    $authn->{'Password'} = $old_password;
                    $authn->{'Type'}     = $old_type;
                    croak
                      "Basic Auth log in for user \"$new_username\" at URL \""
                      . $authn->{'BaseURL'}
                      . "\" was unsuccessful\n";
                }
            }
            else {
                $authn->{'Message'} = 'Fast User Switch completed!';
            }
        }
        else {

            # Reset credentials:
            $authn->{'Username'} = $old_username;
            $authn->{'Password'} = $old_password;
            $authn->{'Type'}     = $old_type;
            croak "Unsupported auth type: \"$type\"\n";
        }
    }
    else {
        $authn->{'Message'} = 'User already active, no need to switch!';
    }
    if ( $authn->{'Verbose'} >= 1 ) {
        Apache::Sling::Print::print_result($authn);
    }
    return 1;
}

#}}}

#{{{sub user_agent
sub user_agent {
    my ( $class, $referer ) = @_;
    my $lwp_user_agent = LWP::UserAgent->new( keep_alive => 1 );
    push @{ $lwp_user_agent->requests_redirectable }, 'POST';
    my $tmp_cookie_file_name;
    $lwp_user_agent->cookie_jar( { file => \$tmp_cookie_file_name } );
    if ( defined $referer ) {
        $lwp_user_agent->default_header( 'Referer' => $referer );
    }
    return \$lwp_user_agent;
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::Authn - Authenticate to an Apache Sling instance.

=head1 ABSTRACT

Useful utility functions for general Authn functionality.

=head1 METHODS

=head2 new

Create, set up, and return an Authn object.

=head2 set_results

Set a suitable message and response object.

=head2 basic_login

Perform basic authentication for a user.

=head2 login_user

Perform login authentication for a user.

=head2 switch_user

Switch to a different authenticated user.

=head1 USAGE

use Apache::Sling::Authn;

=head1 DESCRIPTION

Library providing useful utility functions for general Authn functionality.

=head1 REQUIRED ARGUMENTS

None required.

=head1 OPTIONS

n/a

=head1 DIAGNOSTICS

n/a

=head1 EXIT STATUS

0 on success.

=head1 CONFIGURATION

None required.

=head1 DEPENDENCIES

LWP::UserAgent

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>
