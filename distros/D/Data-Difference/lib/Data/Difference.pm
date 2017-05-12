package Data::Difference;
{
  $Data::Difference::VERSION = '0.112850';
}

use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(data_diff);

sub data_diff {
  my ($a, $b) = @_;

  if (ref($a)) {
    if (my $sub = __PACKAGE__->can("_diff_" . ref($a))) {
      return $sub->($a, $b);
    }
    else {
      return {path => [], a => $a, b => $b};
    }
  }
  elsif (defined $a ? defined $b ? $a ne $b : 1 : 0) {
    return {path => [], a => $a, b => $b};
  }

  return;
}

sub _diff_HASH {
  my ($a, $b, @path) = @_;

  return {path => \@path, a => $a, b => $b} unless ref($a) eq ref($b);

  my @diff;
  my %k;
  @k{keys %$a, keys %$b} = ();
  foreach my $k (sort keys %k) {
    if (!exists $a->{$k}) {
      push @diff, {path => [@path, $k], b => $b->{$k}};
    }
    elsif (!exists $b->{$k}) {
      push @diff, {path => [@path, $k], a => $a->{$k}};
    }
    elsif (ref($a->{$k})) {
      if (my $sub = __PACKAGE__->can("_diff_" . ref($a->{$k}))) {
        push @diff, $sub->($a->{$k}, $b->{$k}, @path, $k);
      }
      else {
        push @diff, {path => [@path, $k], a => $a->{$k}, b => $b->{$k}};
      }
    }
    elsif (defined $a->{$k} ? defined $b->{$k} ? $b->{$k} ne $a->{$k} : 1 : 0) {
      push @diff, {path => [@path, $k], a => $a->{$k}, b => $b->{$k}};
    }
  }

  return @diff;
}

sub _diff_ARRAY {
  my ($a, $b, @path) = @_;
  return {path => \@path, a => $a, b => $b} unless ref($a) eq ref($b);

  my @diff;
  my $n = $#$a > $#$b ? $#$a : $#$b;

  foreach my $i (0 .. $n) {
    if ($i > $#$a) {
      push @diff, {path => [@path, $i], b => $b->[$i]};
    }
    elsif ($i > $#$b) {
      push @diff, {path => [@path, $i], a => $a->[$i]};
    }
    elsif (ref($a->[$i])) {
      if (my $sub = __PACKAGE__->can("_diff_" . ref($a->[$i]))) {
        push @diff, $sub->($a->[$i], $b->[$i], @path, $i);
      }
      else {
        push @diff, {path => [@path, $i], a => $a->[$i], b => $b->[$i]};
      }
    }
    elsif (defined $a->[$i] ? defined $b->[$i] ? $b->[$i] ne $a->[$i] : 1 : 0) {
      push @diff, {path => [@path, $i], a => $a->[$i], b => $b->[$i]};
    }
  }

  return @diff;
}

1;

__END__

=head1 NAME

Data::Difference - Compare simple hierarchical data

=head1 VERSION

version 0.112850

=head1 SYNOPSYS

  use Data::Difference qw(data_diff);
  use Data::Dumper;

  my %from = (Q => 1, W => 2, E => 3, X => [1,2,3], Y=> [5,6]);
  my %to = (W => 4, E => 3, R => 5, => X => [1,2], Y => [5,7,9]);
  my @diff = data_diff(\%from, \%to);

  @diff = (
    # value $a->{Q} was deleted
    { 'a'    => 1, 'path' => ['Q'] },

    # value $b->{R} was added
    { 'b'    => 5, 'path' => ['R'] },

    # value $a->{W} changed
    { 'a'    => 2, 'b'    => 4, 'path' => ['W'] },

    # value $a->{X}[2] was deleted
    { 'a'    => 3, 'path' => ['X', 2] },

    # value $a->{Y}[1] was changed
    { 'a'    => 6, 'b'    => 7, 'path' => ['Y', 1] },

    # value $b->{Y}[2] was added
    { 'b'    => 9, 'path' => ['Y', 2] },
  );

=head1 DESCRIPTION

C<Data::Difference> will compare simple data structures returning a list of details about what was
added, removed or changed. It will currently handle SCALARs, HASH references and ARRAY references.

Each change is returned as a hash with the following element.

=over

=item path

path will be an ARRAY reference containing the hierarchical path to the value, each element in the array
will be either the key of a hash or the index on an array

=item a

If it exists it will contain the value from the first argument passed to C<data_diff>. If it
does not exist then this element did not exist in the first argument.

=item b

If it exists it will contain the value from the second argument passed to C<data_diff>. If it
does not exist then this element did not exist in the second argument.

=back

=head1 AUTHOR

Graham Barr C<< <gbarr@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2011 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
