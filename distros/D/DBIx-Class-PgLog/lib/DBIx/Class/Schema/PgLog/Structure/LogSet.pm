package DBIx::Class::Schema::PgLog::Structure::LogSet;

use strict;
use warnings FATAL => 'all';

=head1 NAME

DBIx::Class::Schema::PgLog::Structure::LogSet

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Perhaps a little code snippet.

    use DBIx::Class::Schema::PgLog::Structure::LogSet;

    my $foo = DBIx::Class::Schema::PgLog::Structure::LogSet->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';

=head1 TABLE: C<LogSet>

=cut

__PACKAGE__->table("LogSet");

=head1 ACCESSORS

=head2 Id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: '"LogSet_Id_seq"'

=head2 Epoch

  data_type: 'integer'
  is_nullable: 0

=head2 Description 

  data_type: 'text'
  is_nullable: 0

=head2 UserId 

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "Id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "\"LogSet_Id_seq\"",
  },
  "Epoch",
  { data_type => "integer", is_nullable => 0 },
  "Description",
  { data_type => "text", is_nullable => 0},
  "UserId",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</Id>

=back

=cut

__PACKAGE__->set_primary_key("Id");



=head1 AUTHOR

Sheeju Alex, C<< <sheeju at exceleron.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-pglog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-PgLog>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Schema::PgLog::Structure::Log


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-PgLog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-PgLog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-PgLog>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-PgLog/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Sheeju Alex.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

__PACKAGE__->meta->make_immutable;
1; # End of DBIx::Class::Schema::PgLog::Structure::LogSet
