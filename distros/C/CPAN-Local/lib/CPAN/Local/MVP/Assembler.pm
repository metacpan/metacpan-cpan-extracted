package CPAN::Local::MVP::Assembler;
{
  $CPAN::Local::MVP::Assembler::VERSION = '0.010';
}

# ABSTRACT: MVP assembler for CPAN::Local

use strict;
use warnings;

use String::RewritePrefix;

use Moose;
extends 'Config::MVP::Assembler';
with 'Config::MVP::Assembler::WithBundles';
use namespace::clean -except => 'meta';

has 'root_namespace' =>
(
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

sub expand_package
{
    my ($self, $package) = @_;

    my $str = String::RewritePrefix->rewrite({
        '=' => '',
        '@' => $self->root_namespace . '::PluginBundle::',
        '%' => $self->root_namespace . '::Stash::',
        ''  => $self->root_namespace . '::Plugin::',
    }, $package );

    return $str;
}

__PACKAGE__->meta->make_immutable;

__END__
=pod

=head1 NAME

CPAN::Local::MVP::Assembler - MVP assembler for CPAN::Local

=head1 VERSION

version 0.010

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

