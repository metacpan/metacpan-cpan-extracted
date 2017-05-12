#############################################################################
#   $Author: markus $
#     $Date: 2009-11-12 19:54:03 +0100 (Thu, 12 Nov 2009) $
# $Revision: 1848 $
#############################################################################

package Bio::Grep::Backend::BackendI;

use strict;
use warnings;

use Carp::Assert;
use version; our $VERSION = qv('0.10.6');

use English qw( -no_match_vars );
use autodie qw (open close opendir closedir);

use File::Spec;
use File::Copy;
use File::Temp qw/ tempfile tempdir /;
use File::Basename;

use Scalar::Util qw(reftype);
use Cwd 'abs_path';
use IPC::Open3 'open3';
use Readonly;

use Bio::AlignIO;
use Bio::Factory::EMBOSS;
use Bio::Index::Fasta;
use Bio::Seq;
use Bio::SeqIO;

use Bio::Grep::SearchSettings;
use Bio::Grep::Root;

use UNIVERSAL qw(isa);

use base 'Bio::Grep::Root';

use Class::MethodMaker [
    new    => 'new2',
    scalar => [qw / settings _output_fh _output_fn _current_res_id _tmp_var/],
    array  => [qw / _query_seqs _results/],
    hash   => [qw / features/],
    abstract => [
        qw / search get_sequences get_databases
            generate_database _parse_next_res/
    ],
];

Readonly my $DNA_ALPHABET_SIZE => 5;

sub new {
    my $self = shift->new2;

    # initialize standard settings
    my $settings = Bio::Grep::SearchSettings->new();

    $self->settings($settings);

    # assume back-end binary is in path
    $self->settings->execpath(q{});

    $self->features( %{ $self->_get_all_possible_features() } );
    $self->import;
    return $self;
}

sub _get_all_possible_features {
    my ($self) = @_;
    return {
        MISMATCHES         => 1,
        GUMISMATCHES       => 1,
        EDITDISTANCE       => 1,
        INSERTIONS         => 1,
        DELETIONS          => 1,
        FILTERS            => 1,
        NATIVE_ALIGNMENTS  => 1,
        EVALUE             => 1,
        PERCENT_IDENTITY   => 1,
        PROTEINS           => 1,
        ONLINE             => 1,
        UPSTREAM           => 1,
        DOWNSTREAM         => 1,
        SORT               => 1,
        MAXHITS            => 1,
        COMPLETE           => 1,
        QUERY              => 1,
        QUERY_FILE         => 1,
        QUERY_LENGTH       => 1,
        SHOWDESC           => 1,
        QSPEEDUP           => 1,
        HXDROP             => 1,
        EXDROP             => 1,
        REGEX              => 1,
        REVCOM_DEFAULT     => 1,
        DIRECT_AND_REV_COM => 1,
        NATIVE_D_A_REV_COM => 1,    # backend supports searching for
                                    # direct and revcom matches or
                                    # do we have to emulate it?
    };
}

sub _get_databases {
    my ( $self, $suffix ) = @_;
    my %result = ();
    opendir my $DIR, $self->settings->datapath;
    my @files = grep {/${suffix} \z/xms} readdir $DIR;
    closedir $DIR;
FILE:
    foreach my $file (@files) {
        my $prefix = $file;
        $prefix =~ s/$suffix//xms;
        $result{$prefix} = $prefix;
        $file =~ s/$suffix/\.nfo/xms;
        $file = $self->_cat_path_filename( $self->settings->datapath, $file );
        next FILE if !-e $file;
        open my $FILE, '<', $file;
        my $desc = q{};

        while ( my $line = <$FILE> ) {
            chomp $line;
            $desc .= $line;
        }
        $result{$prefix} = $desc;
        close $FILE;
    }
    return %result;
}

sub _filter_result {
    my ( $self, $res ) = @_;
    if ( $self->settings->filters_isset ) {
        foreach my $filter ( @{ $self->settings->filters } ) {
            $filter->message_reset;

            #$res->_real_query( $self->settings->_real_query );
            $filter->search_result($res);
            if ( !$filter->filter ) {
                if ( $filter->delete ) {
                    return 0;
                }
            }
            if ( $filter->message_isset ) {
                $res->remark( $filter->message );
            }
        }
    }
    return $res;
}

sub results {
    my ($self) = @_;
    $self->deprecated(q{Use 'next_res()' instead.});
    my @results;
    while ( my $res = $self->next_res ) {
        push @results, $res;
    }
    return wantarray ? @results : \@results;
}

sub _prepare_results {
    my ($self) = @_;

    # sorting by dG is a Bio::Grep sortmode,  not a back-end sortmode. so we
    # have to load the results in memory and sort them.
    # next_res() will then shift the next result in _results() (see
    # next_res())
    if ( $self->settings->sort_isset
        && substr( $self->settings->sort, 0, 1 ) eq 'g' )
    {
        my @results;
        while ( my $res = $self->next_res ) {
            push @results, $res;
        }
        @results = $self->_sort_by_dg(@results);
        $self->_results(@results);

        # reset for next_res iterator
        $self->_current_res_id(0);
    }
    else {
        $self->_results_reset;
    }
    return;
}

