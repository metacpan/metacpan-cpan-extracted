package DBIO::Generate::Util;
# ABSTRACT: Safe Perl-literal emission helpers for DBIO::Generate styles

use strict;
use warnings;

our $VERSION = '0.900005';

use B ();
use Carp::Clan qw/^DBIO/;
use Data::Dumper ();
use DBIO::Exception ();
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


sub pl_val {
  my ($v) = @_;
  return pl_str($v) unless defined $v;
  if (ref $v) {
    local $Data::Dumper::Indent   = 0;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Sortkeys = 1;
    return Data::Dumper::Dumper($v);
  }
  return $v =~ /\A-?[0-9]+\z/ ? $v : pl_str($v);
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


sub assert_method_name {
  my ($method, $what) = @_;
  DBIO::Exception->throw("$what is not a Perl identifier")
    unless defined $method && !ref $method && $method =~ /\A[A-Za-z_]\w*\z/;
  return $method;
}


my %RELATIONSHIP_METHOD = map { $_ => 1 }
  qw(belongs_to has_one has_many might_have many_to_many);

sub assert_relationship_method {
  my ($method) = @_;
  assert_method_name($method, 'relationship method');
  DBIO::Exception->throw('relationship method is not a known relationship method')
    unless $RELATIONSHIP_METHOD{$method};
  return $method;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Generate::Util - Safe Perl-literal emission helpers for DBIO::Generate styles

=head1 VERSION

version 0.900005

=head1 METHODS

=head2 pl_str

    my $literal = pl_str($s);

Renders an arbitrary string as a safe, single-token Perl string literal via
C<B::perlstring>, which escapes quotes, backslashes, newlines and all other
special characters. The result can be spliced into emitted source wherever a
string is wanted (hash key, call argument, ...). C<undef> becomes the bareword
C<undef>.

=head2 pl_val

    my $source = pl_val($v);

Renders a column-info value as Perl source. An integer stays a bare number,
a reference (a C<[precision, scale]> size, a C<\'CURRENT TIMESTAMP'> default)
is dumped as a single-line Perl expression through L<Data::Dumper>, and any
other string goes through L</pl_str>.

=head2 abstract_comment

    my $text = abstract_comment($s);

Renders a value safe for emission on a C<# ABSTRACT: ...> comment line: all
vertical whitespace is collapsed to single spaces and the result trimmed, so a
newline in the source string cannot break out of the comment and inject a
fresh line of executable code. C<undef> becomes the empty string.

=head2 assert_pkg

    my $name = assert_pkg($name);

Validates a string that is about to be emitted as a bareword package/class
name (e.g. C<package $name;>), where a string literal is not an option.
C<croak>s naming the offending value unless C<$name> is a strict,
well-formed Perl package name; otherwise returns C<$name> unchanged.

=head2 assert_method_name

    my $method = assert_method_name($method, 'extra_statements method');

Validates a method name that is about to be emitted as a bareword
(C<< __PACKAGE__->$method(...) >>, a DSL statement). A method name is a Perl
identifier: a letter or underscore followed by word characters. Throws
naming C<$what>, the slot the name came from, and returns C<$method>
unchanged otherwise.

=head2 assert_relationship_method

    my $method = assert_relationship_method($method);

A relationship method is one of C<belongs_to>, C<has_one>, C<has_many>,
C<might_have> and C<many_to_many>. Throws naming the slot for anything else
and returns C<$method> unchanged otherwise.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
