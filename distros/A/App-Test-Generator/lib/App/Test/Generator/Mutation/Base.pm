package App::Test::Generator::Mutation::Base;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Abstract base class for all mutation strategies in
App::Test::Generator. Subclasses must implement both
C<applies_to> and C<mutate>.

=head2 new

Construct a new mutation strategy object.

    my $strategy = My::Mutation::Subclass->new;

=head3 Arguments

None.

=head3 Returns

A blessed hashref of the subclass type.

=head3 API specification

=head4 input

    {}

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::Mutation::Base',
    }

=cut

sub new { bless {}, shift }

=head2 applies_to

Return true if this mutation strategy applies to the
given PPI document. Subclasses must override this method.

    if ($strategy->applies_to($doc)) {
        my @mutants = $strategy->mutate($doc);
    }

=head3 Arguments

=over 4

=item * C<$doc>

A L<PPI::Document> object.

=back

=head3 Returns

A boolean. Croaks if called on the base class directly.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::Base' },
        doc  => { type => OBJECT, isa => 'PPI::Document' },
    }

=head4 output

    { type => SCALAR }

=cut

sub applies_to {
	croak ref(shift) . '::applies_to() must be implemented by subclass';
}

=head2 mutate

Generate and return a list of mutants for the given PPI
document. Subclasses must override this method.

    my @mutants = $strategy->mutate($doc);

=head3 Arguments

=over 4

=item * C<$doc>

A L<PPI::Document> object representing the source file
to mutate. Must not be modified by this method.

=back

=head3 Returns

A list of L<App::Test::Generator::Mutant> objects.
Croaks if called on the base class directly.

=head3 API specification

=head4 input

    {
        self => { type => OBJECT, isa => 'App::Test::Generator::Mutation::Base' },
        doc  => { type => OBJECT, isa => 'PPI::Document' },
    }

=head4 output

    {
        type     => ARRAYREF,
        elements => { type => OBJECT, isa => 'App::Test::Generator::Mutant' },
    }

=cut

sub mutate {
	croak ref(shift) . '::mutate() must be implemented by subclass';
}

1;