sub next_res {
    my ($self) = @_;
    my $id = $self->_current_res_id;
    $self->_current_res_id( $id + 1 );
    if ( $self->_results_isset ) {
        if ( $id >= scalar @{ $self->_results } ) {
            return 0;
        }
        else {
            return $self->_results->[$id];
        }
    }
    else {
        return $self->_parse_next_res();
    }
}

sub _sort_by_dg {
    my ( $self, @results ) = @_;
    foreach my $result (@results) {
        if ( !$result->dG_isset ) {
            $self->warn(
                'Not sorting results by dG because some results have no '
                    . 'dG calculated. Use Bio::Grep::RNA.' );
            return @results;
        }
    }
    if ( $self->settings->sort eq 'gd' ) {
        @results = reverse sort { $a->dG <=> $b->dG } @results;
    }
    else {
        @results = sort { $a->dG <=> $b->dG } @results;
    }
    return @results;
}

sub _results_may_have_gaps {
    my ($self) = @_;
    my $s = $self->settings;
    return 1 if ( defined $s->editdistance && $s->editdistance > 0 );
    return 1 if ( defined $s->insertions   && $s->insertions > 0 );
    return 1 if ( defined $s->deletions    && $s->deletions > 0 );
    return 0;
}

# calculates needleman-wunsch global alignment with the EMBOSS
# implementation
sub _get_alignment {
    my ( $self, $seq_a, $seq_b ) = @_;

    # aligments are easy when settings don't allow gaps
    # back-ends must return hit coordinates
    if ( !$self->_results_may_have_gaps
        && length $seq_a->seq == length $seq_b->seq )
    {
        my $alignment = Bio::SimpleAlign->new( -source => 'Bio::Grep' );
        $alignment->add_seq($seq_a);
        $alignment->add_seq($seq_b);
        return $alignment;
    }

    my $factory = Bio::Factory::EMBOSS->new();
    my $prog    = $factory->program('needle');
    my $outfile = $self->_cat_path_filename( $self->settings->tmppath,
        $seq_a->id . '.out' );
    my $gapopen = '5.0';
    if ( !$self->settings->editdistance_isset ) {
        $gapopen = '50.0';
    }

    $prog->run(
        {   -asequence => $seq_a,
            -bsequence => $seq_b,
            -gapopen   => $gapopen,
            -gapextend => '5.0',
            -outfile   => $outfile
        }
    );

    if ( -e $outfile ) {
        my $alignio_fmt = 'emboss';
        my $align_io    = Bio::AlignIO->new(
            -format => $alignio_fmt,
            -file   => $outfile
        );
        unlink $outfile;
        my $alignment = $align_io->next_aln();
        my $s1        = $alignment->get_seq_by_pos(1);
        my $s2        = $alignment->get_seq_by_pos(2);
        $s1->start( $seq_a->start );
        $s1->end( $seq_a->end );
        $alignment = Bio::SimpleAlign->new( -source => 'Bio::Grep' );
        $alignment->add_seq($s1);
        $alignment->add_seq($s2);
        return $alignment;
    }

}

# concatenates a path and a filename platform-independently
sub _cat_path_filename {
    my ( $self, $path, $filename ) = @_;
    if ( $path eq q{} ) {
        return $filename;
    }
    else {
        return File::Spec->catfile( $path, $filename );
    }
}

sub _check_search_settings {
    my ( $self, $arg_ref ) = @_;

    if ( defined $arg_ref ) {
        $self->settings->set_attributes($arg_ref);
    }
    if ( !defined $self->settings->upstream ) {
        $self->settings->upstream(0);
    }
    if ( !defined $self->settings->downstream ) {
        $self->settings->downstream(0);
    }

    $self->_check_int_features();
    $self->_check_sort_mode();
    $self->_check_database();
    $self->_check_for_unsupported_features();

    if (   defined $self->settings->editdistance
        && defined $self->settings->mismatches
        && $self->settings->editdistance > 0
        && $self->settings->mismatches > 0 )
    {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => q{Can't combine editdistance and mismatches.},
            -value => $self->settings->editdistance . ' and '
                . $self->settings->mismatches,
        );
    }
    if ( $ENV{BIOGREPDEBUG} ) {
        carp $self->settings->to_string();
    }

    # reset all filters
    if ( $self->settings->filters_isset ) {
        foreach my $filter ( @{ $self->settings->filters } ) {
            $filter->reset_filter;
        }
    }
    $self->_results_reset;
    $self->_current_res_id(0);
    return;
}

### SOME IMPORTANT SETTINGS TESTS
### called by _check_search_settings()

