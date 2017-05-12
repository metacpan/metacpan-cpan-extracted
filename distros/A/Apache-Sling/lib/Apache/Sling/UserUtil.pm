#!/usr/bin/perl -w

package Apache::Sling::UserUtil;

use 5.008001;
use strict;
use warnings;
use Carp;
use Apache::Sling::URL;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.27';

#{{{sub add_setup

sub add_setup {
    my ( $base_url, $act_on_user, $act_on_pass, $properties ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined to add against!'; }
    if ( !defined $act_on_user ) { croak 'No user name defined to add!'; }
    if ( !defined $act_on_pass ) {
        croak "No user password defined to add for user $act_on_user!";
    }
    my $property_post_vars =
      Apache::Sling::URL::properties_array_to_string($properties);
    my $post_variables =
"\$post_variables = [':name','$act_on_user','pwd','$act_on_pass','pwdConfirm','$act_on_pass'";
    if ( $property_post_vars ne q{} ) {
        $post_variables .= ",$property_post_vars";
    }
    $post_variables .= ']';
    return "post $base_url/system/userManager/user.create.html $post_variables";
}

#}}}

#{{{sub add_eval
# Return true if the return code is 200 or 201
# to support Sakai Nakamura using the more correct
# 201 "Created" return code:

sub add_eval {
    my ($res) = @_;
    return ( ${$res}->code =~ /^20(0|1)$/x );
}

#}}}

#{{{sub change_password_setup

sub change_password_setup {
    my ( $base_url, $act_on_user, $act_on_pass, $new_pass, $new_pass_confirm ) =
      @_;
    if ( !defined $base_url ) { croak 'No base url defined!'; }
    if ( !defined $act_on_user ) {
        croak 'No user name defined to change password for!';
    }
    if ( !defined $act_on_pass ) {
        croak "No current password defined for $act_on_user!";
    }
    if ( !defined $new_pass ) {
        croak "No new password defined for $act_on_user!";
    }
    if ( !defined $new_pass_confirm ) {
        croak "No confirmation of new password defined for $act_on_user!";
    }
    my $post_variables =
"\$post_variables = ['oldPwd','$act_on_pass','newPwd','$new_pass','newPwdConfirm','$new_pass_confirm']";
    return
"post $base_url/system/userManager/user/$act_on_user.changePassword.html $post_variables";
}

#}}}

#{{{sub change_password_eval

sub change_password_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub delete_setup

sub delete_setup {
    my ( $base_url, $act_on_user ) = @_;
    if ( !defined $base_url ) {
        croak 'No base url defined to delete against!';
    }
    if ( !defined $act_on_user ) { croak 'No user name defined to delete!'; }
    my $post_variables = '$post_variables = []';
    return
"post $base_url/system/userManager/user/$act_on_user.delete.html $post_variables";
}

#}}}

#{{{sub delete_eval

sub delete_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub exists_setup

sub exists_setup {
    my ( $base_url, $act_on_user ) = @_;
    if ( !defined $base_url ) {
        croak 'No base url to check existence against!';
    }
    if ( !defined $act_on_user ) {
        croak 'No user to check existence of defined!';
    }
    return "get $base_url/system/userManager/user/$act_on_user.tidy.json";
}

#}}}

#{{{sub exists_eval

sub exists_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub update_setup

sub update_setup {
    my ( $base_url, $act_on_user, $properties ) = @_;
    if ( !defined $base_url ) {
        croak 'No base url defined to update against!';
    }
    if ( !defined $act_on_user ) { croak 'No user name defined to update!'; }
    my $property_post_vars =
      Apache::Sling::URL::properties_array_to_string($properties);
    my $post_variables = '$post_variables = [';
    if ( $property_post_vars ne q{} ) {
        $post_variables .= "$property_post_vars";
    }
    $post_variables .= ']';
    return
"post $base_url/system/userManager/user/$act_on_user.update.html $post_variables";
}

#}}}

#{{{sub update_eval

sub update_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::UserUtil - Methods to generate and check HTTP requests required for manipulating users.

=head1 ABSTRACT

Utility library returning strings representing Rest queries that perform
user related actions in the system.

=head1 METHODS

=head2 add_setup

Returns a textual representation of the request needed to add the user to the
system.

=head2 add_eval

Check result of adding user to the system.

=head2 change_password_setup

Returns a textual representation of the request needed to change the password
of the user in the system.

=head2 change_password_eval

Verify whether the change password attempt for the user in the system was successful.

=head2 delete_setup

Returns a textual representation of the request needed to delete the user from
the system.

=head2 delete_eval

Check result of deleting user from the system.

=head2 exists_setup

Returns a textual representation of the request needed to test whether a given
username exists in the system.

=head2 exists_eval

Inspects the result returned from issuing the request generated in exists_setup
returning true if the result indicates the username does exist in the system,
else false.

=head2 update_setup

Returns a textual representation of the request needed to update the user in the
system.

=head2 update_eval

Check result of updateing user to the system.

=head1 USAGE

use Apache::Sling::UserUtil;

=head1 DESCRIPTION

UserUtil perl library essentially provides the request strings needed to
interact with user functionality exposed over the system rest interfaces.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

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

=head1 INCOMPATIBILITIES

None known.

=head1 BUGS AND LIMITATIONS

None known.

=head1 AUTHOR

Daniel David Parry <perl@ddp.me.uk>

=head1 LICENSE AND COPYRIGHT

LICENSE: http://dev.perl.org/licenses/artistic.html

COPYRIGHT: (c) 2011 Daniel David Parry <perl@ddp.me.uk>
