#!perl #-T 

BEGIN{
    use lib 't';
    use BioGrepSkip;
    use Test::NoWarnings;
    use Test::More; 
    my ($skip,$msg) = BioGrepSkip::skip_all();
    plan skip_all => $msg if $skip;
}

use BioGrepTest;
plan tests => 9;


my $backendname  = 'Vmatch';
# make taint happy    
BioGrepSkip::set_path( qw(vmatch guugle agrep) );
delete_files;

SKIP:{

    skip 'Vmatch binary not in path', 3 if
        BioGrepSkip::find_binary_in_path( lc($backendname) ) eq '';

    delete_files;

my $code =<<'EOT'
  use Bio::Grep;
  
  my $sbe = Bio::Grep->new('Vmatch');	
  
  # define the location of the suffix arrays
  $sbe->settings->datapath('data');
  
  mkdir($sbe->settings->datapath);	
  
  # now generate a suffix array. you have to do this only once.
  $sbe->generate_database({
     file => 't/ATH1.cdna',
     description => 'AGI Transcripts',
  });
  
  # search in this suffix array
  $sbe->settings->database('ATH1.cdna');
  
  # search for the reverse complement and allow 2 mismatches
  $sbe->settings->query('UGAACAGAAAG');
  $sbe->settings->reverse_complement(1);
  $sbe->settings->mismatches(2);

  # or you can use Fasta file with queries
  # $sbe->settings->query_file('Oligos.fasta');

  # $sbe->search();

  # Alternatively, you can specify the settings in the search call.
  # This also resets everything except the paths and the database
  # (because it is likely that they don't change when search is called
  # multiple times)

  $sbe->search( { query  =>  'AGAGCCCT',
                  reverse_complement => 1,
                  mismatches         => 1,
                 });  
  
  my @ids;

  # output some informations! 
  while ( my $res = $sbe->next_res ) {
     print $res->sequence->id . "\n";
     print $res->alignment_string() . "\n\n";
     push @ids, $res->sequence_id;
  }
  
  # get the gene sequences of all matches as Bio::SeqIO object.
  # (to generate a Fasta file for example)
  my $seqio = $sbe->get_sequences(\@ids);

EOT
;

    ok(!code_eval($code),"SYNOPSIS compiles") || diag $@;

    delete_files;
$code =<<'EOT'
  use Bio::Grep;
  
  my $sbe = Bio::Grep->new('Vmatch');
  
  # generate a Vmatch suffix array. you have to do this only once.
  $sbe->generate_database({ 
    file          => 't/Test_DB_RevCom.fasta', 
    description   => 'AGI Transcripts',
    datapath      => 'data',
    prefix_length => 3,
  });
 
  # search for the reverse complement and allow 4 mismatches
  # parse the description (max. 100 chars) directly out of the
  # Vmatch output instead of calling vsubseqselect for every
  # search result

  $sbe->search({
    query   => 'UGAACAGAAAGCUCAUGAGCC',
    reverse_complement => 1,
    mismatches         => 4,
    showdesc           => 100,
    database           => 'ATH1.cdna',
  });

  # output the searchresults with nice alignments
  while ( my $res = $sbe->next_res ) {
     print $res->sequence->id . "\n";
     print $res->mark_subject_uppercase() . "\n";
     print $res->alignment_string() . "\n\n";

     # sequence_id now contains the gene id (e.g. At1g1234),
     # not the Vmatch internal id 
     # To retrieve the complete sequences, one has to
     # call get_sequences for every gene id
     my $seq_io = $sbe->get_sequences([$res->sequence_id]);
     my $sequence = $seq_io->next_seq;
  }
  
  # for retrieving up- and downstream regions,
  # Vmatch internal sequence ids are required
  # (no showdesc possible)

  $sbe->search({
    query   => 'AGAGCCCT',
    reverse_complement => 1,
    mismatches         => 1,
    upstream           => 30,
    downstream         => 30,
  });
 
  my @internal_ids;
  while ( my $res = $sbe->next_res ) {
    # vsubseqselect is called now for every result ...
    push @internal_ids, $res->sequence_id;
  }

  # ... but one can retrieve all complete sequences with
  # just one call of vseqselect
  my $seq_io = $sbe->get_sequences(\@internal_ids);

EOT
;
    eval $code;
    ok(!code_eval($code),"Vmatch SYNOPSIS compiles") || diag $@;


$code =<<'EOT'
  use Bio::Grep;
  use Bio::SeqIO;
 
  my $sbe = Bio::Grep->new('Vmatch');
 
  my $out = Bio::SeqIO->new( -format => 'Fasta',
                             -file   => '>motifs.fasta',
                           );
 
  # you have an array with DNA sequences
  my @motifs = ( 'aaaaaa', 'gggggg' );
  
  for my $i (0 .. $#motifs ) {
     my $seq = Bio::Seq->new(
             -id => $i,
             -seq => $motifs[$i],
         );
     $out->write_seq($seq);
  }
 
  $sbe->search({
     datapath   => 't/data',
     database   => 'ATH1.cdna',
     query_file => 'motifs.fasta',
     complete   => 1,
  });

EOT
;
    ok(!code_eval($code),"Cookbook recipe motifs solution a compiles") || diag $@;

    unlink 'motifs.fasta';
}

# Agrep
$backendname  = 'Agrep';

