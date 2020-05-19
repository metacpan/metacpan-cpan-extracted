################################################################################
#
# PROGRAM: config.pl
#
################################################################################
#
# DESCRIPTION: Generate tokenizer code for config options
#
################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Devel::Tokenizer::C;

@options = qw(
  UnsignedBitfields
  UnsignedChars
  Warnings
  PointerSize
  EnumSize
  IntSize
  CharSize
  ShortSize
  LongSize
  LongLongSize
  FloatSize
  DoubleSize
  LongDoubleSize
  Alignment
  CompoundAlignment
  Include
  Define
  Assert
  DisabledKeywords
  KeywordMap
  ByteOrder
  EnumType
  HasCPPComments
  HasMacroVAARGS
  OrderMembers
  Bitfields
  StdCVersion
  HostedC
);

@sourcify = qw(
  Context
  Defines
);

$file = shift;

if( $file =~ /config/ ) {
  @OPT  = @options;
  $PRE  = 'OPTION';
  $NAME = 'ConfigOption';
}
elsif( $file =~ /sourcify/ ) {
  @OPT  = @sourcify;
  $PRE  = 'SOURCIFY_OPTION';
  $NAME = 'SourcifyConfigOption';
}

$ROUT = "get$NAME";
$ROUT =~ s/([a-z])([A-Z])/$1_\l$2/g;

$enums  = join "\n", map "  ${PRE}_$_,", @OPT;
$switch = Devel::Tokenizer::C->new( TokenFunc => sub { "return ${PRE}_$_[0];\n" },
                                    TokenString => 'option' )
                             ->add_tokens( @OPT )->generate;

open OUT, ">$file" or die $!;
print OUT <<END;
typedef enum {
$enums
  INVALID_$PRE
} $NAME;

static $NAME $ROUT( const char *option )
{
$switch
unknown:
  return INVALID_$PRE;
}
END
close OUT;

