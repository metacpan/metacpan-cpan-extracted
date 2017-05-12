#!perl -w
$ENV{'CLASS_ACCESSOR_LVALUE_CLASS'} = 'Class::Accessor::Lvalue::Fast';
use lib qw(t);
require 'lval-core.pl';
