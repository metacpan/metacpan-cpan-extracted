package DBIx::Class::Wrapper::Factory;
$DBIx::Class::Wrapper::Factory::VERSION = '0.009';
use Moose;
extends qw/DBIx::Class::Wrapper::FactoryBase/;

=head1 NAME

DBIx::Class::Wrapper::Factory - A factory class that decorates a L<DBIx::Class::ResultSet>.

=head1 SYNOPSIS

A model implementing the role DBIx::Class::Wrapper will automatically instantiate
subclasses of this for any underlying DBIx::Class ResultSet.

To implement your own factory containing your business code for the underlying
DBIC resulsets, you need to subclass this.

See L<DBIx::Class::Wrapper> for a simple synopsis overview.

=head1 PROPERTIES

=head2 dbic_rs

The original L<DBIx::Class::ResultSet>. Mandatory.

=head2 bm

The business model consuming the role L<DBIx::Class::Wrapper>. Mandatory.

See L<DBIx::Class::Wrapper> for more details.

=cut

has 'dbic_rs' => ( is => 'ro' , isa => 'DBIx::Class::ResultSet', required => 1 , lazy_build => 1);
has 'bm' => ( is => 'ro' , does => 'DBIx::Class::Wrapper' , required => 1 , weak_ref => 1 );
has 'name' => ( is => 'ro' , isa => 'Str' , required => 1 );

sub _build_dbic_rs{
    my ($self) = @_;
    return $self->build_dbic_rs();
}

=head2 build_dbic_rs

Builds the dbic ResultSet to be wrapped by this factory.

Defaults to the DBIx::Class Resultset with the same name
as this factory.

You can override this in your business specific factories to build
specific resultsets:

 package My::Model::Factory::SomeName;

 use Moose; extends  qw/DBIx::Class::Wrapper::Factory/ ;

 sub build_dbic_rs{
    my ($self) = @_;
    return $self->bm->dbic_schema->resultset('SomeOtherName');

    # Or with some restriction:

    return $self->bm->dbic_schema->resultset('SomeOtherName')
           ->search({ bla => ... });
 }


=cut

sub build_dbic_rs{
  my ($self) = @_;
  my $resultset = eval{ return $self->bm->dbic_schema->resultset($self->name); };
  if( my $err = $@ ){
    confess("Cannot build resultset for $self NAME=".$self->name().' :'.$err);
  }
  return $resultset;
}


=head2 new_result

Instantiate a new NOT INSERTED IN DB row and wrap it using
the wrap method.

See L<DBIx::Class::ResultSet/new_result>

=cut

sub new_result{
    my ($self, $args) = @_;
    return $self->wrap($self->dbic_rs->new_result($args));
}

=head2 create

Creates a new object in the DBIC Schema and return it wrapped
using the wrapper method.

See L<DBIx::Class::ResultSet/create>

=cut

sub create{
    my ($self , $args) = @_;
    return $self->wrap($self->dbic_rs->create($args));
}

=head2 find

Finds an object in the DBIC schema and returns it wrapped
using the wrapper method.

See L<DBIx::Class::ResultSet/find>

=cut

sub find{
    my ($self , @rest) = @_;
    my $original = $self->dbic_rs->find(@rest);
    return $original ? $self->wrap($original) : undef;
}

=head2 first

Equivalent to DBIC Resultset 'first' method.

See <DBIx::Class::ResultSet/first>

=cut

sub first{
  my ($self) = @_;
  my $original = $self->dbic_rs->first();
  return $original ? $self->wrap($original) : undef;
}

=head2 single

Equivalent to DBIx::Class::ResultSet::single. It's a bit more efficient than C<first()>.

=cut

sub single {
  my ($self) = @_;
  my $original = $self->dbic_rs->single();
  return $original ? $self->wrap($original) : undef;
}

=head2 update_or_create

Wraps around the original DBIC update_or_create method.

See L<DBIx::Class::ResultSet/update_or_create>

=cut

sub update_or_create {
    my ($self, $args) = @_;
    my $original = $self->dbic_rs->update_or_create($args);
    return $original ? $self->wrap($original) : undef;
}

=head2 find_or_create

Wraps around the original DBIC find_or_create method.

See L<DBIx::Class::ResultSet/find_or_create>

=cut

