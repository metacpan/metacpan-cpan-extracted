package Cogit::Config;
$Cogit::Config::VERSION = '0.001001';
use Moo;
use MooX::Types::MooseLike::Base qw( InstanceOf );
use namespace::clean;

extends 'Config::GitLike';

has '+confname' => ( default => "gitconfig" );

has git => (
    is => 'ro',
    isa => InstanceOf['Cogit'],
    required => 1,
    weak_ref => 1,
);

sub dir_file {
    my $self = shift;
    return $self->git->gitdir->file("config");
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::Config

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
