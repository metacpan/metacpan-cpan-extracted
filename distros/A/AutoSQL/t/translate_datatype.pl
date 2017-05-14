use strict;
use lib 'lib', 't/lib';
use Test;
BEGIN{ plan tests=>2;}
use AutoSQL::SQLGenerator;
my $g=AutoSQL::SQLGenerator->new;

ok $g->_translate_datatype('C^8'), 'TEXT';
ok $g->_translate_datatype('C+8'), 'LONGTEXT';

print $g->_translate_datatype('C255') ."\n";
print $g->_translate_datatype('C256') ."\n";
eval {
    AutoSQL::SQLGenerator->_translate_datatype('C2^9U');
};

ok($@);

print $g->_translate_datatype('I^9U') ."\n";
ok $g->_translate_datatype('I^9U'), 'SMALLINT UNSIGNED';
print $g->_translate_datatype('I9U') ."\n";