sub _check_int_features {
    my ($self) = @_;

    my @int_features
        = map { lc $_ } keys %{ $self->_get_all_possible_features() },
        'reverse_complement', 'no_alignments';

    my %skip = (
        FILTERS            => 1,    # checked later
        NATIVE_ALIGNMENTS  => 1,
        NATIVE_D_A_REV_COM => 1,
        PERCENT_IDENTITY   => 1,    # no user setting
        PROTEINS           => 1,    # no user setting
        SORT               => 1,    # checked later
        QUERY_FILE         => 1,    # checked later
        QUERY              => 1,    # checked later
        EVALUE             => 1,    # no user setting
        REVCOM_DEFAULT     => 1,    # no user setting
        REGEX              => 1,    # no user setting
    );

INT_FEATURE:
    for my $option (@int_features) {
        next INT_FEATURE if defined $skip{ uc $option };

        # check if values are integers and untaint them
        $self->settings->$option(
            $self->is_integer( $self->settings->$option, $option ) );
        if ( !defined $self->settings->$option ) {
            my $reset = $option . '_reset';
            $self->settings->$reset;
        }
    }
    return 1;
}

sub _check_for_unsupported_features {
    my ($self) = @_;

    # some warnings if user requests features that are not available
    my %skip = (
        NATIVE_ALIGNMENTS  => 1,
        NATIVE_D_A_REV_COM => 1,
        PERCENT_IDENTITY   => 1,
        REVCOM_DEFAULT     => 1,
        PROTEINS           => 1,
        EVALUE             => 1,
        REGEX              => 1,    # no user setting
    );

FEATURE:
    for my $feature ( keys %{ $self->_get_all_possible_features() } ) {
        next FEATURE if defined $skip{$feature};
        my $value_ok = 0;
        if ( $feature eq 'GUMISMATCHES' ) {
            $value_ok = 1;
        }
        if ( !defined $self->features->{$feature} ) {
            my $lc_f = lc $feature;
            my $lc_i = $lc_f . '_isset';
            if (   $self->settings->$lc_i
                && $self->settings->$lc_f ne $value_ok )
            {
                $self->warn( $lc_f . ' not available in this back-end.' );
            }
        }
    }
    return;
}

sub _check_database {
    my ($self) = @_;

    if ( !$self->settings->datapath_isset ) {
        $self->settings->datapath(q{./});
    }

    # check if database is set and valid
    my $found_database = 0;
    if ( defined $self->settings->database ) {
        $self->settings->database(
            $self->is_word( $self->settings->database ) );
        my %available_dbs = $self->get_databases;
        if ( !defined $available_dbs{ $self->settings->database } ) {
            $self->throw(
                -class => 'Bio::Root::BadParameter',
                -text  => 'Database not found.',
                -value => $self->settings->database,
            );
        }
    }
    else {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Database not defined.',
        );
    }
    return 1;
}

sub _check_sort_mode {
    my ($self) = @_;

    if ( $self->settings->sort_isset ) {
        my %sort_modes = $self->available_sort_modes();
        if ( defined $sort_modes{ $self->settings->sort } ) {
            my ($sort_mode) = $self->settings->sort =~ /(\w+)/xms;
            $self->settings->sort($sort_mode);    #make taint happy
        }
        else {
            $self->throw(
                -class => 'Bio::Root::BadParameter',
                -text  => 'Sort mode not valid.',
                -value => 'sort mode'
            );
        }
    }
    return 1;
}

### END OF SETTINGS TESTS

