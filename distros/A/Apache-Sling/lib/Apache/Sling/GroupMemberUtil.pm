#!/usr/bin/perl -w

package Apache::Sling::GroupMemberUtil;

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
    my ( $base_url, $act_on_group, $add_member ) = @_;
    if ( !defined $base_url ) { croak 'No base url defined to add against!'; }
    if ( !defined $act_on_group ) {
        croak 'No group name defined to add to!';
    }
    if ( !defined $add_member ) { croak 'Group addition detail missing!'; }
    my $post_variables =
      "\$post_variables = [':member','/system/userManager/user/$add_member']";
    return
"post $base_url/system/userManager/group/$act_on_group.update.html $post_variables";
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
    my ( $base_url, $act_on_group, $delete_member ) = @_;
    if ( !defined $base_url ) {
        croak 'No base url defined to delete against!';
    }
    if ( !defined $act_on_group ) {
        croak 'No group name defined to delete from!';
    }
    if ( !defined $delete_member ) {
        croak 'Group deletion detail missing!';
    }
    my $post_variables =
"\$post_variables = [':member\@Delete','/system/userManager/user/$delete_member']";
    return
"post $base_url/system/userManager/group/$act_on_group.update.html $post_variables";
}

#}}}

#{{{sub delete_eval

sub delete_eval {
    my ($res) = @_;
    return ( ${$res}->code eq '200' && ${$res}->content ne q{} );
}

#}}}

1;

__END__

=head1 NAME

Apache::Sling::GroupMemberUtil Methods to generate and check HTTP requests required for manipulating groups.

=head1 ABSTRACT

Utility library returning strings representing Rest queries that perform
group related actions in the system.

=head1 METHODS

=head2 add_setup

Returns a textual representation of the request needed to add add a member to a
group in the system.

=head2 add_eval

Check result of adding a member to a group in the system.

=head2 delete_setup

Returns a textual representation of the request needed to delete a member from
a group in the system.

=head2 delete_eval

Check result of deleting a member from a group in the system.

=head1 USAGE

use Apache::Sling::GroupMemberUtil;

=head1 DESCRIPTION

GroupMemberUtil perl library essentially provides the request strings needed to
interact with group membership functionality exposed over the system rest
interfaces.

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
