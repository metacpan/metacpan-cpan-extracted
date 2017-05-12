package Beagle::Model::Article;
use Any::Moose;
use Beagle::Util;
extends 'Beagle::Model::Entry';

has 'title' => (
    isa     => 'Str',
    is      => 'rw',
    default => '',
);

sub summary {
    my $self = shift;

    my $value = $self->title || $self->body;
    $self->_summary( $value, @_ );
}

sub extra_meta_fields_in_web_view { [] }

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

