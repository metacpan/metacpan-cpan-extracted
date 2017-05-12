use Test::More;
use Test::Exception;

BEGIN 
{
    eval { require Test::Without::Module; };
    plan skip_all => "Test::Without::Module is required: $@" if $@;
}

plan tests => 3;

use_ok 'AnyEvent::Digest';

my $our;

# NOTE: eval is unnecessary from the viewpoint of behavior for:
#       eval { use/no Test::Without::Module qw(...); };
#       However, use is detected by build_prereq_matches_use,
#       so eval guard is used.

eval { use Test::Without::Module qw(AnyEvent::AIO); };
throws_ok { $our = AnyEvent::Digest->new('Digest::MD5', backend => 'aio') }
    qr/^AnyEvent::Digest: `aio' backend requires `IO::AIO' and `AnyEvent::AIO'/, 'without AnyEvent::AIO';

eval { no  Test::Without::Module qw(AnyEvent::AIO); };
eval { use Test::Without::Module qw(IO::AIO); };
throws_ok { $our = AnyEvent::Digest->new('Digest::MD5', backend => 'aio') }
    qr/^AnyEvent::Digest: `aio' backend requires `IO::AIO' and `AnyEvent::AIO'/, 'without IO::AIO';
