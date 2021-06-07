package App::PS1::Plugin::Branch;

# Created on: 2011-06-21 09:48:47
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use English qw/ -no_match_vars /;
use Path::Tiny;
use Term::ANSIColor qw/color/;

our $VERSION = 0.08;

sub branch {
    my ($self, $options) = @_;
    my ($type, $branch);
    my $dir = eval { path('.')->realpath };
    my $git = git();
    my $cvs = cvs();
    while ( $dir ne $dir->parent ) {
        if ( -f $dir->child('.git', 'HEAD') ) {
            $type = 'git';
            $branch = $dir->child('.git')->child('HEAD')->slurp;
            chomp $branch;
            $branch =~ s/^ref: \s+ refs\/heads\/(.*)/$1/xms;
            if ( length $branch == 40 && $branch =~ /^[\da-f]+$/ ) {
                my ($ans) = map {/^[*] [(]detached from (.*)[)]$/; $1} grep {/^[*]\s/} `$git branch --contains $branch`;
                $branch = "[$ans]" if $ans;
            }
        }
        elsif (-f $dir->child('CVS', 'Tag')) {
            $type = 'cvs';
            $branch = $dir->child('CVS', 'Tag')->slurp;
            chomp $branch;
            $branch =~ s/^N//;
            $branch = "($branch)";
        }
        elsif (-f $dir->child('CVS', 'Root')) {
            $type   = 'cvs';
            $branch = 'master';
        }

        last if $type;
        $dir = $dir->parent;
    }

    return if !$type;

    $type = $self->cols && $self->cols > 40 ? "$type " : '';

    my $max_branch_width = ( $self->cols || 80 ) / 3;
    if ($max_branch_width > 60) {
        $max_branch_width = 60;
    }
    if ( length $branch > $max_branch_width ) {
        if ( $options->{summarize} ) {
            $branch =~ s{^(\w)(?:[^/]+)/}{$1/};
        }
        if ( length $branch > $max_branch_width ) {
            $branch = substr $branch, 0, $max_branch_width;
            $branch .= '...';
        }
    }

    my ($len, $status) = status($type);
    return $self->surround(
        $len + length $type . $branch,
        $self->colour('branch_label') . $type
        . $self->colour('branch') . $branch
        . $status
    );
}

sub status {
    my ($type) = @_;
    return (0, '') if $type ne 'git ';

    my %status = (
        staged    => 0,
        unstaged  => 0,
        untracked => 0,
    );
    my @status = `git status --porcelain`;
    for my $status (@status) {
        my ($staged, $unstaged) = $status =~ /^(.)(.)/;
        $status{staged}++ if $staged ne '?' && $staged ne ' ';
        $status{unstaged}++ if $unstaged ne '?' && $unstaged ne ' ';
        $status{untracked}++ if $staged eq '?' && $unstaged eq '?';
    }

    my @chars = (' ', '①','②','③','④','⑤','⑥','⑦','⑧','⑨','⑩','⑪','⑫','⑬','⑭','⑮','⑯','⑰','⑱','⑲','⑳','㉑','㉒','㉓','㉔','㉕','㉖','㉗','㉘','㉙','㉚','㉛','㉜','㉝','㉞','㉟', '∞');
    my $str = '';
    $str .= ' ' . color('green') . ($chars[$status{staged}   ] || $chars[36]) if $status{staged};
    $str .= ' ' . color('red'  ) . ($chars[$status{unstaged} ] || $chars[36]) if $status{unstaged};
    $str .= ' ' . color('white') . ($chars[$status{untracked}] || $chars[36]) if $status{untracked};

    return (
        (! $status{staged}    ? 0 : $status{staged}    > 20 ? 3 : 2) +
        (! $status{unstaged}  ? 0 : $status{unstaged}  > 20 ? 3 : 2) +
        (! $status{untracked} ? 0 : $status{untracked} > 20 ? 3 : 2),
        $str
    );
}

sub git {
    for (split /:/, $ENV{PATH}) {
        return "$_/git" if -x "$_/git";
    }
    return 'git';
}

sub cvs {
    for (split /:/, $ENV{PATH}) {
        return "$_/cvs" if -x "$_/cvs";
    }
    return 'cvs';
}

1;

__END__

=head1 NAME

App::PS1::Plugin::Branch - Adds the current branch to prompt

=head1 VERSION

This documentation refers to App::PS1::Plugin::Branch version 0.08.

=head1 SYNOPSIS

   use App::PS1::Plugin::Branch;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<branch ()>

If the current is under source code control returns the current branch etc

=head3 C<git ()>

Returns the full path for the git executable

=head3 C<cvs ()>

Returns the full path for the cvs executable

=head3 C<status ()>

Adds a status of the number of changes present for git repositories.

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

Copyright (c) 2011 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia 2077)
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
