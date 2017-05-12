use Test::More tests => 3;
use Test::Exception;

use_ok 'AnyEvent::Digest';

use Digest::MD5;

my $ref = Digest::MD5->new;
my $our;
lives_ok { $our = AnyEvent::Digest->new('Digest::MD5') } 'construction';

is($ref->add("FOO", "BAR", "BAZ")->digest, $our->add("FOO", "BAR", "BAZ")->digest, 'add -> digest');
