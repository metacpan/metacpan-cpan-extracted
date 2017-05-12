use Test::Base;
use Data::ClearSilver::HDF;

$Data::ClearSilver::HDF::USE_SORT = 1;

sub hdf_dump {
    my $hdf = Data::ClearSilver::HDF->hdf(shift);
    return Data::ClearSilver::HDF->hdf_dump($hdf);
}

plan tests => 2;
run_is in => "out";

__END__
=== simple
Test by simple hash
--- in eval hdf_dump join
bless { a => 1, b => 2, c => 3, d => 4, e => 5 }
--- out
a = 1
b = 2
c = 3
d = 4
e = 5

=== complex
Test by complex array
--- in eval hdf_dump join
{
  foo => bless ({
    a => 1,
    b => bless ({
      A => 1,
      B => [0 .. 5]
    }),
    c => 2
  }),
  bar => {
    a => "hoge\nfuga",
    b => 1,
    c => {
      A => bless ({
        X => 1,
        Y => 2
      }),
      B => 2
    }
  }
}
--- out
bar {
  a << EOM
hoge
fuga
EOM
  b = 1
  c {
    A {
      X = 1
      Y = 2
    }
    B = 2
  }
}
foo {
  a = 1
  b {
    A = 1
    B {
      0 = 0
      1 = 1
      2 = 2
      3 = 3
      4 = 4
      5 = 5
    }
  }
  c = 2
}
