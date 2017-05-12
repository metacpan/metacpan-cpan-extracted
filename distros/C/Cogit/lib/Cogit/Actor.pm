package Cogit::Actor;
$Cogit::Actor::VERSION = '0.001001';
use Moo;
use MooX::Types::MooseLike::Base 'Str';
use namespace::clean;

has name => (
    is => 'ro',
    isa => Str,
    required => 1,
);

has email => (
    is => 'ro',
    isa => Str,
    required => 1,
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Cogit::Actor

=head1 VERSION

version 0.001001

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <cogit@afoolishmanifesto.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
