use strict;
use warnings;
package Test::ValCaps;

sub rewrite {
  my ($class, $data) = @_;

  if (ref $data) {
    if (ref $data eq 'HASH') {
      foreach my $key (keys %$data) {
        if (ref $data->{$key}) {
          $data->{$key} = $class->rewrite($data->{$key});
        } else {
          $data->{$key} = uc $data->{$key};
        }
      }
    } elsif (ref $data eq 'ARRAY') {
      foreach my $i (0 .. $#{ $data }) {
        $data->[$i] = $class->rewrite($data->[$i]);
      }
    }
  }

  return $data;
}

1;

