package App::Mimosa::Controller::Sequence;
use Moose;
use Bio::Chado::Schema;
use File::Spec::Functions;
use App::Mimosa::Database;
use JSON::Any;
use Data::Dumper;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' };

sub sequence_sha1 :Path("/api/sequence/sha1/") :Args(2) {
    my ( $self, $c, $composite_sha1, $name ) = @_;
    my $bcs = $c->model('BCS');

    $name =~ s/\.txt$//g;
    $name =~ s/\.fasta$//g;

    my $seq_data_dir = $c->config->{sequence_data_dir};
    my $mimosa_root  = $c->config->{mimosa_root};
    # TODO: stop hardcoding location and prefix of cached composite seq sets
    my $dbname       = catfile($mimosa_root, $seq_data_dir, ".mimosa_cache_$composite_sha1");

    unless (-e "$dbname.seq") {
        $c->stash->{error} = 'Sorry, that sequence set cannot be found';
        $c->detach('/input_error');
    }

    my $db = App::Mimosa::Database->new(
        context     => $c,
        db_basename => $dbname,
        # TODO: get the correct alphabet
        alphabet    => "nucleotide",
        write       => 1,
    )->index;

    my $seq   = $db->get_sequence($name);

    die Dumper [ "get_sequence returned an invalid bioperl sequence:", $seq ] unless $seq && $seq->isa("Bio::PrimarySeqI");

    $c->stash->{sequences} = [ $seq ];
    $c->forward( 'View::SeqIO' );

}

sub sequence_id :Path("/api/sequence/id/") :Args(2) {
    my ( $self, $c, $mimosa_sequence_set_id, $name ) = @_;
    my $bcs = $c->model('BCS');

    my $return_json = ( $name =~ m/\.json$/ );

    $name =~ s/\.txt$//g;
    $name =~ s/\.fasta$//g;

    # Mimosa resultsets
    my $rs   = $bcs->resultset('Mimosa::SequenceSet')->find( { mimosa_sequence_set_id => $mimosa_sequence_set_id } );
    unless ($rs) {
        $c->stash->{error} = 'Sorry, that sequence set id is invalid';
        $c->detach('/input_error');
    }

    my $seq_data_dir = $c->config->{sequence_data_dir};
    my $mimosa_root  = $c->config->{mimosa_root};
    my $dbname       = catfile($mimosa_root, $seq_data_dir, $rs->shortname);
    #warn "dbname=$dbname, alphabet=" . $rs->alphabet;

    my $db = App::Mimosa::Database->new(
        db_basename => $dbname,
        alphabet    => $rs->alphabet,
        write       => 1,
    );

    my $seq   = $db->get_sequence($name);

    $c->stash->{sequences} = [ $seq ];
    $c->forward( 'View::SeqIO' );

}

1;
