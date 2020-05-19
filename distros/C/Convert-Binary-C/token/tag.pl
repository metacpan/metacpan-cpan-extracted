################################################################################
#
# PROGRAM: tag.pl
#
################################################################################
#
# DESCRIPTION: Generate code for CBC tags
#
################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Devel::Tokenizer::C;

my $TAG_PRE = 'CBC_TAG';

my %tags = (
  Hooks     => {
                 vtable => 1,
               },
  Format    => {
                 strval => [qw( String Binary )],
                 verify => 1,
               },
  ByteOrder => {
                 strval => [qw( BigEndian LittleEndian )],
                 verify => 1,
               },
  Dimension => {
                 vtable => 1,
                 verify => 1,
               },
);

my @tags = sort keys %tags;

sub tag2def
{
  my $tag = shift;
  $tag =~ s/([A-Z])/_$1/g;
  return "\U$tag\E";
}

my $file = shift;

if ($file =~ /\.h$/i) {
  open OUT, ">$file" or die "$file: $!";
  
  my $s_tags = join ",\n", map { "  $TAG_PRE" . tag2def($_) } @tags;
  
  print OUT <<ENDC;
enum CbcTagId {
$s_tags,
  CBC_INVALID_TAG
};
ENDC

  for my $tag (@tags) {
    my $tagdef = tag2def($tag);
    if (exists $tags{$tag}{strval}) {
      $s_tags = join ",\n", map { "  $TAG_PRE" . tag2def($tag.$_) } @{$tags{$tag}{strval}};
      print OUT <<ENDC;

enum CbcTag$tag {
$s_tags,
  CBC_INVALID$tagdef
};
ENDC
    }
  }
  
  close OUT;
}

if ($file =~ /\.c$/i) {
  my @tagmeth;
  my @vtable;
  my @proto;
  my @tokenizer;
  my @method;

  for my $t (@tags) {
    my $vtbl = "NULL";
    if ($tags{$t}{vtable}) {
      $vtbl = "&gs_${t}_vtable";
      push @vtable, <<ENDVTBL;
/**********************************************************************
 *
 *  $t Vtable
 *
 **********************************************************************/

static CtTagVtable gs_${t}_vtable = {
  ${t}_Init,
  ${t}_Clone,
  ${t}_Free
};
ENDVTBL
      push @proto, "static TAG_INIT($t);",
                   "static TAG_CLONE($t);",
                   "static TAG_FREE($t);";
    }

    push @proto, "static TAG_SET($t);",
                 "static TAG_GET($t);";

    my $verify = 'NULL';

    if ($tags{$t}{verify}) {
      $verify = "${t}_Verify";
      push @proto, "static TAG_VERIFY($t);";
    }

    push @tagmeth, "  { ${t}_Set, ${t}_Get, $verify, $vtbl }";

    if (exists $tags{$t}{strval}) {
      my $tagdef = tag2def($t);
      my $valstr = join ",\n", map { qq(    "$_") } @{$tags{$t}{strval}};
      my $switch = Devel::Tokenizer::C->new(TokenFunc   => sub { "return $TAG_PRE" . tag2def($t.$_[0]) . ";\n" },
                                            TokenString => 't')
                                      ->add_tokens(@{$tags{$t}{strval}})
                                      ->generate;
      $switch =~ s/^/  /gm;
      push @tokenizer, <<ENDC;
/**********************************************************************
 *
 *  $t Tokenizer
 *
 **********************************************************************/

static enum CbcTag$t GetTag$t(const char *t)
{
$switch
unknown:
  return CBC_INVALID$tagdef;
}
ENDC

      push @method, <<ENDC;
/**********************************************************************
 *
 *  $t Set/Get Methods
 *
 **********************************************************************/

static TAG_SET($t)
{
  if (SvOK(val))
  {
    if (SvROK(val))
      Perl_croak(aTHX_ "Value for $t tag must not be a reference");
    else
    {
      const char *valstr = SvPV_nolen(val);
      enum CbcTag$t $t = GetTag$t(valstr);

      if ($t == CBC_INVALID$tagdef)
        Perl_croak(aTHX_ "Invalid value '%s' for $t tag", valstr);

      tag->flags = $t;

      return TSRV_UPDATE;
    }
  }

  return TSRV_DELETE;
}

static TAG_GET($t)
{
  static const char *val[] = {
$valstr
  };

  if (tag->flags >= sizeof(val) / sizeof(val[0]))
    fatal("Invalid value (%d) for $t tag", tag->flags);

  return newSVpv(val[tag->flags], 0);
}
ENDC
      push @proto, "static enum CbcTag$t GetTag$t(const char *t);";
    }
  }

  my $s_tags = join ",\n", map { qq(  "$_") } @tags;
  my $s_tagmethods = join ",\n", @tagmeth;
  my $s_vtables = join "\n", @vtable;
  my $s_protos = join "\n", @proto;
  my $s_tokenizers = join "\n", @tokenizer;
  my $s_methods = join "\n", @method;

  my $tag_switch = Devel::Tokenizer::C->new(TokenFunc   => sub { "return $TAG_PRE" . tag2def($_[0]) . ";\n" },
                                            TokenString => 'tag')
                                      ->add_tokens(@tags)->generate;
  $tag_switch =~ s/^/  /gm;
  
  open OUT, ">$file" or die "$file: $!";
  
  print OUT <<END;
/**********************************************************************
 *
 *  Prototypes
 *
 **********************************************************************/

static enum CbcTagId get_tag_id(const char *tag);
$s_protos

/**********************************************************************
 *
 *  Tag IDs
 *
 **********************************************************************/

static const char *gs_TagIdStr[] = {
$s_tags,
  "<<INVALID>>"
};

$s_vtables
/**********************************************************************
 *
 *  Tag Method Table
 *
 **********************************************************************/

static const struct tag_tbl_ent {
  TagSetMethod set;
  TagGetMethod get;
  TagVerifyMethod verify;
  CtTagVtable *vtbl;
} gs_TagTbl[] = {
$s_tagmethods,
  {NULL, NULL, NULL, NULL}
};

/**********************************************************************
 *
 *  Main Tag Tokenizer
 *
 **********************************************************************/

static enum CbcTagId get_tag_id(const char *tag)
{
$tag_switch
unknown:
  return CBC_INVALID_TAG;
}

$s_tokenizers
$s_methods
END
  
  close OUT;
}
