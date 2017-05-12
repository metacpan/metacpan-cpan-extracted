
use Test::Most;
use Test::File;
use Test::File::Contents;

# http://www.cpantesters.org/cpan/report/f0925d72-3e45-11e1-a48f-e7fb434ae6f1
# perl 5.10.0 and File::Slurp 9999.19 has errors that cause NoWarnings to fail

# Is there a better way to do this?

BEGIN {

  eval "require File::Slurp";

  die "File::Slurp is not installed"
    if $@;

  my $fs_ver = $File::Slurp::VERSION;

  my $tests = 32;

  if ( $] eq '5.010000' && $fs_ver eq '9999.19' ) {

    note( 'Perl 5.10.0 and File::Slurp 9999.19 cause problems with Test::NoWarnings, not testing for warnings' );
    $tests--;

  } else {

    require Test::NoWarnings;
    Test::NoWarnings->import();

  }

  plan tests => $tests;

  use_ok( 'Config::NameValue' );

}

my $test_config = 't/test.config';
my $new_config  = 't/temp.test.config';
my $bad_config  = 'why do you have a file named like this?';
my $bad_name    = 'bad name that should never be used';

my $c;

#############################################################################
# Data we're expecting config object

explain 'Expected data: ', my $expected = { 'count' => 9, 'file' => $test_config, 'lines' => [ '# !!! Remember to change the test file if you change this file !!!', '', '# This is a basic name/value config file', '# These lines should be ignored', '', 'name1=value1', 'name2=value2 # This comment should not be part of the value', 'name3=value\\#3 # This value has a octothorpe as part of the value', '  name4=value4', ], 'modified' => 0, 'name' => { 'name1' => { 'line' => 5, 'modified' => 0, 'value' => 'value1', }, 'name2' => { 'line' => 6, 'modified' => 0, 'value' => 'value2', }, 'name3' => { 'line' => 7, 'modified' => 0, 'value' => 'value#3' }, 'name4' => { 'line' => 8, 'modified' => 0, 'value' => 'value4' }, }, };

#############################################################################
# No function calls are supported (except error)

throws_ok { Config::NameValue::new() } qr/Calling new as a function is not supported/,   'caught call to new as a function';
throws_ok { Config::NameValue::load() } qr/Calling load as a function is not supported/, 'caught call to load as a function';
throws_ok { Config::NameValue::save() } qr/Calling save as a function is not supported/, 'caught call to save as a function';
throws_ok { Config::NameValue::get() } qr/Calling get as a function is not supported/,   'caught call to get as a function';
throws_ok { Config::NameValue::set() } qr/Calling set as a function is not supported/,   'caught call to set as a function';

#############################################################################
# new with no filename, calls to methods with no filename

explain 'Empty config objected created: ', $c = Config::NameValue->new();
cmp_deeply( $c, noclass( {} ), 'object has expected data' );

throws_ok { $c->load } qr/No file to load/, 'caught bad load attempt';
throws_ok { $c->save } qr/No file to save/, 'caught bad save attempt';
throws_ok { $c->get } qr/Nothing loaded/,   'caught bad get attempt';
throws_ok { $c->set } qr/Nothing loaded/,   'caught bad set attempt';

#############################################################################
# new with no filename, load badfile, goodfile

explain 'Empty config objected created: ', $c = Config::NameValue->new();
cmp_deeply( $c, noclass( {} ), 'object has expected data' );

throws_ok { $c->load( $bad_config ) } qr/read_file '\Q$bad_config\E' - sysopen: No such file or directory/, 'bad filename caught';

explain 'Config object loaded: ', $c->load( $test_config );
cmp_deeply( $c, noclass( $expected ), 'object has expected data' );

#############################################################################
# new with filename (load is called from new)

explain 'Config object created: ', $c = Config::NameValue->new( $test_config );
cmp_deeply( $c, noclass( $expected ), 'object has expected data' );

#############################################################################
# save to same filename explicitly

throws_ok { $c->save( $test_config ) } qr/No changes, not saving/, 'not saving unmodified config to same file';

#############################################################################
# save unmodified config to new file

ok( $c->save( $new_config ), 'saved new_config' );
file_exists_ok( $new_config, "$new_config exists" );
files_eq $test_config, $new_config, 'new_config matches original';
is( unlink( $new_config ), 1, "unlinked $new_config" );
file_not_exists_ok( $new_config, "$new_config is gone" );

#############################################################################
# sub get

for my $n ( keys %{ $expected->{ name } } ) {

  is( $c->get( $n ), $expected->{ name }{ $n }{ value }, "$n value is correct" );
  is( Config::NameValue::error(), undef, 'error is empty' );

}

is( $c->get( $bad_name ), undef, "$bad_name is undefined" );
is( $c->error(), "$bad_name does not exist", 'caught bad name' );

#############################################################################
# sub set