# copies the specified fasta file in the data directory and cerate a file
# <databasename>.nfo with the description, specified in the optional 2nd
# argument
# changes directory! so please save the oldpath before calling this method
sub _copy_fasta_file_and_create_nfo {
    my ( $self, $args ) = @_;

    # throw exception if filename looks wrong
    $self->is_word( $args->{basefilename}, 'Fasta filename' );

    my $newfile = $self->_cat_path_filename( $self->settings->datapath,
        $args->{basefilename} );

    $args->{filename} = $newfile;

    my %dbs = $self->get_databases;

    if ( defined $dbs{ $args->{basefilename} } ) {
        $self->warn( "Database with that name already exists.\n"
                . 'Skipping database generation.' );
        $args->{skip} = 1;
        return;
    }

    if ( defined $args->{copy} && $args->{copy} ) {
        copy( $args->{file}, $newfile )
            or $self->throw(
            -class => 'Bio::Root::IOException',
            -text  => q{Can't copy } . $args->{file} . " to $newfile",
            -value => $OS_ERROR,
            );
    }
    else {
        my $abs_path = $self->is_path( abs_path( $args->{file} ) );
        symlink $abs_path, $newfile || $self->throw(
            -class => 'Bio::Root::IOException',
            -text  => q{Can't symlink } . $abs_path . " to $newfile",
            -value => $OS_ERROR,
        );
    }
    if ( defined $args->{description} ) {
        open my $NFOFILE, '>', $newfile . '.nfo';
        print ${NFOFILE} $args->{description}
            or $self->_cannot_print("$newfile.nfo");
        close $NFOFILE;
    }
    return;
}

sub _guess_alphabet_of_file {
    my ( $self, $filename ) = @_;
    my $in = Bio::SeqIO->new( -file => $filename );
    return $in->next_seq->alphabet;
}

sub _bioseq_query {
    my ($self) = @_;
    my $query_obj = $self->settings->query;
    my $query;

    if ( !defined $query_obj ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Query not defined.',
        );
    }
    my $db_alphabet
        = $self->get_alphabet_of_database( $self->settings->database );

    if ( eval { $query_obj->isa('Bio::Seq') } ) {
        $query = $query_obj->seq;
    }
    else {
        $query = $query_obj;
        if ( $query =~ m{\A \w+ \z}xms ) {
            if ( $db_alphabet eq 'dna' ) {
                $query =~ tr/uU/tT/;
            }
            $query_obj = Bio::Seq->new(
                -id   => '1',
                -desc => 'Query',
                -seq  => $query
            );
        }
        else {
            $query_obj = Bio::Seq->new( -id => '1', -desc => 'Query' );
        }
    }
    return ( $query, $query_obj, $db_alphabet );
}

# prepares the query, for example calculating the reverse complement
# if necessary
# returns the prepared query. settings->query is unchanged!
sub _prepare_query {
    my $self = shift;
    my ( $query, $seq, $db_alphabet ) = $self->_bioseq_query();

    if ( $seq->alphabet ne $db_alphabet ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Alphabet of query and database not equal',
            -value => 'Seq: ' . $seq->alphabet . ", DB: $db_alphabet"
        );
    }
    if (   $self->settings->reverse_complement
        || $self->settings->direct_and_rev_com )
    {
        if ( $db_alphabet eq 'dna' ) {
            if ( defined $self->features->{REVCOM_DEFAULT} ) {
                $seq->desc( $seq->desc . ' (reverse complement)' );
            }
            elsif ( defined $self->features->{NATIVE_D_A_REV_COM}
                && $self->settings->direct_and_rev_com )
            {
            }
            else {
                $query = $seq->revcom->seq;
                $seq->desc( $seq->desc . ' (reverse complement)' );
                $seq->seq($query);
            }
        }
        else {
            $self->throw(
                -class => 'Bio::Root::BadParameter',
                -text =>
                    'Reverse complement only available for DNA databases.',
            );
        }
    }
    elsif ( defined $self->features->{REVCOM_DEFAULT}
        && $db_alphabet eq 'dna' )
    {
        $query = $seq->revcom->seq;
        $seq->seq($query);
    }

    # $self->settings->_real_query( uc $query );
    $self->{_query_obj} = $seq;
    return uc $query;    # $self->settings->_real_query();
}

sub generate_database_out_of_fastafile {
    my ( $self, @args ) = @_;
    $self->deprecated( "generate_database_out_of_fastafile() is deprecated.\n"
            . q{Use generate_database() instead.} );
    return $self->generate_database(@args);
}

sub available_sort_modes {
    my ($self) = @_;
    return (
        ga => 'ascending order of dG',
        gd => 'descending order of dG',
    );
}

sub _get_sequences_from_bio_index {
    my ( $self, $seqid ) = @_;

    $self->is_arrayref_of_size( $seqid, 1 );
    my $indexfile = $self->settings->datapath . q{/}
        . $self->settings->database . '.idx';
    my $idx = Bio::Index::Fasta->new($indexfile);
    my $string;
    my $stringio = IO::String->new($string);
    my $out = Bio::SeqIO->new( -fh => $stringio, -format => 'Fasta' );
    foreach my $seqid ( @{$seqid} ) {
        $out->write_seq( $idx->fetch($seqid) );
    }
    $stringio = IO::String->new($string);
    return Bio::SeqIO->new( -fh => $stringio, -format => 'Fasta' );
}

sub get_alphabet_of_database {
    my ( $self, $db ) = @_;
    my %dbs = $self->get_databases();
    if ( !defined $dbs{$db} ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Database not found',
            -value => $db,
        );
    }
    $db = $self->is_word($db);

    open my $ALFILE, '<',
        $self->_cat_path_filename( $self->settings->datapath, $db . '.al1' );
    my $lines = 0;
    while ( my $line = <$ALFILE> ) {
        $lines++;
    }
    close $ALFILE;
    return $lines <= $DNA_ALPHABET_SIZE ? return 'dna' : return 'protein';
}

