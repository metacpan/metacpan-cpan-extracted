#!/usr/bin/perl -w

package Apache::Sling::GroupUtil;

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
    my ( $base_url, $act_on_group, $properties ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined to add against!'; }
    if ( !defined $act_on_group ) { croak 'No group name defined to add!'; }

    # property_post_vars is set to q{} if no properties are specified:
    my $property_post_vars =
      Apache::Sling::URL::properties_array_to_string($properties);
    my $post_variables = "\$post_variables = [':name','$act_on_group'";
    if ( $property_post_vars ne q{} ) {
        $post_variables .= ",$property_post_vars";
    }
    $post_variables .= "]";
    return
      "post $base_url/system/userManager/group.create.html $post_variables";
}

#}}}

#{{{sub add_eval

sub add_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub delete_setup

sub delete_setup {
    my ( $base_url, $act_on_group ) = @_;
    if ( !defined $base_url ) {
        croak 'No base url defined to delete against!';
    }
    if ( !defined $act_on_group ) { croak 'No group name defined to delete!'; }
    my $post_variables = q{$post_variables = []};
    return
"post $base_url/system/userManager/group/$act_on_group.delete.html $post_variables";
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
    my ( $base_url, $act_on_group ) = @_;
    if ( !defined $base_url ) {
        croak 'No base url to check existence against!';
    }
    if ( !defined $act_on_group ) {
        croak 'No group to check existence of defined!';
    }
    return "get $base_url/system/userManager/group/$act_on_group.json";
}

#}}}

#{{{sub exists_eval

sub exists_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' );
}

#}}}

#{{{sub view_setup

sub view_setup {
    my ( $base_url, $act_on_group ) = @_;
    if ( !defined $base_url )     { croak 'No base url to view with defined!'; }
    if ( !defined $act_on_group ) { croak 'No group to view defined!'; }
    return "get $base_url/system/userManager/group/$act_on_group.tidy.json";
}

#}}}

#{{{sub view_eval

sub view_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' && ${$res}->content ne q{} );
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::GroupUtil Methods to generate and check HTTP requests required for manipulating groups.

=head1 ABSTRACT

Utility library returning strings representing Rest queries that perform
group related actions in the system.

=head1 METHODS

=head2 add_setup

Returns a textual representation of the request needed to add the group to the
system.

=head2 add_eval

Check result of adding group to the system.

=head2 delete_setup

Returns a textual representation of the request needed to delete the group from
the system.

=head2 delete_eval

Check result of deleting group from the system.

=head2 exists_setup

Returns a textual representation of the request needed to test whether a given
group exists in the system.

=head2 exists_eval

Inspects the result returned from issuing the request generated in exists_setup
returning true if the result indicates the group does exist in the system, else
false.

=head2 view_setup

Returns a textual representation of the request needed to view a given group in
the system. This function is similar to exists expect authentication is forced.

=head2 view_eval

Inspects the result returned from issuing the request generated in view_setup
returning true if the result indicates the group view was returned, else false.

=head1 USAGE

use Apache::Sling::GroupUtil;

=head1 DESCRIPTION

GroupUtil perl library essentially provides the request strings needed to
interact with group functionality exposed over the system rest interfaces.

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
