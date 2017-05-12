#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 50;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    note "************* DBIx::DR::PerlishTemplate *************";
    use_ok 'DBIx::DR::PerlishTemplate';
    use_ok 'File::Spec::Functions', 'catfile', 'rel2abs';
    use_ok 'File::Basename', 'dirname', 'basename';

}

my $tpl = DBIx::DR::PerlishTemplate->new;
ok $tpl, 'DBIx::DR::PerlishTemplate->new';


my @tests = (
    {
        template    => q{%#},
        prepend     => [],
        args        => [],
        sql         => qr{^$}s,
        vars        => [],
        name        => 'Commented last line',
    },
    {
        template    => q{
            %= 50 - 11
            +
            <%==
                24 / 12
             %> + <%== 12 / 6 %>
             %== '+ 1'
        },
        prepend     => [],
        args        => [],
        sql         => qr{^\s*\?\s*\+\s*2\s*\+\s*2\s*\+\s*1\s*$}s,
        vars        => [ 39 ],
        name        => 'Immediate substitutions',
    },

    {
        template    => '%= 13 / 8',
        prepend     => [],
        args        => [],
        sql         => qr{^\?$},
        vars        => [ 13 / 8 ],
        name        => 'Placeholder test',
    },
    {
        template    => '%== 13 / 8',
        prepend     => [],
        args        => [],
        sql         => qr{^1\.625$},
        vars        => [],
        name        => 'Immediate substitution',

    },

    {
        template    => '%= $variable',
        prepend     => ['my $variable = 127'],
        args        => [],
        sql         => qr{^\?$},
        vars        => [127],
        name        => 'Placeholder substitution with prepend',
    },

    {
        template    => '%= $variable',
        prepend     => [],
        args        => [],
        sql         => qr{^\?$},
        vars        => [127],
        name        => 'Placeholder substitution without prepend',
        die         => qr{\$variable}
    },

    {
        template    => '<%== 24 / 12 %> + <%== 12 / 6 %>',
        prepend     => [],
        args        => [],
        sql         => qr{^2 \+ 2$},
        vars        => [],
        name        => 'Immediate substitutions',
    },

    {
        template    => '<%= 24 / 12 %> + <%== 12 / 6 %>',
        prepend     => [],
        args        => [],
        sql         => qr{^\? \+ 2$},
        vars        => [2],
        name        => 'Immediate and placeholder substitutions',
    },

    {
        template    => 'a%<%== "♥" %>-% + <%= "♥" %>',
        prepend     => [],
        args        => [],
        sql         => qr{^a%♥-% \+ \?$},
        vars        => ['♥'],
        name        => 'UTF8 Immediate and placeholder substitutions',
    },

    {
        template    => q{
            % my $path = $0;
            % use File::Spec::Functions qw(catfile rel2abs);
            % use File::Basename qw(dirname);
            %= rel2abs dirname $0},
        prepend     => [],
        args        => [],
        sql         => qr{^\s*\?$},
        vars        => [ rel2abs dirname $0 ],
        name        => 'UTF8 Immediate and placeholder substitutions',
    },
    {
        template    => q[
            % for (1 .. 10) {
            <%= $_ %>,
            % }
        ],
        prepend     => [],
        args        => [],
        sql         => qr[^(\s*\?,){10}\s*$]s,
        vars        => [ 1 .. 10 ],
        name        => 'foreach',
    },
    {
        template    => q^
            SELECT
                '{abc}'::text[] AS "array"
        ^,
        prepend     => [],
        args        => [],
        sql         => qr[SELECT\s+'\{abc\}']s,
        vars        => [],
        name        => '{} brackets',
    },
);

for my $t(@tests) {
    $t->{prepend} ||= [];
    $t->{preprepend} ||= [];


    $tpl->clean_prepend;
    $tpl->prepend($_) for @{ $t->{prepend} };
    $tpl->preprepend($_) for @{ $t->{preprepend} };

    my $res = eval { $tpl->render($t->{template}, @{ $t->{args} }) };
    diag $@ unless ok $res || $t->{die}, $t->{name};
    if ($t->{die}) {
        like $@, $t->{die}, 'Renderer died';
    } else {
        diag $@ unless ok !$@, 'Rendered without exceptions';
        like $tpl->sql, $t->{sql}, 'Rendering sql';
        diag $tpl->sql unless
        is_deeply $tpl->variables, $t->{vars}, 'Bind variables';
    }
}


=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=cut

