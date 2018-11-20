package App::BitBucketCli::PullRequest;

# Created on: 2015-09-16 16:41:19
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;

our $VERSION = 0.007;

extends qw/App::BitBucketCli::Base/;

has [qw/
    state
    toRef
    closed
    version
    attributes
    open
    fromRef
    updatedDate
    createdDate
    title
    reviewers
    participants
    author
/] => (
    is  => 'rw',
);

sub emails {
    my $self = shift;
    my %emails;

    my %email;
    for my $users (qw/author participants reviewers/) {
        if ( !$self->$users ) {
            warn "No $users in " . $self->from_branch . "!\n";
            next;
        }
        $self->$users( [$self->{$users}] ) if ref $self->$users ne 'ARRAY';

        for my $user (@{ $self->{$users} }) {
            $emails{ $user->{user}{emailAddress} }++;
        }
    }

    return [ sort keys %emails ];
}

sub from_branch     { $_[0]->fromRef->{displayId}; }
sub to_branch       { $_[0]->toRef->{displayId}; }
sub from_repository { $_[0]->fromRef->{repository}{name}; }
sub to_repository   { $_[0]->toRef->{repository}{name}; }
sub from_project    { $_[0]->fromRef->{repository}{project}{name}; }
sub to_project      { $_[0]->toRef->{repository}{project}{name}; }
sub from_name {
    $_[0]->from_project
    . '/'
    . $_[0]->from_repository
    . '/'
    . $_[0]->from_branch;
}
sub to_name   {
    $_[0]->to_project
    . '/'
    . $_[0]->to_repository
    . '/'
    . $_[0]->to_branch;
}

sub from_data {
    my ($self) = @_;

    return {
        branch      => $self->from_branch,
        project     => $self->from_project,
        project_key => $self->fromRef->{repository}{project}{key},
        repository  => $self->from_repository,
        release_age => undef,
    };
}

sub to_data {
    my ($self) = @_;

    return {
        branch      => $self->to_branch,
        project     => $self->to_project,
        project_key => $self->toRef->{repository}{project}{key},
        repository  => $self->to_repository,
        release_age => undef,
    };
}

1;

__END__

=head1 NAME

App::BitBucketCli::PullRequest - Stores details about a pull request

=head1 VERSION

This documentation refers to App::BitBucketCli::PullRequest version 0.007

=head1 SYNOPSIS

   use App::BitBucketCli::PullRequest;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<emails ()>

=head2 C<from_branch ()>

=head2 C<from_data ()>

=head2 C<from_name ()>

=head2 C<from_project ()>

=head2 C<from_repository ()>

=head2 C<to_branch ()>

=head2 C<to_data ()>

=head2 C<to_name ()>

=head2 C<to_project ()>

=head2 C<to_repository ()>

=head2 C<TO_JSON ()>

Used by L<JSON::XS> for dumping the object

=head1 ATTRIBUTES

=head2 state

=head2 id

=head2 toRef

=head2 closed

=head2 version

=head2 attributes

=head2 open

=head2 fromRef

=head2 updatedDate

=head2 createdDate

=head2 title

=head2 links

=head2 reviewers

=head2 participants

=head2 link

=head2 author

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
