use Test::Base;
use Data::ClearSilver::HDF;

sub hdf_dump {
    my $hdf = Data::ClearSilver::HDF->hdf(shift);
    return Data::ClearSilver::HDF->hdf_dump($hdf);
}

plan tests => 2;
run_is in => "out";

__END__
=== simple
Test by simple numeric array
--- in eval hdf_dump join
[0..10]
--- out
0 = 0
1 = 1
2 = 2
3 = 3
4 = 4
5 = 5
6 = 6
7 = 7
8 = 8
9 = 9
10 = 10

=== complex
Test by complex array
--- in eval hdf_dump join
["a", "b", ["c", "d"], "e", ["f"], [["g", "h"], ["i"], ["j", "k", "l"]]]
--- out
0 = a
1 = b
2 {
  0 = c
  1 = d
}
3 = e
4 {
  0 = f
}
5 {
  0 {
    0 = g
    1 = h
  }
  1 {
    0 = i
  }
  2 {
    0 = j
    1 = k
    2 = l
  }
}
