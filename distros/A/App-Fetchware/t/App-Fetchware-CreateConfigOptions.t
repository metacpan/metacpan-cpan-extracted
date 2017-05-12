#!perl
# App-Fetchware-CreateConfigOptions.t tests App::Fetchware::CreateConfigOptions, which is a helper
# class for fetchware extensions.
use strict;
use warnings;
use 5.010001;

# Set a umask of 022 just like bin/fetchware does. Not all fetchware tests load
# bin/fetchware, and so all fetchware tests must set a umask of 0022 to ensure
# that any files fetchware creates during testing pass fetchware's safe_open()
# security checks.
umask 0022;

# Test::More version 0.98 is needed for proper subtest support.
use Test::More 0.98 tests => '4'; #Update if this changes.

use Test::Fetchware ':TESTING';
use App::Fetchware::Config '__clear_CONFIG';

# Set PATH to a known good value.
$ENV{PATH} = '/usr/local/bin:/usr/bin:/bin';
# Delete *bad* elements from environment to make it safer as recommended by
# perlsec.
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

# Test if I can load the module "inside a BEGIN block so its functions are exported
# and compile-time, and prototypes are properly honored."
# There is no ':OVERRIDE_START' to bother importing.
BEGIN { use_ok('App::Fetchware::CreateConfigOptions'); }


subtest 'Test _create_config_options() success' => sub {
    package TestPackage;
    use App::Fetchware::Util ':UTIL';
    use App::Fetchware::Config 'config';
    use App::Fetchware;
    use Test::More;
    our @one;
    our @onearrref;
    our @many;
    our @bool;
    our @import;
BEGIN {
    package TestPackage;
    @one = qw(conf_sub0 conf_sub1 conf_sub2);
    @onearrref = qw(one_arrref_one one_arrref_two);
    @many = qw(many_sub0 many_sub1 many_sub2);
    @bool = qw(bool0 bool1 bool2);
    @import = qw(temp_dir no_install);
    my @api_subs;

    @api_subs = (
        [conf_sub0 => 'ONE'],
        [conf_sub1 => 'ONE'],
        [conf_sub2 => 'ONE'],
    );

    # Just fake the caller.
    my $caller = 'TestPackage';

    App::Fetchware::CreateConfigOptions::_create_config_options($caller, ONE => \@one);

    App::Fetchware::CreateConfigOptions::_create_config_options($caller, ONEARRREF => \@onearrref);

    App::Fetchware::CreateConfigOptions::_create_config_options($caller, MANY => \@many);

    App::Fetchware::CreateConfigOptions::_create_config_options($caller, BOOLEAN => \@bool);
    
    App::Fetchware::CreateConfigOptions::_create_config_options($caller, IMPORT => \@import);
}

    for my $sub (@one, @onearrref, @many, @bool, @import) {
        ok(eval "$sub 'test';",
            "checked [$sub] execution.");
        ok(config($sub),
            "checked [$sub] exists in %CONFIG");
    }

    package main;
    export_ok([@one, @onearrref, @many, @bool, @import],
        \@TestPackage::EXPORT);

    # Clear %CONFIG since its global.
    __clear_CONFIG();
    
    package TestPackage2;
    use App::Fetchware::Util ':UTIL';
    use App::Fetchware;

    # Just fake the caller.
    my $caller = 'TestPackage2';

    App::Fetchware::CreateConfigOptions::_create_config_options(
        $caller,
        ONE => [qw(a b c)],
        ONEARRREF => [qw(d e f)],
        MANY => [qw(g h i)],
        BOOLEAN => [qw(j k l)],
        IMPORT => \@import,
    );

    package main;
    export_ok(['a'..'l', @import], \@TestPackage2::EXPORT);
    
    # Clear %CONFIG since its global.
    __clear_CONFIG();
};


