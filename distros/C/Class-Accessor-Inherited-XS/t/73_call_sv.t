use Test::More;
use Class::Accessor::Inherited::XS inherited => [qw/foo/];

sub TIESCALAR { bless \my $foo };
*FETCH = *foo;

tie my $bar, 'main';
eval {$bar+1}; # used to segfault

ok 1;

done_testing;
