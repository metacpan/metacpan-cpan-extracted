package DarkPAN::Indexer::Format;

use strict;
use warnings;

use English qw(-no_match_vars);
use Dist::Metadata;

use Role::Tiny;

requires 'create_index';

requires 'update_index';

requires 'load_index';

requires 'delete_from_index';

requires 'new';

########################################################################
sub index_distribution {
########################################################################
  my ( $self, %args ) = @_;

  my ( $output_fh, $distribution, $fetch ) = @args{qw(output_fh distribution fetch)};

  my $archive_file = $fetch->($distribution);

  my $metadata = Dist::Metadata->new( file => $archive_file, );

  my $distribution_version = $metadata->version();
  my $package_versions     = $metadata->package_versions();

  die "unable to determine distribution version\n"
    if !defined $distribution_version || $distribution_version eq q{};

  die "unable to determine packages provided by distribution\n"
    if ref $package_versions ne 'HASH';

  my $module_count = 0;

  for my $module_name ( keys %{$package_versions} ) {
    my $module_version = $package_versions->{$module_name};

    if ( !defined $module_version || $module_version eq q{} || $module_version eq '0' ) {
      $module_version = $distribution_version;
    }

    print {$output_fh} join( "\t", $distribution, $module_name, $module_version, ), "\n"
      or die sprintf "unable to write index record: %s\n", $OS_ERROR,;

    $module_count++;
  }

  return $module_count;
}

1;