subtest 'Test import() success.' => sub {
    package TestPackage3;
    use App::Fetchware::Util ':UTIL';
    use App::Fetchware::Config 'config';
    use App::Fetchware;
    use Test::More;
    our @one;
    our @onearrref;
    our @many;
    our @bool;
    our @import;
BEGIN {
    @one = qw(conf_sub0 conf_sub1 conf_sub2);
    @onearrref = qw(one_arrref_one one_arrref_two);
    @many = qw(many_sub0 many_sub1 many_sub2);
    @bool = qw(bool0 bool1 bool2);
    @import = qw(temp_dir no_install);
    my @api_subs;

    @api_subs = (
        [conf_sub0 => 'ONE'],
        [conf_sub1 => 'ONE'],
        [conf_sub2 => 'ONE'],
    );
    App::Fetchware::CreateConfigOptions->import(ONE => \@one);

    App::Fetchware::CreateConfigOptions->import(ONEARRREF => \@onearrref);

    App::Fetchware::CreateConfigOptions->import(MANY => \@many);

    App::Fetchware::CreateConfigOptions->import(BOOLEAN => \@bool);
    
    App::Fetchware::CreateConfigOptions->import(IMPORT => \@import);
}

    for my $sub (@one, @onearrref, @many, @bool, @import) {
        ok(eval "$sub 'test';",
            "checked [$sub] execution.");
        ok(config($sub),
            "checked [$sub] exists in %CONFIG");
    }

    package main;
    export_ok([@one, @onearrref, @many, @bool, @import],
        \@TestPackage3::EXPORT);

    # Clear %CONFIG since its global.
    __clear_CONFIG();
    
    package TestPackage4;
    use App::Fetchware::Util ':UTIL';
    use App::Fetchware;
    App::Fetchware::CreateConfigOptions->import(
        ONE => [qw(a b c)],
        ONEARRREF => [qw(d e f)],
        MANY => [qw(g h i)],
        BOOLEAN => [qw(j k l)],
        IMPORT => \@import,
    );

    package main;
    export_ok(['a'..'l', @import], \@TestPackage4::EXPORT);

    # Clear %CONFIG since its global.
    __clear_CONFIG();
};


subtest 'Test use App::Fetchware::CreateConfigOptions.' => sub {
    package TestPackage5;
    use App::Fetchware::Util ':UTIL';
    use App::Fetchware::Config 'config';
    use App::Fetchware;
    use Test::More;
    our @one;
    our @onearrref;
    our @many;
    our @bool;
    our @import;
BEGIN {
    @one = qw(conf_sub0 conf_sub1 conf_sub2);
    @onearrref = qw(one_arrref_one one_arrref_two);
    @many = qw(many_sub0 many_sub1 many_sub2);
    @bool = qw(bool0 bool1 bool2);
    @import = qw(temp_dir no_install);

note("ONE[@one]");
note("ONEARRREF[@onearrref]");
note("MANY[@many]");
note("BOOL[@bool]");
note("IMPORT[@import]");
note("PACKAGE[@{[caller]}]");

    my @api_subs;

    @api_subs = (
        [conf_sub0 => 'ONE'],
        [conf_sub1 => 'ONE'],
        [conf_sub2 => 'ONE'],
    );
    use App::Fetchware::CreateConfigOptions
        ONE => [qw(conf_sub0 conf_sub1 conf_sub2)];

    use App::Fetchware::CreateConfigOptions
        ONEARRREF => [qw(one_arrref_one one_arrref_two)];

    use App::Fetchware::CreateConfigOptions
        MANY => [qw(many_sub0 many_sub1 many_sub2)];

    use App::Fetchware::CreateConfigOptions
        BOOLEAN => [qw(bool0 bool1 bool2)];
    
    use App::Fetchware::CreateConfigOptions
        IMPORT => [qw(temp_dir no_install)];
}

    for my $sub (@one, @onearrref, @many, @bool, @import) {
        ok(eval "$sub 'test';",
            "checked [$sub] execution.");
        ok(config($sub),
            "checked [$sub] exists in %CONFIG");
    }

    package main;
    export_ok([@one, @onearrref, @many, @bool, @import],
        \@TestPackage5::EXPORT);

    # Clear %CONFIG since its global.
    __clear_CONFIG();
    
    package TestPackage6;
    use App::Fetchware::Util ':UTIL';
    use App::Fetchware;
    use App::Fetchware::CreateConfigOptions
        ONE => [qw(a b c)],
        ONEARRREF => [qw(d e f)],
        MANY => [qw(g h i)],
        BOOLEAN => [qw(j k l)],
        IMPORT => [qw(temp_dir no_install)],
    ;

    package main;
    export_ok(['a'..'l', @import], \@TestPackage6::EXPORT);

    # Clear %CONFIG since its global.
    __clear_CONFIG();
};


# Remove this or comment it out, and specify the number of tests, because doing
# so is more robust than using this, but this is better than no_plan.
#done_testing();
