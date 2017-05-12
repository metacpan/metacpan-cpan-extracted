package CPAN::Local::App;
{
  $CPAN::Local::App::VERSION = '0.010';
}

# ABSTRACT: CPAN::Local's App::Cmd

use CPAN::Local;

use Moose;
extends 'MooseX::App::Cmd';

has cpan_local =>
(
    is         => 'ro',
    isa        => 'CPAN::Local',
    lazy_build => 1,
);

sub _build_cpan_local
{
    return CPAN::Local->new;
}

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

CPAN::Local::App - CPAN::Local's App::Cmd

=head1 VERSION

version 0.010

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

