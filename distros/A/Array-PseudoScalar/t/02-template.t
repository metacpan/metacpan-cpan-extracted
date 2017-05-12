#!perl
use strict;
use warnings;

use constant N_TESTS => 4;
use Test::More tests => N_TESTS;

use Array::PseudoScalar;

SKIP: {
  eval "use Template; 1"
    or skip "Template Toolkit is not installed on this system", N_TESTS;

  $Template::Config::STASH = 'Template::Stash';

  my $subclass = Array::PseudoScalar->subclass(';');
  my %data     = (obj => $subclass->new(qw/FOO BAR BUZ/));

  my $tmpl = Template->new();
  my $result = "";
  $tmpl->process(\<<"", \%data, \$result);
     [% obj.replace(";", " / ") ; %]

  like($result, qr[^\s+FOO / BAR / BUZ$], "scalar .replace()");

  $result = "";
  $tmpl->process(\<<"", \%data, \$result);
     size is [% obj.size %]
     last is [% obj.last %]
     [% FOREACH member IN obj %]member is [% member %] [% END; # FOREACH %]

  like($result, qr/size is 3/,     "array .size");
  like($result, qr/last is BUZ/,   "array .last");
  like($result, qr/member is BAR/, "array FOREACH");
}
