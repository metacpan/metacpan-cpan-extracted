package Barcode::DataMatrix;
use Moo;
use Barcode::DataMatrix::Engine ();

our $VERSION = '0.09';

has 'encoding_mode' => (
    is       => 'ro',
    isa      => sub { my $type = shift; for (qw(ASCII C40 TEXT BASE256 NONE AUTO)) { return 1 if $type eq $_ } return 0; },
    default  => 'AUTO',
    documentation => 'The encoding mode for the data matrix. Can be one of: ASCII C40 TEXT BASE256 NONE AUTO',
);
has 'size' => (
    is       => 'ro',
    isa      => sub { my $type = shift; return 1 if defined Barcode::DataMatrix::Engine::stringToFormat $type; return 0; },
    default  => 'AUTO',
    documentation => 'The module size for the data matrix. Can be one of: 10x10 12x12 14x14 16x16 18x18 20x20 22x22 24x24 26x26 32x32 36x36 40x40 44x44 48x48 52x52 64x64 72x72 80x80 88x88 96x96 104x104 120x120 132x132 144x144 8x18 8x32 12x26 12x36 16x36 16x48 AUTO',
);
has 'process_tilde' => (
    is       => 'ro',
    default  => 0,
    documentation => 'Boolean. Set to true to indicate the tilde character "~" is being used to recognize special characters.',
);

=head1 NAME

Barcode::DataMatrix - Generate data for Data Matrix barcodes

=head1 SYNOPSIS

    use Barcode::DataMatrix;
    my $data = Barcode::DataMatrix->new->barcode('MONKEY');
    for my $row (@$data) {
        print for map { $_ ? "#" : ' ' } @$row;
        print "\n";
    }

=cut

=head1 DESCRIPTION

This class is used to generate data for Data Matrix barcodes. It is primarily
useful as a data source for barcode modules that do rendering,
such as L<HTML::Barcode::DataMatrix>.  You can easily make a version that
renders an image, PDF, or anything else.

=head1 METHODS

=head2 new (%attributes)

Instantiate a new Barcode::DataMatrix object. The C<%attributes> hash
can take any of the other L<attributes|/ATTRIBUTES> listed below.

=cut

=head2 barcode ($text)

Generate barcode data representing the C<$text> string.  This returns
an array ref of rows in the data matrix, each containing array refs of
cells within that row. The cells are true and false values
that represent filled or empty squares.

This can throw an exception if it's unable to generate the barcode data.

=cut

sub barcode {
    my ($self, $text) = @_;

    my $engine = Barcode::DataMatrix::Engine->new(
        $text,
        $self->encoding_mode,
        $self->size,
        $self->process_tilde,
    );

    my $rows = $engine->{rows};
    my $cols = $engine->{cols};
    my $bitmap = $engine->{bitmap};
    my $rv = [];
    for my $r (0 .. $rows - 1) {
        my $row = [];
        for my $c (0 .. $cols - 1) {
            push @$row, ($bitmap->[$c]->[$r] ? 1 : 0);
        }
        push @$rv, $row;
    }

    return $rv;
}

=head1 ATTRIBUTES

=head2 encoding_mode

The encoding mode for the data matrix. Can be one of:
C<AUTO> (default), C<ASCII>, C<C40>, C<TEXT>, C<BASE256>, or C<NONE>.

=head2 size

The module size for the data matrix. Can be one of:
C<AUTO> (default), C<10x10>, C<12x12>, C<14x14>, C<16x16>, C<18x18>, C<20x20>, C<22x22>, C<24x24>, C<26x26>, C<32x32>, C<36x36>, C<40x40>, C<44x44>, C<48x48>, C<52x52>, C<64x64>, C<72x72>, C<80x80>, C<88x88>, C<96x96>, C<104x104>, C<120x120>, C<132x132>, C<144x144>, C<8x18>, C<8x32>, C<12x26>, C<12x36>, C<16x36>, C<16x48>.

=head2 process_tilde

Boolean. Set to true to indicate the tilde character "~" is being used to recognize
special characters. See this page for more information:
L<http://www.idautomation.com/datamatrixfaq.html>

=cut

=head1 AUTHORS

Mons Anderson C<< <inthrax@gmail.com> >> (GD::Barcode::DataMatrix at L<https://github.com/Mons/perl-ex/>, from which this distribution originates)

Mark A. Stratman, C<< <stratman@gmail.com> >>

Paul Cochrane, L<https://github.com/paultcochrane>

=head1 SOURCE REPOSITORY

L<http://github.com/mstratman/Barcode-DataMatrix>

=head1 SEE ALSO

=over 4

=item L<HTML::Barcode::DataMatrix>

=item L<http://grandzebu.net/informatique/codbar-en/datamatrix.htm>

=item L<http://www.idautomation.com/datamatrixfaq.html>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015 the AUTHORs listed above.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Barcode::DataMatrix
