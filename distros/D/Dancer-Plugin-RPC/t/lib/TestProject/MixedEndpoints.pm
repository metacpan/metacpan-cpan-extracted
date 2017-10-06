package TestProject::MixedEndpoints;
use warnings;
use strict;

=head1 DESCRIPTION

Package with calls for diffent endpoints.

=head2 call_for_system

=for xmlrpc system.call call_for_system /system

=for jsonrpc system_call call_for_system /system

=for restrpc call call_for_system /system

=cut

sub call_for_system { return {endpoint => '/system'} }

=head2 call_for_testing

=for xmlrpc testing.call call_for_testing /testing

=for jsonrpc testing_call call_for_testing /testing

=for restrpc call call_for_testing /testing

=cut

sub call_for_testing { return {endpoint => '/testing'} }


=head2 call_for_all_endpoints

=for xmlrpc any.call call_for_all_endpoints

=for jsonrpc any_call call_for_all_endpoints

=for restrpc any-call call_for_all_endpoints

=cut

sub call_for_all_endpoints { return {endpoint => '*'} }

1;
