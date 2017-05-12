package B::XPath;

use strict;
use warnings;

our $VERSION = '0.01';

use B;
use Scalar::Util 'blessed';

sub fetch_root
{
	my ($class, $sub) = @_;
	my $op            = B::svref_2object( $sub )->ROOT();
	my $op_class      = $class->find_op_class( $op );
	return $op_class->create( root => $op );
}

sub fetch_main_root
{
	my ($class)  = @_;
	my $op       = B::main_root();
	my $op_class = $class->find_op_class( $op );
	return $op_class->create( root => $op );
}

sub find_op_class
{
	my ($class, $op)  = @_;
	my $node_class    =  blessed( $op );
	$node_class       =~ s/(::\w+)$/::XPath$1/;
	return $node_class;
}

package B::XPath::Node;

use Class::XPath
	get_name       => 'name',
	get_parent     => 'parent',
	get_root       => 'get_root',
	get_children   => 'get_children',
	get_attr_names => 'get_attr_names',
	get_attr_value => 'get_attr_value',
	get_content    => 'get_content';

sub create
{
	my ($class, %args)   = @_;
	my $self             = \%args;
	@args{qw( op root )} = ($args{root}, $self) unless $args{op};

	bless $self, $class;

	$self->create_children();
	return $self;
}

sub get_root
{
	my $self = shift;
	return $self->{root};
}

sub op
{
	my $self = shift;
	return $self->{op};
}

sub parent
{
	my $self = shift;
	return unless exists $self->{parent};
	return $self->{parent};
}

sub create_children
{
	my $self = shift;
	my $root = $self->get_root();
	my $kids = $self->{children} = [];

	for my $kid ($self->kids())
	{
		my $kid_class = B::XPath->find_op_class( $kid );
		push @$kids, $kid_class->create(
			op     => $kid,
			root   => $root,
			parent => $self,
		);
	}
}

sub kids
{
	my $self = shift;
	return unless $self->name() eq 'null';
}

sub get_children
{
	my $self = shift;
	return unless $self->{children};
	return @{ $self->{children} };
}

sub get_name
{
	my $self = shift;
	return $self->name();
}

sub DESTROY {}

sub AUTOLOAD
{
	our $AUTOLOAD;
	my $self     = $_[0];
	my ($method) = $AUTOLOAD =~ /::(\w+)$/;
	my $op       = $self->op();

	die "Unimplemented method $method for $self\n" unless $op->can( $method );
	my $sub = sub { shift->op()->$method() };
	no strict 'refs';
	*{ Scalar::Util::blessed( $self ) . '::' . $method } = $sub;
	goto &$sub;
}

sub get_attr_value
{
	my ($self, $attr) = @_;
	my $op            = $self->op();
	return unless $op->can( $attr );
	return $op->$attr();
}

sub get_nextstate
{
	my $self = shift;
	return $self->{nextstate} if $self->{nextstate};
	$self->{nextstate} = $self->find_nextstate();
}

sub find_nextstate
{
	my $self   = shift;
	my $parent = $self->parent();

	my $nextstate;

	for my $sibling ( $parent->get_children() )
	{
		last if $sibling eq $self;
		next unless $sibling->name() eq 'nextstate';
		$nextstate = $sibling;
	}

	return $nextstate if defined $nextstate;
	return $parent->find_nextstate();
}

sub get_line
{
	my $self      = shift;
	my $nextstate = $self->get_nextstate();
	return $nextstate->line();
}

sub get_file
{
	my $self      = shift;
	my $nextstate = $self->get_nextstate();
	return $nextstate->file();
}

sub name
{
	my $self = shift;
	my $name = $self->op()->name();
	return $name unless $name eq 'null';
	return substr( B::ppname( $self->targ() ), 3 );
}

package B::XPath::NULL;

use base 'B::XPath::Node';

package B::XPath::OP;

use base 'B::XPath::Node';

sub get_attr_names
{
	return qw( sibling ppaddr desc targ type opt static flags private spare );
}

sub get_content
{
	my $self = shift;
	return $self->name();
}

package B::XPath::UNOP;

use base 'B::XPath::Node';

