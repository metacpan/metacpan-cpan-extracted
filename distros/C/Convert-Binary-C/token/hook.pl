################################################################################
#
# PROGRAM: hook.pl
#
################################################################################
#
# DESCRIPTION: Generate code for CBC hooks
#
################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Devel::Tokenizer::C;

my @hooks = qw(
  pack
  unpack
  pack_ptr
  unpack_ptr
);

my $file = shift;

if ($file =~ /\.h$/i) {
  open OUT, ">$file" or die "$file: $!";
  
  my $hooks = join ",\n", map { "  HOOKID_$_" } @hooks;
  
  print OUT <<ENDC;
enum HookId {
$hooks,
  HOOKID_COUNT,
  HOOKID_INVALID 
};
ENDC

  close OUT;
}

if ($file =~ /\.c$/i) {
  my $switch = Devel::Tokenizer::C->new(TokenFunc   => sub { "return HOOKID_$_[0];\n" },
                                        TokenString => 'hook')
                                  ->add_tokens(@hooks)->generate;
  
  open OUT, ">$file" or die "$file: $!";

  my $s_hookids = join ",\n", map { qq(  "$_") } @hooks;

  print OUT <<END;
static const char *gs_HookIdStr[] = {
$s_hookids
};

static enum HookId get_hook_id(const char *hook)
{
$switch
unknown:
  return HOOKID_INVALID;
}
END
  
  close OUT;
}
