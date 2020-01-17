#!/usr/bin/env perl

use rlib qw(../inc ../lib);
use Modern::Perl;

use Class::Load qw(try_load_class);
use DBIx::Class::Schema::Loader qw(make_schema_at);
use MyContainer;

my $default_resultset_class = do {
    my $candidate = "Catalyst::Authentication::RedmineCookie::Base::Schema::ResultSet";
    my $ret = try_load_class $candidate;
    $ret ? "+$candidate" : "+DBIx::Class::ResultSet::HashRef";
};
my $result_base_class       = do {
    my $candidate = "Catalyst::Authentication::RedmineCookie::Base::Schema::Core";
    my $ret = try_load_class $candidate;
    $ret ? "$candidate" : undef; # こっちは + を付けなくて良い
};

# find /usr/local/www/redmine/app/models -type f | sort | xargs greple -pe '^\s*(has_many|belongs_to|might_have|has_one|many_to_many|has_and_belongs_to_many)' | less 

make_schema_at(
    "Catalyst::Authentication::RedmineCookie::Schema",
    {
        _components => [
            "IntrospectableM2M",
        ],
        datetime_timezone => "Asia/Tokyo",
        datetime_locale   => "ja_JP",
        ( $default_resultset_class ? ( default_resultset_class => $default_resultset_class ) : () ),
        dump_directory => './lib',
        constraint => qr/^(user|group|member|role|project)/i,
        exclude    => qr/managed|tracker/i,
        generate_pod => 0,
        naming => 'preserve',
        ( $result_base_class ? ( result_base_class => $result_base_class ) : () ),
        use_moose      => 0,
        use_namespaces => 1,
    },
    container('config')->{web}{'Model::DBIC'}{connect_info} || die,
);
