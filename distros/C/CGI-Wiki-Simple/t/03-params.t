#!/usr/bin/perl -w
use strict;
use Test::More tests => 9;
use Test::Without::Module qw( HTML::Template );

BEGIN{ use_ok('CGI::Wiki::Simple') };

my $wiki = CGI::Wiki::Simple->new(
      PARAMS => { store => {}, header => "header", footer => "footer", style => "style"} # dummy store
   );
isa_ok($wiki, 'CGI::Wiki::Simple', "The created wiki");

for (qw(header footer style)) {
  is($wiki->param($_),$_,"Parameter '$_'");
};

is($wiki->param('script_name'),"/$0","Default script name");

$wiki = CGI::Wiki::Simple->new(
      PARAMS => { store => {}, script_name => 'test' } # dummy store
   );
isa_ok($wiki, 'CGI::Wiki::Simple', "The created wiki");
is($wiki->param("style"),undef,"No preset style sheet");
is($wiki->param("script_name"),'test',"Script name can be overridden");
