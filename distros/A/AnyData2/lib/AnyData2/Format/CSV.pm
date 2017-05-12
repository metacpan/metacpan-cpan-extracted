package AnyData2::Format::CSV;

use 5.008001;
use strict;
use warnings FATAL => 'all';

use base qw(AnyData2::Format AnyData2::Role::GuessImplementation);

use Carp 'croak';

=head1 NAME

AnyData2::Format::CSV - CSV format class for AnyData2

=cut

our $VERSION = '0.002';

=head1 METHODS

=head2 new

  my $af = AnyData2->new(
    CSV              => {},
    "File::Linewise" => { filename => File::Spec->catfile( $test_dir, "simple.csv" ) }
  );

constructs a CSV accessor, passes all options down to C<csv_class> beside
C<csv_class>, C<csv_cols> and C<csv_skip_first_row>. C<csv_class> is used
to instantiate the parser and prefers L<Text::CSV_XS> over L<Text::CSV>
by default.  When C<csv_skip_first_row> is set to a true value, the first
line of the csv isn't used to guess the names in C<csv_cols>. Specifying
C<csv_cols> always wins over any value of C<csv_skip_first_row>.

=cut

sub new
{
    my ( $class, $storage, %options ) = @_;
    my $self = $class->SUPER::new($storage);

    my $csv_class          = delete $options{csv_class};
    my $csv_skip_first_row = delete $options{csv_skip_first_row};

    defined $csv_class or $csv_class = $class->_guess_suitable_class(qw(Text::CSV_XS Text::CSV));

    my $csv = $csv_class->new( {%options} );
    $self->{csv} = $csv;

    # XXX
    $self->cols unless ( defined $csv_skip_first_row and $csv_skip_first_row );

    $self;
}

sub _handle_error
{
    my ( $self, $code, $str, $pos, $rec, $fld ) = @_;
    defined $pos and defined $rec and defined $fld and croak "record $rec at line $pos in $fld - $code - $str";
    defined $pos and defined $rec and croak "record $rec at line $pos - $code - $str";
    croak "$code - $str";
}

=head2 cols

Deliver the columns of the CSV ...

=cut

sub cols
{
    my $self = shift;
    defined $self->{csv_cols} and return $self->{csv_cols};
    $self->{csv_cols} = $self->fetchrow;
}

=head2 fetchrow

Parses a line read from storage and return the result

=cut

sub fetchrow
{
    my $self = shift;
    my $buf  = $self->{storage}->read();
    defined $buf or return;
    my $stat = $self->{csv}->parse($buf);
    $stat or return $self->_handle_error( $self->{csv}->error_diag );
    [ $self->{csv}->fields ];
}

=head2 pushrow

Encodes values and write to storage

=cut

sub pushrow
{
    my ( $self, $fields ) = @_;
    my $stat = $self->{csv}->combine(@$fields);
    $stat or return $self->_handle_error( $self->{csv}->error_diag );
    $self->{storage}->write( $self->{csv}->string );
}

=head1 LICENSE AND COPYRIGHT

Copyright 2015,2016 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

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
direct or contributory patent infringement, then this License
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

1;