sub _delete_output {
    my ($self) = @_;
    return 0 if !defined $self->_output_fn;
    return 0 if !-e $self->_output_fn;
    unlink $self->_output_fn
        or $self->throw(
        -class => 'Bio::Root::IOException',
        -text  => q{Can't remove } . $self->_output_fn,
        -value => $OS_ERROR,
        );
    return 1;
}

sub _execute_command {
    my ( $self, $cmd ) = @_;
    $self->_delete_output();
    my ( $tmp_fh, $tmp_fn )
        = tempfile( 'parser_XXXXXXXXXXXX', DIR => $self->settings->tmppath );
    $self->_output_fh($tmp_fh);
    $self->_output_fn($tmp_fn);
    system "$cmd > $tmp_fn";

    return !$CHILD_ERROR;
}

sub _execute_command_and_return_output {
    my ( $self, $cmd ) = @_;
    my ( $writer, $reader, $err );
    my $pid = open3( $writer, $reader, $err, $cmd );
    waitpid $pid, 0;
    my $output = do { local $INPUT_RECORD_SEPARATOR = undef; <$reader> };

    #    my $error = join q{}, <$err>;
    return $output;
}

sub _create_index_and_alphabet_file {
    my ( $self, $filename ) = @_;
    my $in = Bio::SeqIO->new( -file => $filename, -format => 'Fasta' );
    my $alphabet = $in->next_seq()->alphabet();
    if ( !defined $self->features->{PROTEINS} && $alphabet eq 'protein' ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Back-end does not support protein data',
            -value => $alphabet,
        );
    }

    # create a vmatch alphabet file
    open my $ALFILE, '>', "$filename.al1";
    if ( $alphabet eq 'dna' ) {
        print ${ALFILE} "aA\ncC\ngG\ntTuU\nnsywrkvbdhmNSYWRKVBDHM\n"
            or $self->_cannot_print("$filename.al1");
    }
    else {
        print ${ALFILE}
            "L\nV\nI\nF\nK\nR\nE\nD\nA\nG\nS\nT\nN\nQ\nY\nW\nP\nH\nM\nC\nXUBZ*\n"
            or $self->_cannot_print("$filename.al1");
    }
    close $ALFILE;

    # create database from directory of fasta files
    my $idx = Bio::Index::Fasta->new(
        -filename   => $filename . '.idx',
        -write_flag => 1
    );
    $idx->make_index( ($filename) );

    return;
}

sub _create_tmp_query_file {
    my ($self)     = @_;
    my $s          = $self->settings;
    my $query_file = 0;
    my ( $tmp_fh, $tmp_query_file );
    if ( defined $s->query_file ) {
        $query_file = $self->is_path( $s->query_file );
    }
    if ( $s->query_isset && $s->query_file_isset ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Query and query_file are set. I am confused...',
            -value => $s->query . ' and ' . $s->query_file,
        );
    }
    my @query_seqs = ();

    my $query = q{};
    if ( !$query_file ) {
        $query = $self->_prepare_query();

        ( $tmp_fh, $tmp_query_file ) = tempfile(
            'spatter_XXXXXXXXXXXX',
            DIR    => $s->tmppath,
            UNLINK => !$ENV{BIOGREPDEBUG}
        );    # don't delete when in debug mode, so
              # we can reproduce it.

        # construct a temporary fasta file with the query for vmatch
        my $seqobj = $self->{_query_obj};

        my $outseqio = Bio::SeqIO->new(
            -fh     => $tmp_fh,
            -format => 'fasta'
        );
        $outseqio->write_seq($seqobj);

        push @query_seqs, $seqobj;
        if ( $s->direct_and_rev_com
            && !defined $self->features->{NATIVE_D_A_REV_COM} )
        {
            my $seqobj2 = $seqobj->revcom;
            if ( defined $self->features->{REVCOM_DEFAULT} ) {
                my ($desc)
                    = $seqobj->desc
                    =~ m{\A(.*) \s\(reverse\scomplement\) \z}xms;
                $seqobj2->desc($desc);
            }
            else {
                $seqobj2->desc( $seqobj->desc . ' (reverse complement)' );
            }
            $outseqio->write_seq($seqobj2);
            push @query_seqs, $seqobj2;
        }

    }
    else {
        $tmp_query_file = $query_file;
        my $query_in = Bio::SeqIO->new( -file => $tmp_query_file );
        while ( my $query_seq = $query_in->next_seq ) {
            push @query_seqs, $query_seq;
        }
    }
    $self->_query_seqs(@query_seqs);
    return ( $query, $query_file, $tmp_query_file );
}

