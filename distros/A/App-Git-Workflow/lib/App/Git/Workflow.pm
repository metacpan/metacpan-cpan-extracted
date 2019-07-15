package App::Git::Workflow;

# Created on: 2014-03-11 22:09:32
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use autodie;
use Carp qw/carp croak cluck confess longmess/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use App::Git::Workflow::Repository qw//;
use base qw/Exporter/;

our $VERSION   = version->new(1.1.4);

sub _alphanum_sort {
    no warnings qw/once/;
    my $A = $a;
    $A =~ s/(\d+)/sprintf "%014i", $1/egxms;
    my $B = $b;
    $B =~ s/(\d+)/sprintf "%014i", $1/egxms;

    return $A cmp $B;
}

sub new {
    my $class = shift;
    my %param = @_;
    my $self  = \%param;

    bless $self, $class;

    $self->{TEST}     = 0;
    $self->{VERBOSE}  = 0;
    $self->{GIT_DIR}  = '.git';
    $self->{branches} = undef;
    $self->{tags}     = undef;
    $self->{settings_dir} = ($ENV{HOME} || "/tmp/") . '/.git-workflow';
    mkdir $self->{settings_dir} if !-d $self->{settings_dir};

    return $self;
}

sub git { $_[0]->{git} || ($_[0]->{git} = App::Git::Workflow::Repository->git); }

sub branches {
    my ($self, $type, $contains) = @_;
    $type ||= 'local';
    my @options
        = $type eq 'local'  ? ()
        : $type eq 'remote' ? ('-r')
        : $type eq 'both'   ? ('-a')
        :                     confess "Unknown type '$type'!\n";

    if ($contains) {
        push @options, "--contains", $contains;
        $type .= $contains;
    }

    # assign to or cache
    $self->{branches}{$type} = [
        sort _alphanum_sort
        map { /^[*]?\s+(?:remotes\/)?(.*?)\s*$/xms }
        grep {!/HEAD/}
        $self->git->branch(@options)
    ] if !$self->{branches}{$type};

    return @{ $self->{branches}{$type} };
}

sub tags {
    my ($self) = @_;
    # assign to or cache
    $self->{tags} = [
        sort _alphanum_sort
        #map { /^(.*?)\s*$/xms }
        $self->git->tag
    ] if !$self->{tags} || !@{ $self->{tags} };

    return @{ $self->{tags} };
}

sub current {
    my ($self) = @_;
    # get the git directory
    my $git_dir = $self->git->rev_parse("--show-toplevel");
    chomp $git_dir;

    # read the HEAD file to find what branch or id we are on
    open my $fh, '<', "$git_dir/$self->{GIT_DIR}/HEAD";
    my $head = <$fh>;
    close $fh;
    chomp $head;

    if ($head =~ m{ref: refs/heads/(.*)$}) {
        return ('branch', $1);
    }

    # try to identify the commit as it's not a local branch
    open $fh, '<', "$git_dir/$self->{GIT_DIR}/FETCH_HEAD";
    while (my $line = <$fh>) {
        next if $line !~ /^$head/;

        my ($type, $name, $remote) = $line =~ /(tag|branch) \s+ '([^']+)' \s+ of \s+ (.*?) $/xms;
        # TODO calculate the remote's alias rather than assume that it is "origin"
        return ($type, $type eq 'branch' ? "origin/$name" : $name);
    }

    # not on a branch or commit
    return ('sha', $head);
}

sub config {
    my ($self, $name, $default) = @_;
    my $value = $self->git->config($name);

    return $value || $default;
}

sub match_commits {
    my ($self, $type, $regex, %option) = @_;
    $option{max_history} ||= 1;
    $option{branches}      = defined $option{branches} ? $option{branches} : 1;
    my @commits = grep {/$regex/} $type eq 'tag' ? $self->tags() : $self->branches('both');

    my $oldest = @commits > $option{max_history} ? -$option{max_history} : -scalar @commits;
    return map { $self->commit_details($_, branches => $option{branches}) } @commits[ $oldest .. -1 ];
}

sub release {
    my ($self, $tag_or_branch, $local, $search) = @_;
    my @things
        = $tag_or_branch eq 'branch'
        ? $self->branches($local ? 'local' : 'remote')
        : $self->tags();
    my ($release) = reverse grep {/$search/} @things;
    chomp $release;

    return $release;
}

sub releases {
    my ($self, %option) = @_;
    my ($type, $regex);
    if ($option{tag}) {
        $type = 'tag';
        $regex = $option{tag};
    }
    elsif ($option{branch}) {
        $type = 'branch';
        $regex = $option{branch};
    }
    else {
        my $prod = $self->config('workflow.prod') || ( $option{local} ? 'branch=^master$' : 'branch=^origin/master$' );
        ($type, $regex) = split /\s*=\s*/, $prod;
        if ( !$regex ) {
            $type = 'branch';
            $regex = '^origin/master$';
        }
    }

    my @releases = $self->match_commits($type, $regex, %option);
    die "Could not find any historic releases for $type /$regex/!\n" if !@releases;
    return @releases;
}

