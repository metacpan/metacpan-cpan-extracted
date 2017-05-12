use strict;
use Test::More;
BEGIN { 
  # In order to make this test, we need Data::Dumper, but it 
  # is not required for normal use of Config::Natural, therefore 
  # it the module is not available, the test is skipped. 
  eval {
    require Data::Dumper;
    require IO::File;
  };
  $@ and plan skip_all => "Data::Dumper or IO::File not available";
  plan tests => 2;
}
use Config::Natural;
Config::Natural->options(-quiet => 1);

$Data::Dumper::Sortkeys = 1 if defined $Data::Dumper::Sortkeys;

my $obj = new Config::Natural;
$obj->read_source(File::Spec->catfile('t','nerv.txt'));

# save the data of the object
my $data = Data::Dumper::Dumper($obj->{'param'});

# dump $obj in a temp file
my $fh = IO::File->new_tmpfile() or die "Unable to make new temporary file: $!";
print $fh $obj->dump_param;
seek($fh, 0, 0);  # rewind

# checking that calling ->dump_param() didn't mess up anything
# (fixed in 0.98)
is( Data::Dumper::Dumper($obj->{'param'}) , $data );  #01

# create $dup reading the temp file; $dup should be a clone of $obj
my $dup = new Config::Natural;
$dup->read_source($fh);

# check the clones are real twins
is_deeply( $obj->dump_param, $dup->dump_param );  #02
