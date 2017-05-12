package App::KGB::Client::CVS;
use utf8;

use strict;
use warnings;

our $VERSION = 1.23;

# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration -- CVS support
# Copyright © 2012 Damyan Ivanov
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

=head1 NAME

App::KGB::Client::CVS - KGB interface to CVS

=head1 SYNOPSIS

    use App::KGB::Client::CVS;
    my $client = App::KGB::Client::CVS(
        # common App::KGB::Client parameters
        repo_id => 'my-repo',
        ...
        # CVS-specific
        cvs_root  => $ENV{CVSROOT},
        author    => $ENV{USER},
        directory => 'module/dir',
    );
    $client->run;

=head1 DESCRIPTION

B<App::KGB::Client::CVS> provides CVS-specific retrieval of
commits and changes for L<App::KGB::Client>.

=head1 CONSTRUCTOR

=head2 B<new> ( { initializers } )

Standard constructor. Accepts inline hash with initial field values.

=head1 FIELDS

App:KGB::Client::CVS defines the following additional fields:

=over

=item B<cvs_root> (B<mandatory>)

Physical path to the CVS root directory.

=item B<author>

The user name of the commit author.

=item B<directory>

Relative (to CVS root) path to the directory this change is in.

As a convention, the first path member is taken as a module.

=back

=head1 METHODS

=over

=item describe_commit

The first time this method is called, it parses STDIN and determines commit
contents, returning an instance of L<App::KGB::Commit> class describing the
commit.

All subsequential invocations return B<undef>.

=back

=cut

require v5.10.0;
use base 'App::KGB::Client';
use App::KGB::Change;
use App::KGB::Commit;
use Carp qw(confess);
__PACKAGE__->mk_accessors(qw( _called author cvs_root directory ));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->_called(0);

    defined( $self->cvs_root )
        or confess "'cvs_root' is mandatory";

    return $self;
}

use Fcntl qw(:flock);

sub describe_commit {
    my ($self) = @_;

    return undef if $self->_called;

    my $merge_file = File::Spec->catfile( $self->cvs_root, 'CVSROOT',
        sprintf( 'kgb-client-%d-%d.tmp', $<, getpgrp() ) );

    open(MERGE, ">>$merge_file") or die "Unable to open $merge_file: $!\n";

    my $first_dir_in_commit = flock( MERGE, LOCK_EX | LOCK_NB );

    my ( $tag, $log, @changes );
    # the first element is module, the rest - directory path
    my ($module, $dir) = $self->directory =~ m{([^/]+)(/.+)?};
    $dir //= '';
    $dir .= '/' if $dir;

    while ( defined( my $line = <> ) ) {
        $tag = $1, next if $line =~ /^\s*Tag: ([a-zA-Z0-9_-]+)/;

        if ( $line =~ /^Added Files:/ ) {
            while ( defined( $line = <> ) and $line =~ /^\s+(.+?)\s?$/ ) {
                my $files = $1;
                push @changes,
                    App::KGB::Change->new(
                    {   action => 'A',
                        path   => "$dir$_",
                    }
                    ) for split( /\s+/, $files );
            }
            redo;
        }
        if ( $line =~ /^Modified Files:/ ) {
            while ( defined( $line = <> ) and $line =~ /^\s+(.+?)\s?$/ ) {
                my $files = $1;
                push @changes,
                    App::KGB::Change->new(
                    {   action => 'M',
                        path   => "$dir$_",
                    }
                    ) for split( /\s+/, $files );
            }
            redo;
        }
        if ( $line =~ /^Removed Files:/ ) {
            while ( defined( $line = <> ) and $line =~ /^\s+(.+?)\s?$/ ) {
                my $files = $1;
                push @changes,
                    App::KGB::Change->new(
                    {   action => 'D',
                        path   => "$dir$_",
                    }
                    ) for split( /\s+/, $files );
            }
            redo;
        }
        last if $line =~ /^Log Message/;
    }

    while(defined(my $line = <>)) {
        $log .= $line;
    }

    my $root = $self->cvs_root;
    $log =~ s{$root/}{} if $log;

    print MERGE "$_\n" for @changes;

    unless ($first_dir_in_commit) {
        close(MERGE);
        return undef;
    }

    return if fork();   # parent process exits

    #warn "$$ waiting\n";
    # wait for the merge file to settle
    while( time() - (stat(MERGE))[9] < 3 ) {
        sleep(1);
    }

    close(MERGE);
    open(MERGE, $merge_file) or die "Error reopening $merge_file: $!\n";
    unlink $merge_file or warn "Error removing $merge_file: $!\n";

    @changes = ();

    while ( defined( my $line = <MERGE> ) ) {
        chomp($line);
        push @changes, App::KGB::Change->new($line);
    }
    close(MERGE);

    $self->_called(1);

    return App::KGB::Commit->new(
        {   changes     => \@changes,
            author      => $self->author,
            author_name => $self->_get_full_user_name( $self->author ),
            log         => $log,
            module      => $module,
        }
    );
}

1;
