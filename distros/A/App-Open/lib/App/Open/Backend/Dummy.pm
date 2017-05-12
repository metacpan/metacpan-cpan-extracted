#
#===============================================================================
#
#         FILE:  Dummy.pm
#
#  DESCRIPTION:  Dummy backend
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Erik Hollensbe (), <erik@hollensbe.org>
#      COMPANY:
#      VERSION:  1.0
#      CREATED:  06/02/2008 05:54:21 AM PDT
#     REVISION:  ---
#===============================================================================

package App::Open::Backend::Dummy;

use strict;
use warnings;

=head1 NAME

App::Open::Backend::Dummy: A dummy backend for testing.

=head1 SYNOPSIS

Please read App::Open::Backend for information on how to use backends.

=head1 METHODS

Read App::Open::Backend for what the interface provides, method descriptions
here will only cover implementation.

=over 4

=item new

Boilerplate constructor.

=cut

sub new {
    bless {}, shift;
}

=item lookup_file

Returns 'dummy_file'

=cut

sub lookup_file { 'dummy_file' }

=item lookup_url

Returns 'dummy_url'

=cut

sub lookup_url  { 'dummy_url' }

=back

=head1 LICENSE

This file and all portions of the original package are (C) 2008 Erik Hollensbe.
Please see the file COPYING in the package for more information.

=head1 BUGS AND PATCHES

Probably a lot of them. Report them to <erik@hollensbe.org> if you're feeling
kind. Report them to CPAN RT if you'd prefer they never get seen.

=cut

1;
