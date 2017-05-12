#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 9;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    note "************* DBIx::DR::Util *************";
    use_ok 'DBIx::DR::Util';
}


my ($module, $method) = camelize 'test-module_name#foo';
ok $module eq 'Test::ModuleName', 'camelize "test-module_name#foo": module';
ok $method eq 'foo', 'camelize "test-module_name#foo": method';

($module, $method) = camelize 'dbix-dr-iterator#new';
ok $module eq 'DBIx::DR::Iterator', 'camelize "dbix-dr-iterator#new": module';
ok $method eq 'new', 'camelize "dbix-dr-iterator#new": method';


($module, $method) = camelize 'dbix-dr-iterator';
ok $module eq 'DBIx::DR::Iterator', 'camelize "dbix-dr-iterator": module';
ok !defined $method, 'camelize "dbix-dr-iterator": method';

cmp_ok
    'test-module-sub_module#new',
    'eq',
    decamelize('Test::Module::SubModule', 'new'),
    'decamelize Test::Module::SubModule->new'
;

cmp_ok
    'test',
    'eq',
    decamelize('Test'),
    'decamelize Test'
;

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=cut

