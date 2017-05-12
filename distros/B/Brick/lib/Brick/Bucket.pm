package Brick::Bucket;
use strict;

use base qw(Exporter);
use subs qw();
use vars qw($VERSION);

use Carp;

use Brick::Constraints;

foreach my $package ( qw(Numbers Regexes Strings Dates General
	Composers Filters Selectors Files) )
	{
	# print STDERR "Requiring $package\n";
	eval "require Brick::$package";
	print STDERR $@ if $@;
	}

$VERSION = '0.227';

=encoding utf8

=head1 NAME

Brick::Bucket - The thing that keeps everything straight

=head1 SYNOPSIS

	use Brick::Bucket;

	my $bucket = Brick::Bucket->new();

=head1 DESCRIPTION

=head2 Class methods

=over 4

=item new()

Creates a new bucket to store Brick constraints

=cut

sub new
	{
	my( $class ) = @_;

	my $self = bless {}, $class;

	$self->_init;

	$self;
	}

sub _init
	{
	my $self = shift;

	$self->{_names}        = {};
	$self->{_field_labels} = {};
	}

=item entry_class


Although this is really a class method, it's also an object method because
Perl doesn't know the difference. The return value, however, isn't designed
to be mutable. You may want to change it in a subclass, but the entire system
still needs to agree on what it is. Since I don't need to change it (although
I don't want to hard code it either), I have a method for it. If you need
something else, figure out the consequences and see if this could work another
way.

=cut

sub entry_class { __PACKAGE__ . "::Entry"; }

=back

=head2 Object methods

=over 4

=item add_to_bucket( HASHREF )

=item add_to_pool # DEPRECATED

You can pass these entries in the HASHREF:

	code        - the coderef to add to the bucket
	name        - a name for the entry, which does not have to be unique
	description - explain what this coderef does
	args        - a reference to the arguments that the coderef closes over
	fields      - the input field names the coderef references
	unique      - this name has to be unique

If you pass a true value for the C<unique> value, then there can't be
any other brick with that name already, or a later brick which tries to
use the same name will fail.

The method adds these fields to the entry:

	gv          - a GV reference from B::svref_2object($sub), useful for
				finding where an anonymous coderef came from

	created_by  - the name of the routine that added the entry to the bucket

It returns the subroutine reference.

=cut

sub add_to_pool { croak "add_to_pool is now add_to_bucket" }

sub add_to_bucket
	{
	require B;
	my @caller = __caller_chain_as_list();
	# print STDERR Data::Dumper->Dump( [\@caller],[qw(caller)] );
	my( $bucket, $setup ) = @_;

	my( $sub, $name, $description, $args, $fields, $unique )
		= @$setup{ qw(code name description args fields unique) };

	$unique ||= 0;

	unless( defined $name )
		{
		my $default = '(anonymous)';
		#carp "Setup does not specify a 'name' key! Using $default";
		$name   ||= $default;
		}

	# ensure we have a sub first
	unless( ref $sub eq ref sub {} )
		{
		#print STDERR Data::Dumper->Dump( [$setup],[qw(setup)] );
		croak "Code ref [$sub] is not a reference! $caller[1]{sub}";
		}
	# and that the name doesn't exist already if it's to be unique
	elsif( $unique and exists $bucket->{ _names }{ $name } )
		{
		croak "A brick named [$name] already exists";
		}
	# or the name isn't unique already
	elsif( exists $bucket->{ _names }{ $name } and $bucket->{ _names }{ $name } )
		{
		croak "A brick named [$name] already exists";
		}
	# and that the code ref isn't already in there
	elsif( exists $bucket->{ $sub } )
		{
		no warnings;
		my $old_name = $bucket->{ $sub }{name};
		}

	my $entry = $bucket->{ $sub } || $bucket->entry_class->new( $setup );

	$entry->{code}   = $sub;
	$entry->{unique} = $unique;

	$entry->set_name( do {
		if( defined $name ) { $name }
		elsif( defined $entry->get_name ) { $entry->get_name }
		elsif( ($name) = map { $_->{'sub'} =~ /^__|add_to_bucket/ ? () :  $_->{'sub'} } @caller )
			{
			$name;
			}
		else
			{
			"Unknown";
			}
		} );

	$entry->set_description(
		$entry->get_description
		  ||
		$description
		  ||
		"This spot left intentionally blank by a naughty programmer"
		);

	$entry->{created_by} ||= [ map { $_->{'sub'} =~ /add_to_bucket/ ? () :  $_->{'sub'} } @caller ];

	$entry->set_gv( B::svref_2object($sub)->GV );

	$bucket->{ $sub } = $entry;
	$bucket->{ _names }{ $name } = $unique;
	$sub;
	}

