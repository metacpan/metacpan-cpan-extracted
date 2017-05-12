#!perl -T

use strict;
use warnings;
use Test::More tests => 17;

BEGIN {
	use_ok( 'Config::KeyValue' );
}


my $cfg = Config::KeyValue->new();
isa_ok($cfg, 'Config::KeyValue');

undef $@;
eval { $cfg->load_file('this/file/does/not/exist'); };
like($@, qr/^could not open file for reading/, 'error on non-existent file');

my $config_file = 't/config';

undef $@;
eval { $cfg->load_file($config_file); };
is($@, '', 'no error when reading existing file');

my $exp = {
  'double_quoted'     => '"this value is double quoted"',
  'mixed_quotes'      => "'this value has mixed quotes\"",
  'one_key'           => 'multiple values',
  'simple_key'        => 'simple_value',
  'single_quoted'     => "'this value is single quoted'",
  'trailing_comment'  => 'trailing comment value'
};
my $got = $cfg->load_file($config_file);
is_deeply($got, $exp);

# Get values as-is
is( $cfg->get('double_quoted'),     '"this value is double quoted"'   );
is( $cfg->get('mixed_quotes'),      "'this value has mixed quotes\""  );
is( $cfg->get('one_key'),           'multiple values'                 );
is( $cfg->get('simple_key'),        'simple_value'                    );
is( $cfg->get('trailing_comment'),  'trailing comment value'          );
is( $cfg->get('single_quoted'),     "'this value is single quoted'"   );

# Get the tidied values
is( $cfg->get_tidy('double_quoted'),    'this value is double quoted'   );
is( $cfg->get_tidy('mixed_quotes'),     "'this value has mixed quotes\"");
is( $cfg->get_tidy('one_key'),          'multiple values'               );
is( $cfg->get_tidy('simple_key'),       'simple_value'                  );
is( $cfg->get_tidy('trailing_comment'), 'trailing comment value'        );
is( $cfg->get_tidy('single_quoted'),    'this value is single quoted'   );

