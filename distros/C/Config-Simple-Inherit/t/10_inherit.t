#!/usr/bin/perl -wT
use strict;
use warnings;

use Data::Dumper;
use Test::More ( 'no_plan' );
use Test::Deep;

use lib qw { . };
use lib qw { lib };

BEGIN {
        use_ok( 'Config::Simple' );
        use_ok( 'Config::Simple::Inherit' );
}

my @methods = ('inherit');
foreach my $method (@methods){
  can_ok('Config::Simple::Inherit',$method);
}

my $base_dir = '.';
my $file = 't/simplified.ini';
my $file_inherit = 't/simplified_inherit.ini';
my $file_inherit_again = 't/simplified_inherit_again.ini';

my $cfg = Config::Simple->new( filename => "$base_dir/$file" );
isa_ok($cfg,'Config::Simple');

my $cfg_inherit;
# print STDERR "$base_dir/$file_inherit \n";
$cfg_inherit = Config::Simple::Inherit->inherit({ base_config => '', filename => "$base_dir/$file_inherit" });
isa_ok($cfg_inherit,'Config::Simple','Config::Simple::Inherit, w/o base_config object returns a Config::Simple object, and ');

# print STDERR Dumper(\$cfg_inherit);

$cfg_inherit = Config::Simple::Inherit->inherit({ base_config => $cfg, filename => "$base_dir/$file_inherit" });
isa_ok($cfg,'Config::Simple','The base configuration');
isa_ok($cfg_inherit,'Config::Simple','The child configuration');

my $expected_results = get_expected_results();
cmp_deeply($cfg_inherit->{'_DATA'},$expected_results,'New Configuration appropriately inherited from and overloaded base configuration.');

my $cfg_inherit_again = Config::Simple::Inherit->inherit({ base_config => $cfg_inherit, filename => "$base_dir/$file_inherit_again" });
isa_ok($cfg_inherit_again,'Config::Simple','The grand child configuration');

$expected_results->{'default'}->{'6'} = [ 'ftp(1):/public_html/mpfcu/lib/MPFCU/more_inherited_new_again.pm' ];
$expected_results->{"default"}{"Count"}[0] = 6;
$expected_results->{"default"}{"2"}[0] = 'ftp(1):/public_html/mpfcu/lib/MPFCU/Base_inherited_overloaded_again.pm';
$expected_results->{"default"}{"Name"}[0] = 'MPFCU_Inherited_overloaded_again';

cmp_deeply($cfg_inherit->{'_DATA'},$expected_results,'Grandchild Configuration appropriately inherited from and overloaded base and child configurations.');

is($cfg_inherit_again->{'_FILE_NAMES'}[0],"$base_dir/$file",'Object has correct base config file.');
is($cfg_inherit_again->{'_FILE_NAMES'}[1],"$base_dir/$file_inherit",'Object has correct child config file.');
is($cfg_inherit_again->{'_FILE_NAMES'}[2],"$base_dir/$file_inherit_again",'Object has correct grand child config file.');

# print "Given a base configuration, and a file which inherits from that configuration, and another from that . . . " . Dumper(\$cfg_inherit);

diag( "Testing Config::Simple::Inherit $Config::Simple::Inherit::VERSION, Perl $], $^X" );


1;

sub get_expected_results {
  return {
  'default' => {
           '0' => [ 'ftp(1):/public_html/mpfcu/.mpfcu' ],
           '1' => [ 'ftp(1):/public_html/mpfcu/lib/MPFCU/Agent.pm' ],
           '2' => [ 'ftp(1):/public_html/mpfcu/lib/MPFCU/Base_inherited_overloaded.pm' ],
           '3' => [ 'ftp(1):/public_html/mpfcu/lib/MPFCU/EStatements.pm' ],
           '5' => [ 'ftp(1):/public_html/mpfcu/lib/MPFCU/EStatements_inherited_new.pm' ],
       'Count' => [ '5' ],
        'Name' => [ 'MPFCU_Inherited_overloaded' ],
     'Library' => [ 'Config::Simple::Inherit' ],
           }
      };
}

