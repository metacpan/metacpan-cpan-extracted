package Cogit::Object;
$Cogit::Object::VERSION = '0.001001';
use Moo;
use Digest::SHA;
use MooX::Types::MooseLike::Base qw( Str Int InstanceOf );
use namespace::clean;

has kind => (
    is => 'ro',
    isa => sub {
        die "$_[0] is not a valid object type" unless $_[0] =~ m/commit|tree|blob|tag/
    },
    required => 1,
);

# TODO: make this required later
has content => (
    is => 'rw',
    builder => '_build_content',
    lazy => 1,
    predicate => 'has_content',
);

has size => (
    is => 'ro',
    isa => Int,
    builder => '_build_size',
    lazy => 1,
);

has sha1 => (
    is => 'ro',
    isa => Str,
    builder => '_build_sha1',
    lazy => 1,
);

has git => (
    is => 'rw',
    isa => InstanceOf['Cogit'],
    weak_ref => 1,
);

sub _build_sha1 {
    my $self = shift;
    my $sha1 = Digest::SHA->new;
    $sha1->add( $self->raw );
    my $sha1_hex = $sha1->hexdigest;
    return $sha1_hex;
}

sub _build_size {
    my $self = shift;
    return length($self->content || "");
}

sub raw {
    my $self = shift;
    return $self->kind . ' ' . $self->size . "\0" . $self->content;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::Object

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
