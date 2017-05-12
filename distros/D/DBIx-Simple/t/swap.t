use Test::More tests => 5;

my $hash1orig = bless { qw(a b c d) }, 'Foo';
my $hash1swap = bless { qw(a b c d) }, 'Foo';
my $hash2orig = bless { qw(e f g h) }, 'Bar';
my $hash2swap = bless { qw(e f g h) }, 'Bar';

use_ok('DBIx::Simple');

DBIx::Simple::_swap($hash1swap, $hash2swap);
is_deeply($hash1orig, $hash2swap);
is_deeply($hash2orig, $hash1swap);
is(ref $hash1orig, ref $hash2swap);
is(ref $hash2orig, ref $hash1swap);