SKIP:{

    skip 'Agrep binary not in path', 1 if
        BioGrepSkip::find_binary_in_path( lc($backendname) ) eq '';

    delete_files;
    mkdir 't/data';

my $code =<<'EOT'
  use Bio::Grep;
  
  my $sbe = Bio::Grep->new('Agrep');
  
  # generate a database. you have to do this only once. 
  $sbe->generate_database({ 
    file        => 't/Test_DB_RevCom.fasta', 
    description => 'AGI Transcripts',
    datapath    => 'data',
  });
  
  # search for the reverse complement and allow 2 mismatches 
  # Don't calculate Alignments with EMBOSS
  $sbe->search({
    query   => 'GAGCCCTT',
    reverse_complement => 1, 
    mismatches         => 2,
    no_alignments      => 1,
    database           => 'ATH1.cdna',
  });
  
  my @internal_ids;
  
  # output the searchresults with nice alignments
  while ( my $res = $sbe->next_res) {
     print $res->sequence->id . "\n";
     # print $res->alignment_string() . "\n\n";
     push @internal_ids, $res->sequence_id;
  }
  
  # get the complete sequences as Bio::SeqIO object
  my $seq_io = $sbe->get_sequences(\@internal_ids);


EOT
;
    ok(!code_eval($code),"Agrep SYNOPSIS compiles") || diag $@;
}
    

# GUUGle
$backendname  = 'GUUGle';

SKIP:{

    skip 'GUUGle binary not in path', 1 if
        BioGrepSkip::find_binary_in_path( lc($backendname) ) eq '';
    
     delete_files;
    mkdir 't/data';

my $code =<<'EOT'

  use Bio::Grep;
  
  my $sbe = Bio::Grep->new('GUUGle');
  
  # generate a GUUGle Bio::Grep database. you have to do this only once.
  # GUUGle does not create a persistent index right now.
  # This function generates an fast index for $sbe->get_sequences
  # and files with a description and the alphabet (only DNA/RNA allowed)
  $sbe->generate_database({ 
    file        => 't/Test_DB_RevCom.fasta', 
    description => 'AGI Transcripts',
    datapath    => 'data',
  });
 
  # search on both strands (GU allowed) 
  # retrieve up- and downstream regions of size 30
  $sbe->search({
    query   => 'GAGCCCTT',
    direct_and_rev_com => 1, 
    upstream           => 30,
    downstream         => 30,
    gumismatches       => 0,
    database           => 'ATH1.cdna',
  });

  my @internal_ids;

  # output all informations we have!
  while ( my $res = $sbe->next_res ) {
     print $res->sequence->id . "\n";
     print $res->mark_subject_uppercase() . "\n";
     print $res->alignment_string() . "\n\n";
     push @internal_ids, $res->sequence_id;
  }
  
  # get the complete sequences as Bio::SeqIO object
  my $seq_io = $sbe->get_sequences(\@internal_ids);
  
  # search for targets (GU allowed)
  $sbe->search({
    query   => 'GAGCCCTTGGGGGGG',
    reverse_complement => 1, 
    gumismatches       => 0,
  });

EOT
;
    ok(!code_eval($code),"GUUGle SYNOPSIS compiles") || diag $@;
}
    
# RE
delete_files;
mkdir 't/data';

my $code =<<'EOT'

  use Bio::Grep;
  
  my $sbe = Bio::Grep->new('RE');
  
  $sbe->settings->datapath('data');
  
  # generate a database. you have to do this only once. 
  $sbe->generate_database({ 
    file        => 't/Test_DB_RevCom.fasta', 
    description => 'AGI Transcripts',
    datapath    => 'data',
  });
  
  # search on both strands  
  # retrieve up- and downstream regions of size 30
  
  $sbe->search({
    query   => 'GAGCCCTT',
    direct_and_rev_com => 1, 
    upstream           => 30,
    downstream         => 30,
    database           => 'ATH1.cdna',
  });
  
  my @internal_ids;
  
  # output the searchresults with nice alignments
  while ( my $res = $sbe->next_res) {
     print $res->sequence->id . "\n";
     print $res->mark_subject_uppercase() . "\n";
     print $res->alignment_string() . "\n\n";
     push @internal_ids, $res->sequence_id;
  }
  
  # get the complete sequences as Bio::SeqIO object
  my $seq_io = $sbe->get_sequences(\@internal_ids);

  # sequences with at least 10 As
  $sbe->search({ query => '[A]{10,}' });
 
  # some SNPs
  $sbe->search({query => '[CG]TGC[AT]CTCTTCT[CG]TCA'});

EOT
;
ok(!code_eval($code),"RE SYNOPSIS compiles") || diag $@;

$code =<<'EOT'
  use Bio::Grep;
 
  my $sbe = Bio::Grep->new('RE');
 
  my $motif = '[AC]{4}TAAAA[AGCT]GG';
 
  $sbe->search({
     datapath  => 't/data',
     database  => 'Test_DB_RevCom.fasta',
     query      => $motif,
  });
EOT
;
eval $code;
ok(!$@,"Cookbook recipe motifs solution b compiles") || diag $@;

$code = 'bllll';
eval $code;
ok(code_eval($code),"bllll not compiles");

delete_files;
rmdir('t/tmp');
rmdir('t/data');
rmdir('t/data2');

sub code_eval {
    my ( $code ) = @_;
    $code =~ s/ATH1.cdna/Test_DB_RevCom.fasta/g;
    $code =~ s{'data'}{'t/data'}g;
    $code =~ s{generate_database\('T}{generate_database('t/T}g;
#    diag $code;
    eval $code;
    return $@;
}    
1;

# vim: ft=perl sw=4 ts=4 expandtab
