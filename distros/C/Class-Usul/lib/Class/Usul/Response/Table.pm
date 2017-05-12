package Class::Usul::Response::Table;

use namespace::autoclean;

use Moo;
use Class::Usul::Types qw( ArrayRef HashRef Int Str );

has 'caption'  => is => 'ro', isa => Str,           default => q();
has 'class'    => is => 'ro', isa => HashRef | Str, default => q();
has 'classes'  => is => 'ro', isa => HashRef,       default => sub { {} };
has 'count'    => is => 'ro', isa => Int,           default => 0;
has 'fields'   => is => 'ro', isa => ArrayRef,      default => sub { [] };
has 'hclass'   => is => 'ro', isa => HashRef,       default => sub { {} };
has 'labels'   => is => 'ro', isa => HashRef,       default => sub { {} };
has 'sizes'    => is => 'ro', isa => HashRef,       default => sub { {} };
has 'typelist' => is => 'ro', isa => HashRef,       default => sub { {} };
has 'values'   => is => 'ro', isa => ArrayRef,      default => sub { [] };
has 'widths'   => is => 'ro', isa => HashRef,       default => sub { {} };
has 'wrap'     => is => 'ro', isa => HashRef,       default => sub { {} };

1;

__END__

=pod

=head1 Name

Class::Usul::Response::Table - Data structure for the table widget

=head1 Synopsis

   use Class::Usul::Response::Table;

   $table_obj = Class::Usul::Response::Table->new( \%params );

=head1 Description

Response class for the table widget in L<HTML::FormWidgets>

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item C<caption>

=item C<class>

=item C<classes>

=item C<count>

=item C<fields>

=item C<hclass>

=item C<labels>

=item C<sizes>

=item C<typelist>

=item C<values>

=item C<widths>

=item C<wrap>

=back

=head1 Subroutines/Methods

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module.
Please report problems to the address below.
Patches are welcome

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
