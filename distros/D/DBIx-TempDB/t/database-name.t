use strict;
use Test::More;
use DBIx::TempDB;

my $tmpdb    = DBIx::TempDB->new('postgresql://example.com', auto_create => 0, keep_too_long_database_name => 1);
my $exe      = lc File::Basename::basename($0);
my $hostname = lc Sys::Hostname::hostname();
my $uid      = $<;

$exe =~ s!\W!_!g;
$hostname =~ s!\W!_!g;

my $name = $tmpdb->_generate_database_name(0);
is $name, "tmp_${uid}_database_name_t_${hostname}", 'tmp + uid + script + host';

$name = $tmpdb->_generate_database_name(1);
is $name, "tmp_${uid}_database_name_t_${hostname}_1", 'tmp + uid + script + host + 1';

$tmpdb->{template} = 'bar%i_%H_%P_%T_%U_%X_foo';
$name = $tmpdb->_generate_database_name(0);
is $name, join('_', 'bar', $hostname, $$, $^T, $<, $exe, 'foo'), $name;

$name = $tmpdb->_generate_database_name(3);
is $name, join('_', 'bar', 3, $hostname, $$, $^T, $<, $exe, 'foo'), $name;

$tmpdb->{template} = 'TEST';
$name = $tmpdb->_generate_database_name(0);
is $name, 'test';

done_testing;
