package Beagle::Backend::git;
use Any::Moose;
use Beagle::Wrapper::git;
use Beagle::Util;
use Email::Address;

extends 'Beagle::Backend::base';

has 'git' => (
    isa     => 'Beagle::Wrapper::git',
    is      => 'rw',
    lazy    => 1,
    builder => '_init_git',
);

has 'user_name' => (
    isa => 'Str',
    is  => 'rw',
);

has 'user_email' => (
    isa => 'Str',
    is  => 'rw',
);

sub create {
    my $self   = shift;
    my $object = shift;

    local ( $ENV{GIT_AUTHOR_NAME}, $ENV{GIT_AUTHOR_EMAIL} ) =
      $self->_find_git_author($object);
    $ENV{GIT_AUTHOR_NAME}  ||= $self->git->config( '--get', 'user.name' );
    $ENV{GIT_AUTHOR_EMAIL} ||= $self->git->config( '--get', 'user.email' );

    my %args = (@_);
    $args{'message'} ||= $object->commit_message;
    $self->_save( $object, %args );
}

sub update {
    my $self   = shift;
    my $object = shift;

    my $path = $object->path;
    return unless $path;

    my $ret = 1;

    if (   $object->can('original_path')
        && $object->original_path
        && $object->original_path ne $object->path )
    {
        my $full_path =
          encode( locale_fs => catfile( $self->root, $object->path ) );
        my $parent = parent_dir($full_path);
        make_path($parent) unless -e $parent;

        ($ret) = $self->git->mv( $object->original_path, $object->path );
        $object->original_path( $object->path );
    }

    my %args = ( commit => 1, @_ );
    $args{'message'} ||= $object->commit_message;

    return unless $ret;
    return $self->_save( $object, %args );
}

sub delete {
    my $self   = shift;
    my $object = shift;
    my %args   = ( commit => 1, @_ );

    my $path = $object ? $object->path : $args{path};
    return unless $path;

    my $full_path = encode( locale_fs => catfile( $self->root, $path ) );
    return unless -e $full_path;

    my ($ret) = $self->git->rm( '--force', '-r', $path );
    return unless $ret;
    ($ret) = $self->git->commit(
        -m => $args{message} || "delete $path",
        $path,
    );
    return $ret;
}

sub _save {
    my $self   = shift;
    my $object = shift;
    my %args   = ( commit => 1, @_ );

    my $path = $object->path;
    return unless $path;

    my $full_path = encode( locale_fs => catfile( $self->root, $path ) );

    my $parent = parent_dir($full_path);
    make_path($parent) unless -e $parent;

    if ( $object->can('content_file') && $object->content_file ) {
        require File::Copy;
        File::Copy::copy( encode( locale_fs => $object->content_file ),
            $full_path )
          or die $!;
    }
    else {
        my $string = $object->serialize;
        open my $fh, '>', $full_path or die $!;
        binmode $fh;
        unless ( $object->can('is_raw') && $object->is_raw ) {
            $string = encode_utf8 $string;
        }
        print $fh $string;
        close $fh;
    }

    my ($ret) = $self->git->add($path);
    return unless $ret;
    return $ret unless $args{commit};

    if ( $self->git->has_changes_indexed ) {
        ($ret) = $self->git->commit( -m => $args{message} || 'save ' . $path );
        return $ret;
    }
    else {
        return 1;
    }
}

sub updated {
    my $self = shift;
    my ( $ret, $updated ) = $self->git->log( '-n1', '--format=%H', 'HEAD' );
    return unless $ret;
    chomp $updated if $updated;
    return $updated;
}

sub _find_git_author {
    my $self  = shift;
    my $entry = shift;
    my ( $name, $email ) = ( $ENV{GIT_AUTHOR_NAME}, $ENV{GIT_AUTHOR_EMAIL} );
    if ( $entry && $entry->can('author') && $entry->author ) {
        my ($address) = Email::Address->parse( $entry->author );
        if ($address) {
            ( $name, $email ) = ( $address->name, $address->address );
        }
        else {
            ( $name, $email ) = ( $entry->author, $entry->author );
        }
    }
    return ( $name, $email );
}

sub _init_git {
    my $self = shift;
    my $git = Beagle::Wrapper::git->new( root => $self->root );

    # config user.name, user.email and branch
    return $git;
}

sub commit {
    my $self = shift;
    my %args = @_;
    if ( $self->git->has_changes_indexed ) {
        my ($ret) =
          $self->git->commit( -m => $args{message}
              || $args{'-m'}
              || 'commited' );
        return $ret;
    }
    else {
        return;
    }
}

our $AUTOLOAD;

sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.+:://;
    return if $method eq 'DESTROY';

    return $self->git->$method(@_);
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__


=head1 AUTHOR

    sunnavy <sunnavy@gmail.com>


=head1 LICENCE AND COPYRIGHT

    Copyright 2011 sunnavy@gmail.com

    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

