package Beagle::Model::Attachment;
use Any::Moose;
use Beagle::Util ();

has 'root' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub { current_root() },
);

sub path {
    my $self = shift;
    return catdir( 'attachments', split_id( $self->parent_id ), $self->name );
}

with 'Beagle::Role::File';

has 'is_raw' => (
    isa     => 'Bool',
    is      => 'ro',
    default => 1,
    lazy    => 1,
);

has 'parent_id' => (
    isa => 'Str',
    is  => 'rw',
);

has 'name' => (
    isa => 'Str',
    is  => 'ro',
);

has 'content_file' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'mime_type' => (
    isa     => 'Str',
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Beagle::Util::mime_type( $self->name );
    },
);

has 'commit_message' => (
    isa     => 'Maybe[Str]',
    is      => 'rw',
    default => '',
    lazy    => 1,
);

sub serialize {
    my $self = shift;
    return $self->content;
}

sub type { 'attachment' }

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

