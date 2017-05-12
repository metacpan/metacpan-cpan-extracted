package App::KGB::Client::Subversion;
use utf8;

# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration
# Copyright © 2008 Martín Ferrari
# Copyright © 2009,2010 Damyan Ivanov
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; either version 2 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc., 51
# Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

use strict;
use warnings;

our $VERSION = 1.27;

=head1 NAME

App::KGB::Client::Subversion - KGB interface to Subversion

=head1 SYNOPSIS

    use App::KGB::Client::Subversion;
    my $client = App::KGB::Client::Subversion(
        # common App::KGB::Client parameters
        repo_id => 'my-repo',
        ...
        # Subversion-specific
        repo_path   => '/svn/project',
        revision    => 42,
    );
    $client->run;

=head1 DESCRIPTION

B<App::KGB::Client::Subversion> provides Subversion-specific retrieval of
commits and changes for L<App::KGB::Client>.

=head1 CONSTRUCTOR

=head2 B<new> ( { initializers } )

Standard constructor. Accepts inline hash with initial field values.

=head1 FIELDS

App:KGB::Client::Subversion defines two additional fields:

=over

=item B<repo_path> (B<mandatory>)

Physical path to Subversion repository.

=item B<revision>

The revision about which to notify. If omitted defaults to the last revision
of the repository.

=back

=head1 METHODS

=over

=item describe_commit

The first time this method is called, it retrieves commit number and repository
path from command-line parameters and returns an instance of
L<App::KGB::Commit> class describing the commit.

All subsequential invocations return B<undef>.

=back

=cut

require v5.10.0;
use base 'App::KGB::Client';
use App::KGB::Change;
use App::KGB::Commit;
use Carp qw(confess);
use SVN::Core;
use SVN::Fs;
use SVN::Repos;
__PACKAGE__->mk_accessors(qw( _called repo_path revision ));

use constant rev_prefix => 'r';

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->_called(0);

    defined( $self->repo_path )
        or confess "'repo_path' is mandatory";

    return $self;
}

sub describe_commit {
    my ($self) = @_;

    return undef if $self->_called;

    my ( $author, $log, @changes );

    # Shut up the perl compiler warnings
    if (    $SVN::Fs::PathChange::modify
        and $SVN::Fs::PathChange::add
        and $SVN::Fs::PathChange::delete
        and $SVN::Fs::PathChange::replace )
    {
    }

    my $repo = SVN::Repos::open( $self->repo_path );
    my $fs = $repo->fs or die $!;

    $self->revision( $fs->youngest_rev ) unless defined( $self->revision );
    $log    = $fs->revision_prop( $self->revision, "svn:log" );
    $author = $fs->revision_prop( $self->revision, "svn:author" );

    my $root    = $fs->revision_root( $self->revision );
    my $changed = $root->paths_changed();
    foreach ( keys %$changed ) {
        my $k = $changed->{$_}->change_kind();
        if ( $k == $SVN::Fs::PathChange::modify ) {
            $k = "M";
        }
        elsif ( $k == $SVN::Fs::PathChange::add ) {
            $k = "A";
        }
        elsif ( $k == $SVN::Fs::PathChange::delete ) {
            $k = "D";
        }
        elsif ( $k == $SVN::Fs::PathChange::replace ) {
            $k = "R";
        }

        my $pm = $changed->{$_}->prop_mod();

        push @changes,
            App::KGB::Change->new(
            {   action      => $k,
                prop_change => $pm,
                path        => $_,
            }
            );
    }

    $self->_called(1);

    return App::KGB::Commit->new(
        {   id      => $self->revision,
            changes => \@changes,
            author  => $author,
            author_name => $self->_get_full_user_name($author),
            log     => $log,
        }
    );
}

1;
