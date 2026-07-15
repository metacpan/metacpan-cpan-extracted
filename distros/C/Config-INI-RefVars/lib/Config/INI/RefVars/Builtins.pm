# lib/Config/INI/RefVars/Builtins.pm
package Config::INI::RefVars::Builtins;

use 5.010;
use strict;
use warnings;

use File::Spec::Functions;# qw(catdir catfile);
use File::Basename qw(dirname basename);


our $VERSION = '1.06';


sub default_dispatch_table {
  return {
          catdir   => \&File::Spec::Functions::catdir,
          catfile  => \&File::Spec::Functions::catfile,
          catpath  => \&_catpath,
          ignore   => \&_ignore,
          concat   => \&_concat,
          join     => \&_join,
          substr   => \&_substr,
          x        => \&_x,
          'and'    => \&_and,
          'or'     => \&_or,
          'if'     => \&_if,
          s        => \&_s,
          tr       => \&_tr,
          m        => \&_m,
          not      => \&_not,
          eq       => \&_eq,
          dirname  => \&dirname,
          basename => \&basename,
         };
}

sub _catpath {
  die("catpath: expected 3 arguments\n") unless @_ == 3;
  return File::Spec::Functions::catpath(@_);
}


sub _clean_error {
  my ($error) = @_;
  chomp($error);
  $error =~ s/\s+at\s+\S+\s+line\s+\d+\.?\z//;
  return $error;
}


sub _ignore {
  return "";
}


sub _concat {
  return join("", @_);
}


sub _join {
  return @_ ? join(shift(@_), @_) : "";
}


sub _substr {
  die("substr: expected 2 or 3 arguments\n") if @_ < 2 || @_ > 3;

  my $warning = "";

  local $SIG{__WARN__} = sub {
    $warning = _clean_error($_[0]);
  };

  my $result = @_ == 2
    ? substr($_[0], $_[1]) : substr($_[0], $_[1], $_[2]);

  die("substr: $warning\n") if $warning ne "";
  return $result;
}


sub _x {
  die("x: expected 2 arguments\n") if @_ != 2;

  my ($str, $n) = @_;

  die("x: second argument must be a non-negative integer\n")
    unless $n =~ /^\+?[0-9]+$/;

  return $str x $n;
}


sub _and {
  foreach my $arg (@_) {
    return "" if $arg eq "";
  }
  return @_ ? $_[-1] : "";
}


sub _or {
  foreach my $arg (@_) {
    return $arg if $arg ne "";
  }
  return "";
}


