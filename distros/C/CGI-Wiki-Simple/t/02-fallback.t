#!/usr/bin/perl -w
use strict;
use Test::More tests => 3;
use Test::Without::Module qw( HTML::Template );

BEGIN{ use_ok('CGI::Wiki::Simple') };

my $wiki = CGI::Wiki::Simple->new(
      PARAMS => { store => {} } # dummy store
   );
isa_ok($wiki, 'CGI::Wiki::Simple', "The created wiki");
isa_ok($wiki, 'CGI::Wiki::Simple::NoTemplates', "The created wiki");
