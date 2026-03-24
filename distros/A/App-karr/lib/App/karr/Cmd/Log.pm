# ABSTRACT: Show activity log

package App::karr::Cmd::Log;
our $VERSION = '0.102';
use Moo;
use MooX::Cmd;
use MooX::Options (
    usage_string => 'USAGE: karr log [--agent NAME] [--task ID] [--last N] [--json]',
);
use App::karr::Role::BoardAccess;
use App::karr::Role::Output;
use JSON::MaybeXS qw( decode_json );

with 'App::karr::Role::BoardAccess', 'App::karr::Role::Output';


option agent => (
    is => 'ro',
    format => 's',
    doc => 'Filter by agent name',
);

option task => (
    is => 'ro',
    format => 'i',
    doc => 'Filter by task ID',
);

option last => (
    is => 'ro',
    format => 'i',
    default => sub { 20 },
    doc => 'Number of entries to show (default: 20)',
);

sub execute {
    my ($self, $args_ref, $chain_ref) = @_;

    require App::karr::Git;
    my $git = App::karr::Git->new(dir => $self->board_dir->parent->stringify);

    unless ($git->is_repo) {
        print "Not a git repository. No log available.\n";
        return;
    }

    # Read all log refs
    my $refs_output = $git->_git_cmd('for-each-ref', '--format=%(refname)', 'refs/karr/log/');
    my @entries;

    if ($refs_output) {
        for my $ref (split /\n/, $refs_output) {
            my $content = $git->read_ref($ref);
            next unless $content;
            for my $line (split /\n/, $content) {
                my $entry = eval { decode_json($line) };
                push @entries, $entry if $entry;
            }
        }
    }

    # Sort by timestamp
    @entries = sort { $a->{ts} cmp $b->{ts} } @entries;

    # Apply filters
    if ($self->agent) {
        @entries = grep { ($_->{agent} // '') eq $self->agent } @entries;
    }
    if ($self->task) {
        @entries = grep { ($_->{task_id} // 0) == $self->task } @entries;
    }

    # Limit
    if ($self->last && @entries > $self->last) {
        @entries = @entries[-$self->last .. -1];
    }

    if ($self->json) {
        $self->print_json(\@entries);
        return;
    }

    unless (@entries) {
        print "No log entries.\n";
        return;
    }

    for my $e (@entries) {
        printf "%s  %-15s %-10s task#%s %s\n",
            $e->{ts} // '?',
            $e->{agent} // '?',
            $e->{action} // '?',
            $e->{task_id} // '?',
            $e->{detail} // '';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::karr::Cmd::Log - Show activity log

=head1 VERSION

version 0.102

=head1 SYNOPSIS

    karr log
    karr log --agent agent-fox
    karr log --task 12 --last 50 --json

=head1 DESCRIPTION

Reads activity entries stored in C<refs/karr/log/*> and prints a merged view of
recent actions. The command is only available when the board is inside a Git
repository because the log lives in Git refs, not in local task files.

=head1 FILTERS

=over 4

=item * C<--agent>

Only show entries recorded for a specific agent.

=item * C<--task>

Only show entries associated with a specific task id.

=item * C<--last>

Limit the output to the most recent C<N> entries after sorting by timestamp.

=back

=head1 SEE ALSO

L<karr>, L<App::karr>, L<App::karr::Cmd::Handoff>, L<App::karr::Cmd::Show>,
L<App::karr::Cmd::Board>, L<App::karr::Cmd::AgentName>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-app-karr/issues>.

=head2 IRC

Join C<#ai> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
