#-*-Perl-*-
## Bioperl Test Harness Script for Modules

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.t'

use strict;
use ExtUtils::MakeMaker;
use File::Temp qw(tempfile);
use Bio::Root::IO;
use FindBin '$Bin';
use constant TEST_COUNT => 32;

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

use Bio::DB::BigWig;

# high level tests
ok('loaded ok');

my $testfile = "$Bin/../ExampleData/dpy-27-variable.bw";
my $wig      = Bio::DB::BigWig->new(-bigwig=>$testfile,
#				    -fasta=>'/var/www/gbrowse2/databases/elegans_scaffolds'
    );
ok($wig);
ok($wig->isa('Bio::DB::BigWig'));

my $iterator = $wig->get_seq_stream(-seq_id=>'I',-start=>100,-end=>1000,-type=>'region');
ok ($iterator);
my $nodes = 0;
my $inbounds = 1;
while (my $f = $iterator->next_seq) {
    $nodes++;
    $inbounds &&= $f->seq_id eq 'I' && $f->start <= 1000 && $f->end >= 100;
}
ok($nodes,11);
ok($inbounds);

my @features = $wig->features(-seq_id=>'I',-start=>100,-end=>1000);
ok (scalar @features,$nodes);

{
    my $warning;
    local $SIG{__WARN__} = sub { $warning .= $_[0] };
    my @f = $wig->features(-seq_id=>'I',-start=>100,-end=>1000,-type=>['region','bin']);
    ok (scalar @f,$nodes);
    ok ($warning =~ /this module only supports/i);
}

my $id = $features[0]->id;
ok($id);
my $f  = $wig->get_feature_by_id($id);
ok($f);
ok($f->score>0);
ok($f->score,$features[0]->score);

my @big_vals  = grep {$_->score >= 0.5} @features;
my @big_vals2 = $wig->features(-seq_id=>'I',
			       -start=>100,
			       -end=>1000,
			       -filter=>sub {shift->score >0.5}
    );
ok (@big_vals,@big_vals2);

my @foo = $wig->features(-type=>'foo',-seq_id=>'I');
ok(@foo,0);

@foo = $wig->features(-type=>'foo');
ok(@foo,0);



# One way of getting summary data is as a series of feature objects of type 'bin'.
# The score of each is the extended summary hash
my @bins = $wig->features(-type=>'bin:1024',-seq_id=>'I');
ok(@bins,1024);
ok($bins[0]->score->{maxVal} > 0);

@bins = $wig->features(-type=>'bin:10',-seq_id=>'I');
ok(@bins,10);
ok($bins[0]->start,1);
ok($bins[-1]->end,$wig->bw->chromSize('I'));

# another way is to fetch type='summary'
my @summary = $wig->features(-type=>'summary');  # one for each chromosome
ok(@summary,7);
ok(join(' ',sort map{$_->seq_id} @summary),'I II III IV MtDNA V X');

ok(defined $summary[0]->can('statistical_summary'));
my $bins = $summary[0]->statistical_summary(100);
ok(@$bins,100);
ok($bins->[0]{maxVal} > 0);

# testing segment functionality
my $seg = $wig->segment('II',1=>50000);
ok($seg);
ok($seg->isa('Bio::DB::BigFile::Segment'));
ok($seg->length,50000);
ok(length $seg->dna,50000);

my @f = $seg->features('summary');
ok(@f,1);
ok(defined $f[0]->can('statistical_summary'));

1;

