#!/usr/bin/perl

package Apache::Sling::AuthzUtil;

use 5.008001;
use strict;
use warnings;
use Carp;

require Exporter;

use base qw(Exporter);

our @EXPORT_OK = ();

our $VERSION = '0.27';

#{{{imports
use strict;
use lib qw ( .. );

#}}}

#{{{sub get_acl_setup

=pod

=head2 get_acl_setup

Returns a textual representation of the request needed to retrieve the ACL for
a node in JSON format.

=cut

sub get_acl_setup {
    my ( $base_url, $remote_dest ) = @_;
    croak "No base url defined!"                    unless defined $base_url;
    croak "No destination to view ACL for defined!" unless defined $remote_dest;
    return "get $base_url/$remote_dest.acl.json";
}

#}}}

#{{{sub get_acl_eval

=pod

=head2 get_acl_eval

Inspects the result returned from issuing the request generated in
get_acl_setup returning true if the result indicates the node ACL was returned
successfully, else false.

=cut

sub get_acl_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

#{{{sub delete_setup

=pod

=head2 delete_setup

Returns a textual representation of the request needed to retrieve the ACL for
a node in JSON format.

=cut

sub delete_setup {
    my ( $base_url, $remote_dest, $principal ) = @_;
    croak "No base url defined!" unless defined $base_url;
    croak "No destination to delete ACL for defined!"
      unless defined $remote_dest;
    croak "No principal to delete ACL for defined!" unless defined $principal;
    my $post_variables = "\$post_variables = [':applyTo','$principal']";
    return "post $base_url/$remote_dest.deleteAce.html $post_variables";
}

#}}}

#{{{sub delete_eval

=pod

=head2 delete_eval

Inspects the result returned from issuing the request generated in delete_setup
returning true if the result indicates the node ACL was deleted successfully,
else false.

=cut

sub delete_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

#{{{sub modify_privilege_setup

=pod

=head2 modify_privilege_setup

Returns a textual representation of the request needed to modify the privileges
on a node for a specific principal.

=cut

sub modify_privilege_setup {
    my ( $base_url, $remote_dest, $principal, $grant_privileges,
        $deny_privileges )
      = @_;
    croak "No base url defined!" unless defined $base_url;
    croak "No destination to modify privilege for defined!"
      unless defined $remote_dest;
    croak "No principal to modify privilege for defined!"
      unless defined $principal;
    my %privileges = (
        'read',                1, 'modifyProperties',    1,
        'addChildNodes',       1, 'removeNode',          1,
        'removeChildNodes',    1, 'write',               1,
        'readAccessControl',   1, 'modifyAccessControl', 1,
        'lockManagement',      1, 'versionManagement',   1,
        'nodeTypeManagement',  1, 'retentionManagement', 1,
        'lifecycleManagement', 1, 'all',                 1
    );
    my $post_variables = "\$post_variables = ['principalId','$principal',";
    foreach my $grant ( @{$grant_privileges} ) {
        if ( $privileges{$grant} ) {
            $post_variables .= "'privilege\@jcr:$grant','granted',";
        }
        else {
            croak "Unsupported grant privilege: \"$grant\" supplied!\n";
        }
    }
    foreach my $deny ( @{$deny_privileges} ) {
        if ( $privileges{$deny} ) {
            $post_variables .= "'privilege\@jcr:$deny','denied',";
        }
        else {
            croak "Unsupported deny privilege: \"$deny\" supplied!\n";
        }
    }
    $post_variables =~ s/,$/]/x;
    return "post $base_url/$remote_dest.modifyAce.html $post_variables";
}

#}}}

#{{{sub modify_privilege_eval

=pod

=head2 modify_privilege_eval

Inspects the result returned from issuing the request generated in
modify_privilege_setup returning true if the result indicates the privileges
were modified successfully, else false.

=cut

sub modify_privilege_eval {
    my ($res) = @_;
    return ( $$res->code =~ /^200$/x );
}

#}}}

1;

__END__

=head1 NAME

AuthzUtil - Utility library returning strings representing queries that perform
authz operations in the system.

=head1 ABSTRACT

AuthzUtil perl library essentially provides the request strings needed to
interact with authz functionality exposed over the system interfaces.

Each interaction has a setup and eval method. setup provides the request,
whilst eval interprets the response to give further information about the
result of performing the request.

=cut
