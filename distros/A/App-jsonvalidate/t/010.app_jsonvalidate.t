use strict;
use warnings;
use utf8;
use open ':std' => 'utf8';
use Test::More;
use Module::Generic::File qw( file tempdir );
use JSON ();
our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;

my $json = JSON->new->canonical->utf8;

my $tmp = tempdir( cleanup => 1 );
my $schema = <<'JSON';
{
    "$schema": "https://json-schema.org/draft/2020-12/schema",
    "type": "object",
    "required": ["x"],
    "properties": { "x": { "type": "integer", "minimum": 0 } },
    "additionalProperties": false
}
JSON
my $instances = <<'JSONL';
{"x":1}
{"x":0}
{"x":-1}
{"y":1}
JSONL

my $f = $tmp->child( 's.json' );
$f->unload_utf8( $schema ) || die( $f->error );

my $il = $tmp->child( 'i.jsonl' );
$il->unload_utf8( $instances ) || die( $il->error );

# Run CLI
my $cmd = qq{$^X -Ilib scripts/jsonvalidate --schema $tmp/s.json --instance $tmp/i.jsonl --jsonl --json};
$cmd .= qq{ --debug $DEBUG} if( $DEBUG );
diag( "Executing command: $cmd" ) if( $DEBUG );
my @out = qx( $cmd );
ok( @out >= 1, 'got output from jsonvalidate' );

my $ok = 0; my $fail = 0;
for my $line ( @out )
{
    my $rec = eval{ $json->decode( $line ) } || {};
    $ok   += 1 if( $rec->{ok} );
    $fail += 1 if( defined( $rec->{ok} ) && !$rec->{ok} );
}

ok( $ok >= 2,   'at least two OK' );
ok( $fail >= 2, 'at least two FAIL' );

done_testing();

__END__