sub find_or_create{
  my ($self , $args) = @_;
  my $original = $self->dbic_rs->find_or_create($args);
  return $original ? $self->wrap($original) : undef;
}

=head2 find_or_new

Wraps around the original DBIC find_or_new method.

See L<DBIx::Class::ResultSet/find_or_new>

=cut

sub find_or_new {
  my ($self, @args) = @_;
  return $self->wrap( $self->dbic_rs->find_or_new( @args ) );
}


=head2 pager

Shortcut to underlying dbic_rs pager.

See L<DBIx::Class::ResultSet/pager>.

=cut

sub pager{
  my ($self) = @_;
  return $self->dbic_rs->pager();
}

=head2 delete

Shortcut to L<DBIx::Class::ResultSet/delete>

=cut

sub delete{
  my ($self , @rest) = @_;
  return $self->dbic_rs->delete(@rest);
}

=head2 get_column

Shortcut to the get_column of the decorated dbic_rs

See L<DBIx::Class::ResultSet/get_column>

=cut

sub get_column{
  my ($self, @rest) = @_;
  return $self->dbic_rs->get_column(@rest);
}

=head2 search_rs

Alias for search

=cut

sub search_rs{
  goto &search;
}

=head2 search

Search objects in the DBIC Schema and returns a new instance
of this factory.

Note that unlike DBIx::Class::ResultSet, this search method
will not return an Array of all results in an array context.

=cut

sub search{
    my ($self , @rest) = @_;
    my $class = ref($self);
    return $class->new({ dbic_rs => $self->dbic_rs->search_rs(@rest),
			 bm => $self->bm(),
			 name => $self->name()
		       });
}


=head2 wrap

Wraps an L<DBIx::Class::Row> in a business object. By default, it returns the
Row itself.

Override that in your subclasses of factories if you need to wrap some business code
around the L<DBIx::Class::Row>:

  sub wrap{
     my ($self, $o) = @_;

     return My::Model::O::SomeObject->new({ o => $o , ... });
  }

=cut

sub wrap{
    my ($self , $o) = @_;
    return $o;
}


=head2 all

Similar to DBIC Resultset all.

Usage:

 my @objs = $this->all();

=cut

sub all{
  my ($self) = @_;
  my $search = $self->search();
  my @res = ();
  while( my $next = $search->next() ){
    push @res , $next;
  }
  return @res;
}

=head2 loop_through

Loop through all the elements of this factory
whilst paging and execute the given code
with the current retrieved object.

WARNINGS:

Make sure your resultset is ordered as
it wouldn't make much sense to page through an unordered resultset.

In case other things are concurrently adding to this resultset, it is possible
that the code you give will be called with the same objects twice.

If it's not the problem and if the rate at which objects are added is
not too fast compared to the processing you are doing in the code, it
should be just fine.

In other cases, you probably want to wrap this in a transaction to have
a frozen view of the resultset.

Usage:

 $this->loop_through(sub{ my $o = shift ; do something with o });
 $this->loop_through(sub{...} , { limit => 1000 }); # Do only 1000 calls to sub.
 $this->loop_through(sub{...} , { rows => 20 }); # Go by pages of 20 rows

=cut

sub loop_through{
  my ($self, $code , $opts ) = @_;

  unless( defined $opts ){
      $opts = {};
  }

  my $limit = $opts->{limit};
  my $rows = defined $opts->{rows} ? $opts->{rows} : 10;

  my $attrs = { %{$self->dbic_rs->{attrs} || {} } };
  unless( $attrs->{order_by} ){
    warn(q|

Missing order_by attribute. Order will be undefined in |.__PACKAGE__.q| loop_through.

|);

  }

  # init
  my $page = 1;
  my $search = $self->search(undef , { page => $page , rows => $rows });
  my $last_page = $search->pager->last_page();

  my $ncalls = 0;
  # loop though all pages.
 PAGELOOP:
  while( $page <= $last_page ){
    # Loop through this page
    while( my $o = $search->next() ){
      $code->($o);
      $ncalls++;
      if( $limit && ( $ncalls >= $limit ) ){
        last PAGELOOP;
      }
    }
    # Done with this page.
    # Go to the next one.
    $page++;
    $search = $self->search(undef, { page => $page , rows => $rows });
  }
}


=head2 fast_loop_through