=item get_from_bucket( CODEREF )

Gets the entry for the specified CODEREF. If the CODEREF is not in the bucket,
it returns false.

The return value is an entry instance.

=cut

sub get_from_bucket
	{
	my( $bucket, $sub ) = @_;

	return exists $bucket->{$sub} ? $bucket->{$sub} : ();
	}

=item get_brick_by_name( NAME )

Gets the code references for the bricks with the name NAME. Since
bricks don't have to have a unique name, it might return more than
one.

In list context return the bricks with NAMe, In scalar context
returns the number of bricks it found.

=cut

sub get_brick_by_name
	{
	my( $bucket, $name ) = @_;

	my @found;

	foreach my $key ( $bucket->get_all_keys )
		{
		#print STDERR "Got key $key\n";
		my $brick = $bucket->get_from_bucket( $key );
		#print STDERR Data::Dumper->Dump( [$brick], [qw(brick)] );

		next unless $brick->get_name eq $name;

		push @found, $brick->get_coderef;
		}

	wantarray ? @found : scalar @found;
	}

=item get_all_keys

Returns an unordered list of the keys (entry IDs) in the bucket.
Although you probably know that the bucket is a hash, use this just in
case the data structure changes.

=cut

sub get_all_keys { grep { ! /^_/ } keys %{ $_[0] } }

=item comprise( COMPOSED_CODEREF, THE_OTHER_CODEREFS )

Tell the bucket that the COMPOSED_CODEREF is made up of THE_OTHER_CODEREFS.

	$bucket->comprise( $sub, @component_subs );

=cut

sub comprise
	{
	my( $bucket, $compriser, @used ) = @_;

	$bucket->get_from_bucket( $compriser )->add_bit( @used );
	}


=item dump_bucket

Show the names and descriptions of the entries in the bucket. This is
mostly a debugging tool.

=cut

sub dump_bucket
	{
	my $bucket = shift;

	foreach my $key ( $bucket->get_all_keys )
		{
		my $brick = $bucket->get_from_bucket( $key );

		print $brick->get_name, " --> $key\n";
		print $brick->get_description, "\n";
		}

	1;
	}

=back

=head2 Field labels

The bucket can store a dictionary that maps field names to arbitrary
strings. This way, a brick can translate and input parameter name
(e.g. a CGI input field name) into a more pleasing string for humans
for its error messages. By providing methods in the bucket class,
every brick has a chance to call them.

=over 4

=item use_field_labels( HASHREF )

Set the hash that C<get_field_label> uses to map field names to
field labels.

This method croaks if its argument isn't a hash reference.

=cut

sub use_field_labels
	{
	croak "Not a hash reference!" unless UNIVERSAL::isa( $_[1], ref {} );
	$_[0]->{_field_labels} = { %{$_[1]} };
	}

=item get_field_label( FIELD )

Retrieve the label for FIELD.

=cut

sub get_field_label
	{
	no warnings 'uninitialized';
	$_[0]->{_field_labels}{ $_[1] };
	}

=item set_field_label( FIELD, VALUE )

Set the label for FIELD to VALUE. It returns VALUE.

=cut

sub set_field_label
	{
	$_[0]->{_field_labels}{ $_[1] } = $_[2];
	}

sub __caller_chain_as_list
	{
	my $level = 0;
	my @Callers = ();

	while( 1 )
		{
		my @caller = caller( ++$level );
		last unless @caller;

		push @Callers, {
			level   => $level,
			package => $caller[0],
			'sub'   => $caller[3] =~ m/(?:.*::)?(.*)/,
			};
		}

	#print STDERR Data::Dumper->Dump( [\@Callers], [qw(callers)] ), "-" x 73, "\n";
	@Callers;
	}

