package App::Git::Workflow::Command::Pom;

# Created on: 2014-03-19 17:18:17
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use English qw/ -no_match_vars /;
use App::Git::Workflow::Pom;
use App::Git::Workflow::Command qw/get_options/;
use Path::Tiny;

our $VERSION = version->new(1.1.4);
our $workflow = App::Git::Workflow::Pom->new;
our ($name)   = $PROGRAM_NAME =~ m{^.*/(.*?)$}mxs;
our %option;
our %p2u_extra;

sub run {
    my ($self) = @_;
    %option = (
        pom   => $workflow->config('workflow.pom', 'pom.xml'),
        fetch => 1,
    );
    get_options(
        \%option,
        'pom|P=s',
        'update|u!',
        'skip|s=s',
        'match|m=s',
        'fetch|f!',
        'tag|t=s',
        'branch|b=s',
        'local|l!',
    ) or return;
    my $sub_command = @ARGV ? 'do_' . shift @ARGV : "do_uniq";
    $sub_command =~ s/-/_/g;

    if ( !$self->can($sub_command) ) {
        warn "Unknown sub command '$sub_command'!\n";
        App::Git::Workflow::Command::pod2usage( %p2u_extra, -verbose => 1 );
        return 1;
    }

    $workflow->{VERBOSE} = $option{verbose};
    $workflow->{TEST   } = $option{test};

    # make sure that git is up-to-date
    $workflow->git->fetch if $option{fetch};

    $self->$sub_command($option{pom}, @ARGV);

    return;
}

sub do_uniq {
    my (undef, $pom) = @_;
    my $versions  = $workflow->get_pom_versions($pom, $option{match}, $option{skip});
    my $numerical = my $version = $workflow->pom_version((scalar path($pom)->slurp), $pom, 1);
    $numerical =~ s/-SNAPSHOT$//xms;

    if ( !$versions->{$numerical} || keys %{ $versions->{$numerical} } <= 1 ) {
        print "POM Version $version is unique\n";
    }
    else {
        warn "Following branches are using version $numerical\n";
        warn "\t", join "\n\t", (sort keys %{ $versions->{$numerical} }), "\n";
        return scalar keys %{ $versions->{$numerical} };
    }

    return;
}

sub do_next {
    my (undef, $pom) = @_;

    my $version = $workflow->next_pom_version($pom);
    print "$version\n";

    if ($option{update}) {
        system(qw/mvn versions:set/, "–DnewVersion=$version");
    }

    return;
}

sub do_whos {
    my (undef, $pom, $version) = @_;

    if (!$version) {
        warn "No version supplied!\n";
        App::Git::Workflow::Command::pod2usage( %p2u_extra, -verbose => 1 );
        return 1;
    }

    $version =~ s/-SNAPSHOT$//;

    my $versions = $workflow->get_pom_versions($pom, $option{match}, $option{skip});

    my $version_re = $version =~ /^\d+[.]\d+[.]\d+/ ? qr/^$version$/ : qr/$version/;
    my %versions = map {%{ $versions->{$_} }} grep {/$version_re/} keys %{ $versions };

    print map {"$_\t$versions{$_}\n"} sort keys %versions;

    return;
}

sub do_bad_branches {
    my (undef, $pom) = @_;

    my @branches = $workflow->branches('both');
    my $max_age  = $workflow->_max_age;

    BRANCH:
    for my $branch (sort @branches) {
        my $current = $workflow->commit_details($branch);

        # Skip any branches that are over $MAX_AGE old
        if ( $current->{time} < time - $max_age ) {
            next BRANCH;
        }

        my $xml = $workflow->git->show("$branch:$pom");
        chomp $xml;
        next if !$xml;

        $branch =~ s{^origin/}{}xms;

        my $version = eval { $workflow->pom_version($xml) };

        # make sure we get a valid version
        if ( $@ ) {
            warn "$branch is bad!\n";
        }
    }

    return;
}

1;

__DATA__

=head1 NAME

git-pom - Manage pom.xml (or package.json) file versions

=head1 VERSION

This documentation refers to git-pom version 1.1.4

=head1 SYNOPSIS

   git-pom [uniq] [option]
   git-pom next [--update|-u]
   git-pom whos version [option]

 SUB-COMMAND:
  uniq          Confirm that the current branch is the only branch using its version
  next          Calculates the next available version number
  whos          Which branch uses the pom version "version"

 OPTIONS:
  -P --pom[=]file
                Specify the pom file location (Default pom.xml)
  -u --update   Update to next version (used with next)
  -t --tag[=]str
                Specify a tag that any branch with newer commits must contain
  -b --branch[=]str
                Similarly a branch that other branches with newer commits must
                contain (Default origin/master)
  -l --local    Shorthand for --branch '^master$'

  -v --verbose  Show more detailed option
     --version  Prints the version information
     --help     Prints this help information
     --man      Prints the full documentation for git-pom

=head1 DESCRIPTION

The C<git-pom> tool helps working with Maven POM files by looking at all branches to see
what versions are set. The sub commands allow different kinds of checking to be done.

=over 4

=item uniq

Check that the current branch's POM version is unique across all branches.

=item next

Finds the next available POM version number buy finding the current nighest
POM version and incrementing the second number. If C<--update> is used then
the POM version is updated to that number.

=item whos

Find which branch or branches use a POM version number.

=back

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Executes the git workflow command

=head2 C<do_whos ()>

=head2 C<do_next ()>

=head2 C<do_uniq ()>

=head2 C<do_bad_branches ($pom)>

Show branches with pom.xml files that don't pass

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

Defaults for this script can be set through C<git config>

 workflow.prod  Sets how a prod release is determined
                eg the default equivalent is branch=^origin/master$
 workflow.pom   The default location for the pom.xml file (used by C<--new-pom>
                when updating pom.xml for the new branch)

You can set these values either by editing the repository local C<.git/config>
file or C<~/.gitconfig> or use the C<git config> command

 # eg Setting the global value
    git config --global workflow.prod 'branch=^origin/master$'

 # or set a repository's local value
    git config workflow.prod 'tag=^release_\d{4}_\d{2}\d{2}$'

 # or set pom.xml location to a sub directory
    git config workflow.pom 'somedir/pom.xml'

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
