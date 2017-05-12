# $Id: /mirror/projects/Catalyst-Model-SVN/branches/fix-svn-1_5/lib/Catalyst/Model/SVN.pm 8052 2008-10-09T23:21:36.257589Z bobtfish  $
package Catalyst::Model::SVN;
use strict;
use warnings;
use SVN::Core;
use SVN::Ra;
use IO::Scalar;
use URI;
use Path::Class qw( dir file );
use NEXT;
use DateTime;
use Catalyst::Model::SVN::Item;
use Scalar::Util qw/blessed/;
use Carp qw/confess croak/;
use base 'Catalyst::Model';

our $VERSION = '0.13';

__PACKAGE__->mk_ro_accessors('repository');
__PACKAGE__->config( revision => 'HEAD' );

sub new {
    my ( $self, $c, $config ) = @_;

    $self = $self->NEXT::new(@_);

    die("No configured repository") unless $self->repository;

    my $root_pool = SVN::Pool->new_default;
    my $ra        = SVN::Ra->new(
        url  => $self->repository,
        auth => undef,
        pool => $root_pool,
    );
    
    $self->{pool} = $root_pool;
    $self->{ra}   = $ra;

    return $self;
}

sub _ra {
    my $self = shift;
    confess('Need an instance') unless blessed $self;
    return $self->{ra};
}

sub revision {
    my $self    = shift;
    my $subpool = SVN::Pool::new_default_sub;
    return $self->_ra->get_latest_revnum();
}

sub ls {
    my ( $self, $path, $revision ) = @_;
    
    $revision ||= ($self->{revision} || $self->config->{revision});
    if ( $revision eq 'HEAD' ) {
        $revision = $SVN::Core::INVALID_REVNUM;
    }
    my $subpool = SVN::Pool::new_default_sub;

    my @nodes;
    my $mypath = _ra_path( $self, $path );
    my ( $dirents, $revnum, $props )
        = $self->_ra->get_dir( $mypath, $revision );

# Note that simple data which comes back here is ok, but the dirents data structure
# will be magically deallocated when $subpool goes out of scope, so we borg all the
# info from it now..

    @nodes = map {
        Catalyst::Model::SVN::Item->new(
            {   repos       => $self->repository,
                name        => $_,
                path        => $path,
                svn         => $self,
                size        => $dirents->{$_}->size,
                kind        => $dirents->{$_}->kind,
                time        => $dirents->{$_}->time,
                author      => $dirents->{$_}->last_author,
                created_rev => $dirents->{$_}->created_rev,
            }
        );
    } sort keys %{$dirents};

    return wantarray ? @nodes : \@nodes;
}

# _ra_path( $path )
#
# Takes a path or URL, and returns a normalised from relative to the 
# configured repository path.

sub _ra_path { # FIXME - This is fugly..
    my ( $self, $path ) = @_;
    $path ||= '/';
    if ($path =~ s|\w+://[\w\.]+/||) {
        my $repos_path = URI->new($self->repository)->path;
        $repos_path =~ s|^/||;
        $path =~ s/^$repos_path//;
    }
    $path =~ s|/$||; # Remove trailing / or svn can crash
    $path =~ s|//+|/|g; # Replace multiple slashes with a single slash
    $path =~ s|^/||; # Remove leading / or svn 1.5 asserts.  
    return $path;
}

sub cat {
    my ( $self, $path, $revision ) = @_;
    return ( $self->_get_file( $path, $revision ) )[0];
}

sub propget {
    my ( $self, $path, $propname, $revision ) = @_;

    croak('No propname passed to propget method') unless defined $propname;
    
    my $props_hr = $self->properties_hr($path, $revision);
    return $props_hr->{$propname}
}

sub properties_hr {
    my ( $self, $path, $revision ) = @_;

    croak('No path passed to props_hr method') unless defined $path;
    
    return ( $self->_get_file( $path, $revision ) )[1];
}

# _get_file( $path [, $revision] )
#
# Calls the L<SVN::Ra> get_file method. Handles directories and files which 
# have moved in older revisions

