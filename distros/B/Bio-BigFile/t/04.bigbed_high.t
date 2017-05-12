#-*-Perl-*-
## Bioperl Test Harness Script for Modules

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempfile);
use Bio::Root::IO;
use FindBin '$Bin';
use constant TEST_COUNT => 35;

use lib "$Bin/../lib","$Bin/../blib/lib","$Bin/../blib/arch";

BEGIN {
  # to handle systems with no installed Test module
  # we include the t dir (where a copy of Test.pm is located)
  # as a fallback
  eval { require Test; };
  if( $@ ) {
    use lib 't';
  }
  use Test;
  plan test => TEST_COUNT;
}

use Bio::DB::BigBed;

# high level tests
ok('loaded ok');

my $testfile = "$Bin/../ExampleData/refSeqTest.flat.bb";
my $bed      = Bio::DB::BigBed->new(-bigbed=>$testfile,
#				    -fasta=>'/var/www/gbrowse2/databases/elegans_scaffolds'
    );
ok($bed);
ok($bed->isa('Bio::DB::BigBed'));

my $iterator = $bed->get_seq_stream(-seq_id=>'chr1',
				    -start => 11704300,
				    -end   => 11914000,
				    -type=>'region');
ok ($iterator);
my $nodes = 0;
my $inbounds = 1;
while (my $f = $iterator->next_seq) {
    $nodes++;
    $inbounds &&= $f->seq_id eq 'chr1' && $f->start <= 11914000 && $f->end >= 11704300;
}
ok($nodes,4);
ok($inbounds);

my @features = $bed->features(-seq_id=>'chr1',-start=>11704300,-end=>11914000);
ok (scalar @features,$nodes);

{
    my $warning;
    local $SIG{__WARN__} = sub { $warning .= $_[0] };
    my @f = $bed->features(-seq_id=>'chr1',
			   -start=>11704300,
			   -end=>11914000,
			   -type=>['region','bin']);
    ok (scalar @f,$nodes);
    ok ($warning =~ /this module only supports/i);
}

{ 
    no warnings;
    my @big_vals  = grep {$_->score >= 0.5} @features;
    my @big_vals2 = $bed->features(-seq_id=>'chr1',
				   -start=>11704300,
				   -end=>11914000,
				   -filter=>sub {shift->score >0.5});
    ok (@big_vals,@big_vals2);
}

@features = $bed->features;
ok(@features,7);

@features = $bed->get_features_by_location('chr1');
ok(@features,6);

@features = $bed->get_features_by_location(-seq_id=>'chr1',
					   -strand=>'-1');
ok(@features,1);

my $id = $features[0]->id;
ok($id);
my @f  = $bed->get_feature_by_id($id);
ok(@f,1);
ok($f[0]->display_name eq $features[0]->display_name);

my @foo = $bed->features(-type=>'foo',-seq_id=>'chr1');
ok(@foo,0);

@foo = $bed->features(-type=>'foo');
ok(@foo,0);

# One way of getting summary data is as a series of feature objects of type 'bin'.
# The score of each is the extended summary hash
my @bins = $bed->features(-type=>'bin:1024',-seq_id=>'chr1');
ok(@bins,1024);
ok($bins[48]->score->{maxVal} > 0);

@bins = $bed->features(-type=>'bin:10',-seq_id=>'chr1');
ok(@bins,10);
ok($bins[0]->start,1);
ok($bins[-1]->end,$bed->bw->chromSize('chr1'));

# another way is to fetch type='summary'
my @summary = $bed->features(-type=>'summary');  # one for each chromosome
ok(@summary,2);
ok(join(' ',sort map{$_->seq_id} @summary),'chr1 chr4');

ok(defined $summary[0]->can('statistical_summary'));
my $bins = $summary[0]->statistical_summary(100);
ok(@$bins,100);
ok($bins->[4]{maxVal} > 0);

# testing segment functionality
my $seg = $bed->segment('chr4',71_200_001 => 71_300_000);
ok($seg);
ok($seg->isa('Bio::DB::BigFile::Segment'));
ok($seg->length,100000);
ok(length $seg->dna,100000);
ok($seg->features,1);

@f = $seg->features('summary');
ok(@f,1);
ok(defined $f[0]->can('statistical_summary'));

1;

