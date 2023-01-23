package BoardStreams::Client::Util;

use Mojo::Base -strict, -signatures;

use Mojo::Log;

use Exporter 'import';
our @EXPORT_OK = qw/ debug unique_id /;

our $VERSION = "v0.0.31";

my $log = Mojo::Log->new;
sub debug (@args) { $log->info(@args) }

my $UNIQUE_ID_LIMIT = 2 ** 50;
my $unique_id_cursor = 1;
sub unique_id {
    my $ret = $unique_id_cursor++;
    $unique_id_cursor <= $UNIQUE_ID_LIMIT or $unique_id_cursor = 1;
    return "$ret";
}

1;
