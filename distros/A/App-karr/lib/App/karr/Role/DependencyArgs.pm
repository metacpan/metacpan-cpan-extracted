# ABSTRACT: Turn the dependency ids a command was given into validated numbers

package App::karr::Role::DependencyArgs;
our $VERSION = '0.500';
use Moo::Role;

# What this role calls on its consumer (ticket #128's rule): usage_error from
# App::karr::Role::ExitCodes, find_task from App::karr::Role::BoardAccess. Both
# halves of the dependency pair need find_task -- deliberately the same lookup,
# see assert_dependencies_exist below -- and nothing else is shared, which is
# why the pair is two roles (ticket #137).
requires qw( find_task usage_error );


# Ticket #124, gated on the CLI route existing; the move-time warning in
# App::karr::Role::DependencyCheck is #123.
#
# Both rejections here condemn the whole invocation rather than one id of a
# batch: a malformed or unknown dependency id is wrong for every id at once, so
# it is a usage error (exit 2) raised before anything is written -- ticket #54's
# rule, the same reason Cmd::Create runs them before allocating an id. The one
# per-id case, a self-reference, cannot live here: which id is "self" differs
# per batch id, so the caller checks it inside its batch loop (#61).
sub parse_dependency_ids {
    my ( $self, $flag, $value ) = @_;
    my ( @ids, %seen );
    for my $raw ( split /,/, $value ) {
        $self->usage_error(
            qq{invalid $flag id "$raw" (ids are comma-separated numbers)} )
            unless $raw =~ /\A[0-9]+\z/;
        # Numified on purpose: YAML::XS and JSON::MaybeXS both encode by the
        # scalar's own type, so a string "2" would round-trip as '2' / "2" --
        # which go-yaml refuses to unmarshal into kanban-md's IntSlice. Same
        # care run_batch takes when echoing batch ids. Deduplicated here, once
        # for every flag, so `--depends-on 2,2` cannot store [2,2]: a repeated
        # id carries no meaning in any of the three flags, and edit's
        # append-unique only guards against ids the card already carries.
        push @ids, $raw + 0 unless $seen{ $raw + 0 }++;
    }
    $self->usage_error("$flag requires at least one id") unless @ids;
    return \@ids;
}


sub assert_dependencies_exist {
    my ( $self, $ids ) = @_;
    for my $dep_id (@$ids) {
        $self->usage_error(
            "dependency task $dep_id does not exist on this board" )
            unless $self->find_task($dep_id);
    }
    return $ids;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Role::DependencyArgs - Turn the dependency ids a command was given into validated numbers

=head1 VERSION

version 0.500

=head1 DESCRIPTION

The set-time half of karr's dependency handling: what C<--depends-on>,
C<--add-depends-on> and C<--remove-depends-on> mean between the command line
and C<< $task->depends_on >>. Composed by L<App::karr::Cmd::Create> and
L<App::karr::Cmd::Edit>, the only two commands that take those options.

Its sibling is L<App::karr::Role::DependencyCheck>, which reads the field back
when a card is taken up. kanban-md does both too (C<ValidateDependencyIDs>,
F<internal/task/validate.go>:155): set-time catches a typo while the author
still remembers what they meant, move-time catches state that changed
afterwards, which set-time can never see.

=head2 Why it is not one role with the check

The two halves have different contracts. This one reports through
L<App::karr::Role::ExitCodes/usage_error> -- it refuses the invocation and
nothing is written -- while the checking half prints a warning, proceeds, and
therefore needs the command's output options (C<--json>, C<--quiet>) to decide
which channel the warning goes out of. Carrying both in one role meant the
C<requires> line could only name what B<every> consumer had, so C<json> could
not be required at all: C<create> composed the role for these two helpers
alone and has no C<--json> (ticket #137). Split, each half declares its own
collaborators in full, and C<create> no longer inherits two methods it must
never call.

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Role::DependencyCheck>,
L<App::karr::Cmd::Create>, L<App::karr::Cmd::Edit>

=head2 parse_dependency_ids

    my $ids = $self->parse_dependency_ids( '--depends-on', $self->depends_on );

Splits a comma-separated dependency option value into an arrayref of numeric
ids, in order, duplicates collapsed. A value that is not a plain number is a
usage error naming the flag and the value, raised before any task is touched
-- it condemns the invocation, never one id of a batch. The ids are returned
as numbers so they round-trip numerically through the frontmatter and
C<--json> (kanban-md models the field as an C<IntSlice>).

=head2 assert_dependencies_exist

    $self->assert_dependencies_exist($ids);

Usage error unless every id names a task on this board, archived included --
the same L<App::karr::Role::BoardAccess/find_task> lookup
L<App::karr::Role::DependencyCheck/check_dependencies> resolves ids with, so
set-time and move-time can never disagree about what exists. Called with ids
that are about to be B<added>; removing an id the board no longer has must stay
legal, because that is how a dependency on a deleted task is cleaned up.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/karr/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
