package Data::Difference 0.113001;
# ABSTRACT: Compare simple hierarchical data

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
    elsif (defined $a->{$k} ? defined $b->{$k} ? $b->{$k} ne $a->{$k} : 1 : defined $b->{$k}) {
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
    elsif (defined $a->[$i] ? defined $b->[$i] ? $b->[$i] ne $a->[$i] : 1 : defined $b->[$i]) {
      push @diff, {path => [@path, $i], a => $a->[$i], b => $b->[$i]};
    }
  }

  return @diff;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Data::Difference - Compare simple hierarchical data

=head1 VERSION

version 0.113001

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should
work on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

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

=head1 AUTHOR

Graham Barr C<< <gbarr@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2011 Graham Barr. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Graham Barr

=head1 CONTRIBUTORS

=for stopwords Graham Barr Ricardo Signes

=over 4

=item *

Graham Barr <gbarr@pobox.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Graham Barr.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SYNOPSYS
#pod
#pod   use Data::Difference qw(data_diff);
#pod   use Data::Dumper;
#pod
#pod   my %from = (Q => 1, W => 2, E => 3, X => [1,2,3], Y=> [5,6]);
#pod   my %to = (W => 4, E => 3, R => 5, => X => [1,2], Y => [5,7,9]);
#pod   my @diff = data_diff(\%from, \%to);
#pod
#pod   @diff = (
#pod     # value $a->{Q} was deleted
#pod     { 'a'    => 1, 'path' => ['Q'] },
#pod
#pod     # value $b->{R} was added
#pod     { 'b'    => 5, 'path' => ['R'] },
#pod
#pod     # value $a->{W} changed
#pod     { 'a'    => 2, 'b'    => 4, 'path' => ['W'] },
#pod
#pod     # value $a->{X}[2] was deleted
#pod     { 'a'    => 3, 'path' => ['X', 2] },
#pod
#pod     # value $a->{Y}[1] was changed
#pod     { 'a'    => 6, 'b'    => 7, 'path' => ['Y', 1] },
#pod
#pod     # value $b->{Y}[2] was added
#pod     { 'b'    => 9, 'path' => ['Y', 2] },
#pod   );
#pod
#pod =head1 DESCRIPTION
#pod
#pod C<Data::Difference> will compare simple data structures returning a list of details about what was
#pod added, removed or changed. It will currently handle SCALARs, HASH references and ARRAY references.
#pod
#pod Each change is returned as a hash with the following element.
#pod
#pod =over
#pod
#pod =item path
#pod
#pod path will be an ARRAY reference containing the hierarchical path to the value, each element in the array
#pod will be either the key of a hash or the index on an array
#pod
#pod =item a
#pod
#pod If it exists it will contain the value from the first argument passed to C<data_diff>. If it
#pod does not exist then this element did not exist in the first argument.
#pod
#pod =item b
#pod
#pod If it exists it will contain the value from the second argument passed to C<data_diff>. If it
#pod does not exist then this element did not exist in the second argument.
#pod
#pod =back
#pod
#pod =head1 AUTHOR
#pod
#pod Graham Barr C<< <gbarr@cpan.org> >>
#pod
#pod =head1 COPYRIGHT
#pod
#pod Copyright (c) 2011 Graham Barr. All rights reserved.
#pod This program is free software; you can redistribute it and/or modify it
#pod under the same terms as Perl itself.
#pod
#pod =cut
