use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON;
use Test::More;

use Data::NestedKey::CLI ();

{
  package Test::NestedKeyCLI;
  use parent qw(Data::NestedKey::CLI);

  sub new { my ( $class, %args ) = @_; return bless \%args, $class; }
  sub get_fh { return $_[0]->{fh}; }
  sub get_format { return $_[0]->{format}; }
  sub get_output_format { return $_[0]->{output_format}; }
  sub get_infile { return $_[0]->{infile}; }
  sub get_backup { return $_[0]->{backup}; }
  sub get_replace { return $_[0]->{replace}; }
  sub get_error_on_undefined { return $_[0]->{error_on_undefined}; }
  sub get_args { return @{ $_[0]->{args} || [] }; }
  sub set_data { my ( $self, $data ) = @_; $self->{data} = $data; return $self; }
  sub get_data { return $_[0]->{data}; }
}

sub write_text {
  my ( $file, $text ) = @_;
  open my $fh, '>', $file or die $!;
  print {$fh} $text or die $!;
  close $fh or die $!;
  return;
}

sub read_text {
  my ($file) = @_;
  open my $fh, '<', $file or die $!;
  local $/;
  my $text = <$fh>;
  close $fh;
  return $text;
}

sub cli_from_json {
  my ( $json, %args ) = @_;
  open my $fh, '<', \$json or die $!;
  return Test::NestedKeyCLI->new( fh => $fh, %args );
}

my $cli = cli_from_json( '{"config":{"name":"original"}}' );
my $dnk = $cli->_fetch_data;
is( $dnk->get('config.name'), 'original', 'JSON input decoded' );
is( $Data::NestedKey::FORMAT, 'JSON', 'JSON takes precedence during autodetection' );

$cli = cli_from_json( '{"config":{"name":"original"}}', args => [] );
my $output = q{};
{
  open my $out, '>', \$output or die $!;
  local *STDOUT = $out;
  is( $cli->cmd_get, 0, 'get without a key succeeds' );
}
is_deeply( decode_json($output), { config => { name => 'original' } }, 'get defaults to entire document' );

$cli = cli_from_json( '{"config":{"name":"original"}}', args => ['config.name'] );
$output = q{};
{
  open my $out, '>', \$output or die $!;
  local *STDOUT = $out;
  is( $cli->cmd_get, 0, 'get nested value succeeds' );
}
is( $output, 'original', 'get prints scalar' );

$cli = cli_from_json( '{"config":{"name":"original"}}', format => 'json', args => [ 'config.name', 'updated' ] );
$output = q{};
{
  open my $out, '>', \$output or die $!;
  local *STDOUT = $out;
  is( $cli->cmd_set, 0, 'set without replace succeeds' );
}
is( decode_json($output)->{config}{name}, 'updated', 'set emits changed data' );

my $tmp = tempdir( CLEANUP => 1 );
my $file = File::Spec->catfile( $tmp, 'config.json' );
write_text( $file, '{"config":{"name":"original"}}' );
chmod 0640, $file or die $!;

$cli = cli_from_json( read_text($file), infile => $file, replace => 1, args => [ 'config.name', 'replaced' ] );
is( $cli->cmd_set, 0, '--replace succeeds without --backup' );
is( decode_json( read_text($file) )->{config}{name}, 'replaced', 'file was replaced' );
is( ( stat($file) )[2] & 0777, 0640, 'replacement preserves file permissions' );

$cli = cli_from_json( read_text($file), infile => $file, backup => 'bak', args => [ 'config.name', 'backed-up' ] );
is( $cli->cmd_set, 0, '--backup implies replacement' );
is( decode_json( read_text($file) )->{config}{name}, 'backed-up', 'replacement file updated' );
my $backup = File::Spec->catfile( $tmp, 'config.bak' );
is( decode_json( read_text($backup) )->{config}{name}, 'replaced', 'backup holds previous contents' );

$cli = cli_from_json( read_text($file), infile => $file, backup => 'bak', args => [ 'config.name', 'again' ] );
my $error = eval { $cli->cmd_set; q{} };
like( $@, qr/backup already exists/, 'refuses to overwrite existing backup' );
is( decode_json( read_text($file) )->{config}{name}, 'backed-up', 'failed backup leaves source untouched' );
is( decode_json( read_text($backup) )->{config}{name}, 'replaced', 'failed backup leaves prior backup untouched' );

$cli = cli_from_json( '{"x":1}', backup => 'bak', args => [ x => 2 ] );
eval { $cli->cmd_set; };
like( $@, qr/require an input filename/, 'cannot replace STDIN' );

$cli = cli_from_json( 'not valid JSON', format => 'json' );
eval { $cli->_fetch_data; };
like( $@, qr/unable to deserialize input/, 'explicit-format errors are reported' );

done_testing();
1;