sub _prepare_generate_database {
    my ( $self, @args ) = @_;
    my $reftype = reftype $args[0];
    my %args;
    if ( !defined $reftype ) {
        $self->deprecated(
                  'List argument for generate_database() is deprecated. '
                . 'Use hashref instead.' );
        %args = (
            format      => 'Fasta',
            file        => $args[0],
            description => $args[1],
            copy        => 0,
        );
    }
    elsif ( $reftype eq 'HASH' ) {
        %args = %{ $args[0] };
    }
    else {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'Invalid arguments. Hashref assumed.',
        );
    }

    if ( !-e $args{file} ) {
        $self->throw(
            -class => 'Bio::Root::BadParameter',
            -text  => 'No such file.',
            -value => $args{file},
        );
    }
    my ($filename) = fileparse( $args{file} );
    $args{basefilename} = $filename;

    if ( !defined $args{format} ) {
        $args{format} = 'Fasta';
    }
    if ( defined $args{prefix_length} ) {

        # untaint pl
        $args{prefix_length} = $self->is_integer( $args{prefix_length} );
    }
    if ( defined $args{datapath} ) {
        $self->settings->datapath( $args{datapath} );
    }
    if ( !defined $self->settings->datapath ) {
        $self->settings->datapath(q{./});
    }
    $self->_copy_fasta_file_and_create_nfo( \%args );

    return %args;
}

sub _parse_regions {
    my ( $self, $args ) = @_;
    my $upstream_seq = q{};
    my $subject_seq = substr $args->{complete_seq}, $args->{subject_begin},
        $args->{subject_end} - $args->{subject_begin};
    my $downstream_seq = q{};

    # initialized for assert below
    my $upstream_begin = $args->{subject_begin};

    if ( $self->settings->upstream > 0 || $self->settings->downstream > 0 ) {

        # coordinates of upstream region, check if available region is
        # as large as requested
        $upstream_begin = $args->{subject_begin} - $self->settings->upstream;
        if ( $upstream_begin < 0 ) {
            $upstream_begin = 0;
        }

        $upstream_seq = substr $args->{complete_seq}, $upstream_begin,
            $args->{subject_begin} - $upstream_begin;

        # and same for the downstream region
        my $downstream_end
            = $args->{subject_end} + $self->settings->downstream;

        if ( $downstream_end > length $args->{complete_seq} ) {
            $downstream_end = length $args->{complete_seq};
        }

        $downstream_seq = substr $args->{complete_seq}, $args->{subject_end},
            $downstream_end - $args->{subject_end};

    }
    my @ret = ( $upstream_seq, $subject_seq, $downstream_seq );
    assert(
        index( $args->{complete_seq}, join( q{}, @ret ), $upstream_begin )
            == $upstream_begin )
        if DEBUG;
    return @ret;
}

1;    # Magic true value required at end of module
__END__

=head1 NAME

Bio::Grep::Backend::BackendI - Superclass for all back-ends  

=head1 DESCRIPTION

B<Bio::Grep::Backend::BackendI> is the superclass for all back-ends. Don't 
use this class directly.

=head1 METHODS

See L<Bio::Grep::Root> for inherited methods.

=head2 CONSTRUCTOR

=over  

=item C<new()>

This method constructs a L<Bio::Grep::Backend::BackendI> object and is never 
used directly. Rather, all other back-ends in this package inherit the methods
of this interface and call its constructor internally.

=back

=head2 PACKAGE METHODS

=over  

=item C<$sbe-E<gt>next_res>

Returns next result as a L<Bio::Grep::SearchResult> object after search() was
called.

    $sbe->search();

    while ( my $res = $sbe->next_res ) {
        # output result
    }

          
=item C<$sbe-E<gt>settings()>

Get the settings. This is a L<Bio::Grep::SearchSettings> object

  # search for the reverse complement and allow 4 mismatches
  $sbe->settings->database('ATH1.cdna');
  $sbe->settings->query('UGAACAGAAAGCUCAUGAGCC');
  $sbe->settings->reverse_complement(1);
  $sbe->settings->mismatches(4);

=item C<$sbe-E<gt>features()>

Get available features. This is a hash. Valid features are
MISMATCHES, GUMISMATCHES, EDITDISTANCE, INSERTIONS, DELETIONS, 
FILTERS, NATIVE_ALIGNMENTS, PROTEINS, UPSTREAM, DOWNSTREAM, MAXHITS, COMPLETE,
QUERY, QUERY_FILE, QUERY_LENGTH, DIRECT_AND_REV_COM, SHOWDESC, QSPEEDUP, 
HXDROP, EXDROP, EVALUE and PERCENT_IDENTITY.

  if (defined($sbe->features->{GUMISMATCHES})) {
          # $sbe->settings->gumismatches(0);
          $sbe->settings->gumismatches(0.5);
  } else {
        print "\nBack-end does not support wobble pairs\n";
  }

=item C<$sbe-E<gt>get_alphabet_of_database($db)>

Returns 'dna' if the specified database is a DNA database, 'protein'
otherwise.

=back

=head2 ABSTRACT METHODS

Every back-end must implement these methods.

=over

=item C<$sbe-E<gt>search>

This method starts the back-end with the settings specified in the 
L<Bio::Grep::SearchSettings> object C<$sbe-E<gt>settings>.
 
    $sbe->search();

