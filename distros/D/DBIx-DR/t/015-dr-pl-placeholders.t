#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 95;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    note "************* DBIx::DR::PlPlaceHolders *************";

    use_ok 'DBIx::DR::PlPlaceHolders';
    use_ok 'File::Spec::Functions', qw(catfile rel2abs);
    use_ok 'File::Basename', qw(basename dirname);
}

my $ph = DBIx::DR::PlPlaceHolders->new;

ok !eval { $ph->set_helper; 1}, 'Wrong set_helper call';
$ph->set_helper(test1 => sub {
    my ($t) = @_;
    $t->quote('this is a test helper')
});

ok $ph, 'Constructor';
my $sql_dir = catfile(rel2abs(dirname $0), 'sql');
ok -d $sql_dir, 'Test SQL dir found: ' . $sql_dir;

ok !eval { $ph->sql_dir('directory that is not exists'); 1 }, 'Wrong sql_dir';
ok $ph->sql_dir($sql_dir), 'Well sql_dir';
ok $ph->sql_dir eq $sql_dir, 'sql_dir was changed';
ok $ph->file_suffix eq '.sql.ep', 'Default sql file suffix';

ok !eval { $ph->sql_transform; 1 }, 'Wrong arguments for sql_transform';

my @inline_tests = (
    {
        sql         => q{<%=
            $variable
        %>},
        variables   => [ variable => 123 ],
        like        => qr{^\?$},
        bind_values => [ 123 ],
        name        => 'one variable',
        died        => 0,
    },
    {
        sql         => q{<%= $variable %>},
        variables   => [ variable => 123 ],
        like        => qr{^\?$},
        bind_values => [ 123 ],
        name        => 'one variable',
        died        => 0,
    },
    {
        sql         => q{<%= $variable %>},
        variables   => [ variable => 123 ],
        like        => qr{^\?$},
        bind_values => [ 123 ],
        name        => 'one variable (repeating call)',
        died        => 0,
    },
    {
        sql         => q{<%== $variable %>},
        variables   => [ variable => 345 ],
        like        => qr{^345$},
        bind_values => [],
        name        => 'immediatelly variable substitution',
        died        => 0,
    },
    {
        sql         => q{<%== $variable %>},
        variables   => [],
        like        => qr{^123$},
        bind_values => [],
        name        => 'immediatelly variable substitution',
        died        => 1,
        die_like    => qr{\$variable},
    },
    {
        sql         => q{<% quote 'abc'; %>},
        variables   => [],
        like        => qr{^\?$},
        bind_values => ['abc'],
        name        => 'Function quote',
        died        => 0,
    },
    {
        sql         => q{<% quote 'русский'; %>},
        variables   => [],
        like        => qr{^\?$},
        bind_values => ['русский'],
        name        => 'Function quote utf8',
        died        => 0,
    },
    {
        sql         => q{<%= quote 'abc' %>},
        variables   => [],
        like        => qr{^\?$},
        bind_values => ['abc'],
        name        => 'Function quote',
        died        => 0,
    },
    {
        sql         => q{<% immediate 'cde'; %>},
        variables   => [],
        like        => qr{^cde$},
        bind_values => [],
        name        => 'Function immediate',
        died        => 0,
    },
    {
        sql         => q{<%= immediate 'cde' %>},
        variables   => [],
        like        => qr{^cde$},
        bind_values => [],
        name        => 'Function immediate',
        died        => 0,
    },
    {
        sql         => q{
            % our $var = 987;
            %== $var
        },
        variables   => [],
        like        => qr{^\s*987\s*$},
        bind_values => [],
        name        => 'uses our variable',
        died        => 0,
    },
    {
        sql         => q{
            % our $var;
            %= $var
        },
        like        => qr{^\s*\?\s*$},
        variables   => [],
        bind_values => [undef ],
        name        => 'uses our variable again (clean_namespace)',
    },
    {
        sql         => q{
            % test1
        },
        bind_values => ['this is a test helper'],
        name        => 'helper "test"',
        like        => qr{^\s*\?\s*},
    },
    {
        sql         => q{
            %= list @$ary
        },
        variables   => [
            ary     => [ 1, 2, 3 ]
        ],
        bind_values => [ 1, 2, 3],
        like        => qr[^\s*\?(?:\,\?){2}\s*$],
        name        => 'helper "list" (wrong include)',
    },
    {
        sql         => q{
            % list @$ary
        },
        variables   => [
            ary     => [ 1, 2, 3 ]
        ],
        bind_values => [ 1, 2, 3],
        like        => qr[^\s*\?(?:\,\?){2}\s*$],
        name        => 'helper "list"',
    },
    {
        sql         => q{
            % hlist @$ary
        },
        variables   => [
            ary     => [ { a => 1 }, { b => 2 },  { a => 3 } ]
        ],
        bind_values => [ 1, 2, 3],
        like        => qr[^\s*\(\?\)(?:\,\(\?\)){2}\s*$],
        name        => 'helper "hlist" - all values',
    },
    {
        sql         => q{
            % hlist ['a'], @$ary
        },
        variables   => [
            ary     => [ { a => 1 }, { b => 2 },  { a => 3 } ]
        ],
        bind_values => [ 1, undef, 3],
        like        => qr[^\s*\(\?\)(?:\,\(\?\)){2}\s*$],
        name        => 'helper "hlist" - one key name',
    },
    {
        sql         => q{
            % hlist ['a', 'b'], @$ary
        },
        variables   => [
            ary     => [ { a => 1 }, { b => 2 },  { a => 3 } ]
        ],
        bind_values => [ 1, undef, undef, 2, 3, undef ],
        like        => qr[^\s*\(\?,\?\)(?:\,\(\?,\?\)){2}\s*$],
        name        => 'helper "hlist" - a few key names',
    },
    {
        sql         => q{
            %= hlist ['a', 'b'], @$ary
        },
        variables   => [
            ary     => [ { a => 1 }, { b => 2 },  { a => 3 } ]
        ],
        bind_values => [ 1, undef, undef, 2, 3, undef ],
        like        => qr[^\s*\(\?,\?\)(?:\,\(\?,\?\)){2}\s*$],
        name        => 'helper "hlist" - a few key names',
    },
    {
        sql         => q{
            %== hlist ['a', 'b'], @$ary
        },
        variables   => [
            ary     => [ { a => 1 }, { b => 2 },  { a => 3 } ]
        ],
        bind_values => [ 1, undef, undef, 2, 3, undef ],
        like        => qr[^\s*\(\?,\?\)(?:\,\(\?,\?\)){2}\s*$],
        name        => 'helper "hlist" - a few key names',
    },
    {
        sql         => q{
            % hlist ['a', 'b'], @$ary
        },
        variables   => [
            ary     => [ { a => 1 }, { b => 2 },  12345 ]
        ],
        name        => 'helper "hlist" - a few key names',
        died        => 1,
        die_like    => qr("12345"),
    },
    {
        sql         => q{
            line 2
            % unknown_function
            line 4
        },
        name        => 'call for unknown_function',
        died        => 1,
        die_like    => qr{inline template line 3}
    }
);

