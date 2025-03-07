package Bio::Phylo::Forest::DBTree;
use strict;
use warnings;
use DBI;
use Bio::Phylo::Factory;
use Bio::Phylo::Util::Exceptions 'throw';
use base 'DBIx::Class::Schema';
use base 'Bio::Phylo::Forest::Tree';

__PACKAGE__->load_namespaces;

my $SINGLETON;
my $DBH;
my $fac = Bio::Phylo::Factory->new;
use version 0.77; our $VERSION = qv("v0.2.0");

=head1 NAME

Bio::Phylo::Forest::DBTree - Phylogenetic database as a tree object

=head1 SYNOPSIS

 use Bio::Phylo::Forest::DBTree;
 
 # connect to the Green Genes tree
 my $file = 'gg_13_5_otus_99_annotated.db';
 my $dbtree = Bio::Phylo::Forest::DBTree->connect($file);

 # $dbtree can be used as a Bio::Phylo::Forest::Tree object,
 # and the node objects that are returned can be used as
 # Bio::Phylo::Forest::Node objects
 my $root = $dbtree->get_root;

=head1 DESCRIPTION

This package provides the functionality to handle very large phylogenies (examples: the
NCBI taxonomy, the Green Genes tree) as if they are L<Bio::Phylo> tree objects, with all 
the possibilities for traversal, computation, serialization, and visualization, but stored
in a SQLite database. These databases are single files, so that they can be easily shared.
Some useful database files are available here: 
https://figshare.com/account/home#/projects/18808

To make new tree databases, a number of scripts are provided with the distribution of this
package:

=over

=item * C<megatree-loader> Loads a very large Newick tree into a database.

=item * C<megatree-ncbi-loader> Loads the NCBI taxonomy dump into a database.

=item * C<megatree-phylotree-loader> Loads a tree in the format of L<http://phylotree.org>
into a database.

=back

As an example of interacting with a database tree, the script C<megatree-pruner> can be
used to extract subtrees from a database.

=head1 DATABASE METHODS

The following methods deal with the database as a whole: creating a new database, 
connecting to an existing one, persisting a tree in a database and extracting one as a
mutable, in-memory object.

=head2 create()

Creates a SQLite database file in the provided location. Usage:

  use Bio::Phylo::Forest::DBTree;
  
  # second argument is optional
  Bio::Phylo::Forest::DBTree->create( $file, '/opt/local/bin/sqlite3' );

The first argument is the location where the database file is going to be created. The
second argument is optional, and provides the location of the C<sqlite3> executable that
is used to create the database. By default, the C<sqlite3> is simply found on the 
C<$PATH>, but if it is installed in a non-standard location that location can be provided
here. The database schema that is created corresponds to the following SQL statements:

 create table node(
   id int not null,
   parent int,
   left int,
   right int,
   name varchar(20),
   length float,
   height float,
   primary key(id)
 );
 create index parent_idx on node(parent);
 create index left_idx on node(left);
 create index right_idx on node(right);
 create index name_idx on node(name);

=cut

sub create {
	my $class = shift;
	my $file  = shift;
	my $sqlite3 = shift || 'sqlite3';
	my $command = do { local $/; <DATA> };
	system("echo '$command' | sqlite3 '$file'") == 0 or die 'Create failed!';
}

=head2 connect()

Connects to a SQLite database file, returns the connection as a 
C<Bio::Phylo::Forest::DBTree> object. Usage:

 use Bio::Phylo::Forest::DBTree;
 my $dbtree = Bio::Phylo::Forest::DBTree->connect($file);

The argument is a file name. If the file exists, a L<DBD::SQLite> database handle to that
file is returned. If the file does not exist, a new database is created in that location,
and subsequently the handle to that newly created database is returned. The creation of 
the database is handled by the C<create()> method (see below).

=cut

sub connect {
	my $class = shift;
	my $file  = shift;
	if ( not $SINGLETON ) {
		
		# create if not exist
		if ( not -e $file ) {
			$class->create($file);
		}
	
		# fuck it, let's just hardcode it here - Yeehaw!
		my $dsn  = "dbi:SQLite:dbname=$file";
		$DBH = DBI->connect($dsn,'','');
		$DBH->{'RaiseError'} = 1;
		$SINGLETON = $class->SUPER::connect( sub { $DBH } );
	}
	return $SINGLETON;
}

=head2 persist()

Persist a phylogenetic tree object (a subclass of L<Bio::Phylo::Forest::Tree>) into a 
newly created database file. Usage:

  use Bio::Phylo::Forest::DBTree;  
  my $dbtree = Bio::Phylo::Forest::DBTree->persist(
      -file => $file,
      -tree => $tree,
  );

