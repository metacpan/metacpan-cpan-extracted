#!/usr/bin/env perl

use Test::Most;
use Test::Files;

use autodie;
use feature qw(say);

use Module::Runtime qw(use_module);
use Path::Class qw(file);

use Bio::FastParsers;
use Bio::MUST::Core;
use Bio::MUST::Drivers;

my     $class = 'Bio::MUST::Drivers::Hmmer::Model';
my $tmp_class = 'Bio::MUST::Drivers::Hmmer::Model::Temporary';
my  $db_class = 'Bio::MUST::Drivers::Hmmer::Model::Database';


# Note: provisioning system is not enabled to help tests to pass on CPANTS
my $app = use_module('Bio::MUST::Provision::Hmmer')->new;
unless ( $app->condition ) {
    plan skip_all => <<"EOT";
skipped all HMMER tests!
If you want to use this module you need to install HMMER executables:
http://hmmer.org/download.html
If you --force installation, I will eventually try to install HMMER with brew:
https://brew.sh/
EOT
}

{ # Tests 1 and 3: Use of a pre-existing model
    my $hmmfile = file('test', 'aligned.hmm');
    my $model = $class->new( file => $hmmfile );
    cmp_ok $model->cksum, 'eq', '1835300390',
        'got expected model checksum';

    my $target = file('test', 'ready_unaligned.fasta');
    my $std_parser = $model->search($target);
    ok $std_parser, 'got HMM parser on pre-existing model and target';

    my $filename = $std_parser->filename;
    $std_parser->remove;
    ok(!-e $filename, '... and it got deleted as expected!');
}

