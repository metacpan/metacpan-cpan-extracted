
use Test::More;
use Test::Output;

use Crypt::URandom::MonkeyPatch;

eval "use String::Random";

plan skip_all => "String::Random not installed" if $@;

local $ENV{CRYPT_URANDOM_MONKEYPATCH_DEBUG} = 1;

stderr_like {

    my $sg = String::Random->new;
    my $pa = $sg->randpattern(".....");

    note $pa;
}
qr/^(Crypt::URandom::MonkeyPatch::urandom used from String::Random line [1-9][0-9]+\n){5}/, "debug output";

done_testing;
