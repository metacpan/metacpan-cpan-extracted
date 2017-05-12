package Beagle::Model::Review;
use Any::Moose;
use Beagle::Util;
extends 'Beagle::Model::Entry';

has 'title' => (
    isa     => 'Str',
    is      => 'rw',
    default => sub { $_[0]->work_title || '' },
    lazy    => 1,
);

has 'work_title' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'work_isbn' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'work_published' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'work_link' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'work_price' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'work_publisher' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'work_author' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'work_translator' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

has 'work_location' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);


sub work_cover {
    my $self     = shift;
    my @exts = qw/jpg png gif/;
    my @names = ( 'cover', $self->work_isbn );
    my @ids = split_id( $self->id );
    for my $name (@names) {
        next unless $name;
        for my $ext (@exts) {
            my $file =
              catfile( $self->root, 'attachments', @ids, "$name.$ext" );
            return "$name.$ext" if -e $file;
        }
    }
    return;
}

sub summary {
    my $self = shift;

    my $value = $self->title || $self->body;
    $self->_summary( $value, @_ );
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

