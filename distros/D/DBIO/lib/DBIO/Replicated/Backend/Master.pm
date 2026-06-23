package DBIO::Replicated::Backend::Master;
# ABSTRACT: Master backend wrapper

use strict;
use warnings;

use base 'DBIO::Replicated::Backend';

sub new {
  my ($class, %args) = @_;
  $args{kind} = 'master';
  return $class->SUPER::new(%args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated::Backend::Master - Master backend wrapper

=head1 VERSION

version 0.900000

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
