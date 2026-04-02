package ClarID::Tools::Util;

use strict;
use warnings;
use Carp               qw(croak);
use YAML::XS           qw(LoadFile);
use JSON::XS           qw(decode_json);
use Exporter 'import';
use ClarID::Tools ();
our @EXPORT_OK = qw( load_yaml_file load_json_file assert_supported_codebook_version );

# Load a YAML file, ensure it’s a HASHREF
sub load_yaml_file {
    my ($file) = @_;
    my $data = eval { LoadFile($file) };
    croak "Error loading YAML file '$file': $@" if $@;
    croak "Expected a HASH in '$file'" unless ref $data eq 'HASH';
    assert_supported_codebook_version( $data, $file );
    return $data;
}

sub assert_supported_codebook_version {
    my ( $data, $file ) = @_;

    my $version = $data->{metadata}{version};
    croak "Missing metadata.version in codebook '$file'"
      unless defined $version && $version ne '';

    my %supported =
      map { $_ => 1 } @ClarID::Tools::SUPPORTED_CODEBOOK_VERSIONS;

    return 1 if $supported{$version};

    my $supported = join ', ', @ClarID::Tools::SUPPORTED_CODEBOOK_VERSIONS;
    croak
"Unsupported codebook version '$version' in '$file'. This ClarID-Tools release supports: $supported";
}

# Load a JSON file, ensure it’s a HASHREF
sub load_json_file {
    my ($file) = @_;
    open my $fh, '<', $file
      or croak "Error opening JSON file '$file': $!";
    local $/;
    my $text = <$fh>;
    close $fh;
    my $data = eval { decode_json($text) };
    croak "Error parsing JSON in '$file': $@" if $@;
    croak "Expected a HASH in '$file'" unless ref $data eq 'HASH';
    return $data;
}

1;
