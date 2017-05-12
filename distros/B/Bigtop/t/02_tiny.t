use strict;

use Test::More tests => 3;

use Bigtop::Parser;

my $bigtop_string = <<'EO_Bigtop';
config {}
app Apps::Checkbook {
    # keeps track of payees and payors
    table payeepayor {
        field id    { is int4, primary_key, assign_by_sequence; }
    }
}
EO_Bigtop

Bigtop::Parser->add_valid_keywords(
    'field',
    { keyword => 'is' },
    { keyword => 'update_with' },
);

my $tree = Bigtop::Parser->parse_string($bigtop_string);

isa_ok( $tree,                  'bigtop_file',   'whole tree' );
isa_ok( $tree->{application},   'application',   'app subtree' );

ok( ref( $tree->{configuration} ) =~ /HASH/, 'config hash' );

#use Data::Dumper; warn Dumper( $tree );
