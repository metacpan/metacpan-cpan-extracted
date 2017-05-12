#!perl

use strict;

use IO::File;
use Test::More tests => 8;

# Check their perl version
use_ok('Config::INI::Reader');

# Try to read in a config
my $hashref = Config::INI::Reader->read_file( 'examples/simple.ini' );
isa_ok($hashref, 'HASH', "return of Config::INI::Reader->read_file");

# Check the structure of the config
my $expected = {
  '_' => {
    root => 'something',
  },
  section => {
    one   => 'two',
    Foo   => 'Bar',
    this  => 'Your Mother!',
    blank => '',
    moo   => 'kooh',
  },
  'Section Two' => {
    'something else' => 'blah',
    'remove' => 'whitespace',
  },
};

is_deeply($hashref, $expected, 'Config structure matches expected');

# Add some stuff to the trivial config and check read_string() for it
my $Trivial = {};
$Trivial->{_} = { root1 => 'root2' };
$Trivial->{section} = {
  foo   => 'bar',
  this  => 'that',
  blank => '',
};
$Trivial->{section2} = {
  'this little piggy' => 'went to market'
};

my $string = <<END;
root1=root2

[ section ]
blank=
foo=bar
this=that

[section2]
this little piggy=went to market
END

{ # Test read_string
  my $hashref = Config::INI::Reader->read_string( $string );
  isa_ok($hashref, 'HASH', "return of Config::INI::Reader->read_string");

  is_deeply( $hashref, $Trivial, '->read_string returns expected value' );
}

{ # Test read_handle
  my $fh = IO::File->new('examples/simple.ini', 'r');
  my $data = do { local $/ = undef; <$fh> };

  open my $io, '<', \$data or die "can't open in memory string: $!";
  is_deeply(
    Config::INI::Reader->new->read_handle( $io ),
    $expected,
    '->read_handle returns expected value'
  );
}

#####################################################################
# Bugs that happened we don't want to happen again

{
  # Reading in an empty file, or a defined but zero length string, should yield
  # a valid, but empty, object.
  my $empty = Config::INI::Reader->read_string('');
  is_deeply($empty, {}, "an empty string gets an empty hashref");
}

{
  # "0" is a valid section name
  my $config = Config::INI::Reader->read_string("[0]\nfoo = 1\n");
  is_deeply(
    $config,
    { 0 => { foo => 1 } },
    "we can use 0 as a section name",
  );
}