# amino acid
{ # Tests 4 to 7: Creation of driver, model and parser + Target name recovery

    # basic model creation
    my $infile = file('test', 'aligned.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);
    ok my $model = $tmp_class->new(
        seqs => $ali,       # alternatively: $infile or [ $ali->all_seqs ]
        model_args => { '--plaplace' => undef }
    ), "$tmp_class constructor";

    # check delegation to Bio::FastParsers::Hmmer::Model
    cmp_ok $model->model->cksum, 'eq', '1835300390',
        'got expected model checksum';

    # build target sequence file
    my $target = Bio::MUST::Core::Ali::Temporary->new(
        seqs => $ali, args => { degap => 1 }
    );

    # standard output search
    my $std_parser = $model->search($target);
    ok $std_parser, 'got standard HMM parser on temporary model';

    my @target_reports = $std_parser->get_iteration(0)->all_targets;
    my $got_targets = [ map { $_->name } @target_reports ];
#   my $report = $std_parser->filename;
#   qx{cp $report /Users/denis/Desktop/aligned_notextw.out};
    $std_parser->remove;

    my $std_exp_file_output = file('test', 'aligned_notextw.out');
    my $std_exp_output = Bio::FastParsers::Hmmer::Standard->new(
        file => $std_exp_file_output
    );

    my $exp_targets = [
        map { $_->name } $std_exp_output->get_iteration(0)->all_targets
    ];

    cmp_deeply $got_targets, $exp_targets,
        'got expected target list for standard report';

# Tests 8 and 9: Table parser from hmmsearch

    # tabular output search
    my $tbl_parser = $model->search( $target, { '--tblout' => undef } );
    ok $tbl_parser, 'got tabular HMM parser';

    my @tbl_got_names;
    while ( my $hit = $tbl_parser->next_hit ) {
        push @tbl_got_names, $hit->target_name;
    }
#   my $report = $tbl_parser->filename;
#   qx{cp $report /Users/denis/Desktop/aligned_table.out};
    $tbl_parser->remove;

    my $tbl_exp_file_output = file('test', 'aligned_table.out');
    my $tbl_exp_output = Bio::FastParsers::Hmmer::Table->new(
        file => $tbl_exp_file_output
    );

    my @tbl_exp_names;
    while ( my $hit = $tbl_exp_output->next_hit ) {
        push @tbl_exp_names, $hit->target_name;
    }

    cmp_deeply \@tbl_got_names, \@tbl_exp_names,
        'got expected target list for tabular report';

# Tests 10 and 11: DomTable parser from hmmsearch

    # DomTable output search
    my $domtbl_parser = $model->search( $target, { '--domtblout' => undef } );
    ok $domtbl_parser, 'got domain table HMM parser';

    my @domtbl_got_names;
    while ( my $hit = $domtbl_parser->next_hit ) {
        push @domtbl_got_names, $hit->target_name;
    }
#   my $report = $domtbl_parser->filename;
#   qx{cp $report /Users/denis/Desktop/aligned_domtable.out};
    $domtbl_parser->remove;

    my $domtbl_exp_file_output = file('test', 'aligned_domtable.out');
    my $domtbl_exp_output = Bio::FastParsers::Hmmer::DomTable->new(
        file => $domtbl_exp_file_output
    );

    my @domtbl_exp_names;
    while ( my $hit = $domtbl_exp_output->next_hit ) {
        push @domtbl_exp_names, $hit->target_name;
    }

    cmp_deeply \@domtbl_got_names, \@domtbl_exp_names,
        'got expected target list for domain table report';

    my $filename = $model->filename;
    $model->remove;
    ok(!-e $filename, 'Ali::Temporary file got deleted as expected!');

    my $model_filename = $model->model->filename;
    $model->model->remove;
    ok(!-e $model_filename, 'Model::Temporary file got deleted as expected!');
}

# nucleotide
{ # Tests 14 to 17: Creation of driver, model and parser + Target name recovery

    # basic model creation
    my $infile = file('test', 'aligned-nuc.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);
    ok my $model = $tmp_class->new(
        seqs => $ali,
        model_args => { '--plaplace' => undef }
    ), "$tmp_class constructor";

    cmp_ok $model->model->cksum, 'eq', '3750044850',
        'got expected model checksum';

    # build target sequence file
    my $target = Bio::MUST::Core::Ali::Temporary->new(
        seqs => $ali, args => { degap => 1 }
    );

    # standard output search
    my $std_parser = $model->search($target);
    ok $std_parser, 'got standard HMM parser';

    my @target_reports = $std_parser->get_iteration(0)->all_targets;
    my $got_targets = [ map {
        Bio::MUST::Core::SeqId->new(
            full_id => $target->long_id_for( $_->name ) )->foreign_id
    } @target_reports ];
    $std_parser->remove;

    my $std_exp_file_output = file('test', 'aligned-nuc_notextw.out');
    my $std_exp_output = Bio::FastParsers::Hmmer::Standard->new(
        file => $std_exp_file_output
    );

    my $exp_targets = [
        map { $_->name } $std_exp_output->get_iteration(0)->all_targets
    ];

    cmp_deeply $got_targets, $exp_targets,
        'got expected target list for standard report';

# Tests 18 and 19: Table parser from hmmsearch

    # tabular output search
    my $tbl_parser = $model->search( $target, { '--tblout' => undef } );
    ok $tbl_parser, 'got tabular HMM parser';

    my @tbl_got_names;
    while ( my $hit = $tbl_parser->next_hit ) {
        push @tbl_got_names, Bio::MUST::Core::SeqId->new(
            full_id => $target->long_id_for( $hit->target_name )
        )->foreign_id;
    }
    $tbl_parser->remove;

    my $tbl_exp_file_output = file('test', 'aligned-nuc_table.out');
    my $tbl_exp_output = Bio::FastParsers::Hmmer::Table->new(
        file => $tbl_exp_file_output
    );

    my @tbl_exp_names;
    while ( my $hit = $tbl_exp_output->next_hit ) {
        push @tbl_exp_names, $hit->target_name;
    }

    cmp_deeply \@tbl_got_names, \@tbl_exp_names,
        'got expected target list for tabular report';

# Tests 20 and 23: DomTable parser from hmmsearch

    # DomTable output search
    my $domtbl_parser = $model->search( $target, { '--domtblout' => undef } );
    ok $domtbl_parser, 'got domain table HMM parser';

    my @domtbl_got_names;
    while ( my $hit = $domtbl_parser->next_hit ) {
        push @domtbl_got_names, Bio::MUST::Core::SeqId->new(
            full_id => $target->long_id_for( $hit->target_name )
        )->foreign_id;
    }
    $domtbl_parser->remove;

    my $domtbl_exp_file_output = file('test', 'aligned-nuc_domtable.out');
    my $domtbl_exp_output = Bio::FastParsers::Hmmer::DomTable->new(
        file => $domtbl_exp_file_output
    );

    my @domtbl_exp_names;
    while ( my $hit = $domtbl_exp_output->next_hit ) {
        push @domtbl_exp_names, $hit->target_name;
    }

    cmp_deeply \@domtbl_got_names, \@domtbl_exp_names,
        'got expected target list for domain table report';

    my $filename = $model->filename;
    $model->remove;
    ok(!-e $filename, 'Ali::Temporary file got deleted as expected!');

    my $model_filename = $model->model->filename;
    $model->model->remove;
    ok(!-e $model_filename, 'Model::Temporary file got deleted as expected!');
}

# empty
{ # Tests 24 and 25: Check if returning undefined object with empty ali
    my $infile = file('test', 'empty.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);
    ok my $model = $tmp_class->new(
        seqs => $ali,
        model_args => { '--plaplace' => undef }
    ), "$tmp_class constructor";

    ok(!$model->model, 'got undefined model from empty file as expected' );
}

# emit
{ # Tests 26 to 29: Emit method, use of consensus
    my $infile = file('test', 'aligned.ali');
    my $ali = Bio::MUST::Core::Ali->load($infile);
    ok my $model = $tmp_class->new(
        seqs => $ali,
        model_args => { '--plaplace' => undef }
    ), "$tmp_class constructor";

    ok my $consensus = $model->emit, 'got consensus from hmmemit';
    isa_ok $consensus, 'Bio::MUST::Core::Ali::Stash';

    my $expected_consensus_seq = 'VVLAAEAEAARSIKSQKKDVNKIYPAHPSLFGRGVPRPADKLRAHDFAEDKVNLVVKEIGKNAAEGAALARVAGLGEALARLPLATRVLNGGICANKYDTGLLGKLGFAERIRLPALNVKKLVSLCKKKASCYGTTTISRRKKPAGEKATAIELARRARFKFHKRLKLPASPKGFKVKASSKKGPLKAANVAYLG';
    cmp_ok $consensus->get_seq(0)->seq, 'eq', $expected_consensus_seq,
        'got expected consensus seq from hmmemit';
}

{ # Tests 30: hmmscan
    my $db = $db_class->new( file => file('test', 'generic_domains.hmm') );
    my $target = file('test', 'test.faa');
    my $domtbl_parser = $db->scan($target);
    ok $domtbl_parser, 'got domain table HMM parser on model database';
    $domtbl_parser->remove;
}

done_testing;
