package NoLanginfo;
# Test helper: make I18N::Langinfo unavailable, as on Strawberry Perl 5.20 for
# Windows. Loaded with -MNoLanginfo before anything else.
use strict;
use warnings;

unshift @INC, sub {
  return unless $_[1] eq 'I18N/Langinfo.pm';
  die "Can't locate I18N/Langinfo.pm in \@INC (simulated: perl without nl_langinfo)\n";
};

1;
