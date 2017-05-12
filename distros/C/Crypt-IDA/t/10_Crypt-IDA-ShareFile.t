# -*- Perl -*-

use Test::More tests => 6;
BEGIN { use_ok('Crypt::IDA::ShareFile', ':all') };

use Crypt::IDA ":all";

my $patt='%f-%c-%s';

ok (sf_sprintf_filename($patt,"foo",2,3) eq 'foo-2-3',
    "sf_sprintf_filename");

# first test uses an identity matrix as the transform, which should
# effect a striping of input
my $id=Math::FastGF2::Matrix->
  new_identity(size => 3, org => 'rowwise', width => 1);
ok (defined ($id),   "problem creating 3x3 identity matrix!");

my $secret="abcdefghi";
my $tempfile="tempfile.$$";
open TEMPFILE, ">$tempfile" or die "Couldn't created tempfile\n";
print TEMPFILE $secret;
close TEMPFILE;
my $filler=fill_from_file($tempfile, 3);

sf_split(quorum => 3, shares => 3, matrix => $id, filename => $tempfile);

unlink $tempfile;

sf_combine(infiles => [ map { "$tempfile-$_.sf"} (0..2) ],
	   outfile => $tempfile);
open TEMPFILE, "<$tempfile";

map { unlink "$tempfile-$_.sf"} (0..2);

my $got_back=<TEMPFILE>;

ok ($secret eq $got_back,     "simple striping of secret");

# Try the same, but with a randomly generated key
my $rng=ida_rng_init(1);
my $key=ida_generate_key(3,3,1,$rng);

sf_split(quorum => 3, shares => 3, filename => $tempfile,
	 key => $key, sharelist => [0..2]);

unlink $tempfile;

sf_combine(infiles => [ map { "$tempfile-$_.sf"} (0..2) ],
	   outfile => $tempfile);
open TEMPFILE, "<$tempfile";

map { unlink "$tempfile-$_.sf"} (0..2);

$got_back=<TEMPFILE>;
ok ($secret eq $got_back,     "(3,3) scheme with our key");

# Same, but without passing in a key/matrix

sf_split(quorum => 3, shares => 3, filename => $tempfile);

unlink $tempfile;

sf_combine(infiles => [ map { "$tempfile-$_.sf"} (0..2) ],
	   outfile => $tempfile);
open TEMPFILE, "<$tempfile";

map { unlink "$tempfile-$_.sf"} (0..2);

$got_back=<TEMPFILE>;
ok ($secret eq $got_back,     "(3,3) scheme without key/matrix");

unlink $tempfile;

