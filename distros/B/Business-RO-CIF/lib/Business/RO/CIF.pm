package Business::RO::CIF;
$Business::RO::CIF::VERSION = '0.005';
# ABSTRACT: Romanian CIF validation

use Moo;
use 5.010;
use utf8;
use Types::Standard qw(Int ArrayRef Str);

has 'cif' => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has 'errstr' => (
    is       => 'rw',
    isa      => Str,
    default  => sub {''},
);

has 'rev_key' => (
    is       => 'lazy',
    isa      => ArrayRef,
    init_arg => undef,
);

sub _build_rev_key {
    my $self = shift;
    my @revkey = reverse split //, '753217532';
    return \@revkey;
}

has 'checksum' => (
    is       => 'rw',
    isa      => Int,
    init_arg => undef,
);

has 'rev_cif' => (
    is       => 'lazy',
    isa      => ArrayRef,
    init_arg => undef,
);

sub _build_rev_cif {
    my $self = shift;
    if ( my $cif = $self->cif ) {
        my @revcif = reverse split //, $cif;
        $self->checksum(shift @revcif);
        return \@revcif;
    }
    else {
        die "No CIF?";
    }
}

sub valid {
    my $self = shift;

    if ( $self->cif =~ m{[^0-9]} ) {
        $self->errstr('The input string contains invalid characters');
        return 0;
    }

    my @rev_cif = @{ $self->rev_cif };
    my @rev_key = @{ $self->rev_key };

    my $len = scalar @rev_cif;
    if ($len < 5) {
        $self->errstr('The input is too short (< 5)');
        return 0;
    }
    if ($len > 9) {
        $self->errstr('The input is too long (> 9)');
        return 0;
    }

    my $sum = 0;
    foreach ( 0 .. $#rev_cif ) {
        $sum += $rev_cif[$_] * $rev_key[$_];
    }

    my $m11 = $sum * 10 % 11;
    my $ctc = $m11 == 10 ? 0 : $m11;

    if ( $self->checksum == $ctc ) {
        return 1;
    }
    else {
        $self->errstr('The checksum failed');
        return 0;
    }
    return
}

sub BUILDARGS {
    my ( $class, @args ) = @_;
    if ( @args == 1 && !ref $args[0] ) {
        $args[0] =~ s{^RO\s*}{}i;
        return { cif => $args[0] };
    }
    else {
        my %para = @args;
        $para{cif} =~ s{^RO\s*}{}i;
        return \%para;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Business::RO::CIF - Romanian CIF validation

=head1 VERSION

version 0.005

=head1 SYNOPSIS

use Business::RO::CIF;

my $cif = Business::RO::CIF->new( cif => 123456789 );

or

my $cif = Business::RO::CIF->new( 'RO 123456789' );

say $cif->errstr unless $cif->valid;

=head1 DESCRIPTION

Romanian CIF (ro: Cod de Identificare Fiscală; en: Tax Identification
Code) validation.

=head1 ATTRIBUTES

=head2 C<cif>

The C<cif> attribute holds the input CIF string.  It should contain
only Arabic numerals (0-9).

=head2 C<errstr>

The C<errstr> attribute holds a message string that describes what
part of the validation algorithm failed.

=head2 C<rev_key>

The C<rev_key> attribute is a array reference of the validation
string, in reverse order.

=head2 C<rev_cif>

The C<rev_cif> attribute is a array reference of the input string,
without the checksum digit, in reverse order.

=head2 C<checksum>

The C<checksum> attribute holds the last character (digit) of the
input string.

=head1 METHODS

=head2 C<valid>

The C<valid> method implements the validation algorithm for the Romanian CIF.

Returns 1 if the CIF is valid and 0 otherwise.

=head2 BUILDARGS

Override C<BUILDARGS> to also allow a single value parameter and
remove the country code (RO) if present.

=head1 BUGS

Please report any bugs or feature requests to C<bug-business-ro-cif at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Business-RO-CIF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Business::RO::CIF

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Business-RO-CIF>

=item * Search CPAN

L<http://search.cpan.org/dist/Business-RO-CIF/>

=back

=head1 SEE ALSO

Other module(s) in the same namespace:

=over

=item L<Business::RO::CNP>

=back

=head1 ACKNOWLEDGEMENTS

This project was created with at the initiative and the suggestion
made by Árpád Szász.

The module is inspired from the Business::RO::CNP module by Octavian
Râșniță (TEDDY).

The validation algorithm is from
L<http://ro.wikipedia.org/wiki/Cod_de_Identificare_Fiscal%C4%83>.

=head1 AUTHOR

Ștefan Suciu <stefan@s2i2.ro>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ștefan Suciu.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
