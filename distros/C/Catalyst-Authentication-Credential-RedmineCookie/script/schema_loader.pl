#!/usr/bin/env perl

use rlib;
use Modern::Perl;

use Class::Load qw(try_load_class);
use DBIx::Class::Schema::Loader qw(make_schema_at);

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
        constraint => qr/^(user|group|member|role)/i,
        exclude    => qr/managed/i,
        generate_pod => 0,
        ( $result_base_class ? ( result_base_class => $result_base_class ) : () ),
        use_moose      => 0,
        use_namespaces => 1,
    },
    [ 
        #container('config')->{schema}{connect_info},
        {
            dsn            => "dbi:mysql:host=127.0.0.1;dbname=xxx",
            user           => "xxx",
            password       => "xxx",
            # quote_names    => 1,
            # on_connect_do  => [
            #     # Mac
            #     #"set lc_time = 'ja_JP'",
            #     # FreeBSD
            #     "set lc_time = 'ja_JP.UTF-8'",
            # ],
            RaiseError        => 1 ,
            PrintError        => 0 ,
            AutoCommit        => 1 ,
            pg_enable_utf8    => 1 ,
            mysql_enable_utf8 => 1 ,
        },
    ],
);
