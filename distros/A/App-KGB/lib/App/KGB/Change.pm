# vim: ts=4:sw=4:et:ai:sts=4
#
# KGB - an IRC bot helping collaboration
# Copyright © 2008 Martín Ferrari
# Copyright © 2009 Damyan Ivanov
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
package App::KGB::Change;

use strict;
use warnings;

our $VERSION = 1.22;

use File::Basename qw(dirname);

=head1 NAME

App::KGB::Change - a single file change

=head1 SYNOPSIS

    my $c = App::KGB::Change->new(
        { action => "M", prop_change => 1, path => "/there" } );

    print $c;

    my $c = App::KGB::Change->new("(M+)/there");

=head1 DESCRIPTION

B<App::KGB::Change> encapsulates a single path change from a given change set
(or commit).

B<App::KGB::Change> overloads the "" operator in order to provide a default
string representation of changes.

=head1 FIELDS

=over

=item B<action> (B<mandatory>)

The action performed on the item. Possible values are:

=over

=item B<M>

The path was modified.

=item B<A>

The path was added.

=item B<D>

The path was deleted.

=item B<R>

The path was replaced.

=back

=item path (B<mandatory>)

The path that was changed.

=item prop_change

Boolean. Indicated that some properties of the path, not the content were
changed.

=back

=cut

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(qw( action prop_change path ));

use Carp qw(confess);

=head1 CONSTRUCTOR

=head2 new ( { I<initial values> } )

More-or-less standard constructor.

It can take a hashref with keys all the field names (See L<|FIELDS>).

Or, it can take a single string, which is de-composed into components.

See L<|SYNOPSIS> for examples.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new();

    my $h = shift;
    if ( ref($h) ) {
        defined( $self->action( delete $h->{action} ) )
            or confess "'action' is required";
        defined( $self->path( delete $h->{path} ) )
            or confess "'path' is required";
        $self->prop_change( delete $h->{prop_change} );
    }
    else {
        my ( $a, $pc, $p ) = $h =~ /^(?:\(([MADR])?(\+)?\))?(.+)$/
            or confess "'$h' is not recognized as a change string";
        $self->action( $a //= 'M' );
        $self->prop_change( defined $pc );
        $self->path($p);
    }

    return $self;
}

=head1 METHODS

=over

=item as_string()

Return a string representation of the change. Used by the ""  overload. The resulting string is suitable for feeding the L<|new> constructor if needed.

=cut

use overload '""' => \&as_string;

sub as_string {
    my $c  = shift;
    my $a  = $c->action;
    my $pc = $c->prop_change ? '+' : '';
    my $p  = $c->path;

    my $text = '';

    # ignore flags for modifications (unless there is also a property change)
    $text = "($a$pc)" if $a ne 'M' or $pc;
    $p =~ s,^/,,;    # strip leading slash from paths
    $text .= $p;
    return $text;
}

=back

=head1 CLASS METHODS

=over

=item detect_common_dir(C<changes>)

Given an arrayref of changes (instances of APP::KGB::Change), detects the
longest path that is common to all of them. All the changes' paths are trimmed
from the common part.

Example:

 foo/b
 foo/x
 foo/bar/a

would return 'foo' and the paths would be trimmed to

 b
 x
 bar/a

=cut

sub detect_common_dir {
    my $self = shift;
    my $changes = shift;

    return '' if @$changes < 2;    # common dir concept only meaningful for
                                   # more than one path

    my %dirs;
    my %most_dirs;
    for my $c (@$changes) {
        my $path = $c->path;

        # we need to pretend the paths are absolute, because otherwise
        # paths like "a" and "." will be treated as being of the same
        # deepness, while "." is really the parent of "a"
        # the leading "/" is stripped before further processing
        $path = "/$path" unless $path =~ m{^/};
        my $dir = dirname($path);
        $dirs{$dir}++;
        while (1) {
            $most_dirs{$dir}++;
            my $ndir = dirname($dir);
            last if $ndir eq $dir;    # reached the root?
            $dir = $ndir;
        }
    }

    my $topdir = '';
    my $max    = 0;

    # we want to print the common root of all the changed files and say
    # "foo/bar (42 files changed)"

    for my $dirpath ( keys %most_dirs ) {
        if (   $max < $most_dirs{$dirpath}
            or $max == $most_dirs{$dirpath}
            and length($topdir) < length($dirpath) )
        {
            $max    = $most_dirs{$dirpath};
            $topdir = $dirpath;
        }
    }

    # remove the artificial leading slash
    $topdir =~ s{^/}{};

    for (@$changes) {
        my $p = $_->path;
        $p =~ s{^/$topdir/?}{}x
            or $p =~ s{^$topdir/?}{};
        $_->path($p);
    }

    return $topdir;
}

=back

=cut

1;
