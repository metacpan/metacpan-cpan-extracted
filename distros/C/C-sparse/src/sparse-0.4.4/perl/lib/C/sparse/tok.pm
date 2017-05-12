package C::sparse::tok::TOKEN_EOF;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_ERROR;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_IDENT;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_ZERO_IDENT;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_NUMBER;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_CHAR;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_CHAR_EMBEDDED_0;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_CHAR_EMBEDDED_1;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_CHAR_EMBEDDED_2;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_CHAR_EMBEDDED_3;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_WIDE_CHAR;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_WIDE_CHAR_EMBEDDED_0;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_WIDE_CHAR_EMBEDDED_1;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_WIDE_CHAR_EMBEDDED_2;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_WIDE_CHAR_EMBEDDED_3;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_STRING;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_WIDE_STRING;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_SPECIAL;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_STREAMBEGIN;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_STREAMEND;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_MACRO_ARGUMENT;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_STR_ARGUMENT;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_QUOTED_ARGUMENT;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_CONCAT;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_GNU_KLUDGE;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_UNTAINT;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_ARG_COUNT;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_IF;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_SKIP_GROUPS;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_ELSE;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok::TOKEN_CONS;
our @ISA = qw (C::sparse::tok);

package C::sparse::tok;
our @ISA = qw (C::sparse);

use overload
    '""'   => \&overload_string;

sub overload_string {
  my ($s) = @_;
  return tok2str($s);
}

1;
