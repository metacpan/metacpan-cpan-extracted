package Articulate::TestEnv;
use strict;
use FindBin;
use YAML;
use Articulate;
use FindBin;
use Exporter::Declare;
default_exports qw( app_from_config app_from_data );

sub app_from_config {
  my $fn = shift // "$FindBin::Bin/environments/testing.yml";
  $fn =~ s/(?<!\.yml)$/.yml/g;
  $fn =~ "$FindBin::Bin/environments/$fn" unless -e $fn;
  open my $fh, '<:encoding(utf8)', $fn;
  my $yaml;
  while ( defined( my $line = <$fh> ) ) { $yaml .= $line }
  my $data = YAML::Load $yaml;
  return app_from_data( $data->{plugins}->{Articulate} );
}

sub app_from_data {
  my $app = Articulate->new(shift);
  $app->components->{'storage'}->empty_all_content;
  return $app;
}

1;
