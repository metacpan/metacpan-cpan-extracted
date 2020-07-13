package CLI::Osprey::InlineSubcommand;
use strict;
use warnings;
use Moo;

# ABSTRACT: A class to wrap coderef subcommands
our $VERSION = '0.08'; # VERSION
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY

has 'name' => (
  is => 'ro',
  required => 1,
);

has 'desc' => (
  is => 'bare',
  reader => '_osprey_subcommand_desc',
);

has 'method' => (
  is => 'ro',
  required => 1,
);

has 'parent_command' => (
  is => 'rw',
);

has 'argv' => (
  is => 'rw',
);

sub new_with_options {
  my ($self, %args) = @_;
  $self->parent_command($args{ parent_command });
  $self->argv([ @ARGV ]);
  return $self;
}

sub run {
  my ($self) = @_;
  my $cmd = $self->parent_command;
  my $method = $self->method;

  @_ = ($self->parent_command, @{ $self->argv });
  goto &$method;
}

no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CLI::Osprey::InlineSubcommand - A class to wrap coderef subcommands

=head1 VERSION

version 0.08

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
