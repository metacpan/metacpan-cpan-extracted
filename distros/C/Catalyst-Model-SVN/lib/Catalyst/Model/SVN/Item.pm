package Catalyst::Model::SVN::Item;
use strict;
use warnings;
use Path::Class qw( file dir );
use Scalar::Util qw( blessed );
use SVN::Core;
use DateTime;
use Carp qw( confess );
use overload '""' => \&stringify, fallback => 1;

our $VERSION = '0.11';

sub new {
    my ( $class, $args ) = @_;
    confess('new needs a hashref parameter') unless ref($args) eq 'HASH';
    my $self = bless $args, ref($class) || $class;

    return $self;
}

sub author {
    return shift->{author};
}

# Name is a mandatory parameter
sub name {
    return shift->{name};
}

sub is_directory {
    my $self = shift;
    my $kind = $self->kind;

    my $is_dir = ( $kind == $SVN::Node::dir ) ? 1 : 0;
    return $is_dir;
}

sub is_file {
    my $self = shift;
    my $kind = $self->kind;

    return ( $kind == $SVN::Node::file ) ? 1 : 0;
}

# In the cat case, a kind ($SVN::Node::File) is passed in the constructor.
sub kind {
    my ($self) = @_;
    return $self->{kind};
}

sub propget {
    my ( $self, $propname ) = @_;

    confess('No propname passed') unless defined $propname;
    return $self->{props}->{$propname} if exists $self->{props};
    $self->{props}
        = ( $self->{svn}->_get_file( $self->path, $self->revision ) )
        [1];
    return $self->{props}->{$propname};
}

sub contents {
    my $self = shift;

    return $self->{contents} if exists $self->{contents};

    # FIXME - use _ra_path?
    my $location = dir( $self->{path}, $self->{name} )->stringify;
    return $self->{contents}
        = $self->{svn}->cat( $location, $self->revision );

}

sub path {
    my ( $self ) = @_;
    # FIXME - use _ra_path?
    return file( $self->{path}, $self->name )->stringify;
}

sub uri {
    my $self = shift;

    my $u = URI->new( $self->{repos} );
    $u->path( $self->path );    # Memoize?
    return $u;
}

sub log {
    my $self = shift;

    return $self->{log} if exists $self->{log};

    use Data::Dumper;

#warn("Log params " . Dumper([[$self->path], #const apr_array_header_t *paths,
#$self->revision, # svn_revnum_t start,
#$self->revision, # svn_revnum_t end,
#1, # svn_boolean_t discover_changed_paths,
#1, # svn_boolean_t strict_node_history,
#1, # svn_boolean_t include_merged_revisions,
#]));
    my ( $changes, $revision, $author, $date );
    my $path = $self->path;
    $path =~ s|^/||; 
    eval {
        $self->{svn}->_ra->get_log(
            [ $path ],    #const apr_array_header_t *paths,
            $self->revision,    # svn_revnum_t start,
            $self->revision,    # svn_revnum_t end,
            1,                  # svn_boolean_t discover_changed_paths,
            1,                  # svn_boolean_t strict_node_history,
            1,                  # svn_boolean_t include_merged_revisions,
            sub {
                ( $changes, $revision, $author, $date, $self->{log} ) = @_;

                #warn("ITEM log Callback with params: " . Dumper(\@_));
            },    #svn_log_entry_receiver_t receiver, void *receiver_baton
        );
    };
    if ($@) {
        my $path
            = $self->{svn}->_resolve_copy( $self->path, $self->revision );
        $path =~ s|^/||;
        if ( $path ne $self->path ) {
            $self->{svn}->_ra->get_log(
                [  $path ],            #const apr_array_header_t *paths,
                $self->revision,    # svn_revnum_t start,
                $self->revision,    # svn_revnum_t end,
                1,                  # svn_boolean_t discover_changed_paths,
                1,                  # svn_boolean_t strict_node_history,
                1,                  # svn_boolean_t include_merged_revisions,
                sub {
                    ( $changes, $revision, $author, $date, $self->{log} )
                        = @_;

                    #warn("ITEM log Callback with params: " . Dumper(\@_));
                },    #svn_log_entry_receiver_t receiver, void *receiver_baton
            );
        }
        else {
            die $@;
        }
    }
    return $self->{log};
}

sub size {
    return shift->{size};
}

sub time {
    my $self      = shift;
    my $item_time = $self->{time};

    if ( !blessed($item_time) ) {

        my $time
            = DateTime->from_epoch( epoch => substr( $item_time, 0, 10 ) );
        $time->add_duration(
            DateTime::Duration->new(
                nanoseconds => substr( $item_time, 10 )
            )
        );

        $time->set_time_zone('UTC');

        $self->{time} = $time;
    }

    return $self->{time};
}

sub revision {
    return shift->{created_rev};
}

sub stringify {
    my $self = shift;

    return $self->{name};
}

1;

__END__

=head1 NAME

Catalyst::Model::SVN::Item - Object representing a file or directory in a subversion repository.

=head1 SYNOPSIS

See L<Catalyst::Model::SVN>

=head1 DESCRIPTION

This class provides an interface to any versioned item in Subversion.

=head1 METHODS

=head2 author

The author of the latest revision of the current item.

=head2 name

Returns the name of the current item.

=head2 is_directory

Returns 1 if the current item is a directory; 0 otherwise.

=head2 is_file

Returns 1 if the current item is a file; 0 otherwise.

=head2 kind

Returns the kind  of the current item. See L<SVN::Core> for the possible types,
usually $SVN::Node::path or $SVN::Node::file.

=head2 propget ($propname) 

The property on the item named $propname

=head2 contents

The contents of the of the current item. This is the same as
calling C<Catalyst::Model::SVN->cat($item->uri, $item->revision)

=head2 path

Returns the path of the current item relative to the repository root.

=head2 uri

Returns the full repository path of the current item.

=head2 log

Returns the last log entry for the current item. Be forewarned, this makes an
extra call to the repository, which is slow. Only use this if you are listing a
single item, and not when looping through large collections of items. If the
current item is a copy, the logs are transversed to find the original. The
request is then reissued for the original path for the C<revision> specified.

=head2 size

Returns the raw file size in bytes for the current item.

=head2 time

Returns the last modified time of the current item as a L<DateTime> object.

=head2 revision

Returns the revision number of this item

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>, L<Catalyst::Model::SVN>, L<SVN::Ra>

=head1 AUTHORS

    Christopher H. Laco
    CPAN ID: CLACO
    claco@chrislaco.com
    http://today.icantfocus.com/blog/

    Tomas Doran
    CPAN ID: BOBTFISH
    bobtfish@bobtfish.net

