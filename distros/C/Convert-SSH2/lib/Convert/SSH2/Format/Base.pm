package Convert::SSH2::Format::Base;

use Moo;

our $VERSION = '0.01';

=head1 NAME

Convert::SSH2::Format::Base - Base class for SSH2 formatters

=head1 PURPOSE

Subclass this module to implement your own RSA SSH2 key reformatters.

=head1 ATTRIBUTES

=over

=item e

The public exponent component of an RSA public key.

=back

=cut

has 'e' => (
    is => 'ro',
    required => 1,
);

=over

=item n

The modulus component of an RSA public key.

=back

=cut

has 'n' => (
    is => 'ro',
    required => 1,
);

=over

=item line_width

How many characters should make a line. Defaults to 64.

=back

=cut

has 'line_width' => (
    is => 'ro',
    default => sub { 64 },
);

=head1 METHOD

=over

=item generate()

Using C<n> and C<e>, generate a representation in a specific format.

=back

=cut

sub generate {
    die "Subclass me.";
}

=over

=item format_lines()

Given a string, insert newlines every C<line_width> characters.

Returns formatted string.

=back

=cut

sub format_lines {
    my $self = shift;
    my $string = shift;

    my $out;
    my $len = length($string);
    for ( my $pos = 0 ; $pos < $len ; $pos += $self->line_width ) {
        $out .= substr($string, $pos, $self->line_width) . "\n";
    }

    return $out;
}

=head1 SEE ALSO

L<Convert::SSH2>

=cut

1;
