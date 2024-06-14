#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl
use strict;
use warnings;
use v5.36;
use Alien::SeqAlignment::edlib;
use BioX::Seq;
use Bio::SeqAlignment::Components::Sundry::IOHelpers
  qw(read_fastx_sequences write_fastx_sequences );
use Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearGeneric;
use Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic;
use Bio::SeqAlignment::Components::Libraries::edlib::OpenMP qw(make_C_index);
use Bio::SeqAlignment::Components::Sundry::IOHelpers qw(read_fastx_sequences);
use Compress::LZF                                    ();
use Carp;
use Cwd;
use Data::MessagePack;
use English;
use File::Basename;
use File::Spec;
use List::MoreUtils qw(mesh);
use MCE;
use Moose::Util qw( apply_all_roles );
use OpenMP::Environment;
use Time::HiRes qw(time);

###############################################################################
my $openmp_env = OpenMP::Environment->new;
$openmp_env->omp_num_threads(1); ## at least one thread for systems w/o OMP env
###############################################################################
my $cwd         = getcwd;
my $db_location = File::Spec->catfile( $cwd, 'db' );
my @dbfiles     = map { File::Spec->catfile( $db_location, $_ ) } (
    'Homo_sapiens.GRCh38.cds.sample.strip.fasta',
    'Homo_sapiens.GRCh38.sample.end.strip.fasta'
);

my $mapper = Bio::SeqAlignment::Components::SeqMapping::Mapper::Generic->new(
    create_refDB       => \&create_db,
    use_refDB          => \&use_refDB,
    init_sim_search    => \&init_sim_search,
    seq_align          => \&seq_align,
    extract_sim_metric => \&extract_sim_metric,
    reduce_sim_metric  => \&reduce_sim_metric
);
## linear generic data flow & provide a the conversion methods w/o polluting
## the script name space
apply_all_roles( $mapper,
    'Bio::SeqAlignment::Components::SeqMapping::Dataflow::LinearGeneric' );

$mapper->create_refDB->( $db_location, 'Hsapiens.cds.sample', \@dbfiles );
my $ref_DB = $mapper->use_refDB->( $db_location, 'Hsapiens.cds.sample' );
$mapper->init_sim_search->();

## get some timings, can vary chunk_size
my @workers     = (1..72);
my @threads = (1..72);


my @combinations;
for my $worker (@workers) {
    for my $thread_num (@threads) {
        push @combinations, [ $worker, $thread_num ];
    }
}

my @timings = map {
    my @mappings;
    my $max_workers = $_->[0];
    my $num_threads = $_->[1];
    print "Max workers: $max_workers, Num threads: $num_threads";
    $openmp_env->omp_num_threads($num_threads);
    $mapper->init_sim_search->();
    my $start_time  = time;
    for my $seqfile (@dbfiles) {
        my $seqdata = read_fastx_sequences($seqfile);
        my $results = $mapper->sim_seq_search(
            $seqdata,
            max_workers => $max_workers,
            chunk_size  => 1
        );
        push @mappings, $results->@*;
    }
    my $end_time       = time;
    my $execution_time = $end_time - $start_time;
    say ", took ", sprintf("%.2f seconds", $execution_time);
    [ $max_workers, $execution_time, $num_threads ]
} @combinations;


## save the timings
{
    local $LIST_SEPARATOR = "\t";
    my @headings = qw(Workers Time Num_threads);
    open my $fh, '>', File::Spec->catfile( $cwd, "timings_openMP.txt" );
    say {$fh} "@headings";
    say {$fh} "@$_" for @timings;
    close $fh;
}


###############################################################################

sub init_sim_search {
    my ( $self, $params ) = @_;
    ## import symbols into the namespace of the mapper
    require Bio::SeqAlignment::Components::Libraries::edlib::OpenMP;
    Bio::SeqAlignment::Components::Libraries::edlib::OpenMP->import(':all');

 
    my $configuration =
      configure_edlib_aligner( $self->sim_search_params-> %*);
    $self->sim_search_params( $configuration->{align_config} );
    $self->refDB_access_params(
        { edlib_config => $configuration->{edlib_config} } );
    fork_around_find_out();
}


## index of information in the array returned by the C code
use constant MIN_REFSEQ_INDEX        => 0;
use constant BEST_REFSEQ_MATCH_SCORE => 1;

