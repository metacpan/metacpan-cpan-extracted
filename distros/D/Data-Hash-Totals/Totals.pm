package Data::Hash::Totals;

use warnings;
use strict;

=head1 NAME

Data::Hash::Totals - Handle hashes that are totals or counts

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

This module is so butt simple, but I'm tired of redoing this code over and over again.

    my %fave_stooge_votes = (
        Moe => 31,
        Larry => 15,
        Curly => 97,
        Shemp => 3,
    );

    print as_table( \%fave_stooge_votes );

prints the following:

      97 Curly
      31 Moe
      15 Larry
       3 Shemp

=cut

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( as_table );
our @EXPORT_OK = qw( as_table );

=head1 EXPORTS

Exports C<as_table>.

=head1 FUNCTIONS

=head2 as_table( $hashref [, key1 => value1 ] )

Prints the contents of I<$hashref> as a table in descending value
order.

I<key>/I<value> pairs modify the output style.  Currently, all
that's supported is C<< comma => 1 >> to insert commas in the
numbers.

=cut

sub as_table {
    my $hash = shift;
    my %parms = @_;

    my %display_values;
    my $longest = 0;
    for my $key ( keys %$hash ) {
        my $disp = $hash->{$key};
        $disp = _commify( $disp ) if $parms{comma};
        $display_values{ $key } = $disp;
        $longest = length( $disp ) if length( $disp ) > $longest;
    }
    for my $disp ( values %display_values ) {
        my $diff = $longest - length($disp);
        $disp = (" " x $diff) . $disp if $diff;
    }

    my @keys = sort {
        $hash->{$b} <=> $hash->{$a} # Values descending
            or $a cmp $b            # Keys ascending
    } keys %$hash;
    my @lines = map { sprintf( "%s %s\n", $display_values{$_}, $_ ) } @keys;

    return @lines;
}

sub _commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

=head1 AUTHOR

Andy Lester, C<< <andy@petdance.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-hash-totals@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2004 Andy Lester, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Data::Hash::Totals
