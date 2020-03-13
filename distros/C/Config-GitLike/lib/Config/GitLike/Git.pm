package Config::GitLike::Git;
use Moo;
use strict;
use warnings;

extends 'Config::GitLike';

has '+confname' => (
    default => 'gitconfig',
);

has '+compatible' => (
    default => 1,
);

sub dir_file {
    my $self = shift;
    return ".git/config" unless @_;
    my $path = shift;
    my $dir = $self->is_git_dir( $path );
    return File::Spec->catfile( $dir, "config" ) if $dir;

    $path = File::Spec->rel2abs( $path );
    return File::Spec->catfile( $path, ".git/config");
}

sub is_git_dir {
    my $self = shift;
    my $path = File::Spec->rel2abs( shift );
    $path =~ s{/+$}{};

    ($path) = grep {-d} map {"$path$_"} (".git/.git", "/.git", ".git", "");
    return unless $path;

    # Has to have objects/ and refs/ directories
    return unless -d "$path/objects" and -d "$path/refs";

    # Has to have a HEAD file
    return unless -f "$path/HEAD";

    if (-l "$path/HEAD" ) {
        # Symbolic link into refs/
        return unless readlink("$path/HEAD") =~ m{^refs/};
    } else {
        open(HEAD, "$path/HEAD") or return;
        my ($line) = <HEAD>;
        close HEAD;
        # Is either 'ref: refs/whatever' or a sha1
        return unless $line =~ m{^(ref:\s*refs/|[0-9a-fA-F]{20})};
    }
    return $path;
}

sub load_dirs {
    my $self = shift;
    my $path = shift;
    my $dir = $self->is_git_dir($path) or return;
    $self->load_file( File::Spec->catfile( $dir, "config" ) );
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

__END__

=head1 NAME

Config::GitLike::Git - load Git configuration files

=head1 SYNOPSIS

    use Config::GitLike::Git;
    my $config = Config::GitLike::Git->new;
    $config->load("/path/to/repo");

=head1 DESCRIPTION

This is a modification of L<Config::GitLike> to look at the same
locations that Git writes to. Unlike with L<Config::GitLike>, you do
not need to pass a confname to its constructor. This module also
enables the L<Config::GitLike> option to maintain git compatibility
when reading and writing variables.

L<Config::GitLike/load> should be passed path to the top level of a
git repository -- this defaults to the current directory.  It will
append C<.git> as necessary.  It supports both bare and non-bare
repositories.

=head1 METHODS

This module overrides these methods from C<Config::GitLike>:

=head2 dir_file

The per-directory configuration file is F<.git/config>.  With an
optional directory argument, will return a fully-qualified path to the
configuration file, as git would edit with C<git config --local -C path>.

=head2 user_file

The per-user configuration file is F<~/.gitconfig>

=head2 global_file

The per-host configuration file is F</etc/gitconfig>

=head2 is_git_dir

Returns true if a file contains the necessary files (as git would reckon
it) for the path to be a git repository.

=head2 load_dirs

Loads the relevant .git/config file.

=head1 SEE ALSO

L<Config::GitLike|Config::GitLike>

=head1 LICENSE

You may modify and/or redistribute this software under the same terms
as Perl 5.8.8.

=head1 COPYRIGHT

Copyright 2010 Best Practical Solutions, LLC

=head1 AUTHORS

Alex Vandiver <alexmv@bestpractical.com>,
Christine Spang <spang@bestpractical.com>
