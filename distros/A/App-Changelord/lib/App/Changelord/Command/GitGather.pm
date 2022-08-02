package App::Changelord::Command::GitGather;
our $AUTHORITY = 'cpan:YANICK';
$App::Changelord::Command::GitGather::VERSION = 'v0.0.1';
use v5.36.0;

use Moo;
use CLI::Osprey
    desc => 'gather changes from git commit messages',
    description_pod => <<'END_POD';
Inspects the git log of the current branch for commit
messages looking like change entries. If any are found, add them to the
changelog.

=head2 Lower bound of the git log

C<git-gather> will inspect the git log from the most recent of those
three points:

=over

=item The last change in the NEXT release having a C<commit> property.

=item The last tagged version.

=item The beginning of time.

=back

=head2 Change-like git message

Git messages are compared to the regular expression
configured at `project.commit_regex`. If none is found, it
defaults to

    ^(?<type>[^: ]+):(?<desc>.*?)(\[(?<ticket>[^\]]+)\])?$

The regular expression must capture a C<desc> field, and may
capture a C<type> and C<ticket> as well.

END_POD

use Path::Tiny;
use Git::Repository;

with 'App::Changelord::Role::Changelog';
with 'App::Changelord::Role::Versions';
with 'App::Changelord::Role::ChangeTypes';

has repo => (
    is => 'ro',
    default => sub { Git::Repository->new( work_tree => '.' ) },
);

has commit_regex => (
    is => 'lazy'
);

sub _build_commit_regex($self) {
    my $regex = $self->changelog->{project}{commit_regex};
    my $default = '^(?<type>[^: ]+):(?<desc>.*?)(\[(?<ticket>[^\]]+)\])?$';
    if(!$regex) {
        warn "project.commit_regex not configured, using the default /$default/\n";
        $regex = $default;
    }
    return $regex;
}

sub lower_bound($self) {
    # either the most recent commit in the current release
    my @sha1s = grep { $_ } map { $_->{commit} } grep { ref } $self->next_release->{changes}->@*;

    return pop @sha1s if @sha1s;

    return $self->latest_version;
}

sub get_commits($self,$since=undef) {
    return reverse $self->repo->run( 'log', '--pretty=format:%H %s', $since ? "$since.." : () );
}

sub munge_message($self,$message) {
    my $regex = $self->commit_regex;

    $message =~ s/(\S+) //;
    my $commit = $1;

    return () unless $message =~ qr/$regex/;

    return { %+, commit => $commit };
}

sub save_changelog($self) {
    my $src = $self->source;

    path($src)->spew( App::Changelord::Command::Init::serialize_changelog($self) );
}

sub run ($self) {

    say "let's check those git logs...";

    # figure out lower bound
    my $from = $self->lower_bound;

    say "checking since ", ( $from || 'the dawn of time' );

    my @messages = map { $self->munge_message($_) } $self->get_commits($from);

    unless(@messages) {
        say "\nno change detected";
        return;
    }

    print "\n";
    say "  * ", $_->{desc} for @messages;
    print "\n";

    push $self->next_release->{changes}->@*, @messages;

    $self->save_changelog;

    say $self->source, " updated";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Changelord::Command::GitGather

=head1 VERSION

version v0.0.1

=head1 AUTHOR

Yanick Champoux <yanick@babyl.ca>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
