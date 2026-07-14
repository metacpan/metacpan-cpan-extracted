package DBIO::Test::Util::UmaskGuard;
# ABSTRACT: RAII guard that restores the umask on scope exit

use strict;
use warnings;

sub DESTROY {
  local ($@, $!);
  eval { defined(umask ${ $_[0] }) or die };
  warn("Unable to reset old umask ${ $_[0] }: " . ($! || 'Unknown error'))
    if $@ || $!;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Test::Util::UmaskGuard - RAII guard that restores the umask on scope exit

=head1 VERSION

version 0.900002

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
