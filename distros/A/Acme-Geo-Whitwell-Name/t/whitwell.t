use Test::More;
use Acme::Geo::Whitwell::Name qw(to_whitwell from_whitwell);

my @tests = (
    # 'nowhere'
    # ['0.00N','0.00W'] => [ 'Outou Tout','Tout Outou' ],                    
    # Sunnyvale CA
    ['37.37N', '122.03W'] => ['Feefee Asedouf','Inin Beveti'], 
    # Kuala Lumpur, Malaysia
    ['3.8N',   '101.42E'] => ['Ipou Boubod','Feit Atake'],       
    # Sydney, Australia
    ['33.55S', '151.17E'] => ['Isilu Buban', 'Fivul Alabee'], 
    # McMurdo Base, Antarctica
    ['77.85S', '166.76E'] => ['Eeseepu Bymeem','Neeveil Amyny'], 
    # Valparaiso, Chile
    ['33.02S', '71.55W']  => ['Isite Navul','Fivoud Eesalu'], 
    # Moscow, Russia
    ['55.75N', '37.61E'] => ['Uleel Feema','Lunu Inyb'], 
);

my @revtests = reverse @tests;

# Sign tests
my %signtests = (
    'Uleel Feema' => [55.75, 37.61],
    'Fivoud Eesalu' => [-33.02, -71.55],
    'Isilu Buban' => [-33.55, 151.17],
    'Feefee Asedouf' => [37.37, -122.03],
);

plan tests => ((int @tests) / 2) * 4 + (int @revtests) + (int keys %signtests);
my $is_neg = qw/[WS]/;

# Conversions to
while (@tests) {
  my ($coord_set, $name_set);
  ($coord_set, $name_set, @tests) = @tests;
  my @names = to_whitwell(@$coord_set);
  for (@names) {
      my($first, $last) = split;
      if ($coord_set->[0] =~ $is_neg) {
          ok $first =~ /[sv]/, "negative indicator inserted";
      }
      else {
          ok $first !~ /[sv]/, "no negative indicator";
      }

      if ($coord_set->[1] =~ $is_neg) {
          ok $last =~ /[sv]/, "negative indicator inserted";
      }
      else {
          ok $last !~ /[sv]/, "no negative indicator";
      }
  }
  is_deeply [sort @names], [sort @$name_set], "names match";
}

# Conversions from
while (@revtests) {
  my ($name_set, $coord_set);
  for (0..1) {
      ($name_set, $coord_set, @revtests) = @revtests;
      my @coords = from_whitwell($name_set->[$_]);
      is_deeply [@coords], $coord_set, "coords match";
  }
}

foreach (keys %signtests) {
    my($lat, $lon) = from_whitwell($_, signed=>1);
    is_deeply [$lat, $lon], $signtests{$_}, 'signs match';
}
