use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;
    plan tests => 1;
}
use Data::Stag qw(:all);
use Data::Stag::HashDB;

my $fn = shift @ARGV || "t/data/homol.itext";
my $hdb = Data::Stag::HashDB->new;

$hdb->unique_key("tax_id");
$hdb->record_type("species");
my $obj = {};
$hdb->index_hash($obj);
Data::Stag->parse(-file=>$fn, -handler=>$hdb);
my $sp = $obj->{7227};
print $sp->sxpr;
$sp->get_common_name eq 'fruitfly'
