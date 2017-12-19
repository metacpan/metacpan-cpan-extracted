#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use Path::Class qw(file);

use Bio::MUST::Core;
use aliased 'Bio::MUST::Core::Seq';
use aliased 'Bio::FastParsers::Hmmer::Standard';
use aliased 'Bio::FastParsers::Hmmer::Table';
use aliased 'Bio::FastParsers::Hmmer::DomTable';
use Bio::MUST::Drivers;

my $class = 'Bio::MUST::Drivers::Hmmer';


# skip all HMMER tests unless hmmsearch is available in the $PATH
unless ( qx{which hmmsearch} ) {
    plan skip_all => <<"EOT";
skipped all HMMER tests!
If you want to use this module you need to install HMMER executables:
http://hmmer.org/download.html
EOT
}

# amino acid
{ # Tests 1 to 4, Creation of driver, model and parser + Targets name recovery

    # basic model creation
    my $test_file = file('test', 'aligned.ali');
    my $ali = Bio::MUST::Core::Ali->load($test_file);
    ok my $hmmer = $class->new( ali => $ali, consider_X => 1,
        args => {
            '--plaplace' => undef,
        }), "$class constructor";

    ok $hmmer->model, 'got model';
    ### test : $hmmer->model

    my @targets = $ali->all_seqs;

    # standard output search
    my $std_parser = $hmmer->search( \@targets, { '--notextw' => undef } );
    ok $std_parser, 'got standard HMM parser';

    my $std_exp_file_output = file('test', 'aligned_notextw.out');
    my $std_exp_output = Standard->new( file => $std_exp_file_output );

    my @target_reports = $std_parser->get_iteration(0)->all_targets;
    my $got_targets = [ map { $_->name } @target_reports ];
    explain $got_targets;

    my $exp_targets = [
        map { $_->name } $std_exp_output->get_iteration(0)->all_targets
    ];
    explain $exp_targets;

    cmp_deeply $got_targets, $exp_targets,
        'got expected target list for standard report';

# Tests 5 and 6, Table parser from hmmsearch

    # tabular output search
    my $tbl_parser = $hmmer->search( \@targets, { '--tblout' => undef } );
    ok $tbl_parser, 'got tabular HMM parser';

    my $tbl_exp_file_output = file('test', 'aligned_table.out');
    my $tbl_exp_output = Table->new( file => $tbl_exp_file_output );
    my @tbl_exp_names;
    while ( my $hit = $tbl_exp_output->next_hit ) {
        push @tbl_exp_names, $hit->target_name;
    }
    explain \@tbl_exp_names;

    my @tbl_got_names;
    while ( my $hit = $tbl_parser->next_hit ) {
        push @tbl_got_names, $hit->target_name;
    }
    explain \@tbl_got_names;

    cmp_deeply \@tbl_got_names, \@tbl_exp_names,
        'got expected target list for tabular report';

# Tests 7 and 8, DomTable parser from hmmsearch

    # DomTable output search
    my $domtbl_parser = $hmmer->search( \@targets, { '--domtblout' => undef } );
    ok $domtbl_parser, 'got domain table HMM parser';

    my $domtbl_exp_file_output = file('test', 'aligned_domtable.out');
    my $domtbl_exp_output = DomTable->new( file => $domtbl_exp_file_output );
    my @domtbl_exp_names;
    while ( my $hit = $domtbl_exp_output->next_hit ) {
        push @domtbl_exp_names, $hit->target_name;
    }
    explain \@domtbl_exp_names;

    my @domtbl_got_names;
    while ( my $hit = $domtbl_parser->next_hit ) {
        push @domtbl_got_names, $hit->target_name;
    }
    explain \@domtbl_got_names;

    cmp_deeply \@domtbl_got_names, \@domtbl_exp_names,
        'got expected target list for domain table report';
}

