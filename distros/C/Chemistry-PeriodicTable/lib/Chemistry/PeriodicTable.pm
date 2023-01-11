package Chemistry::PeriodicTable;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Provide access to chemical element properties

our $VERSION = '0.0400';

use Moo;
use strictures 2;
use Carp qw(croak);
use File::ShareDir qw(dist_dir);
use List::SomeUtils qw(first_index);
use Text::CSV_XS ();
use namespace::clean;


has symbols => (is => 'lazy', init_args => undef);

sub _build_symbols {
    my ($self) = @_;
    my $symbols = $self->as_hash;
    return $symbols;
}


has header => (is => 'lazy', init_args => undef);

sub _build_header {
    my ($self) = @_;
    my @headers = $self->headers;
    return \@headers;
}


sub as_file {
    my ($self) = @_;

    my $file = eval { dist_dir('Chemistry-PeriodicTable') . '/Periodic-Table.csv' };
    $file = 'share/Periodic-Table.csv'
        unless $file && -e $file;

    return $file;
}


sub as_hash {
    my ($self) = @_;

    my $file = $self->as_file;

    my %data;

    my $csv = Text::CSV_XS->new({ binary => 1 });

    open my $fh, '<', $file
        or die "Can't read $file: $!";

    my $counter = 0;

    while (my $row = $csv->getline($fh)) {
        $counter++;

        # skip the first row
        next if $counter == 1;

        $data{ $row->[2] } = $row;
    }

    close $fh;

    return \%data;
}


sub headers {
    my ($self) = @_;

    my $file = $self->as_file;

    my @headers;

    my $csv = Text::CSV_XS->new({ binary => 1 });

    open my $fh, '<', $file
        or die "Can't read $file: $!";

    while (my $row = $csv->getline($fh)) {
        push @headers, @$row;
        last;
    }

    close $fh;

    return @headers;
}


sub number {
    my ($self, $string) = @_;
    my $n;
    if (length $string < 4) {
        $n = $self->symbols->{ ucfirst $string }[0];
    }
    else {
        for my $symbol (keys %{ $self->symbols }) {
            if (lc $self->symbols->{$symbol}[1] eq lc $string) {
                $n = $self->symbols->{$symbol}[0];
            }
        }
    }
    return $n;
}


sub name {
    my ($self, $string) = @_;
    my $n;
    for my $symbol (keys %{ $self->symbols }) {
        if (
            ($string =~ /^\d+$/ && $self->symbols->{$symbol}[0] == $string)
            ||
            (lc $self->symbols->{$symbol}[2] eq lc $string)
        ) {
            $n = $self->symbols->{$symbol}[1];
            last;
        }
    }
    return $n;
}


sub symbol {
    my ($self, $string) = @_;
    my $s;
    for my $symbol (keys %{ $self->symbols }) {
        if (
            ($string =~ /^\d+$/ && $self->symbols->{$symbol}[0] == $string)
            ||
            (lc $self->symbols->{$symbol}[1] eq lc $string)
        ) {
            $s = $symbol;
            last;
        }
    }
    return $s;
}


sub value {
    my ($self, $key, $string) = @_;
    my $v;
    my $idx = first_index { $_ =~ /$string/i } @{ $self->header };
    if ($key !~ /^\d+$/ && length $key < 4) {
        $v = $self->symbols->{$key}[$idx];
    }
    else {
        $key = $self->symbol($key);
        for my $symbol (keys %{ $self->symbols }) {
            next unless $symbol eq $key;
            $v = $self->symbols->{$symbol}[$idx];
            last;
        }
    }
    return $v;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chemistry::PeriodicTable - Provide access to chemical element properties

=head1 VERSION

version 0.0400

=head1 SYNOPSIS

  use Chemistry::PeriodicTable ();

  my $pt = Chemistry::PeriodicTable->new;

  my $filename = $pt->as_file;

  my $headers = $pt->header;
  my $symbols = $pt->symbols; # element properties keyed by symbol

  $pt->number('H');        # 1
  $pt->number('hydrogen'); # 1

  $pt->name(1);   # Hydrogen
  $pt->name('H'); # Hydrogen

  $pt->symbol(1);          # H
  $pt->symbol('hydrogen'); # H

  $pt->value('H', 'weight');               # 1.00794
  $pt->value(118, 'weight');               # 294
  $pt->value('hydrogen', 'Atomic Radius'); # 0.79

=head1 DESCRIPTION

C<Chemistry::PeriodicTable> provides access to chemical element properties.

=head1 ATTRIBUTES

=head2 symbols

  $symbols = $pt->symbols;

The computed hash-reference of the element properties.

=head2 header

  $headers = $pt->header;

The computed array-reference of the property headers.

=head1 METHODS

=head2 new

  $pt = Chemistry::PeriodicTable->new(verbose => 1);

Create a new C<Chemistry::PeriodicTable> object.

=head2 as_file

  $filename = $pt->as_file;

Return the data filename location.

=head2 as_hash

  $data = $pt->as_hash;

Return the data as a hash reference.

Keys are the element symbols and the values are the element
properties.

=head2 headers

  @headers = $pt->headers;

Return the data headers. These are:

  Atomic Number
  Element
  Symbol
  Atomic Weight
  Period
  Group
  Phase
  Most Stable Crystal
  Type
  Ionic Radius
  Atomic Radius
  Electronegativity
  First Ionization Potential
  Density
  Melting Point (K)
  Boiling Point (K)
  Isotopes
  Specific Heat Capacity
  Electron Configuration
  Display Row
  Display Column

=head2 number

  $n = $pt->number($symbol);
  $n = $pt->number($name);

Return the atomic number of either a symbol or name.

=head2 name

  $n = $pt->name($number);
  $n = $pt->name($symbol);

Return the atom name of either an atomic number or symbol.

=head2 symbol

  $s = $pt->symbol($number);
  $s = $pt->symbol($name);

Return the atomic symbol of either an atomic number or name.

=head2 value

  $v = $pt->value($number, $string);
  $v = $pt->value($name, $string);
  $v = $pt->value($symbol, $string);

Return the atomic value of the atomic number, name, or symbol and a
string indicating a unique part of a header name.

=head1 SEE ALSO

The F<t/01-methods.t> file.

L<Moo>

L<File::ShareDir>

L<List::SomeUtils>

L<Text::CSV_XS>

L<https://ptable.com/#Properties>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by Gene Boggs.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