sub _if {
  die("if: expected 2 or 3 arguments\n") if @_ < 2 || @_ > 3;
  return $_[0] ne "" ? $_[1] : ($_[2] // "");
}


sub _s {
  die("s: expected 3 or 4 arguments\n") if @_ < 3 || @_ > 4;

  my ($str, $pattern, $replacement, $mods) = @_;
  $mods //= "";

  die("s: unsupported modifier '$mods'\n") if $mods !~ /^[gimsx]*$/;

  die("s: regex code blocks are not allowed\n") if $pattern =~ /\(\?\??\{/;

  my $global = $mods =~ s/g//g;
  my $re = eval { $mods eq "" ? qr/$pattern/ : qr/(?$mods:$pattern)/; };
  die("s: ", _clean_error($@), "\n") if $@;

  if ($global) {
    $str =~ s/$re/$replacement/g;
  }
  else {
    $str =~ s/$re/$replacement/;
  }
  return $str;
}


sub _pick_tr_delim {
  my @values = @_;

  no warnings 'qw';
  foreach my $delim (qw(| ! / : ; # ~ @ % ^ * + = ?)) {
    return $delim if !grep { index($_ // "", $delim) >= 0 } @values;
  }
  die("tr: no safe delimiter found\n");
}


sub _tr {
  die("tr: expected 3 or 4 arguments\n") if @_ < 3 || @_ > 4;

  my ($str, $search, $replacement, $mods) = @_;
  $mods //= "";

  die("tr: unsupported modifier '$mods'\n") if $mods !~ /^[cds]*$/;

  my $delim = _pick_tr_delim($search, $replacement);
  my $code = "\$str =~ tr${delim}${search}${delim}${replacement}${delim}${mods};";
  eval "$code; 1" or die("tr: ", _clean_error($@), "\n");

  return $str;
}


sub _m {
  die("m: expected 2 or 3 arguments\n") if @_ < 2 || @_ > 3;

  my ($str, $pattern, $mods) = @_;
  $mods //= "";

  die("m: unsupported modifier '$mods'\n") if $mods !~ /^[imsx]*$/;
  die("m: regex code blocks are not allowed\n") if $pattern =~ /\(\?\??\{/;

  my $re = eval { $mods eq "" ? qr/$pattern/ : qr/(?$mods:$pattern)/; };
  die("m: ", _clean_error($@), "\n") if $@;

  return $str =~ $re ? "1" : "";
}


sub _not {
  die("not: expected 1 argument\n") if @_ != 1;
  return $_[0] eq "" ? "1" : "";
}


sub _eq {
  die("eq: expected 2 arguments\n") if @_ != 2;
  return $_[0] eq $_[1] ? "1" : "";
}

1;


__END__

=pod

=head1 NAME

Config::INI::RefVars::Builtins - Built-in functions for Config::INI::RefVars

=head1 VERSION

Version 1.06

=head1 SYNOPSIS

  use Config::INI::RefVars::Builtins;

  my $dispatch =
    Config::INI::RefVars::Builtins::default_dispatch_table();


=head1 DESCRIPTION

This module contains the built-in functions used by L<Config::INI::RefVars>.


=head1 FUNCTIONS

=head2 default_dispatch_table

  my $dispatch =
    Config::INI::RefVars::Builtins::default_dispatch_table();

Returns a hash reference containing all built-in functions.

The returned hash reference may be modified without affecting other parser
objects.


=head1 BUILT-IN FUNCTIONS

In the INI file, built-in functions are called using the syntax C<$(=& ...)>.

Example:

  path = $(=& catdir,foo,bar)

This is parsed by L<Config::INI::RefVars>, where C<catdir> is a key in the
dispatch table returned by C<default_dispatch_table>.


=head2 catdir

  $(=& catdir,arg1,arg2,...)

Equivalent to:

  File::Spec::Functions::catdir(...)


=head2 catfile

  $(=& catfile,arg1,arg2,...)

Equivalent to:

  File::Spec::Functions::catfile(...)

=head2 catpath

  $(=& catpath,arg1,arg2,arg3)

Equivalent to:

  File::Spec::Functions::catpath(...)

=head2 ignore

  $(=& ignore,...)

Ignores all arguments and returns the empty string.


=head2 concat

  $(=& concat,arg1,arg2,...)

Concatenates all arguments.

Example:

  $(=& concat,foo,bar,baz)

Result: C<foobarbaz>


=head2 join

  $(=& join,separator,arg1,arg2,...)

Equivalent to Perl's C<join()> function.

Example:

  $(=& join,:,foo,bar,baz)

Result: C<foo:bar:baz>


=head2 substr

  $(=& substr,string,offset)
  $(=& substr,string,offset,length)

Equivalent to Perl's C<substr()> function.

Examples:

=over

=item *

  $(=& substr,abcdef,2)

Result: C<cdef>

=item *

  $(=& substr,abcdef,2,3)

Result: C<cde>

=back


=head2 x

  $(=& x,string,count)

Equivalent to Perl's string repetition operator.

Example:

  $(=& x,ab,3)

Result: C<ababab>


=head2 and

  $(=& and,arg1,arg2,...)

Returns the last argument if all arguments are non-empty.
Otherwise returns the empty string.

Examples:

=over

=item *

  $(=& and,a,b,c)

Result: C<c>

=item *

  $(=& and,a,,c)

Result: C<"">

=back


=head2 or

  $(=& or,arg1,arg2,...)

Returns the first non-empty argument.

Examples:

=over

=item *

  $(=& or,,b,c)

Result: C<b>

=item *

  $(=& or,,,)

Result: C<"">

=back


=head2 if

  $(=& if,condition,true-value)
  $(=& if,condition,true-value,false-value)

Returns C<true-value> if C<condition> is non-empty.
Otherwise returns C<false-value>, or the empty string if no false-value
was specified.

Examples:

=over

=item *

  $(=& if,yes,foo,bar)

Result: C<foo>

=item *

  $(=& if,,foo,bar)

Result: C<bar>

=back


=head2 s

  $(=& s,string,pattern,replacement)
  $(=& s,string,pattern,replacement,modifiers)

Performs a regular-expression substitution and returns the resulting
string.

Supported modifiers:

  g i m s x

The C<e> modifier is not supported.

Regex code blocks are rejected:

  (?{ ... })
  (??{ ... })


=head2 tr

  $(=& tr,string,search,replacement)
  $(=& tr,string,search,replacement,modifiers)

Performs a character transliteration and returns the resulting string.

Supported modifiers:

  c d s

Examples:

=over

=item *

  $(=& tr,abcabc,a,x)

Result: C<xbcxbc>

=item *

  $(=& tr,abcabc,abc,ABC)

Result: C<ABCABC>

=back


=head2 m

  $(=& m, STRING, PATTERN)
  $(=& m, STRING, PATTERN, MODIFIERS)

Performs a regular-expression match.

Returns C<1> if the pattern matches and the empty string otherwise.

Supported modifiers:

  i m s x

Regex code blocks are rejected.

Examples:

=over

=item *

  $(=& m, abc123, \d+)

Result: C<1>

=item *

  $(=& m, abc, \d+)

Result: C<"">

=back


=head2 not

  $(=& not, VALUE)

Returns C<1> if VALUE is the empty string and the empty string otherwise.


=head2 eq

  $(=& eq, STRING1, STRING2)

Returns C<1> if both strings are equal and the empty string otherwise.


=head2 dirname

  $(=& dirname, PATH)

Equivalent to C<File::Basename::dirname()>.


=head2 basename

  $(=& basename, PATH)

Equivalent to C<File::Basename::basename()>.


=head1 FUTURE EXTENSIONS

Additional built-in functions may be added in future releases.

Applications should therefore avoid relying on the absence of specific
function names.

B<Naming convention>: build in functions that may be added in the future will
never have an underscore in their names.


=head1 SEE ALSO

L<Config::INI::RefVars>, L<File::Basename>, L<File::Spec::Functions>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc Config::INI::RefVars::Builtins

For more information, refer to: L<Config::INI::RefVars>.


=head1 AUTHOR

Abdul al Hazred, C<< <451 at gmx.eu> >>


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Abdul al Hazred.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.



=cut


