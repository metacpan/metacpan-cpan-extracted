#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test various options for reading, such as case folding.

=cut

use Test::More qw(no_plan);


use Data::SExpression;

my $ds = Data::SExpression->new({symbol_case => 'up'});

is(scalar $ds->read('foobarbaz'), \*::FOOBARBAZ);
is(scalar $ds->read('fooBARbaz'), \*::FOOBARBAZ);

$ds = Data::SExpression->new({symbol_case => 'down'});

is(scalar $ds->read('foobarbaz'), \*::foobarbaz);
is(scalar $ds->read('fooBARbaz'), \*::foobarbaz);

$ds = Data::SExpression->new({use_symbol_class => 1});

my $foobar = $ds->read('foobar');

isa_ok($foobar, 'Data::SExpression::Symbol');
is($foobar->name, 'foobar');


$ds = Data::SExpression->new({fold_dashes => 1});

{
    no warnings 'once';
    is(scalar $ds->read('with-open-file'), \*::with_open_file, "Folded dashes to underscores");
}