This method also accepts an hash reference with settings. In this case, all
previous defined options except all paths and the database are set to their
default values.

  $sbe->search({ mismatches => 2, 
                 reverse_complement => 0, 
                 query => $query });


=item C<$sbe-E<gt>generate_database({ file =E<gt> $file })>

Creates a symlink to the specified file in the datapath directory 
(C<$sbe-E<gt>settings-E<gt>datapath>) and generates a database. You have to
do this only once for every file. Returns 1 if database generation was
successful. 

Optional arguments in the hash reference are:

=over 2

=item C<format> 

The format of C<file>. Default is C<Fasta>. See the documentation of your
back-end and L<Bio::SeqIO> for supported formats. Only C<Fasta> is thoroughly
tested. 

=item C<description> 

The description of the database. Later, you can access these descriptions with
get_databases(). Default is the filename of C<file>.

=item C<copy>

Instead of adding a symlink to C<file> in the I<data> directory, copy the
file. Useful for platforms that don't support symbolic links. Default 0
(create a symlink).

=item C<datapath>

C<$sbe-E<gt>settings-E<gt>datapath> is called with this value.

=item C<prefix_length>

C<Vmatch> option: prefix length for bucket sort. If not defined, then
C<mkvtree> automatically determines a reasonable prefix length.

=item C<verbose>

Generate the database more verbosely. Default is 0.

=back

Example:

  $sbe->generate_database({
            file        => 'ATH1.cdna',
            format      => 'Fasta',
            description => 'AGI Transcripts',
            copy        => 1, 
            datapath    => 'data',
            verbose     => 1,
    });

=item C<$sbe-E<gt>get_databases>

Returns a hash with all available databases. The keys are the filenames,
the values are descriptions (or the filename if no description is available).

  my %local_dbs_description = $sbe->get_databases();
  my @local_dbs = sort keys %local_dbs_description;
  
  # take first available database 
  $sbe->settings->database($local_dbs[0]);

=item C<$sbe-E<gt>get_sequences>

This method returns all sequences with the ids in the specified array reference as
a L<Bio::SeqIO> object. 


   my $seqio = $sbe->get_sequences([$id]);
   my $string;  my $stringio = IO::String->new($string);
   my $out = Bio::SeqIO->new('-fh' => $stringio,
                             '-format' => 'fasta');

   while ( my $seq = $seqio->next_seq() ) {
      # write the sequences in a string
      $out->write_seq($seq);
   }
   print $string;
 

=item C<$sbe-E<gt>available_sort_modes()>

Returns a hash with the available result sort modes. Keys are the modes you
can set with C<$sbe-E<gt>settings-E<gt>sort($mode)>, values a short 
description.

=back

=head2 INTERNAL METHODS 

Only back-ends should call them directly. These internal methods are
documented for authors of new back-ends.

=over 

=item C<_check_search_settings> 

Performs some basic error checking. Important security checks, because
we use system(). So we should check, if we get what we assume.

Because every back-end should call this method at the top 
of its search method, we clean things like old search results here up.

=item C<_prepare_query>

Another important method that every back-end must call.
Prepares the query, for example calculating the reverse complement if
necessary, returns the prepared query. C<settings-E<gt>query> is unchanged!


=item C<_prepare_generate_database(@args)>

The method generate_database() should call this internal method as first step.
It checks if the first argument is a valid hash reference (see
generate_database()), sets default values for undefined keys and returns this
modified argument hash. Creates a symlink of the specified file (or copies this
file) in the I<data> directory. Generates a C<.nfo> file with the description
of the database. 

An implementation of generate_database should look like this:

    sub generate_database {
        my ( $self, @args ) = @_;
        my %args = $self->_prepare_generate_database(@args);

        if (defined $args{skip}) {
            return 0;
        }   
        # create the back-end specific indices
        ... 
        
        $self->_create_index_and_alphabet_file( $args{filename} );
        return $args{filename};
    }

=item C<_get_alignment( $seq_query, $seq_subject )>

Calculates and returns an alignment of two L<Bio::Seq> objects. Requires
B<EMBOSS> and B<bioperl-run>.

=item C<_get_databases($suffix)>

This method searches the data directory for files ending with C<$suffix>
and returns this list of files in an array.

Substitutes C<$suffix> with C<.nfo> from all found files and searches for an
info file with that name. The content of that file will be used as description.
When no file is found, the description will be the filename without the suffix:


  %dbs = _get_databases('.al1'); # finds file ATH1.cdna.al1, searches 
                                 # for ATH1.cdna.nfo
  print $dbs{'ATH1.cdna'};       # prints content of ATH1.cdna.nfo
                                 # or 'ATH1.cdna'


=item C<_get_sequences_from_bio_index($id)>

C<GUUGle>, C<RE> and C<Agrep> back-ends use L<Bio::Index> for sequence id queries 
(implemented in this this method). Returns a L<Bio::SeqIO> object.

