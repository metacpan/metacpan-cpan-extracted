use strict;
use warnings;

use File::Spec;
use File::Temp qw(tempdir);
use JSON;
use Test::More;

use Data::NestedKey::CLI ();

{
  package Test::NestedKeyFormatCLI;
  use parent qw(Data::NestedKey::CLI);

  sub new { my ( $class, %args ) = @_; return bless \%args, $class; }
  sub get_fh { return $_[0]->{fh}; }
  sub get_infile { return $_[0]->{infile}; }
  sub get_format { return $_[0]->{format}; }
  sub get_output_format { return $_[0]->{output_format}; }
  sub get_backup { return $_[0]->{backup}; }
  sub get_replace { return $_[0]->{replace}; }
  sub get_args { return @{ $_[0]->{args} || [] }; }
  sub set_data { my ( $self, $data ) = @_; $self->{data} = $data; return $self; }
  sub get_data { return $_[0]->{data}; }
}

sub read_file {
  my ($file) = @_;
  open my $fh, '<', $file or die $!;
  local $/;
  my $content = <$fh>;
  close $fh;
  return $content;
}

sub new_cli {
  my ( $content, %args ) = @_;
  open my $fh, '<', \$content or die $!;
  return Test::NestedKeyFormatCLI->new( fh => $fh, %args );
}

my $cli = new_cli( '{"config":{"name":"old"}}',
  output_format => 'json', args => [ 'config.name', 'new' ] );
my $output = q{};
{
  open my $fh, '>', \$output or die $!;
  local *STDOUT = $fh;
  is( $cli->cmd_set, 0, 'explicit JSON output succeeds' );
}
is( decode_json($output)->{config}{name}, 'new', 'explicit JSON output contains update' );

$cli = new_cli( '{"config":{"name":"old"}}',
  args => [ 'config.name', 'new' ] );
$output = q{};
{
  open my $fh, '>', \$output or die $!;
  local *STDOUT = $fh;
  is( $cli->cmd_set, 0, 'default output format succeeds' );
}
is( decode_json($output)->{config}{name}, 'new', 'default output preserves JSON format' );

SKIP: {
  eval { require YAML::XS; YAML::XS::Dump({ test => 1 }); 1 }
    or skip 'YAML::XS is unavailable', 2;

  $cli = new_cli( '{"config":{"name":"old"}}',
    output_format => 'yaml', args => [ 'config.name', 'new' ] );
  $output = q{};
  {
    open my $fh, '>', \$output or die $!;
    local *STDOUT = $fh;
    is( $cli->cmd_set, 0, 'JSON to YAML conversion succeeds' );
  }
  is( YAML::XS::Load($output)->{config}{name}, 'new', 'YAML contains updated value' );
}

SKIP: {
  eval { require Bedrock::XML; 1 }
    or skip 'optional Bedrock::XML is not installed', 5;

  my $tmp = tempdir( CLEANUP => 1 );
  my $file = File::Spec->catfile( $tmp, 'tagx.xml' );
  open my $fh, '>', $file or die $!;
  print {$fh} qq{<object><scalar name="BEDROCK_SESSION_MANAGER">OldSession</scalar></object>\n};
  close $fh;

  $cli = new_cli( read_file($file), infile => $file,
    replace => 1, args => [ BEDROCK_SESSION_MANAGER => 'UserSession' ] );
  is( $cli->cmd_set, 0, 'legacy XML in-place set use case succeeds' );
  like( read_file($file), qr/<object\b/, 'replacement remains Bedrock XML' );
  my $parsed = Bedrock::XML->new($file)->devolve;
  is( $parsed->{BEDROCK_SESSION_MANAGER}, 'UserSession', 'XML value updated' );

  $cli = new_cli( read_file($file), format => 'xml',
    output_format => 'json', args => [ BEDROCK_SESSION_MANAGER => 'OtherSession' ] );
  $output = q{};
  {
    open my $out, '>', \$output or die $!;
    local *STDOUT = $out;
    is( $cli->cmd_set, 0, 'XML to JSON conversion succeeds' );
  }
  is( decode_json($output)->{BEDROCK_SESSION_MANAGER}, 'OtherSession', 'JSON conversion retains update' );
}

done_testing();
1;
