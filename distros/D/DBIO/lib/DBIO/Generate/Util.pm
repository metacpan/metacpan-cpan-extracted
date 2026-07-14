package DBIO::Generate::Util;
# ABSTRACT: Safe Perl-literal emission helpers for DBIO::Generate styles

use strict;
use warnings;

use B ();
use Carp::Clan qw/^DBIO/;
use namespace::clean;

# SECURITY: every DB-derived identifier (column / table / constraint /
# relationship / moniker name, default values, view definitions, ...) reaches
# generated Perl source through this module. The escaping logic lives here, in
# ONE place, on purpose: a hostile DB identifier must never become executable
# Perl in a generated Result class. Do not inline / duplicate this — see
# t/generate/08-codegen-injection.t.

# Render an arbitrary string as a safe, single-token Perl string literal.
# B::perlstring escapes quotes, backslashes, newlines and all other special
# characters, so the result is a complete literal that can be spliced into
# emitted source wherever a string is wanted (hash key, call argument, ...).
# undef-safe: undef becomes the literal undef.
sub pl_str {
  my ($s) = @_;
  return 'undef' unless defined $s;
  return B::perlstring($s);
}

# Render a value safe for emission on a `# ABSTRACT: ...` comment line.
# A newline in the source string would otherwise break out of the comment and
# inject a fresh line of (executable) code, so all vertical whitespace is
# collapsed to single spaces and the result trimmed. undef -> empty string.
sub abstract_comment {
  my ($s) = @_;
  return '' unless defined $s;
  $s =~ s/\s+/ /g;
  $s =~ s/\A\s+//;
  $s =~ s/\s+\z//;
  return $s;
}

# Validate a string that is about to be emitted as a BAREWORD package /
# class name (e.g. `package $name;`), where a string literal is not an
# option. A bareword can carry arbitrary code, so anything that is not a
# strict, well-formed Perl package name is rejected loudly.
sub assert_pkg {
  my ($name) = @_;
  croak "refusing to emit invalid/unsafe package name: " . (defined $name ? "'$name'" : 'undef')
    unless defined $name
    && $name =~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z_][A-Za-z0-9_]*)*\z/;
  return $name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Generate::Util - Safe Perl-literal emission helpers for DBIO::Generate styles

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
