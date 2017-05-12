use Test::More tests => 3;

use Algorithm::StringHash::FromCSharp35::XS qw(GetHashCode);

my $a = GetHashCode("abcd");
is $a, 2834902953;

my $b = GetHashCode("abcd1");
is $b, 2930960078;

my $b = GetHashCode("/a/b/c/dsfwaaaa1232349900");
is $b, 2683702957;
