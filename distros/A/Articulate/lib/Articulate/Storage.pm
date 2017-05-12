package Articulate::Storage;
use strict;
use warnings;

use Moo;
extends 'Articulate::Storage::Local'; # let's cheat
with 'Articulate::Role::Component';

=head1 NAME

Articulate::Storage - store and retrieve your content

=head1 DESCRIPTION

This class doesn't delegate yet. At the moment, it's cheating and extending L<Articulate::Storage::Local>. Use one of the storage providers listed below.

=cut

=head1 SEE ALSO

=item * L<Articulate::Storage::Local>

=item * L<Articulate::Storage::DBIC::Simple>

=item * L<Articulate::Caching>

=cut

1;
