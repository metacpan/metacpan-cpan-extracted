package CatalystX::Features::Plugin::Static::Simple;
$CatalystX::Features::Plugin::Static::Simple::VERSION = '0.26';
use Moose::Role;
use Carp;

with 'Catalyst::Plugin::Static::Simple';

use namespace::autoclean;

after setup_finalize => sub {
    my $c = shift;

    my $config = $c->config;

    foreach my $feature ( $c->features->list ) {
        # change static paths
        push( @{ $config->{static}->{include_path} }, $feature->root );
    }
    return $c;
};

=head1 NAME

CatalystX::Features::Plugin::Static::Simple - Makes C::P::Static::Simple know about features

=head1 VERSION

version 0.26

=head1 AUTHORS

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
