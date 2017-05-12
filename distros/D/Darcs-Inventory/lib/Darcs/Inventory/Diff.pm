# Copyright (c) 2007-2012 David Caldwell,  All Rights Reserved. -*- perl -*-

package Darcs::Inventory::Diff; use warnings; use strict;
require Exporter; our @ISA = qw(Exporter); our @EXPORT = qw(darcs_inventory_diff);

*darcs_inventory_diff = \&diff;

sub hashify($) {
    my $order = 0;
    return () unless defined $_[0];
    map {
        my $diffable = $_->raw;
        $diffable =~ s/^hash:.*//m; # Hashes can change but still be the same patch (patches before it in the inventory may affect its line numbers)
        $diffable => { order => $order++, patch => $_ }
    } $_[0]->patches;
}

sub unhashify($) {
    my ($h) = @_;
    map { $h->{$_}->{patch} } sort { $h->{$a}->{order} <=> $h->{$b}->{order} } keys %$h;
}

sub diff($$) {
    my ($a, $b) = @_;

    my %a = hashify $a;
    my %b = hashify $b;

    my %not_in_b = %a;
    my %not_in_a = %b;

    foreach my $k (keys %a) {
        delete $not_in_a{$k};
    }

    foreach my $k (keys %b) {
        delete $not_in_b{$k};
    }

    return ([unhashify \%not_in_a],
            [unhashify \%not_in_b]);
}

1;
__END__

=head1 NAME

Darcs::Inventory::Diff - Compute the difference between two darcs inventories

=head1 SYNOPSIS

 use Darcs::Inventory;
 use Darcs::Inventory::Diff;
 my $a = Darcs::Inventory->new($repo_a);
 my $b = Darcs::Inventory->new($repo_b);
 my ($not_in_a, $not_in_b) = darcs_inventory_diff($a, $b);

 for (@$not_in_a) {
     print "-".$_->name."\n";
 }

 for (@$not_in_b) {
     print "+".$_->name."\n";
 }

=head1 DESCRIPTION

Darcs::Inventory::Diff computes the difference between two
B<L<Darcs::Inventory>>s.

=head1 FUNCTIONS

=over 4

=item darcs_inventory_diff($a, $b)

Compute the difference between B<L<Darcs::Inventory>>s $a and $b. It
returns 2 array refs. The first is a list of
B<L<Darcs::Inventory::Patch>>es that were in $b but not in $a. The
second is a list of B<L<Darcs::Inventory::Patch>>es that were in $a
but not in $b.

=back

=head1 SEE ALSO

L<Darcs::Inventory>, L<Darcs::Inventory::Patch>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Copyright (C) 2007-2012 David Caldwell

=head1 AUTHOR

David Caldwell <david@porkrind.org>

=cut