=back

=head1 Brick::Bucket::Entry

=cut

package Brick::Bucket::Entry;

use Carp qw(carp);

=over 4

=item my $entry = Brick::Bucket::Entry->new( HASHREF )

=cut

sub new
	{
	my $class = shift;

	my $self = bless {}, $class;

	$self->{comprises} ||= [];

	$self;
	}


=item $entry->get_gv()

Get the GV object associated with the entry. The GV object comes from
the svref_2object(SVREF) function in the C<B> module. Use it to get
information about the coderef's creation.

	my $entry = $bucket->get_entry( $coderef );
	my $gv    = $entry->get_gv;

	printf "$coderef comes from %s line %s\n",
		map { $gv->$_ } qw( FILE LINE );

The C<B> documentation explains what you can do with the GV object.

=cut

sub get_gv          { $_[0]->{gv}  || Object::Null->new }

=item $entry->get_name()

Get the name for the entry.

=cut

sub get_name        { $_[0]->{name}        }

=item $entry->get_description()

Get the description for the entry.

=cut

sub get_description { $_[0]->{description} }

=item $entry->get_coderef()

Get the coderef for the entry. This is the actual reference that you
can execute, not the string form used for the bucket key.

=cut

sub get_coderef     { $_[0]->{code}        }

=item $entry->get_comprises()

Get the subroutines that this entry composes. A coderef might simply
combine other code refs, and this part gives the map. Use it recursively
to get the tree of code refs that make up this entry.

=cut

sub get_comprises   { $_[0]->{comprises}   }

=item $entry->get_created_by()

Get the name of the routine that added the entry to the bucket. This
is handy for tracing the flow of code refs around the program. Different
routines my make coderefs with the same name, so you also want to know
who created it. You can use this with C<get_gv> to get file and line numbers
too.

=cut

sub get_created_by  { ref  $_[0]->{created_by} ? $_[0]->{created_by} : [] }

=item $entry->get_fields()

=cut

sub get_fields      { [ keys %{ $_[0]->entry( $_[1] )->{fields} } ] }

=item $entry->set_name( SCALAR )

Set the entry's name. Usually this happens when you add the object
to the bucket, but you might want to update it to show more specific or higher
level information. For instance, if you added the code ref with a low
level routine that named the entry "check_number", a higher order routine
might want to reuse the same entry but pretend it created it by setting
the name to "check_integer", a more specific sort of check.

=cut

sub set_name        { $_[0]->{name}        = $_[1] }

=item $entry->set_description( SCALAR )

Set the entry's description. Usually this happens when you add the object
to the bucket, but you might want to update it to show more specific or higher
level information. See C<get_name>.

=cut

sub set_description { $_[0]->{description} = $_[1] }

=item $entry->set_gv( SCALAR )

Set the GV object for the entry. You probably don't want to do this
yourself. The bucket does it for you when it adds the object.

=cut

sub set_gv          { $_[0]->{gv}          = $_[1] }

=item $entry->add_bit( CODEREFS )

I hate this name, but this is the part that adds the CODEREFS to the
entry that composes it.

=cut

sub add_bit
	{
	my $entry = shift;
	no warnings;

	# can things get in here twice
	push @{ $entry->{comprises} }, map { "$_" } @_;
	}

=item $entry->dump

Print a text version of the entry.

=cut

sub dump
	{
	require Data::Dumper;

	Data::Dumper->Dump( [ $_[0]->entry( $_[1] ) ], [ "$_[1]" ] )
	}

=item $entry->applies_to_fields

Return a list of fields the brick applies to.

I don't think I've really figured this out, but the composers should be
the ones to figure it out and add this stuff to the information that the
bucket tracks.

=cut

sub applies_to_fields
	{
	my( $class, $sub, @fields ) = @_;

	foreach my $field ( @fields )
		{
		$class->registry->{$sub}{fields}{$field}++;
		$class->registry->{_fields}{$field}{$sub}++;
		}
	}


=back

=head1 TO DO

TBA

=head1 SEE ALSO

TBA

=head1 SOURCE AVAILABILITY

This source is in Github:

	https://github.com/briandfoy/brick

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2007-2014, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

1;
