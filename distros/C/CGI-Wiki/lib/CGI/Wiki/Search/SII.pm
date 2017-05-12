package CGI::Wiki::Search::SII;

use strict;
use Search::InvertedIndex;
use Carp "croak";
use base 'CGI::Wiki::Search::Base';

use vars qw( @ISA $VERSION );

$VERSION = 0.09;

=head1 NAME

CGI::Wiki::Search::SII - Search::InvertedIndex plugin for CGI::Wiki.

=head1 SYNOPSIS

  my $indexdb = Search::InvertedIndex::DB::Mysql->new( ... );
  my $search = CGI::Wiki::Search::SII->new( indexdb => $indexdb );
  my %wombat_nodes = $search->search_nodes("wombat");

Provides search-related methods for L<CGI::Wiki>.

See also L<CGI::Wiki::Search::Base>, for methods not documented here.

=cut

=head1 METHODS

=over 4

=item B<new>

  # EITHER

  my $indexdb = Search::InvertedIndex::DB::Mysql->new(
                   -db_name    => $dbname,
                   -username   => $dbuser,
                   -password   => $dbpass,
		   -hostname   => '',
                   -table_name => 'siindex',
                   -lock_mode  => 'EX' );

  # OR

  my $indexdb = Search::InvertedIndex::DB::DB_File_SplitHash->new(
                   -map_name  => "/home/wiki/indexes.db",
                   -lock_mode => "EX" );

  # THEN

  my $search = CGI::Wiki::Search::SII->new( indexdb => $indexdb );

Takes only one parameter, which is mandatory. C<indexdb> must be a
C<Search::InvertedIndex::DB::*> object.

=cut

sub _init {
    my ($self, %args) = @_;
    my $indexdb = $args{indexdb};

    my $map = Search::InvertedIndex->new( -database => $indexdb )
      or croak "Couldn't set up Search::InvertedIndex map";
    $map->add_group( -group => "nodes" );
    $map->add_group( -group => "fuzzy_titles" );

    $self->{_map}  = $map;

    return $self;
}

sub _do_search {
    my ($self, $and_or, $terms) = @_;

    # Create a leaf for each search term.
    my @leaves;
    foreach my $term ( @$terms ) {
        my $leaf = Search::InvertedIndex::Query::Leaf->new(-key   => $term,
                                                           -group => "nodes" );
        push @leaves, $leaf;
    }

    # Collate the leaves.
    my $query = Search::InvertedIndex::Query->new( -logic => $and_or,
                                                   -leafs => \@leaves );

    # Perform the search and extract the results.
    my $result = $self->{_map}->search( -query => $query );

    my $num_results = $result->number_of_index_entries || 0;
    my %results;
    for my $i ( 1 .. $num_results ) {
        my ($index, $data, $ranking) = $result->entry( -number => $i - 1 );
	$results{$index} = $ranking;
    }
    return %results;
}

sub _fuzzy_match {
    my ($self, $string, $canonical) = @_;
    my $leaf = Search::InvertedIndex::Query::Leaf->new(
        -key   => $canonical,
        -group => "fuzzy_titles" );

    my $query = Search::InvertedIndex::Query->new( -leafs => [ $leaf ] );

    my $result = $self->{_map}->search( -query => $query );

    my $num_results = $result->number_of_index_entries || 0;
    my %results;
    for my $i ( 1 .. $num_results ) {
        my ($index, $data) = $result->entry( -number => $i - 1 );
	$results{$data} = $data eq $string ? 2 : 1;
    }
    return %results;
}

sub _index_node {
    my ($self, $node, $content, $keys) = @_;
    my $update = Search::InvertedIndex::Update->new(
        -group => "nodes",
        -index => $node,
        -data  => $content,
        -keys => { map { $_ => 1 } @$keys }
    );
    $self->{_map}->update( -update => $update );
}

sub _index_fuzzy {
    my ($self, $node, $canonical) = @_;
    my $update = Search::InvertedIndex::Update->new(
        -group => "fuzzy_titles",
        -index => $node . "_fuzzy_title",
        -data  => $node,
        -keys  => { $canonical => 1 }
    );
    $self->{_map}->update( -update => $update );
}

sub _delete_node {
    my ($self, $node) = @_;
    $self->{_map}->remove_index_from_all({ -index => $node });
}

sub supports_phrase_searches { return 0; }
sub supports_fuzzy_searches  { return 1; }

=back

=head1 SEE ALSO

L<CGI::Wiki>, L<CGI::Wiki::Search::Base>.

=cut

1;