Loops through all the objects of this factory
in a Seeking fashion. If the primary key of the underlying
resultset is orderable and indexed, this should run
in linear time of the number of rows on the resultset.

Usage:

  $this->fast_loop_through(sub{my ($o) = @_; ... } );

  $this->fast_loop_through(sub{ .. } , { rows => 100 , limit => 1000 });

Options:

 rows: Fetch this amount of rows at each query. Default to 100

 limit: Return after looping through this amount of rows.

B<Important>

=over

You do not need to order the set, as this will order it by ascending primary key.

This means aggregation functions (such as group_by) will not work.

Incidentally, it means that if other processes are writing to this resultset,
this method will play catch up on the resultset, so if the writing rate is higher
than the reading rate, this might take a while to return.

If you want to avoid this, set the option 'order' to 'desc'.

=back

Returns the number of rows looped through.

Prerequisites:

Must have:

- The underlying L<DBIx::Class::ResultSource> has a primary key

- Each component of the primary key supports the operators '>' and '<'

- It is possible to order all the rows by this primary key alone.

Should have:

- This primary key is indexed and offers fast comparison access.

Inspired by http://use-the-index-luke.com/sql/partial-results/fetch-next-page

=cut

sub fast_loop_through{
  my ($self , $code, $opts) = @_;

  unless( defined $code ){ $code = sub{}; }
  unless( defined $opts ){ $opts = {}; }

  my $order = $opts->{order} || 'asc';
  my $rows = $opts->{rows} || 100;
  my $limit = $opts->{limit};

  # Gather the required info about the resultset
  my $rs = $self->dbic_rs();

  # What is this source alias?
  my $me = $rs->current_source_alias();

  # The source
  my $source = $rs->result_source();
  my @primary_columns = $source->primary_columns();
  unless( @primary_columns ){
    confess("Result Source ".$source->source_name()." does not have a primary key");
  }

  my $order_by = [ map{ +{ '-'.$order => $me.'.'.$_ } } @primary_columns ];

  my $n_rows = 0;

  my $last_row;
  do{
    my $resultset = $self->dbic_rs->search_rs(undef , { order_by => $order_by , rows => $rows });
    if( $last_row ){
      # We have a last row.
      # The idea here is to use the primary key to get the rows above
      # this last row.

      # The primary key of the first queried row should be greater than
      # the last row's one.
      # Logically it should be: ( queried PK components ) > ( last row PK components )
      # If the primary key is A , B , C , then the where clause should contain (for order desc):
      # A > a || ( A = a && B > b || ( B = b && C > c ) )

      my $top_or = { -or => [] };
      my $cur_or = $top_or;

      my $cmp_op = $order eq 'asc' ? '>' : '<';

      my $key_i = 0;
      for(; $key_i < @primary_columns - 1 ; $key_i++ ){

        my $column = $primary_columns[$key_i];

        my $nested_or = { -or => [] };

        push @{ $cur_or->{-or} } , { $me.'.'.$column => { $cmp_op => $last_row->get_column($column) }};
        push @{ $cur_or->{-or} } , { -and => [ { $me.'.'.$column => { '=' => $last_row->get_column($column) } },
                                               $nested_or
                                             ]
                                   };
        $cur_or = $nested_or;
      }

      my $last_column = $primary_columns[$key_i];
      push @{ $cur_or->{-or} } , { $me.'.'.$last_column => {  $cmp_op => $last_row->get_column($last_column) } };

      $resultset = $resultset->search_rs($top_or);
    } # End of above last row seeking

    $last_row = undef;

    while( my $o = $resultset->next() ){
      $last_row = $o;
      my $wrapped = $self->wrap($o);
      &$code($wrapped);
      $n_rows++;

      if( $limit && ( $n_rows == $limit ) ){
        return $n_rows;
      }
    }
  }while( $last_row );

  return $n_rows;
}

=head2 next

Returns next Business Object from this current DBIx::Resultset.

See L<DBIx::Class::ResultSet/next>

=cut

sub next{
    my ($self) = @_;
    my $next_o = $self->dbic_rs->next();
    return undef unless $next_o;
    return $self->wrap($next_o);
}

=head2 count

Returns the number of objects in this ResultSet.

See L<DBIx::Class::ResultSet/count>

=cut

sub count{
    my ($self) = @_;
    return $self->dbic_rs->count();
}


__PACKAGE__->meta->make_immutable();
1;
