# vim: set sw=2 ft=perl:
package DBIx::Class::Sims::Util;

use 5.010_001;

use strictures 2;

use Scalar::Util ();

sub reftype {
  return Scalar::Util::reftype($_[0]) // '';
}

sub normalize_aoh {
  shift;
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
