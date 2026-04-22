package App::Test::Generator::Mutant;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Represents a single mutant - a specific transformation of a source file
that a test suite should be able to detect. Each mutant carries the
metadata needed to identify it, locate it in the source, and apply the
transformation to a fresh L<PPI::Document> copy at test time.

=head2 new

Construct a new mutant object.

    my $mutant = App::Test::Generator::Mutant->new(
        id          => 'NUM_BOUNDARY_10_5_!=',
        description => 'Numeric boundary flip == to !=',
        original    => '==',
        line        => 10,
        type        => 'comparison',
        group       => 'NUM_BOUNDARY:10',
        transform   => sub {
            my ($doc) = @_;
            # ... modify $doc in place ...
        },
    );

=head3 Arguments

=over 4

=item * C<id>

A unique string identifying this mutant. Required.

=item * C<description>

A human-readable description of the mutation. Required.

=item * C<original>

The original source token or expression being mutated. Required.

=item * C<line>

The line number in the source file where the mutation occurs. Required.

=item * C<transform>

A CODE reference that accepts a L<PPI::Document> and applies the
mutation to it in place. Required.

=item * C<type>

An optional string classifying the mutation kind e.g. C<comparison>,
C<boolean>.

=item * C<group>

An optional string grouping related mutants together e.g. all mutations
on the same source line.

=back

=head3 Returns

A blessed hashref representing the mutant. Croaks if any required
attribute is missing or if C<transform> is not a CODE reference.

=head3 API specification

=head4 input

    {
        id          => { type => SCALAR },
        description => { type => SCALAR },
        original    => { type => SCALAR },
        line        => { type => SCALAR },
        transform   => { type => CODEREF },
        type        => { type => SCALAR, optional => 1 },
        group       => { type => SCALAR, optional => 1 },
    }

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::Mutant',
    }

=cut

sub new {
	my ($class, %args) = @_;

	# Validate all required attributes are present
	for my $required (qw(id description original line transform)) {
		croak "Missing required attribute: $required"
			unless exists $args{$required};
	}

	# Ensure transform is actually executable
	croak 'transform must be a CODE reference'
		unless ref($args{transform}) eq 'CODE';

	return bless \%args, $class;
}

=head2 id

Return the unique identifier for this mutant.

    my $id = $mutant->id;

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Mutant' } }

=head4 output

    { type => SCALAR }

=cut

sub id          { $_[0]->{id}          }

=head2 description

Return the human-readable description of the mutation.

    my $desc = $mutant->description;

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Mutant' } }

=head4 output

    { type => SCALAR }

=cut

sub description { $_[0]->{description} }

=head2 original

Return the original source token or expression that is being mutated.

    my $orig = $mutant->original;

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Mutant' } }

=head4 output

    { type => SCALAR }

=cut

sub original    { $_[0]->{original}    }

=head2 line

Return the line number in the source file where the mutation occurs.

    my $line = $mutant->line;

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Mutant' } }

=head4 output

    { type => SCALAR }

=cut

sub line        { $_[0]->{line}        }

=head2 transform

Return the CODE reference that applies the mutation to a
L<PPI::Document> copy.

    my $xform = $mutant->transform;
    $xform->($doc_copy);

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Mutant' } }

=head4 output

    { type => CODEREF }

=cut

sub transform   { $_[0]->{transform}   }

=head2 type

Return the optional mutation type classification string,
e.g. C<comparison> or C<boolean>.

    my $type = $mutant->type;

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Mutant' } }

=head4 output

    { type => SCALAR, optional => 1 }

=cut

sub type        { $_[0]->{type}        }

=head2 group

Return the optional group string that clusters related mutants,
e.g. all mutations targeting the same source line.

    my $group = $mutant->group;

=head3 API specification

=head4 input

    { self => { type => OBJECT, isa => 'App::Test::Generator::Mutant' } }

=head4 output

    { type => SCALAR, optional => 1 }

=cut

sub group { $_[0]->{group} }

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

Portions of this module's initial design and documentation were created
with the assistance of AI.

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the terms of GPL2.
If you use it,
please let me know.

=cut

1;