sub commit_details {
    my ($self, $name, %options) = @_;
    my $split = "\1";
    my $fmt = $options{user} ? "%ct$split%H$split%an$split%ae$split" : "%ct$split%H$split$split$split";
    my ($time, $sha, $user, $email, $files)
        = split /$split/, $self->git->log(
            "--format=format:$fmt",
            -1,
            ($options{files} ? '--name-only' : ()),
            $name
        );

    return {
        name     => $name,
        sha      => $sha,
        time     => $time,
        user     => $user,
        email    => $email,
        files    => { map {$_ => 1} grep {$_} split "\n", $files || '' },
        branches => $options{branches} ? { map { $_ => 1 } $self->branches('both', $sha) } : {},
    };
}

sub files_from_sha {
    my ($self, $sha) = @_;
    my $show = $self->git->show('--name-status', $sha);
    $show =~ s/\A.*\n\n//xms;
    my %files;
    for my $file (split /\n/, $show) {
        my ($state, $file) = split /\s+/, $file, 2;
        $files{$file} = $state;
    }

    return \%files;
}

sub slurp {
    my ($self, $file) = @_;
    open my $fh, '<', $file;

    return wantarray ? <$fh> : do { local $/; <$fh> };
}

sub spew {
    my ($self, $file, @out) = @_;
    die "No file passed!" if !$file;
    open my $fh, '>', $file;

    print $fh @out;
}

sub settings {
    my ($self) = @_;
    return $self->{settings} if $self->{settings};

    my $key = $self->git->config('remote.origin.url');
    chomp $key if $key;
    if ( !$key ) {
        $key = $self->git->rev_parse("--show-toplevel");
        chomp $key;
    }
    $key = $self->_url_encode($key);

    $self->{settings_file} = "$self->{settings_dir}/$key";

    $self->{settings}
        = -f $self->{settings_file}
        ? do $self->{settings_file}
        : {};

    if ( $self->{settings}->{version} && version->new($self->{settings}->{version}) > $App::Git::Workflow::VERSION ) {
        die "Current settings created with newer version than this program!\n";
    }

    return $self->{settings};
}

sub save_settings {
    my ($self) = @_;
    return if !$self->{settings_file};
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Sortkeys = 1;
    $self->{settings}->{version} = $App::Git::Workflow::VERSION;
    $self->{settings}->{date} = time;
    $self->spew($self->{settings_file}, 'my ' . Dumper $self->{settings});
}

sub _url_encode {
    my ($self, $url) = @_;
    $url =~ s/([^-\w.:])/sprintf "%%%x", ord $1/egxms;
    return $url;
}

sub DESTROY {
    my ($self) = @_;
    $self->save_settings();
}

1;

__END__

=head1 NAME

App::Git::Workflow - Git workflow tools

=head1 VERSION

This documentation refers to App::Git::Workflow version 1.1.4

=head1 SYNOPSIS

   use App::Git::Workflow qw/branches tags/;

   # Get all local branches
   my @branches = $self->branches();
   # or
   @branches = $self->branches('local');

   # remote branches
   @branches = $self->branches('remote');

   # both remote and local branches
   @branches = $self->branches('both');

   # similarly for tags
   my @tags = $self->tags();

=head1 DESCRIPTION

This module contains helper functions for the command line scripts.

=head1 SUBROUTINES/METHODS

=head2 C<new (%params)>

Create a new C<App::Git::Workflow::Pom> object

=head2 C<git ()>

Get the git repository object

=head2 C<branches ([ $type ])>

Param: C<$type> - one of local, remote or both

Returns a list of all branches of the specified type. (Default type is local)

=head2 C<tags ()>

Returns a list of all tags.

=head2 C<_alphanum_sort ()>

Does sorting (for the building C<sort>) in a alpha numerical fashion.
Specifically all numbers are converted for the comparison to 14 digit strings
with leading zeros.

=head2 C<children ($dir)>

Get the child files of C<$dir>

=head2 C<config ($name, $default)>

Get the git config value of C<$name>, or if not set C<$default>

=head2 C<current ()>

Get the current branch/tag or commit

=head2 C<match_commits ($type, $regex, $max)>

=head2 C<release ($tag_or_branch, $local, $search)>

=head2 C<releases (%option)>

=head2 C<commit_details ($name)>

Get info from C<git show $name>

=head2 C<files_from_sha ($sha)>

Get the files changed by the commit

=head2 C<slurp ($file)>

Return the contents of C<$file>

=head2 C<spew ( $file, @data )>

Write C<@data> to the file C<$file>

=head2 C<settings ()>

Get the saved settings for the current repository

=head2 C<save_settings ()>

Save any changed settings for the current repository

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