sub kids
{
	my $self    = shift;
	my $op      = $self->op();
	my $first   = $op->first();

	my @kids    = $first;
	my $sibling = $first;

	while ($sibling = $sibling->sibling())
	{
		if ($sibling->isa( 'B::NULL' ) and $sibling->can( 'kids' ))
		{
			push @kids, $sibling->kids();
		}
		last if $sibling->isa( 'B::NULL' );
		push @kids, $sibling;
	}

	return @kids;
}

package B::XPath::BINOP;

use base 'B::XPath::UNOP';

sub kids
{
	my $self = shift;
	return $self->SUPER::kids();
}

package B::XPath::LOGOP;

use base 'B::XPath::UNOP';

sub kids
{
	my $self = shift;
	return $self->SUPER::kids(), $self->other();
}

package B::XPath::LISTOP;

use base 'B::XPath::BINOP';

sub kids
{
	my $self    = shift;
	my $op      = $self->op();
	my $first   = $op->first();
	my $last    = $op->last();

	my @kids    = $first;
	my $sibling = $first;

	while ($sibling = $sibling->sibling())
	{
		if ($sibling->isa( 'B::NULL' ) and $sibling->can( 'kids' ))
		{
			push @kids, $sibling->kids();
		}
		last if $sibling->isa( 'B::NULL' );
		push @kids, $sibling;
		last if $sibling == $last;
	}

	return @kids;
}

package B::XPath::LOOP;

use base 'B::XPath::LISTOP';

sub kids
{
	my $self = shift;
	my $op   = $self->op();
	return $op->nextop(), $op->lastop(), $op->redoop();
}

package B::XPath::COP;

use base 'B::XPath::OP';

sub get_attr_names
{
	my $self = shift;
	return $self->SUPER::get_attr_names(),
		qw( label stash stashpv file cop_seq arybase line warnings io );
}

package B::XPath::SVOP;

# this package is different; SVOPs contain GVs/SVs
# however, they don't look like it in the optree
# op() here thus delegates all calls to the contained GV

use base 'B::XPath::OP';

# the parent name() uses op(), which is wrong here
sub name
{
	return $_[0]->{op}->name();
}

# hey, these look like GV attributes!
sub get_attr_names
{
	my $self = shift;
	my @names = $self->SUPER::get_attr_names();
	return @names,
		qw( NAME SAFENAME STASH SV IO FORM AV HV EGV CV CVGEN LINE FILE FILEGV
		GvREFCNT FLAGS );
}

# you don't want me, you want my GV
sub op
{
	my $self = shift;
	return $self->{op}->gv();
}

package B::XPath::PADOP;

use base 'B::XPath::OP';

sub get_attr_names
{
	my $self = shift;
	return $self->SUPER::get_attr_names(), qw( padix );
}

package B::XPath::PVOP;

use base 'B::XPath::OP';

sub get_attr_names
{
	my $self = shift;
	return $self->SUPER::get_attr_names(), qw( pv );
}

package B::XPath::SV;

use base 'B::XPath::Node';

sub get_name
{
	my $self = shift;
	return $self->name();
}

sub get_root       {}
sub get_content    {}
sub get_attr_names {}

package B::XPath::IV;

use base 'B::XPath::SV';

sub get_content
{
	my $self = shift;
	my $op   = shift;
	return $op->int_value();
}

sub get_attr_names
{
	my $self  = shift;
	my @names = $self->SUPER::get_attr_names();
	return @names, qw( needs64bits packiv );
}

package B::XPath::NV;

use base 'B::XPath::IV';

sub get_content
{
	my $self = shift;
	return $self->op()->NV();
}

package B::XPath::RV;

use base 'B::XPath::SV';

sub get_content
{
	my $self = shift;
	return $self->op()->RV();
}

package B::XPath::PV;

use base 'B::XPath::SV';

sub name { 'pv' }

sub get_content
{
	my $self = shift;
	return $self->op()->PV();
}

package B::XPath::PVNV;

use base qw( B::XPath::PV B::XPath::NV );

package B::XPath::PVMG;

use base 'B::XPath::PVNV';

package B::XPath::GV;

use base 'B::XPath::PVMG';

sub name { 'gv' }