This method first create a database at the location specified by C<$file> by making a call
to the C<create()> method. Subsequently, the C<$tree> object is traversed from root to 
tips and inserted in the newly created database. Finally, the handle to this database is
returned, i.e. a C<Bio::Phylo::Forest::DBTree> object.

=cut

sub persist {
	my ( $class, %args ) = @_;
	
	# need a file argument to write to
	if ( not $args{'-file'} ) {
		throw 'BadArgs' => "Need -file argument!";
	}
	
	# need a tree argument to persis
	if ( not $args{'-tree'} ) {
		throw 'BadArgs' => "Need -tree argument!";
	}
	
	# create a new database, prepare statement handler
	$class->create( $args{'-file'} );
	my $dsn = 'dbi:SQLite:dbname=' . $args{'-file'};
	my $dbh = DBI->connect($dsn,'','');
	$dbh->{'RaiseError'} = 1;
	my $db = $class->SUPER::connect( sub { $dbh } );		
	my $sth = $dbh->prepare("insert into node values(?,?,?,?)");
	
	# start traversing
	my $counter = 2;
	my %idmap;
	$args{'-tree'}->visit_depth_first(
		'-pre' => sub {
			my $node    = shift;
			my $id      = $node->get_id;
			$idmap{$id} = $counter++;
			
			# get the parent id, or "1" if root
			my $parent_id;
			if ( my $parent = $node->get_parent ) {
				my $pid = $parent->get_id;
				$parent_id = $idmap{$pid};
			}
			else {
				$parent_id = 1;
			}
			
			# do the insertion
			$sth->execute(
				$idmap{$id},               # primary key
				$parent_id,                # self-joining foreign key
				undef,                     # not indexed yet
				undef,                     # not indexed yet
				$node->get_internal_name,  # node label or taxon name
				$node->get_branch_length,  # branch length
				undef                      # not computed yet
			);
		}
	);
	my $i = 0;
	$db->get_root->_index(\$i,0);
	return $db;
}

=head2 extract()

Extracts a tree from a database. The returned tree is an in-memory object. Hence, this is
an expensive operation that is best avoided as much as possible. Usage:

 my $tree = $dbtree->extract;

=cut

sub extract {
	my $self = shift;
	my $tree = $fac->create_tree;
	my $root = $self->get_root;
	_clone_mutable(
		$fac->create_node(
			'-name'          => $root->get_name,
			'-branch_length' => $root->get_branch_length,
		),
		$root,
		$tree
	);
	return $tree;
}

{
	no warnings 'recursion';
	sub _clone_mutable {
		my ( $parent, $template, $tree ) = @_;
		$tree->insert($parent);
		for my $child ( @{ $template->get_children } ) {
			_clone_mutable( 
				$fac->create_node(
					'-name'          => $child->get_name,
					'-branch_length' => $child->get_branch_length,
					'-parent'        => $parent,
				),
				$child,
				$tree
			);
		}
	}
}

=head2 dbh()

Returns the underlying handle through which SQL statements can be executed directly on the
database. This is a L<DBD::SQLite> object. Usage:

 my $dbh = $dbtree->dbh;

=cut

sub dbh { $DBH }

=head1 TREE METHODS

The following methods are implemented here to override methods of the same name in the
L<Bio::Phylo> hierarchy so that the tree database is accessed more efficiently than
otherwise would be the case.

=head2 get_root()

Returns the root of the tree, i.e. a L<Bio::Phylo::Forest::DBTree::Result::Node> object,
which is a subclass of L<Bio::Phylo::Forest::Node>. Usage:

 my $root = $dbtree->get_root;

=cut

sub get_root { 
	shift->_rs->search(
		{ 'parent' => 1 },
		{
			'order_by' => 'id',
			'rows'     => 1,
		}
	)->single 
}

=head2 get_id()

Returns a dummy ID, an integer. Usage:

 my $id = $dbtree->get_id;

=cut

sub get_id { 0 }

=head2 get_by_name()

Returns the first node object that has the provided name. Usage:

 my $node = $dbtree->get_by_name( 'Homo sapiens' );

=cut

sub get_by_name {
	my ( $self, $name ) = @_;
	return $self->_rs->search({ 'name' => $name })->single;
}

=head2 visit()

Given a code reference, visits all the nodes in the tree and executes the code on the 
focal node. Usage:

 $dbtree->visit(sub{
     my $node = shift;
     print $node->name, "\n"; 
 });

=cut

sub visit {
	my ( $self, $code ) = @_;
	my $rs = $self->_rs;
	while( my $node = $rs->next ) {
		$code->($node);
	}
	return $self;
}

sub _rs { shift->resultset('Node') }

1;

__DATA__
create table node(id int not null,parent int,left int,right int,name varchar(20),length float,height float,primary key(id));
create index parent_idx on node(parent);
create unique index left_idx on node(left asc);
create unique index right_idx on node(right asc);
create index name_idx on node(name);