for my $t (@inline_tests) {
    my $res = eval {
        no warnings;
        $ph->sql_transform($t->{sql}, @{ $t->{variables} })
    };
    if ($t->{died}) {
        ok my $err = $@, 'Expected die was thrown: ' . ucfirst $t->{name};
        SKIP: {
            skip "\$t->{die_like} was not noticed", 1 unless $t->{die_like};
            like $err, $t->{die_like}, 'Died with expected message';
        }
        next;
    }
    diag $@ unless ok $res, "Sql perform: " . ucfirst $t->{name};
    SKIP: {
        skip '$t->{like} was not noticed', 1 unless $t->{like};
        like $res->sql, $t->{like}, 'Result SQL';
    };
    is_deeply scalar $res->bind_values, $t->{bind_values}, 'Result bind_values';
}


my $file = rel2abs catfile(catfile(dirname($0), 'sql'), 'usual_select.sql.ep');

my @file_tests = (
    {
        file        => 'usual_select',
        variables   => [ id => 123 ],
        bind_values => [ 123 ],
        like        => qr(id = \?)
    },
    {
        file        => $file,
        variables   => [ id => 123 ],
        bind_values => [ 123 ],
        like        => qr(id = \?)
    },
    {
        file        => 'usual_select',
        died        => 1,
        die_like    => qr("\$id"),
    },
    {
        file        => 'usual_select.sql.ep',
        variables   => [ id => 123 ],
        bind_values => [ 123 ],
        like        => qr(id = \?)
    },
    {
        file        => 'usual_select.sqlaep',
        died        => 1,
        die_like    => qr{\.sqlaep\.sql\.ep},
    },
    {
        file        => 'include.sql.ep',
        variables   => [ iid => 123 ],
        bind_values => [ 123, 123 ],
        like        => qr(id = \?)
    },
    {
        file        => 'unknown_function.sql.ep',
        died        => 1,
        die_like    => qr{unknown_function\.sql\.ep line 3},
    },
    {
        file        => 'stacktrace.sql.ep',
        variables   => [ ],
        bind_values => [ ],
        like        => qr(/\* t/015-dr-pl-placeholders\.t:\d+ \*/),
    },
);


for my $t (@file_tests) {
    $t->{variables} ||= [];
    my $res = eval {
        $ph->sql_transform(-f => $t->{file}, @{ $t->{variables} })
    };

    my $err = $@;

    ok $res || $t->{died}, 'Perform file: ' . $t->{file};

    if ($t->{died}) {
        SKIP: {
            skip '$t->{die_like} is not defined', 1 unless $t->{die_like};
            like $err, $t->{die_like}, 'Died with expected message';
        }

    } else {
        diag $err if $err;
        SKIP: {
            skip "perform was died", 2 if $err;
            diag explain {
                bind_values => scalar $res->bind_values,
                expected_bind_values => $t->{bind_values}
            } unless is_deeply $t->{bind_values}, scalar $res->bind_values,
                'Result bind_values';

            skip '$t->{like} was not noticed', 1 unless $t->{like};
            like $res->sql, $t->{like}, 'Result SQL';
        }
    }

}

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=cut
