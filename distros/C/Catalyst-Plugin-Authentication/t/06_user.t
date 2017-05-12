use strict;
use warnings;

use Test::More;
use Test::Exception;

my $m; BEGIN { use_ok($m = "Catalyst::Authentication::User") }

{
    package SomeBaseUser;
    sub other_method { 'FNAR' };
}

{
    package SomeUser;
    use base $m;

    sub new { bless {}, shift };

    sub supported_features {
        {
            feature => {
                subfeature => 1,
                unsupported_subfeature => 0,
            },
            top_level => 1,
        }
    }
    sub get_object {
        bless {}, 'SomeBaseUser';
    }
}

my $o = SomeUser->new;

can_ok( $m, "supports" );

ok( $o->supports("top_level"), "simple top level feature check");
ok( $o->supports(qw/feature subfeature/), "traversal");
ok( !$o->supports(qw/feature unsupported_subfeature/), "traversal terminating in false");

lives_ok {
    $o->supports("bad_key");
} "can check for non existent feature";

#dies_ok {
#    $o->supports(qw/bad_key subfeature/)
#} "but can't traverse into one";

lives_ok {
    is $o->other_method, 'FNAR', 'Delegation onto user object works';
} 'Delegation lives';

done_testing;


