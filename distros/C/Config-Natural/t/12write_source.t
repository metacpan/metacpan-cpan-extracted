use strict;
use Test::More;
BEGIN {
  # In order to make this test, we need Data::Dumper, but it 
  # is not required for normal use of Config::Natural, therefore
  # it the module is not available, the test is skipped.
  eval {
    require Data::Dumper;
    require POSIX;
  };
  $@ and plan skip_all => "Data::Dumper or POSIX not available";
  plan tests => 2;
}
use Config::Natural;

$Data::Dumper::Sortkeys = 1 if defined $Data::Dumper::Sortkeys;

my $obj = new Config::Natural;
$obj->read_source(File::Spec->catfile('t','eva.txt'));

$obj->param({
    Eva_03 => $obj->param('Eva_03')." - Became the 13th Angel when possessed by Bardiel", 
    Eva_04 => $obj->param('Eva_04')." - Destroyed in the explosion of the Nerv base in the USA", 
});

# write $obj in a temp file
my $file_obj = POSIX::tmpnam();
$obj->write_source($file_obj);

# read that file in another object
my $dup = new Config::Natural $file_obj;

# check that both are identical
is_deeply( Data::Dumper::Dumper($obj->{param}), Data::Dumper::Dumper($dup->{param}) );  #01

# write $dup in a temp file
my $file_dup = POSIX::tmpnam();
$dup->write_source($file_dup);

# read that file in $obj
undef $obj;
$obj = new Config::Natural $file_dup;

# check that both are identical
is_deeply( Data::Dumper::Dumper($obj->{param}), Data::Dumper::Dumper($dup->{param}) );  #02

# remove temp files
unlink $file_obj, $file_dup;
