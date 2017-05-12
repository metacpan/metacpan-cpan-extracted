package Cogit::DirectoryEntry;
$Cogit::DirectoryEntry::VERSION = '0.001001';
use Moo;
use MooX::Types::MooseLike::Base 'Str', 'InstanceOf';
use namespace::clean;

has mode => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has filename => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has sha1 => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has git => (
    is => 'rw',
    isa => InstanceOf['Cogit'],
    weak_ref => 1,
);

sub object {
    my $self = shift;
    return $self->git->get_object( $self->sha1 );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::DirectoryEntry

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
