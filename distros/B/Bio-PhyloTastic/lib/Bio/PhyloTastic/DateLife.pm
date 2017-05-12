package Bio::PhyloTastic::DateLife;
use strict;
use warnings;
use URI::Escape;
use LWP::UserAgent;
use Scalar::Util 'looks_like_number';
use Bio::Phylo::Util::CONSTANT ':objecttypes';
use base 'Bio::PhyloTastic';

=head1 NAME

Bio::PhyloTastic::DateLife - Fetches calibration ages for tree nodes

=head1 SYNOPSIS

 phylotastic DateLife -i <infile> -o <outfile>

=head1 DESCRIPTION

This module attempts to populate an input tree with node ages it obtains from
L<http://datelife.org>.

=head1 OPTIONS AND ARGUMENTS

=over

=item -i infile

An input file. Required.

=item -d informat

An input format, such as NEXUS, Newick, NeXML, PhyloXML, TaxList. Optional.
Default is adjacency table.

=item -o outfile

An output file name. If '-', prints output to STDOUT. Required.

=item -s outformat

An output format, such as NeXML, TaxList. Optional. Default is adjacency
table.

=back

=cut

# url for the datelife.org RESTful service
my $BASE_URL = 'http://datelife.org/cgi-bin/R/result?taxa=%s,%s&format=bestguess&partial=liberal&useembargoed=yes';

# URI for datelife.org terms
my $DL_NS_URI = 'http://datelife.org/terms.owl#';

# instantiate user agent to fetch ages
my $ua = LWP::UserAgent->new;

# defaults
my $deserializer = 'adjacency';
my $serializer   = 'adjacency';

sub _get_args {
	return (
		'serializer=s'   => \$serializer,
		'deserializer=s' => [ $deserializer ],
	);
}

sub _run {
	my ( $class, $project ) = @_;
	
	# parse tree
	my ($tree) = @{ $project->get_items(_TREE_) };
	
	# fetch ages from DatingLife
	_recurse_fetch($tree);
	
	# write output
	return $tree;
}


sub _recurse_fetch {
	my $tree = shift;
	
	# fetch the ages, create branch lengths
	$tree->visit_depth_first(
		'-post' => sub {
			my $node = shift;
			
			# start populating the array of tips, assume ultrametric tree
			if ( $node->is_terminal ) {
				$node->set_generic( 'tips' => [ $node->get_name ] );
				$node->set_generic( 'age'  => 0 );
			}
			else {
				
				# grow the array of tips
				my @children = @{ $node->get_children };
				my @tips;
				for my $child ( @children ) {
					push @tips, @{ $child->get_generic('tips') };
				}
				$node->set_generic( 'tips' => \@tips );
				
				# get the leftmost and rightmost tip
				my ( $left, $right ) = ( $tips[0], $tips[-1] );
				
				# fetch the age
				my $age = _fetch_age($left,$right);
				$node->set_generic( 'age' => $age );
				
				# apply branch lengths to children
				for my $child ( @children ) {
					my $child_age = $child->get_generic('age');
					$child->set_branch_length( $age - $child_age );
				}
				
			}
		}
	);

}

# does a request to datelife
sub _fetch_age {
	my ($left,$right) = @_;
	my $log = __PACKAGE__->_log;
	
	# construct datelife url
	my $url = sprintf $BASE_URL, uri_escape($left), uri_escape($right);
	$log->info("going to fetch $url");
	
	# fetch result
	my $response = $ua->get($url);
	if ( $response->is_success ) {
		$log->info("success: " . $response->status_line);
		
		# read result, this should be a single number 
		my $age = $response->decoded_content;
		chomp($age);
		if ( looks_like_number $age ) {
			$log->info("age: $age");
			return $age;
		}
		else {
			$log->warn("No age for $left <=> $right, got this instead: $age");
			return 0;
		}
	}
	
	# the request failed, carry on regardless
	else {
		$log->warn($response->status_line);
	}
}

1;