package main;

use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::BailOnFail;
use Test2::Tools::LoadModule;

load_module_ok 'Date::ManipX::Almanac::Lang';

load_module_ok 'Date::ManipX::Almanac::Lang::english';

SKIP: {
    my $module = 'Date::ManipX::Almanac::Lang::spanish';
    $ENV{AUTHOR_TESTING}
	or skip "$module is unpublished", 1;
    ( my $file = "blib/lib/$module.pm" ) =~ s<::></>smxg;
    unless ( -e $file ) {
	my $msg = "AUTHOR_TESTING set but unpublished $module not found";
	diag $msg;
	skip $msg, 1;
    }

    load_module_ok $module;
}

load_module_ok 'Date::ManipX::Almanac::Date';

{
    local $@ = undef;

    my $obj = eval { Date::ManipX::Almanac::Date->new() }
	or fail "Date::ManipX::Almanac::Date->new() threw $@";
    isa_ok $obj, 'Date::ManipX::Almanac::Date';

    my $o2 = eval { $obj->new() }
	or fail "\$obj->new() threw $@";
    isa_ok $o2, 'Date::ManipX::Almanac::Date';

    my $o_config = eval { $obj->new_config() }
	or fail "\$obj->new_config() threw $@";
    isa_ok $o_config, 'Date::ManipX::Almanac::Date';

    my $o_date = eval { $obj->new_date() }
	or fail "\$obj->new_date() threw $@";
    isa_ok $o_date, 'Date::ManipX::Almanac::Date';
}

load_module_ok 'Date::ManipX::Almanac';

isa_ok 'Date::ManipX::Almanac', 'Date::Manip::DM6';

done_testing;

1;
