package ClarID::Tools::Util;

use strict;
use warnings;
use Carp               qw(croak);
use YAML::XS           qw(LoadFile);
use JSON::XS           qw(decode_json);
use Exporter 'import';
our @EXPORT_OK = qw( load_yaml_file load_json_file );

# Load a YAML file, ensure it’s a HASHREF
sub load_yaml_file {
    my ($file) = @_;
    my $data = eval { LoadFile($file) };
    croak "Error loading YAML file '$file': $@" if $@;
    croak "Expected a HASH in '$file'" unless ref $data eq 'HASH';
    return $data;
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

