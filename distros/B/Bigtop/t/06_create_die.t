use strict;

use Test::More tests => 1;
use Test::Exception;

use Cwd;
use Bigtop::Parser;

my $bigtop_string = <<'EO_Bigtop';
config {
}
app Apps::Checkbook {
    # keeps track of payees and payors
    table payeepayor {
        field id    { is int4, primary_key, assign_by_sequence; }
    }
}
EO_Bigtop

Bigtop::Parser->add_valid_keywords( 'field', { keyword => 'is' } );

my $old_cwd = cwd();

chdir 't';

dies_ok {
    Bigtop::Parser->gen_from_string( $bigtop_string, undef, 0, 'all' )
}     ". doesn't look like a build dir (level=4),\n"
        .   "  use --create to force a build in or under t\n";

chdir $old_cwd;
