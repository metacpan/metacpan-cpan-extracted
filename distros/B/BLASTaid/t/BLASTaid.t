# Todd Wylie
# perldev@monkeybytes.org
# $Id: BLASTaid.t 20 2006-03-15 21:28:53Z Todd Wylie $
use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok('BLASTaid') };

# Create object:
my $report = "t/REPORT.blast";
my $index  = "/tmp/BLASTaid_test.index";
ok(my $blast = BLASTaid->new( report => $report, index => $index), "Class constructor for BLASTaid object") or exit;

# Return a specified report based on a query:
ok(my $string = $blast->return_report( query => 'gi|29294646|ref|NM_024852.2|' ), "Pulling a report based on query") or exit;

# Walk the entire object gathering query names, compare to known
# values:
my @known = qw(
               gi|45238847|ref|NM_000945.3|
               gi|71143145|ref|NM_006300.2|
               gi|56121814|ref|NM_030957.2|
               gi|17978470|ref|NM_006095.1|
               gi|54633341|ref|NM_207383.2|
               gi|31377804|ref|NM_003425.2|
               gi|50726969|ref|NM_015329.2|
               gi|58743322|ref|NM_001011718.1|
               gi|73858563|ref|NM_001756.3|
               gi|53729353|ref|NM_006522.3|
               gi|53759147|ref|NM_005057.2|
               gi|62243603|ref|NM_016220.3|
               gi|52546688|ref|NM_001005238.1|
               gi|7669500|ref|NM_005561.2|
               gi|34147425|ref|NM_032522.2|
               gi|7662125|ref|NM_015556.1|
               gi|60593053|ref|NM_001012716.1|
               gi|13375814|ref|NM_024607.1|
               gi|29294646|ref|NM_024852.2|
               gi|28626509|ref|NM_020650.2|
               gi|32189367|ref|NM_144646.2|
               gi|27894380|ref|NM_001405.2|
               gi|16945968|ref|NM_052953.2|
               gi|19923241|ref|NM_003409.2|
               gi|22001414|ref|NM_015444.1|
               gi|31791015|ref|NM_181617.1|
               gi|38201639|ref|NM_198268.1|
               gi|7019584|ref|NM_013359.1|
               gi|71559138|ref|NM_144998.2|
               gi|6806912|ref|NM_006869.1|
               gi|34147413|ref|NM_032313.2|
               gi|21071025|ref|NM_005319.3|
               gi|50897295|ref|NM_001002923.1|
               gi|24307882|ref|NM_001986.1|
               gi|24497527|ref|NM_002145.2|
               gi|62000632|ref|NM_016472.3|
               gi|8923134|ref|NM_017681.1|
               gi|34147481|ref|NM_080668.2|
               gi|55770831|ref|NM_001802.1|
               gi|38202215|ref|NM_005417.3|
               );
my @queries;
foreach my $query ( $blast->each_report( ignore => 'yes' ) ) {
    push(@queries, $query);
}
ok( eq_array(\@known, \@queries), "Comparing query lists.") or exit;

# Explicity undef the previous object:
ok($blast->undef(), "UNDEF BLASTaid index.") or exit;

# Now, since the index already exists, try and create another object from it:
ok(my $blast2 = BLASTaid->new( report => $report, index => $index), "New object from previous index.") or exit;

# Get the BLAST report type:
my $type = $blast2->type( report => 'gi|38202215|ref|NM_005417.3|' );
ok($type eq "BLASTN", "Return BLAST report type.") or exit;

__END__
