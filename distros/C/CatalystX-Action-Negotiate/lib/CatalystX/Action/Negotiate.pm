package CatalystX::Action::Negotiate;

use 5.010;
use strict;
use warnings;

use Moose;

extends 'Catalyst::Action';
with 'CatalystX::ActionRole::Negotiate';

=head1 NAME

CatalystX::ActionRole::Negotiate - ActionRole for content negotiation

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    sub foo :Private :ActionClass('+CatalystX::Action::Negotiate') {
        # ...
    }

    sub bar :Does('+CatalystX::ActionRole::Negotiate') {
        # ... see this module's docs
    }

=head1 DESCRIPTION

This module is the stand-alone object-oriented form of the role
L<CatalystX::ActionRole::Negotiate>.

=head1 SEE ALSO

=over 4

=item

L<Catalyst::Action>

=item

L<HTTP::Negotiate>

=item

L<Role::MimeInfo>

=back

=head1 AUTHOR

Dorian Taylor, C<< <dorian at cpan.org> >>

=head1 BUGS

Please report bugs
L<on GitHub|https://github.com/doriantaylor/p5-catalystx-action-negotiate/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CatalystX::Action::Negotiate

You can also look for information at:

=over 4

=item * MetaCPAN

L<http://metacpan.org/release/CatalystX-Action-Negotiate/>

=item * The source

L<https://github.com/doriantaylor/p5-catalystx-action-negotiate>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Dorian Taylor.

Licensed under the Apache License, Version 2.0 (the "License"); you
may not use this file except in compliance with the License.  You may
obtain a copy of the License at
L<http://www.apache.org/licenses/LICENSE-2.0>.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.

=cut

1; # End of CatalystX::ActionRole::Negotiate
