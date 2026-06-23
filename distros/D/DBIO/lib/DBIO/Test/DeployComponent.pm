#   belongs to t/86sqlt.t
package DBIO::Test::DeployComponent;
# ABSTRACT: Test component for sqlt_deploy_hook testing
use warnings;
use strict;

our $hook_cb;

sub sqlt_deploy_hook {
  my $class = shift;

  $hook_cb->($class, @_) if $hook_cb;
  $class->next::method(@_) if $class->next::can;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::DeployComponent - Test component for sqlt_deploy_hook testing

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