=item C<_create_tmp_query_file()>

Examines C<query>, C<query_file> and C<reverse_complement> and generates a 
temporary Fasta file that is passed in the system() call to the back-end. If the
environment variable C<BIOGREPDEBUG> is not set, then this file will be deleted
when the script exits.  

=item C<_create_index_and_alphabet_file($fastafile)>

Creates an index of the specified Fasta file with L<Bio::Index::Fasta>.
Creates an C<Vmatch> alphabet file.

=item C<_parse_regions($hash_ref)>

Takes as argument a hash reference with the gene sequence and the hit
coordinates (keys C<complete_seq>, C<subject_begin> and C<subject_end>,
respectively). Calculates the upstream, subject and downstream sequence.

    my ( $upstream_seq, $subject_seq, $downstream_seq ) =
        $self->_parse_regions({ 
            complete_seq => $complete_seq,
            subject_begin=> $subject_begin, 
            subject_end  => $subject_end, 
        }); 

=back

=head2 DEPRECATED METHODS

=over

=item C<$sbe-E<gt>results()> 

B<DEPRECATED>. Get the results after search() was called. This is an array of 
L<Bio::Grep::SearchResult> objects.
  
  $sbe->search();

  foreach my $res (@{$sbe->results}) {
        # output result
  }

Use next_res() instead.

=item C<$sbe-E<gt>generate_database_out_of_fastafile($fastafile)> 

B<DEPRECATED>. Use generate_database() instead.

=back

=head1 DIAGNOSTICS

See L<Bio::Grep::Root> for other diagnostics.

=over

=item C<Alphabet of query and database not equal>

You tried to search with DNA/RNA query in protein database or vice versa. 
C<Bio::Root::BadParameter>.

=item C<Back-end does not support protein data>

You tried to generate a protein database with a back-end that does not support
protein data. C<Bio::Root::BadParameter>.

=item C<Can't combine editdistance and mismatches.> 

Set either C<editdistance> or C<mismatches>, not both. C<Bio::Root::BadParameter>

=item C<Can't copy ... to ...>

It was not possible to copy the Fasta file in generate_database() in the
I<data> directory. Check path and permissions. C<Bio::Root::IOException>.

=item C<Database not defined.>

You forgot to define a database. You have to build a database with
C<$sbe-E<gt>generate_database> (once) and set it with
C<$sbe-E<gt>settings-E<gt>database>. Example:

  $sbe->generate_database('ATH1.cdna");
  $sbe->settings->database('ATH1.cdna');

C<Bio::Root::BadParameter>.

=item C<Database not found.>

The specified database was not found. Check name and
C<$sbe-E<gt>settings-E<gt>datapath>. C<Bio::Root::BadParameter>.
   
=item C<Database not valid (insecure characters).>

The database name is not valid. Allowed characters are 'a-z', 'A-z','0-9', '.'
, '-' and '_'. C<Bio::Root::BadParameter>.

=item C<Invalid arguments. Hashref assumed.>

The method generate_database() assumes as first argument a hash reference.
C<Bio::Root::BadParameter>.

=item C<No such file.>

The file you have specified in generate_database() does not exist.
C<Bio::Root::BadParameter>.

=item C<Query and query_file are set. I am confused...>

You specified a query and a query file. C<Bio::Root::BadParameter>.

=item C<Query not defined.>

You forgot to define a query or a query file. C<Bio::Root::BadParameter>.

=item C<Reverse complement only available for DNA databases.>

Either C<reverse_complement> or C<direct_and_rev_com> is set and the specified
database is a protein database. These two feature are only available for DNA
databases.

=item C<Sort mode not valid.>

The specified sort mode ($sbe->settings->sort) is not valid.
You can get all valid sort modes with C<$sbe-E<gt>available_sort_modes()>
See L<Bio::Grep::Backend::Vmatch>, L<Bio::Grep::Backend::GUUGle>,
L<Bio::Grep::Backend::RE> and L<Bio::Grep::Backend::Agrep> for details. 
C<Bio::Root::BadParameter>.

=back

=head1 FILES

Requires B<EMBOSS> and L<Bio::Factory::EMBOSS> for the Needleman-Wunsch local 
alignment implementation from B<EMBOSS>. The internal method 
C<_get_alignment($seq_a, $seq_b)> can then calculate an alignment for 
back-ends that do not generate an alignment (like L<Bio::Grep::Backend::Agrep>).


=head1 SEE ALSO

L<Bio::Grep::SearchSettings> 
L<Bio::Grep::SearchResults> 


=head1 AUTHOR

Markus Riester, E<lt>mriester@gmx.deE<gt>


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2009 by M. Riester.

Based on Weigel::Search v0.13, Copyright (C) 2005-2006 by Max Planck 
Institute for Developmental Biology, Tuebingen.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

# vim: ft=perl sw=4 ts=4 expandtab
