use strict;
use warnings;
use Test::More 0.88;
use lib 't/lib';
use Test::Class::Load ':all';

ok(try_load_class('Class::Load::OK'), "loaded class OK");
is($Class::Load::ERROR, undef);

ok(!try_load_class('Class::Load::Nonexistent'), "didn't load class Nonexistent");
like($Class::Load::ERROR, qr{^Can't locate Class/Load/Nonexistent.pm in \@INC});

ok(try_load_class('Class::Load::OK'), "loaded class OK");
is($Class::Load::ERROR, undef);

ok(!try_load_class('Class::Load::SyntaxError'), "didn't load class SyntaxError");
like($Class::Load::ERROR, qr{^Missing right curly or square bracket at });

ok(is_class_loaded('Class::Load::OK'));
ok(!is_class_loaded('Class::Load::Nonexistent'));
ok(!is_class_loaded('Class::Load::SyntaxError'));

do {
    package Class::Load::Inlined;
    sub inlined { 1 }
};

ok(try_load_class('Class::Load::Inlined'), "loaded class Inlined");
is($Class::Load::ERROR, undef);
ok(is_class_loaded('Class::Load::Inlined'));

ok(!try_load_class('Class::Load::VersionCheck', { -version => 43 }));
ok(try_load_class('Class::Load::VersionCheck', { -version => 41 }));

ok(try_load_class('Class::Load::VersionCheck2', { -version => 41 }));
ok(!try_load_class('Class::Load::VersionCheck2', { -version => 43 }));

done_testing;
