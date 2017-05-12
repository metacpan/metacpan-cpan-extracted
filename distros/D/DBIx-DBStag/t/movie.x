use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 1;
}
use DBIx::DBIStag;
use Data::Stag;
use FileHandle;

my $dbh;
$dbh = getdbh(@ARGV) if @ARGV;

my $mset = Data::Stag->parse("t/data/mset.xml");

my @movies = $mset->getnode('movie');
foreach my $movie (@movies) {
    my @movie_chars = $movie->getnode('movie_char');
    $movie->unset('movie_char');
#    $dbh->store_stag($movie);  # stores director too
    foreach my $movie_char (@movie_chars) {
	my $actor = $movie_char->getnode_actor;
	$movie_char->unset('actor');
#	print $actor->xml;
	my $actor_id = $dbh->store_stag($actor);
	my $role =
	  Data::Stag->new(role=>[
				 [movie_name=>$movie->get_name],
				 [movie_char_name=>$movie_char->get_name],
				 [actor_id=>$actor_id]
				]);
	$dbh->store_stag($role);
    }
}

my $xmlstruct =
  $dbh->selectall_stag(q[
                         SELECT bioentry.*, seqfeature.*, seqfeature_qualifier_value.*, ftype.*
                         FROM
                         bioentry NATURAL JOIN (seqfeature NATURAL JOIN seqfeature_qualifier_value) INNER JOIN ontology_term AS ftype ON (ftype.ontology_term_id = seqfeature_key_id) LIMIT 300
                        ],
                       "(bioentry(seqfeature(seqfeature_qualifier_value 1)(ftype 1)))",
                      );
print $xmlstruct->xml;


sub getdbh {
    return DBIx::DBIStag->connect(@_);
}