# nucleotide
{ # Tests 9 to 13, Creation of driver, model and parser + Targets name recovery

    # basic model creation
    my $test_file = file('test', 'aligned-nuc.ali');
    my $ali = Bio::MUST::Core::Ali->load($test_file);
    ok my $hmmer = $class->new( ali => $ali, consider_X => 1,
        args => {
            '--plaplace' => undef,
        }), "$class constructor";

    ok $hmmer->model, 'got model';

    my @targets = $ali->all_seqs;

    # standard output search
    my $std_parser = $hmmer->search( \@targets, { '--notextw' => undef } );
    ok $std_parser, 'got standard HMM parser';

    my $std_exp_file_output = file('test', 'aligned-nuc_notextw.out');
    my $std_exp_output = Standard->new( file => $std_exp_file_output );

    my @target_reports = $std_parser->get_iteration(0)->all_targets;
    my $got_targets = [ map { $_->name } @target_reports ];
    explain $got_targets;

    my $exp_targets = [
        map { $_->name } $std_exp_output->get_iteration(0)->all_targets
    ];
    explain $exp_targets;

    cmp_deeply $got_targets, $exp_targets,
        'got expected target list for standard report';

# Tests 14 and 15, Table parser from hmmsearch

    # tabular output search
    my $tbl_parser = $hmmer->search( \@targets, { '--tblout' => undef } );
    ok $tbl_parser, 'got tabular HMM parser';

    my $tbl_exp_file_output = file('test', 'aligned-nuc_table.out');
    my $tbl_exp_output = Table->new( file => $tbl_exp_file_output );
    my @tbl_exp_names;
    while ( my $hit = $tbl_exp_output->next_hit ) {
        push @tbl_exp_names, $hit->target_name;
    }
    explain \@tbl_exp_names;

    my @tbl_got_names;
    while ( my $hit = $tbl_parser->next_hit ) {
        push @tbl_got_names, $hit->target_name;
    }
    explain \@tbl_got_names;

    cmp_deeply \@tbl_got_names, \@tbl_exp_names,
        'got expected target list for tabular report';

# Tests 16 and 17, DomTable parser from hmmsearch

    # DomTable output search
    my $domtbl_parser = $hmmer->search( \@targets, { '--domtblout' => undef } );
    ok $domtbl_parser, 'got domain table HMM parser';

    my $domtbl_exp_file_output = file('test', 'aligned-nuc_domtable.out');
    my $domtbl_exp_output = DomTable->new( file => $domtbl_exp_file_output );
    my @domtbl_exp_names;
    while ( my $hit = $domtbl_exp_output->next_hit ) {
        push @domtbl_exp_names, $hit->target_name;
    }
    explain \@domtbl_exp_names;

    my @domtbl_got_names;
    while ( my $hit = $domtbl_parser->next_hit ) {
        push @domtbl_got_names, $hit->target_name;
    }
    explain \@domtbl_got_names;

    cmp_deeply \@domtbl_got_names, \@domtbl_exp_names,
        'got expected target list for domain table report';
}

# empty
{ # Test 18 to 19, Check if returning undefined object with empty ali
    my $test_file = file('test', 'empty.ali');
    my $ali = Bio::MUST::Core::Ali->load($test_file);
    ok my $hmmer = $class->new( ali => $ali, consider_X => 1,
        args => {
            '--plaplace' => undef,
        }), "$class constructor";

    my $model = $hmmer->model;
    ok(!defined $model, 'got undefined model from empty file as expected' );
    my $seq = Seq->new(
        seq_id => 'Test sequence@seq0001',
        seq    => 'MGRVIRSQRKGAGSIFRAHTKHRKGAAKLRAHDYAERHGYIKGIVKEIIHDPGRGAPLARVVFRDPYRYKLRKELFLATEGMYTGQFVYCGKRAALSVGNCLPIGAMPEGTVICAVEEKTGDRGKLAKASGNYATVVSHNVDAKKTRVRLPSGSKKVLSSTNRXVIGVVAGGGRIDKPMLKAGRAYHKYKVKRNCWPKVRGVAMNPVEHPHGGGNHQHIGKPSTVKRNTPAGRKVGLIAARRTGRLRGGKK'
    );
    my $parser = $hmmer->search( [ $seq ], { '--notextw' => undef } );
    ok(!defined $parser, 'got undefined parser from empty file as expected');
}

# emit
{ # Test 20-23, Emit method, use of consensus
	use Smart::Comments;

	# basic model creation
    my $test_file = file('test', 'aligned.ali');
    my $ali = Bio::MUST::Core::Ali->load($test_file);
    ok my $hmmer = $class->new( ali => $ali, consider_X => 1,
        args => {
            '--plaplace' => undef,
        }), "$class constructor";

    ok my $consensus = $hmmer->emit, 'Consensus retrieve';
    isa_ok($consensus, 'Bio::MUST::Core::Ali');
    #~ ### $consensus

    my $expected_consensus_seq = 'AARSIKSQKKDVNKIYPAHPSLFGRVPRPADKDKVNLVVKEIGKNAAEGAALARVAGLGEALARLPLATRVLNGGICANKYDTGLLGKLGFAERIRLPALNVKKLVSLCKKKASCYGTTTISRRKKPAGEKATAIELARRMRFKFHKRLKLPASPKKVKASSKKGP';
    cmp_ok($consensus->get_seq(0)->seq, 'eq', $expected_consensus_seq, 'Retrieve expected consensus');

}

done_testing;
