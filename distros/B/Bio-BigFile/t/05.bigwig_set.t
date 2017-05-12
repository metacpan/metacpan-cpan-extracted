#-*-Perl-*-
## Bioperl Test Harness Script for Modules

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempdir);
use Bio::Root::IO;
use FindBin '$Bin';
use constant TEST_COUNT => 24;

use lib "$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";

use Test;
plan test => TEST_COUNT;

use Bio::DB::BigWigSet;

# high level tests
ok('loaded ok');

my $symlink_exists = eval { symlink("",""); 1 };
unless ($symlink_exists) {
    skip('symlinks not supported on this system') for 1..TEST_COUNT-1;
    exit 0;
}

my $testdir  = create_tempdir();
my $wigset   = Bio::DB::BigWigSet->new(-dir => $testdir,
#				        -fasta=>'/var/www/gbrowse2/databases/elegans_scaffolds'
    );
ok($wigset);

my $iterator = $wigset->get_seq_stream(-seq_id=>'I',
				       -start=>100,
				       -end=>1000,
				       -type=>'binding_site');
ok ($iterator);
my $nodes = 0;
my $inbounds = 1;
my $types_ok = 1;
while (my $f = $iterator->next_seq) {
    $nodes++;
    $inbounds &&= $f->seq_id eq 'I' && $f->start <= 1000 && $f->end >= 100;
    $types_ok &&= $f->type   eq 'binding_site';
}
ok($nodes,2);
ok($inbounds);
ok($types_ok);

my @features = $wigset->features(-seq_id=>'I',
				 -type => ['binding_site','chipdata']);
ok(@features,3);

@features = $wigset->features(-seq_id=>'I',
			      -type => 'ChIP-seq');
ok(@features,1);

@features = $wigset->features(-seq_id=>'I',
			      -type => 'ChIP-seq:test');
ok(@features,1);

@features = $wigset->features(-seq_id=>'I',
			      -type => 'ChIP-seq:foobar');
ok(@features,0);


@features = $wigset->features(-name=>'alr-3');
ok(@features,7);
my %name = map {$_->display_name => 1} @features;
ok(keys %name,1);
ok($name{'alr-3'});

@features = $wigset->get_features_by_attribute({confirmed=>1});
ok(@features,14);

my $arry = $features[0]->statistical_summary(100);
ok(@$arry,100);
ok($features[0]->id =~ /test\d+\.bw:I/);

my $feature = $wigset->get_feature_by_id($features[0]->id);
ok($feature->id,$features[0]->id);

@features = $wigset->get_features_by_location('I');
ok(@features,6);  # yep, six copies
my %names = map {$_->display_name=>1} @features;
ok($names{'test1'});
ok($names{'pol-II'});
ok($names{'dumpy-27'});

$wigset   = Bio::DB::BigWigSet->new(-dir          => $testdir,
				    -feature_type => 'bin:100');
@features = $wigset->features(-seq_id    =>'I',
			      -attributes=>{confirmed=>1});
ok(@features,200);

my @f = $wigset->get_features_by_name('foo-3');
ok(@f);
ok($f[0]->type,'ChIP-seq:test');

exit 0;

sub create_tempdir {
    my $dir  = tempdir(CLEANUP => 1);
    my $base = "$Bin/../ExampleData/";
    foreach (qw(dpy-27-variable.bw dumpy-27.bw test1.bw test2.bw test3.bw test4.bw)) {
	symlink "$base/dpy-27-variable.bw","$dir/$_";
    }
    open my $f,">","$dir/metadata.txt";
    print $f <<END;
[dpy-27-variable.bw]
type   = binding_site
method = ChIP-chip
source = LiebLab
display_name = dpy-27

[test2.bw]
type   = binding_site
method = ChIP-chip
source = SteinLab
confirmed = 1
display_name = pol-II

[test3.bw]
type   = chipdata
method = ChIP-seq
source = SteinLab
confirmed = 1
display_name = alr-3

[test4.bw]
method = ChIP-seq
source = test
display_name = foo-3

END
    return $dir;
}
