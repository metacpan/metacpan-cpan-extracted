package CPAN::Local::App::Command::init;
{
  $CPAN::Local::App::Command::init::VERSION = '0.010';
}

# ABSTRACT: Initialize an empty repository

use Moose;
extends 'MooseX::App::Cmd::Command';
use namespace::clean -except => 'meta';

sub execute
{
    my ( $self, $opt, $args ) = @_;
    $_->initialise for $self->app->cpan_local->plugins_with('-Initialise');
}

__PACKAGE__->meta->make_immutable;


__END__
=pod

=head1 NAME

CPAN::Local::App::Command::init - Initialize an empty repository

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  % lpan init

=head1 DESCRIPTION

Initiate a new repository in the current directory.

=head1 AUTHOR

Peter Shangov <pshangov@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Venda, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

