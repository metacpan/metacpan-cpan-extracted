use strict;
use lib qw(t/);

use TestFilter;
use Test::More;

plan tests => 17 + $COUNT_FILTER_INTERFACE + $COUNT_FILTER_STANDARD;

use_ok('Data::Transform::Map');
test_filter_interface('Data::Transform::Map');

# Test erroneous new() args
test_new("No Args");
test_new("Odd number of args", "one", "two", "odd");
test_new("Non code CODE ref", Code => [ ]);
test_new("Single Get ref", Get => sub { });
test_new("Single Put ref", Put => sub { });
test_new("Non CODE Get",   Get => [ ], Put => sub { });
test_new("Non CODE Put",   Get => sub { }, Put => [ ]);

sub test_new {
    my $name = shift;
    my @args = @_;
    my $filter;
    eval { $filter = Data::Transform::Map->new(@args); };
    ok($@ ne '', $name);
}

my $filter;
# Test actual mapping of Get, Put, and Code
$filter = Data::Transform::Map->new( Get => sub {uc($_[0])}, Put => sub {lc($_[0])});

test_filter_standard($filter,
        [qw/a b c/],
        [qw/A B C/],
        [qw/a b c/],
);

$filter = Data::Transform::Map->new(Code => sub { uc($_[0]) });
is_deeply($filter->put([qw/a b c/]), [qw/A B C/], "Test Put (as Code)");
is_deeply($filter->get([qw/a b c/]), [qw/A B C/], "Test Get (as Code)");


$filter = Data::Transform::Map->new( Get => sub { 'GET' }, Put => sub { 'PUT' } );

# Test erroneous modification
  test_modify("Modify Get not CODE ref",  $filter, Get => [ ]);
  test_modify("Modify Put not CODE ref",  $filter, Put => [ ]);
  test_modify("Modify Code not CODE ref", $filter, Code => [ ]);

sub test_modify {
   my ($name, $filter, @args) = @_;
   eval { $filter->modify(@args); };
   ok($@ ne '', $name);
}

$filter->modify(Get => sub { 'NGet' });
is_deeply($filter->get(['a']), ['NGet'], "Modify Get");

$filter->modify(Put => sub { 'NPut' });
is_deeply($filter->put(['a']), ['NPut'], "Modify Put");

$filter->modify(Code => sub { 'NCode' });
is_deeply($filter->put(['a']), ['NCode'], "Modify Code ");
is_deeply($filter->get(['a']), ['NCode'], "Modify Code ");
