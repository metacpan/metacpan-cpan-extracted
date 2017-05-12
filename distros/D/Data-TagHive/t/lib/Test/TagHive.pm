use 5.12.0;
use warnings;
package Test::TagHive;

use Data::TagHive;
use Test::More;

use Sub::Exporter -setup => {
  groups     => { default => \'_gen_group' },
};

sub _gen_group {
  my ($self, $name, $arg, $col) = @_;

  my %sub;

  my $taghive;
  $sub{new_taghive} = sub { $taghive = Data::TagHive->new(@_); };
  $sub{set_taghive} = sub { $taghive = shift; };
  $sub{taghive}     = sub { $taghive };

  $sub{has_tag} = sub {
    my ($tag) = @_;
    ok(
      $taghive->has_tag($tag),
      "tag <$tag> is present",
    );
  };

  $sub{hasnt_tag} = sub {
    my ($tag) = @_;
    ok(
      ! $taghive->has_tag($tag),
      "tag <$tag> is absent",
    );
  };

  return \%sub;
}

1;
