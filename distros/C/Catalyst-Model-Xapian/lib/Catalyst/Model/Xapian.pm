package Catalyst::Model::Xapian;

use base qw/Catalyst::Model/;
use Moose;

use strict;

use Catalyst::Model::Xapian::Result;
use Encode qw/from_to/;
use Search::Xapian qw/:all/;
use Storable;
use MRO::Compat;
use Time::HiRes qw/gettimeofday tv_interval/;

our $VERSION='0.06';

__PACKAGE__->mk_accessors('db');
__PACKAGE__->mk_accessors('qp');
has 'db' => (isa => 'Search::Xapian::Database', is => 'rw');
has 'qp' => (isa => 'Search::Xapian::QueryParser', is => 'rw');


=head1 NAME

Catalyst::Model::Xapian - Catalyst model for Search::Xapian.

=head1 SYNOPSIS

    my ($it,$res)= $c->comp('MyApp::M::Xapian')->search(
      $c->req->param('q'),
      $c->req->param('page') ||0 ,
      $c->req->param('itemsperpage')||0
    );
    $c->stash->{searchresults}=$res;
    $c->stash->{iterator}=$it;
 

=head1 DESCRIPTION

This model class wraps L<Search::Xapian> to provide a friendly, paged 
interface to Xapian (www.xapian.org) indexes. This class adds a little
extra convenience on top of the Search::Xapian class. It expects you to
use the QueryParser, and sets up some keywords based on the standard
omega keywords (id, host, date, month, year,title), so that you can
do searches like 

  'fubar site:microsoft.com'

=head1 CONFIG OPTIONS

=over 4

=item  db

Path to the index directory. will default to <MyApp>/index.

=item language

Language to use for stemming. Defaults to english

=item page_size

Default page sizes for L<Data::Page>. Defaults to 10.

=item utf8_query

Queries are passed as utf8 strings. defaults to 1.

=item order_by_date

Sets weighting to order by docid descending rather than the usual BM25 
weighting. Off by default.

=back

=head1 METHODS

=over 4

=item new

Constructor. sets up the db and qp accessors. Is called automatically by
Catalyst at startup.

=cut

sub new { 
	my ( $self, $c ) = @_;
	$self = $self->NEXT::new($c);                                               	my %config = (
		db         => $c->config->{home}.'/index',
		language   => "english",
		page_size  => 10,
        utf8_query => 1,
		%{ $self->config() },
	);

	$self->db(Search::Xapian::Database->new($config{db}));
	$self->qp(Search::Xapian::QueryParser->new($self->db));
    
    if ( defined($config{language}) ) {
	    my $stemmer=Search::Xapian::Stem->new($config{language});
	    $self->qp->set_stemmer($stemmer);
    }
	$self->qp->set_default_op(OP_AND);
	
    $self->qp->add_boolean_prefix("site", "H");
	$self->qp->add_boolean_prefix("year", "Y");
	$self->qp->add_boolean_prefix("month", "M");
	$self->qp->add_boolean_prefix("date", "D");
	$self->qp->add_boolean_prefix("id", "Q");
	$self->qp->add_prefix("title", "T");

	$self->config(\%config);
	return $self;
}


=item search <q>,[<page>],[<page_size>]

perform a search using the Xapian QueryBuilder. expands the document data
using extract_data. You can override the page size per query by passing
page size as a final argument to the function. returns a L<Data::Page>
object and an arrayref to the extracted document data.

=cut


sub search {
    my ( $class,$q, $page,$page_size) = @_;
    my $t=[gettimeofday];
    $page       ||= 1;
    $page_size  ||=  $class->config->{page_size};
    $class->db->reopen();
    my $query=$class->qp->parse_query( $q, 23 );
    my $enq       = $class->db->enquire ( $query );
    $class->prepare_enq($enq);
    if( $class->config->{order_by_date} ) {
        $enq->set_docid_order(ENQ_DESCENDING);
        $enq->set_weighting_scheme(Search::Xapian::BoolWeight->new());
    }
    my $mset      = $enq->get_mset( ($page-1)*$page_size,
                                     $page_size );
    my ($time)=tv_interval($t) =~ m/^(\d+\.\d{0,2})/;
    $time =~ s/\./\,/;
    from_to($q,'utf-8','iso-8859-1') if $class->config->{utf8_query};
    #$q=utf8::decode($q) if $class->{config}->{utf8_query};
    return Catalyst::Model::Xapian::Result->new({ mset=>$mset,
        search=>$class,query=>$q,query_obj=>$query,querytime=>$time,page=>$page,page_size=>$page_size });
}
 
=item prepare_enq <enq>

Prepare enquire object before getting mset. Allows you to modify 
ordering and such in your subclass.

=cut  
 
sub prepare_enq {}
 
=item extract_data <item> <query>

Extract data from a L<Search::Xapian::Document>. Defaults to
using Storable::thaw.

=cut

sub extract_data {
    my ( $self,$item, $query ) = @_;
    my $data=Storable::thaw( $item->get_data ); 
    return $data;
}

1;

=item qp

Query Parser. The L<Search::Xapian::QueryParser> object used to parse the query.

=back

=head1 AUTHOR

Marcus Ramberg <mramberg@cpan.org>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify it under
the same terms as perl itself.