sub _get_file {
    my ( $self, $path, $revision ) = @_;
    my $repos_path = _ra_path( $self, $path );
    $revision = undef if ( defined $revision && $revision eq 'HEAD' );
    $revision ||= $SVN::Core::INVALID_REVNUM;
    my $requested_path = $repos_path;
    my $file           = IO::Scalar->new;
    my $subpool        = SVN::Pool::new_default_sub;
    my ( $revnum, $props );
    use Data::Dumper;
    eval {
        ( $revnum, $props )
            = $self->_ra->get_file( $repos_path, $revision, $file );

    };
    return ( $file, $props ) unless $@;

    # Handle dictionary case..
    if ( $@ =~ /Attempted to get checksum of a \*non\*-file node/ ) {
        return;
    }

    if ( $@ =~ /ile not found/ ) {
        $repos_path = $self->_resolve_copy( $repos_path, $revision );
        if ( $repos_path ne $requested_path ) {
            return $self->_get_file( $repos_path, $revision );
        }
    }

    die $@;
}

sub _resolve_copy {
    my ( $self, $path, $revision ) = @_;
    my $subpool = SVN::Pool::new_default_sub;
    my $copyfrom;
    $self->_ra->get_log(
        [$path],                       # const apr_array_header_t *paths,
        $self->_ra->get_latest_revnum, # svn_revnum_t start,
        $revision,                     # svn_revnum_t end,
        1,                             # svn_boolean_t discover_changed_paths,
        1,                             # svn_boolean_t strict_node_history,
        1,       # svn_boolean_t include_merged_revisions,
        sub {    # svn_log_entry_receiver_t receiver, void *receiver_baton
            return if $copyfrom;
            my $changes = shift;
            use Data::Dumper;
            foreach my $change ( keys %$changes ) {
                my $obj    = $changes->{$change};
                my $action = $obj->action;
                $copyfrom = $obj->copyfrom_path;
                $copyfrom =~ s|^/||;
                $change =~ s|^/||;
                my $copyfrom_rev = $obj->copyfrom_rev;
                if ( $obj->action eq 'A' && $copyfrom ) {
                    $path =~ s/$change/$copyfrom/;
                }
            }
        },
    );
    return $path;
}

1;

__END__

=head1 NAME

Catalyst::Model::SVN - Catalyst Model to browse Subversion repositories

=head1 SYNOPSIS

    # Model
    __PACKAGE__->config(
        repository => '/path/to/svn/root/or/path'
    );

    # Controller
    sub default : Private {
        my ($self, $c) = @_;
        my $path = join('/', $c->req->args);
        my $revision = $c->req->param('revision') || 'HEAD';

        $c->stash->{'repository_revision'} = MyApp::M::SVN->revision;
        $c->stash->{'items'} = MyApp::M::SVN->ls($path, $revision);

        $c->stash->{'template'} = 'blog.tt';
    };

=head1 DESCRIPTION

This model class uses the perl-subversion bindings to access a Subversion
repository and list items and view their contents. It is currently only a
read-only client but may expand to be a fill fledged client at a later time.

=head1 CONFIG

The following configuration options are available:

=head2 repository

Returns a URI object of the full path to the root of, or any directory in your Subversion
repository. This can be one of http://, svn://, or file:/// schemes. 

This value comes from the config key 'repository'.

=head2 revision

This is the default revision to use when no revision is specified. By default,
this will be C<HEAD>.

=head1 METHODS

=head2 cat($path [, $revision])

Returns the contents of the path specified. If C<path> is a copy, the logs are
transversed to find original. The request is then reissued for the original path
for the C<revision> specified.

=head2 ls($path [, $revision])

Returns a array of L<Catalyst::Model::SVN::Item> objects in list context, each
representing an entry in the specified repository path. In scalar context, it
returns an array reference.  If C<path> is a copy, the logs are
transversed to find the original. The request is then reissued for the original
path for the C<revision> specified.

=head2 propget($path, $propname [, $revision])

Returns a specific property for a path at a specified revision name.

Note: This method is inefficient, if you want to extract multiple properties 
of a single item then use the props_hr method.

=head2 properties_hr($path [, $revision])

Returns a reference to a hash with all the properties set on an object at a specific revision.

=head2 repository

Returns the repository specified in the configuration C<repository> option.

=head2 revision

Returns the latest revisions of the repository you are connected to.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Catalyst::Model::SVN::Item>, L<SVN::Ra>

=head1 AUTHORS

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/
    
    Tomas Doran
    CPAN ID: BOBTFISH
    bobtfish@bobtfish.net
   
=head1 LICENSE

        Copyright (c) 2005-2008 the aforementioned authors. All rights
        reserved. This program is free software; you can redistribute
        it and/or modify it under the same terms as Perl itself.
 
