# vim: set sw=2 ft=perl:
package DBIx::Class::Sims::Util;

use 5.010_001;

use strictures 2;

use base 'Exporter';
our @EXPORT_OK = qw(
  compare_values normalize_aoh reftype
);

use Scalar::Util ();

sub compare_values {
  my ($v1, $v2) = @_;

  return 1 if !defined($v1) && !defined($v2);
  return 1 if defined($v1) && defined($v2) && $v1 eq $v2;
  return;
}

sub reftype {
  return Scalar::Util::reftype($_[0]) // '';
}

sub normalize_aoh {
  my ($input) = @_;

  return unless defined $input;

  # If it's an arrayref, verify all elements are hashrefs
  if (reftype($input) eq 'ARRAY') {
    return $input unless @$input;
    return $input unless grep { reftype($_) ne 'HASH' } @$input;
  }
  elsif (reftype($input) eq 'HASH') {
    return [$input];
  }
  elsif (!reftype($input)) {
    if ($input =~ /^\d+$/) {
      return [ map { {} } 1 .. $input ];
    }
  }

  return;
}

1;
__END__
