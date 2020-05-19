################################################################################
#
# PROGRAM: parser.pl
#
################################################################################
#
# DESCRIPTION: Generate tokenizer code for C parser
#
################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Devel::Tokenizer::C;

# keywords that cannot be disabled
@no_disable = qw(
  break
  case char continue
  default do
  else
  for
  goto
  if int
  return
  sizeof struct switch
  typedef
  union
  while
);

# keywords that can be disabled
@disable = qw(
  asm auto
  const
  double
  enum extern
  float
  inline
  long
  register restrict
  short signed static
  unsigned
  void volatile
);

@basic = qw(
  char
  double
  float
  int
  long
  short signed
  unsigned
);

# put them in a hash
@NDIS{@no_disable} = (1) x @no_disable;

$file = shift;

if( $file =~ /parser/ ) {
  $t = Devel::Tokenizer::C->new( TokenFunc => \&t_parser )
                          ->add_tokens( @disable, @no_disable );
}
elsif( $file =~ /basic/ ) {
  $t = Devel::Tokenizer::C->new( TokenFunc   => \&t_basic,
                                 TokenString => 'c',
                                 TokenEnd    => '*name',
                               )
                          ->add_tokens( @basic );
}
elsif( $file =~ /keywords/ ) {
  $t = Devel::Tokenizer::C->new( TokenFunc => \&t_keywords, TokenString => 'str' )
                          ->add_tokens( @disable );
}
elsif( $file =~ /ckeytok/ ) {
  $t = Devel::Tokenizer::C->new( TokenFunc => \&t_ckeytok, TokenString => 'name' )
                          ->add_tokens( @disable, @no_disable );
}
else { die "invalid file: $file\n" }

open OUT, ">$file" or die "$file: $!";
print OUT $t->generate;
close OUT;

sub t_parser {
  my $token = shift;
  if( exists $NDIS{$token} ) {
    return "return \U$token\E_TOK;\n";
  }
  else {
    return "if( pState->pCPC->keywords & HAS_KEYWORD_\U$token\E )\n"
         . "  return \U$token\E_TOK;\n";
  }
};

sub t_basic {
  my $token = shift;
  if( $token eq 'long' ) {
    return <<END
tflags |= tflags & T_LONG ? T_LONGLONG : T_LONG;
goto success;
END
  }
  return <<END
tflags |= T_\U$token\E;
goto success;
END
};

sub t_keywords {
  my $token = shift;
  return "keywords &= ~HAS_KEYWORD_\U$token\E;\n"
        ."goto success;\n";
};

sub t_ckeytok {
  my $token = shift;
  return <<END
static const CKeywordToken ckt = { \U$token\E_TOK, "$token" };
return &ckt;
END
};

