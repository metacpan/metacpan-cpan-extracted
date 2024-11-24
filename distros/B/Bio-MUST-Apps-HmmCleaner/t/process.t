#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use Modern::Perl;

use Smart::Comments;

use Path::Class qw(file);

use Bio::MUST::Core;
use Bio::MUST::Drivers::Hmmer::Model::Temporary;

use Bio::FastParsers::Hmmer;

use Bio::MUST::Apps::HmmCleaner;

say 'Note: tests designed for: HMMER 3.3.2 (Nov 2020); http://hmmer.org/';

my $class = 'Bio::MUST::Apps::HmmCleaner::Process';

# Creation of the 3 elements needed to build a process
my $ali = Bio::MUST::Core::Ali->load('test/GNTPAN12210.ali');

my $model_args = {
    '--plaplace'    => undef,
    '--fragthresh'  => "0.0",
    '--symfrac'     => 0.5,
};

my $alitemp_args = {
    degap       => 0,
    gapify      => 'X',
    clean       => 1,
};

# Creation of global profile
my $hmmer = Bio::MUST::Drivers::Hmmer::Model::Temporary->new(
    seqs        => [$ali->all_seqs],
    model_args  => $model_args,
    args        => $alitemp_args,
);
my $seq = ($ali->all_seqs)[0];

# Creation of Process object
my $process = $class->new(
    'ali'   => $ali,
    'seq'   => $seq,
    'model' => $hmmer,
);

my $expected_scoreseq = '                                                          g+g++g+g     +ggdparpglsqqqrasqrkaqvr+lprakkleklgvfsackane+ckcngwknp+pptaprmdlqqpaa+lse crsc+h+ladhvshlenvse+einrllgmvvdvenlfmsvhkeedtdtkqvyfylfkllrkcilqm++pvvegslgsppfekpnieqgvlnfvqykfshl+p+erqtm+elskmfllclnywkletp+qfrqrsq +dva+ykvnytrwlcychvpqscdslpryett+vfgr+llrsiftvtrrqllekfrvekdkl+pekrtlilthfpkflsmleeeiyg nspiwe++ftmp+segtql++rpa vs+++vps+p+f+++++ggs+s++++ds g+ep+pgekr lpe+ltledakr+rvmgdipmelvnevmltitdpaamlgpetsllsanaardetarleerrgiiefhvignsl++k+n+++l+wlvglqnvfshqlprmpkeyi+rlvfdpkhktlalikdgrviggicfrmfptqgfteivfcavtsneqvkgygthlmnhlkeyhikhnil+fltyadeyaigyfkkqgfskdikvpksrylgyikdyegatlmecelnpripytelshiikkqkeiikklierkqaqirkvypglscfkegvrqip+es+pgiretgwkp+gkekgkelkdpdqly+tlknllaqikshpsawpfmepvkk+eapdyyevirfpidlktm+erl++ryyvt+klf+adlqrv++ncreynpp+seyc+ca++lekffyfk+ke+glidk';

cmp_ok $process->score, 'eq', $expected_scoreseq,
    'scoreseq processed properly';

done_testing;
