package Babble::Config;
# ABSTRACT: Settings for Babble

use strictures 2;

use constant {
  CACHE_RE => exists $ENV{PERL_BABBLE_CACHE_RE}
    ? $ENV{PERL_BABBLE_CACHE_RE}
    : 1,

  DEBUG_CACHE_MISS => exists $ENV{PERL_BABBLE_DEBUG_CACHE_MISS}
    ? $ENV{PERL_BABBLE_DEBUG_CACHE_MISS}
    : 0,

  BAIL_OUT_EARLY => exists $ENV{PERL_BABBLE_BAIL_OUT_EARLY}
    ? $ENV{PERL_BABBLE_BAIL_OUT_EARLY}
    : 1,

  BAIL_OUT_LATE => exists $ENV{PERL_BABBLE_BAIL_OUT_LATE}
    ? $ENV{PERL_BABBLE_BAIL_OUT_LATE}
    : 1,
};

1;
