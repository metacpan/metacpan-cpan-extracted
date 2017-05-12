use Test::Most 0.22 (tests => 3);
use Test::NoWarnings;

use App::Config::Chronicle::Attribute::Global;
use Data::Hash::DotNotation;

subtest 'get' => sub {
    subtest 'default' => sub {
        my $attribute = App::Config::Chronicle::Attribute::Global->new(
            name        => 'get',
            parent_path => 'tests',
            data_set    => {version => 1},
            definition  => {
                isa     => 'Str',
                default => 'a',
            },
        )->build;

        ok $attribute, "Attribute created";
        is $attribute->path, 'tests.get';
        is $attribute->value, 'a', 'Got from default';
    };

    subtest 'from app_config' => sub {
        my $data = {tests => {get => 'b'}};
        my $app_config = Data::Hash::DotNotation->new(data => $data);

        my $attribute = App::Config::Chronicle::Attribute::Global->new(
            name        => 'get',
            parent_path => 'tests',
            data_set    => {
                version    => 1,
                app_config => $app_config
            },
            definition => {
                isa     => 'Str',
                default => 'a',
            },
        )->build;

        ok $attribute, "Attribute created";
        is $attribute->path, 'tests.get';
        is $attribute->value, 'b', 'Got from app_config';
    };

    subtest 'from global(data)' => sub {
        my $data = {tests => {get => 'c'}};
        my $global = Data::Hash::DotNotation->new(data => $data);

        $data = {tests => {get => 'b'}};
        my $app_config = Data::Hash::DotNotation->new(data => $data);

        my $attribute = App::Config::Chronicle::Attribute::Global->new(
            name        => 'get',
            parent_path => 'tests',
            data_set    => {
                version    => 1,
                app_config => $app_config,
                global     => $global,
            },
            definition => {
                isa     => 'Str',
                default => 'a'
            },
        )->build;

        ok $attribute, "Attribute created";
        is $attribute->path, 'tests.get';
        is $attribute->value, 'c', 'Got from global';
    };
};

subtest 'set - where' => sub {
    my $data = {tests => {get => 'd'}};
    my $app_settings_overrides = Data::Hash::DotNotation->new(data => $data);

    $data = {tests => {get => 'c'}};
    my $global = Data::Hash::DotNotation->new(data => $data);

    $data = {tests => {get => 'b'}};
    my $app_config = Data::Hash::DotNotation->new(data => $data);

    my $attribute = App::Config::Chronicle::Attribute::Global->new(
        name        => 'get',
        parent_path => 'tests',
        data_set    => {
            version                => 1,
            global                 => $global,
            app_config             => $app_config,
            app_settings_overrides => $app_settings_overrides,
        },
        definition => {
            isa     => 'Str',
            default => 'a',
        },
    )->build;

    ok $attribute, "Attribute created";
    is $attribute->path, 'tests.get';
    is $attribute->value, 'd', 'Got d';

    $attribute->value('e');
    is $attribute->value, 'e', 'Got e';

    is $global->get('tests.get'), 'e', 'Value set in global';
};
