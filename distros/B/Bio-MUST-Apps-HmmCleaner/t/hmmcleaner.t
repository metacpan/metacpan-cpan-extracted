#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use Modern::Perl;

use Smart::Comments;

use Path::Class qw(file);

use Bio::MUST::Apps::HmmCleaner;

my $class = 'Bio::MUST::Apps::HmmCleaner';

#~ check_test('GNTPAN12210.ali', 'GNTPAN12210_hmm10_global', { 'perseq' => 0, 'X' => 0});

check_cleaner('GNTPAN12210.ali', 'GNTPAN12210_hmm', { 'perseq' => 0, 'X' => 0});
check_cleaner('GNTPAN12210.ali', 'GNTPAN12210_hmm_X', { 'perseq' => 0, 'X' => 1});
check_cleaner('GNTPAN12210.ali', 'GNTPAN12210_hmm_perseqX', { 'perseq' => 1, 'X' => 1});
check_cleaner('GNTPAN12210.ali', 'GNTPAN12210_hmm_changeID', { 'perseq' => 0, 'X' => 1, changeID => 1});
check_cleaner('GNTPAN12210.ali', 'GNTPAN12210_hmm_changeCost', { 'perseq' => 0, 'X' => 1, costs => [-0.2, -0.05, 0.10, 0.5]});


sub check_cleaner {
    my $file = shift;
    my $expected_outfile = shift;
    my $args = shift // {};

    explain $expected_outfile;

    # read configuration file
    my $actual_args = {
		ali             => file('test',$file),
        ali_model       => file('test',$file),
		consider_X      => $$args{'X'},
		perseq_profile  => $$args{'perseq'},
        outfile_type    => 1, # working in Ali format
	};
    
    $$actual_args{changeID} = $$args{changeID} if exists $$args{changeID};
    $$actual_args{delchar} = $$args{delchar} if exists $$args{delchar};
    $$actual_args{costs} = $$args{costs} if exists $$args{costs};

	### Creating object for file : $file
	my $cleaner = $class->new($actual_args);
	$cleaner->_set_outfile('test/testfile');
	$cleaner->store_all;

    my @goners = (
        file('test', 'testfile.ali'),
        file('test', 'testfile.log'),
        file('test', 'testfile.score'),
    );
    
    compare_ok(
        file('test', "$expected_outfile.ali"),
        $goners[0],
            "wrote expected Ali for: $expected_outfile"
    );

    compare_ok(
        file('test', "$expected_outfile.log"),
        $goners[1],
            "wrote expected log for: $expected_outfile"
    );

    compare_ok(
        file('test', "$expected_outfile.score"),
        $goners[2],
            "wrote expected score for: $expected_outfile"
    );

    foreach my $file ( @goners ) {
        unlink $file or warn "Could not unlink $file: $!";
    }
}

done_testing;
