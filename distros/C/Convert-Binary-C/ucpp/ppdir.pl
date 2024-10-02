################################################################################
#
# PROGRAM: ppdir.pl
#
################################################################################
#
# DESCRIPTION: Generate tokenizer code for C preprocessor directives
#
################################################################################
#
# Copyright (c) 2004-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Devel::Tokenizer::C;
use strict;

my @PP = qw(
  define
  undef
  if
  ifdef
  ifndef
  else
  elif
  endif
  include
  include_next
  pragma
  error
  line
  assert
  unassert
  ident
);

my $file = shift;
my $enums  = join "\n", map "  PPDIR_\U$_\E,", @PP;
my $switch = Devel::Tokenizer::C->new(TokenFunc => sub { "return PPDIR_\U$_[0]\E;\n" },
                                      TokenString => 'ppdir')
                                ->add_tokens(@PP)->generate;

open OUT, ">$file" or die $!;

print OUT <<END;
static enum {
$enums
  PPDIR_UNKNOWN
}
scan_pp_directive(const char *ppdir)
{
$switch
unknown:
  return PPDIR_UNKNOWN;
}
END

close OUT;

