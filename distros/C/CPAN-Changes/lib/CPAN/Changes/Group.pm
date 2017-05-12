package CPAN::Changes::Group;

use strict;
use warnings;

use Text::Wrap   ();

sub new {
    my $class = shift;
    return bless {
        changes    => [],
        @_,
    }, $class;
}

# Intentionally read only
# to prevent hash key and name being out of sync.
sub name {
    my $self = shift;
    if ( not exists $self->{ name } ) {
      $self->{ name } = q[];
    }
    return $self->{ name };
}

sub changes {
    my $self = shift;
    return $self->{ changes };
}

sub add_changes {
    my $self  = shift;
    push @{ $self->{ changes } }, @_;
}

sub set_changes {
    my $self  = shift;
    $self->{ changes } = \@_;
}

sub clear_changes {
    my $self = shift;
    $self->{ changes } = [];
}

sub is_empty {
    my $self = shift;
    return !@{ $self->changes };
}

sub serialize {
    my $self = shift;
    my %args = @_;

    my $output = '';
    my $name = $self->name;
    $output .= sprintf " [%s]\n", $name if length $name;
    # change logs commonly have long URLs we shouldn't break, and by default
    # Text::Wrap wraps on NONBREAKING SPACE.
    local $Text::Wrap::break = '[\t ]';
    local $Text::Wrap::huge = 'overflow';
    $output .= Text::Wrap::wrap( ' - ', '   ', $_ ) . "\n" for @{ $self->changes };

    return $output;
}

1;

__END__

=head1 NAME

CPAN::Changes::Group - A group of related change information within a release

=head1 SYNOPSIS

    my $rel = CPAN::Changes::Release->new(
        version => '0.01',
        date    => '2009-07-06',
    );

    my $grp = CPAN::Changes::Group->new(
        name => 'BugFixes',
    );

    $grp->add_changes(
      'Return a Foo object instead of a Bar object in foobar()'
    );

    $rel->attach_group( $grp ); # clobbers existing group if present.

=head1 DESCRIPTION

A release is made up of several groups. This object provides access
to all of the key data that embodies a such a group.

For instance:

  0.27 2013-12-13

  - Foo

  [ Spec Changes ]

  - Bar

Here, there are two groups, the second one, C< Spec Changes > and the first with the empty label C<q[]>.

=head1 METHODS

=head2 new( %args )

Creates a new group object, using C<%args> as the default data.

  Group->new(
      name => 'Some Group Name',
      changes    => [ ],
  );

=head2 name()

Returns the name of the group itself.

=head2 changes( [ $group ] )

Gets the list of changes for this group as an arrayref of changes.

=head2 add_changes( @changes )

Appends a list of changes to the group.

    $group->add_changes( 'Added foo() function' );

=head2 set_changes( @changes )

Replaces the existing list of changes with the supplied values.

=head2 clear_changes( )

Clears all changes from the group.

=head2 groups( sort => \&sorting_function )

Returns a list of current groups in this release.

=head2 is_empty()

Returns whether or not the given group has changes.

=head2 serialize()

Returns the group data as a string, suitable for inclusion in a Changes
file.

=head1 SEE ALSO

=over 4

=item * L<CPAN::Changes::Release>

=item * L<CPAN::Changes::Spec>

=item * L<CPAN::Changes>

=item * L<Test::CPAN::Changes>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2011-2013 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
