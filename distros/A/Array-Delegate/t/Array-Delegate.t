package Employee;

sub new { my $class = shift; return bless {@_}, $class; }

sub name { return shift->{name} }

# somehow needed to suppress a warning from Test::More
sub DESTROY {}

1;

package Company;

sub new { my $class = shift; return bless {@_}, $class; }


sub employees
{
	return Array::Delegate->new( [Employee->new( name => 'Bob' ), Employee->new( name => 'Alice' )] )
}

sub chairmen
{
	return bless [Employee->new( name => 'Steve' ), Employee->new( name => 'Bill' )], Array::Delegate;
}

1;

package main;

use warnings;
use strict;

use Test::More tests => 7;

BEGIN { use_ok('Array::Delegate') };

my $company = Company->new;

my $employee_names = $company->employees->name;
use Data::Dumper;

ok (scalar @$employee_names == 2);
ok ($employee_names->[0] eq 'Bob');
ok ($employee_names->[1] eq 'Alice');

my $chairmen_names = $company->chairmen->name;

ok (scalar @$chairmen_names == 2);
ok ($chairmen_names->[0] eq 'Steve');
ok ($chairmen_names->[1] eq 'Bill');
