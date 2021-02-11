package BoardStreams::Client::StructDiff;

use Mojo::Base -strict, -signatures;

use Struct::Diff 'patch';

use Exporter 'import';
our @EXPORT_OK = qw/ patch_state /;

our $VERSION = "v0.0.13";

sub patch_state ($struct, $diff) {
    patch($struct, $diff);

    return $struct;
}

1;
