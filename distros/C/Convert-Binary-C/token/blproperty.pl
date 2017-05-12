################################################################################
#
# PROGRAM: blproperty.pl
#
################################################################################
#
# DESCRIPTION: Generate tokenizer code for bitfield layout properties
#
################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Devel::Tokenizer::C;
use IO::File;
use strict;

my @mandatory = (
  Offset        => { option => 0 },
  MaxAlign      => { option => 0 },
  Align         => { option => 0 },
  ByteOrder     => { option => 0, choice => [qw( BigEndian LittleEndian )] },
);

my %engines = (

  Generic => {
    @mandatory,
    # FillDirection => { option => 1, member => 'direction', choice => [qw( Left Right )] },
    # TypeMatters   => { option => 1 },     ???
  },

  Microsoft => {
    @mandatory,
  },

  Simple  => {
    @mandatory,
    # FillDirection => { option => 1, member => 'direction', choice => [qw( Left Right )] },
    BlockSize     => { option => 1 },
  },

);

my @properties = do { my %seen; sort grep !$seen{$_}++,
                      map keys %$_, values %engines };
my @values     = do { my %seen; sort grep !$seen{$_}++,
                      map { map { exists $_->{choice} ? @{$_->{choice}} : () } values %$_ } values %engines };

my $file = shift;
my $fh = IO::File->new(">$file") or die "$file: $!\n";

sub to_name
{
  my($pre, $s) = @_;
  $s =~ s/([A-Z])(?=[a-z])/_$1/g;
  $s = "_$s" unless $s =~ /^_/;
  return $pre . uc $s;
}

sub to_member
{
  my $s = shift;
  $s =~ s/([A-Z])/_$1/g;
  $s =~ s/^_//;
  return lc $s;
}

if ($file =~ /\.h$/) {
  my $blp  = join "\n", map "  $_,", map { to_name('BLP',  $_) } @properties;
  my $blpv = join "\n", map "  $_,", map { to_name('BLPV', $_) } @values;
  my $guard = uc $file;
  $guard =~ s/\W+/_/g;
  $fh->print(<<END);
#ifndef _$guard
#define _$guard

typedef enum {
$blp
  INVALID_BLPROPERTY
} BLProperty;

typedef enum {
$blpv
  INVALID_BLPROPVAL
} BLPropValStr;

#endif
END
}
else {
  for my $eng (sort keys %engines) {
    my $spec = $engines{$eng};
    my @optspec;

    my $m_option = <<END;
static const BLOption *${eng}_options(aSELF, int *count)
{
END

    my $m_get = <<END;
static enum BLError ${eng}_get(aSELF, BLProperty prop, BLPropValue *value)
{
  BL_SELF($eng);

  switch (prop)
  {
END

    my $m_set = <<END;
static enum BLError ${eng}_set(aSELF, BLProperty prop, const BLPropValue *value)
{
  BL_SELF($eng);

  switch (prop)
  {
END

    for my $opt (sort keys %$spec) {
      my $os = $spec->{$opt};

      my $name = to_name('BLP', $opt);
      my $type = exists $os->{choice} ? 'str' : 'int';
      my $uctype = uc $type;
      my $member = exists $os->{member} ? $os->{member} : to_member($opt);

      if ($os->{option}) {
        if (exists $os->{choice}) {
          $m_option .= "  static const BLPropValStr $opt\[] = {\n    "
                     . join(", ", map { to_name('BLPV', $_) } @{$os->{choice}})
                     . "\n  };\n\n";

          push @optspec, "{ $name, BLPVT_$uctype, sizeof $opt / sizeof $opt\[0], &$opt\[0] }";
        }
        else {
          push @optspec, "{ $name, BLPVT_$uctype, 0, 0 }";
        }
      }

      $m_get .= <<END;
    case $name:
      value->type = BLPVT_$uctype;
      value->v.v_$type = self->$member;
      break;

END

      $m_set .= <<END unless $os->{readonly};
    case $name:
      assert(value->type == BLPVT_$uctype);
      self->$member = value->v.v_$type;
      break;

END
    }

    if (@optspec) {
      my $options = join ",\n", map "    $_", @optspec;

      $m_option .= <<END;
  static const BLOption options[] = {
$options
  };

  assert(count != NULL);
  *count = sizeof options / sizeof options[0];
  return &options[0];
}

END
    }
    else {
      $m_option .= <<END;
  assert(count != NULL);
  *count = 0;
  return NULL;
}

END
    }

    $_ .= <<END for $m_get, $m_set;
    default:
      return BLE_INVALID_PROPERTY;
  }

  return BLE_NO_ERROR;
}

END

    $fh->print($m_get . $m_set . $m_option);

  }

  my $blp_switch = Devel::Tokenizer::C->new(TokenFunc => sub { "return ".to_name('BLP', $_[0]).";\n" },
                                            TokenString => 'property')
                                      ->add_tokens(@properties)->generate(Indent => '  ');

  my $blpv_switch = Devel::Tokenizer::C->new(TokenFunc => sub { "return ".to_name('BLPV', $_[0]).";\n" },
                                             TokenString => 'propval')
                                       ->add_tokens(@values)->generate(Indent => '  ');

  my $blp_strings  = join ",\n", map { qq[    "$_"] } @properties;
  my $blpv_strings = join ",\n", map { qq[    "$_"] } @values;

  $fh->print(<<END);
BLProperty bl_property(const char *property)
{
$blp_switch
unknown:
  return INVALID_BLPROPERTY;
}

BLPropValStr bl_propval(const char *propval)
{
$blpv_switch
unknown:
  return INVALID_BLPROPVAL;
}

const char *bl_property_string(BLProperty property)
{
  static const char *properties[] = {
$blp_strings
  };

  if (property < sizeof properties / sizeof properties[0])
    return properties[property];

  return NULL;
}

const char *bl_propval_string(BLPropValStr propval)
{
  static const char *propvalues[] = {
$blpv_strings
  };

  if (propval < sizeof propvalues / sizeof propvalues[0])
    return propvalues[propval];

  return NULL;
}
END
}