sub get_content
{
	my $self = shift;
	return $self->op()->SAFENAME();
}

sub get_attr_names
{
	my $self  = shift;
	my @names = $self->SUPER::get_attr_names();
	return @names,
		qw( NAME SAFENAME STASH SV IO FORM AV HV EGV CV CVGEN LINE FILE FILEGV
		GvREFCNT FLAGS );
}

1;
__END__

=head1 NAME

B::XPath - search Perl optrees with XPath syntax

=head1 SYNOPSIS

Perl represents programs internally as a tree of opcodes.  To execute a
program, it walks this tree, performing each operation as it encounters it.
The L<B> family of modules allows you to examine (and in some cases,
manipulate) this optree on programs I<even as they run>.

B::XPath allows you to use XPath syntax to select ops in the optree.

    use B::XPath;

    my $node    = B::XPath->fetch_root( \&some_function );
	my $root    = B::XPath->fetch_main_root();

	# find all global scalar accesses
	my @globals = $root->match( '//gvsv' );

	# find all global scalar accesses within some_function() named $bob
	my @bobs    = $node->match( '//gvsv[@NAME="bob"]' );

=head1 Class Methods

There are two methods to use to start your match; both set the root of the tree
to search.  There's also a nice helper method you'll probably never use unless
you find a bug.

=head2 C<fetch_root( $subref )>

This method returns the C<B::XPath::Node> object at the root of the optree for
the subroutine reference.  All matches performed on this node will search this
branch of the optree for matching nodes.

=head2 C<fetch_main_root()>

This method returns the C<B::XPath::Node> object at the root of the program.
Use this to search your entire program (at least, the part of it outside of any
given subroutine).

=head2 C<find_op_class( $op )>

Given a C<B::OP> or descendent object, returns the name of the appropriate
C<B::XPath::Node> subclass to use to wrap that op so that C<B::XPath> can
manipulate it appropriately.

=head1 Node Methods

There are several methods available on the nodes returned from find or match
requests.

=head2 C<match( $xpath_expression )>

Given an XPath expression, searches the tree with this node at the root to find
all nodes matching the expression.  Returns a list of all found nodes.

Note that this does I<not> return the nodes in depth-first order.  I think.

=head2 C<create( op => $op, root => $root )>

Creates a new C<B::XPath::Node> object (of the appropriate subclass), setting
the C<op> and C<root> parameters.  This will descend into all of the op's
children, calling C<create()> appropriately.

You probably don't need to know this exists unless you want to fix a bug in
the module

=head2 C<get_root()>

Returns the root node of the tree from which you searched for this node.

=head2 C<get_parent()>

Returns the parent node of this node, if it exists.  If this is a root node, it will return nothing.

=head2 C<get_children()>

Returns a list of all of the child nodes of this node, if there are any.
Otherwise it returns nothing.

=head2 C<get_name()>

Returns the name of the op that this node represents.

=head2 C<get_file()>

Returns the name of the file containing the node this op represents.  This may
not always be completely accurate, depending on certain optimizations -- but it
tries really hard.

=head2 C<get_line()>

Returns the number of the line of course code in which the node this op
represents appears.  This may not always be completely accurate, depending on
certain optimizations -- but it tries really hard.

There are a few other methods available, but I don't want to make them public
just yet.

=head1 AUTHOR

chromatic, C<< <chromatic at wgz.org> >>

=head1 BUGS

There aren't any, to my knowledge, except that this doesn't support all of
XPath.  See L<Class::XPath> for more information.

Of course, there's no guarantee that future versions of Perl will create the
same optrees ... so there's a chance that this isn't as robust as you might
like.

Please report any bugs or feature requests to C<bug-b-xpath at rt.cpan.org>, or
through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=B-XPath>.  This will notify me
and the system will automatically notify you of progress on your bug as I make
changes.

=head1 SUPPORT

You may be able to find more information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/B-XPath>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/B-XPath>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=B-XPath>

=item * Search CPAN

L<http://search.cpan.org/dist/B-XPath>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2006 chromatic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See also I<Perl Hacks>, copyright 2006 O'Reilly Media, Inc., which explains
more about how to use this module.