sub seq_align {
    my ( $self, $query ) = @_;
    my $db_in_use       = $self->refDB_access_params->{DB};
    my $ref_seqs        = $db_in_use->{DATA};
    my $ref_seq_lengths = $db_in_use->{SEQLEN};
    my $query_length    = length $query->seq;
    my $query_seq       = $query->seq;
    my $edlib_config    = $self->refDB_access_params->{edlib_config};
    #say "Query length: $query_length";
    my $align =
      edlibAlign( $query_seq, $query_length, $db_in_use->{C_INDEX},
        $edlib_config );
   my $best_match_seqid =
      $db_in_use->{INDEX}{INDEX_SEQ_INDEX}{ $align->[MIN_REFSEQ_INDEX] };
    [ 
       [ $query->id, $best_match_seqid, $align->[BEST_REFSEQ_MATCH_SCORE] ] 
        ];
}

## in this case the database stores the sequence one at a line!
sub create_db {
    my ( $self, $dbloc, $dbname, $files_aref ) = @_;
    my $seq_num        = 0;
    my %sequence_index = (
        DBNAME          => $dbname,
        CREATED_ON      => scalar localtime,
        NUM_OF_SEQS     => 0,
        INDEX_SEQ_INDEX => {},
        SEQ_POS_INDEX   => {},
    );
    my $DB_fname = File::Spec->catfile( $dbloc, "${dbname}.txt" );
    open my $fh, '>', $DB_fname
      or croak "Could not create '$dbname' at location '$dbloc': $!\n";
    for my $file (@$files_aref) {
        my $bioseq_objects = read_fastx_sequences($file);
        for my $seq (@$bioseq_objects) {
            my $seq_id = $seq->id;
            my $index  = $seq_num;
            say {$fh} $seq->seq;
            $sequence_index{INDEX_SEQ_INDEX}{$index} = $seq_id;
            $sequence_index{SEQ_POS_INDEX}{$seq_id}  = $index;
            $seq_num++;
        }
    }
    close $fh;
    $sequence_index{NUM_OF_SEQS} = $seq_num;

    ## create the index file, pack, compress and store the index
    my $db_index_fname =
      File::Spec->catfile( $dbloc, "${dbname}_index_txt.msgpack" );
    my $msgpack         = Data::MessagePack->new;
    my $packed_data     = $msgpack->pack( \%sequence_index );
    my $compressed_data = Compress::LZF::compress($packed_data);
    open $fh, '>:raw', $db_index_fname;
    print {$fh} $compressed_data;
    close $fh;
}

sub use_refDB {
    my $self = shift;
    unless (@_) {
        croak "No arguments provided to 'use_refDB'\n";
    }
    my ( $db_loc, $dbname ) = @_;
    unless ( -d $db_loc ) {
        croak "The database location '$db_loc' does not exist\n";
    }
    my $seqDB_regex = qr/${dbname}.*\.txt$/;
    my $idx_regex   = qr/${dbname}_index_txt.msgpack$/;
    opendir my $dh, $db_loc
      or croak "Could not open directory '$db_loc' for reading: $!\n";
    my @files = readdir $dh;
    closedir $dh;
    my @matching_files = grep { /$seqDB_regex/ } @files;    ## seqfiles
    unless (@matching_files) {
        croak "No sequence files found for database '$dbname' "
          . "at directory '$db_loc'\n";
    }
    ## get the index into memory
    my @index_fname = grep { /$idx_regex/ } @files;
    unless (@index_fname) {
        croak "The index file for database '$dbname' does not exist "
          . "at directory '$db_loc'\n";
    }
    open my $fh, '<', File::Spec->catfile( $db_loc, $index_fname[0] );
    binmode $fh;
    my $compressed_data = '';
    {
        local $/;
        $compressed_data = <$fh>;
    }
    my $uncompressed_data = Compress::LZF::decompress($compressed_data);
    my $mp                = Data::MessagePack->new();
    my $index_data        = $mp->unpack($uncompressed_data);

    ## load sequence data as an array in memory
    my $seqDB_fname = File::Spec->catfile( $db_loc, $matching_files[0] );
    open $fh, '<', $seqDB_fname;
    my @seqDB = <$fh>;
    chomp @seqDB;
    close $fh;

    ## return a hash of the index, sequence length and tthe C index
    my $ref_DB = {
        INDEX   => $index_data,
        DATA    => \@seqDB,
        SEQLEN  => [ map { length($_) } @seqDB ],
        DBLOC   => $db_loc,
        C_INDEX => make_C_index( \@seqDB )
    };
    $self->{refDB_access_params}->{DB} = $ref_DB;
    return $ref_DB;
}