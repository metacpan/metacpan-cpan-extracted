package App::BitBucketCli::Branch;

# Created on: 2015-11-12 07:36:10
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

our $VERSION = 0.005;

extends qw/App::BitBucketCli::Base/;

has [qw/
    displayId
    isDefault
    latestChangeset
    latestCommit
    metadata
    project
    repository
/] => (
    is  => 'rw',
);
has team => (
    is      => 'rw',
    builder => '_team',
    lazy    => 1,
);
has pull_request => (
    is      => 'rw',
    builder => '_pull_request',
    lazy    => 1,
);
has primary_job => (
    is      => 'rw',
    builder => '_primary_job',
    lazy    => 1,
);
has pr_job => (
    is      => 'rw',
    builder => '_pr_job',
    lazy    => 1,
);
has lastChangeTime => (
    is      => 'rw',
    builder => '_lastChangeTime',
    lazy    => 1,
);

sub timestamp { $_[0]->metadata->{'com.atlassian.stash.stash-branch-utils:latest-changeset-metadata'}{authorTimestamp}/1000; }
sub name      { $_[0]->displayId; }

sub _pull_request {
    my ($self) = @_;
    my $prs = $self->{metadata}{'com.atlassian.stash.stash-ref-metadata-plugin:outgoing-pull-request-metadata'};
    return 0 if !$prs;

    return 0 if exists $prs->{open};

    return App::BitBucketCli::PullRequest->new($prs->{pullRequest});
}

sub _lastChangeTime {
    my ($self) = @_;
    my $metadata = $self->metadata;

    my $time = $metadata->{'com.atlassian.stash.stash-branch-utils:latest-changeset-metadata'}{authorTimestamp};

    return $time ? int $time / 1000 : 0;
}

1;

__END__

=head1 NAME

App::BitBucketCli::Branch - Stores details about a repository's branch

=head1 VERSION

This documentation refers to App::BitBucketCli::Branch version 0.005

=head1 SYNOPSIS

   use App::BitBucketCli::Branch;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<name ()>

=head2 C<timestamp ()>

=head2 C<TO_JSON ()>

Used by L<JSON::XS> for dumping the object

=head1 ATTRIBUTES

=head2 displayId

=head2 id

=head2 isDefault

=head2 latestChangeset

=head2 latestCommit

=head2 metadata

=head2 project

=head2 repository

=head2 team

=head2 pull_request

=head2 primary_job

=head2 pr_job

=head2 lastChangeTime

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

Copyright (c) 2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
