#!/usr/local/bin/perl

use lib qw{/export/home/cradcliff/perlmodules};
use Template::PSP;

print ".\n";

my $filename = $ARGV[0] || die "No PSP file specified";

print ".\n";

my $page_code;
eval { $page_code = Template::PSP::pspload($filename, undef, 1) };

if ($@)
{
  die "can't load page: $@";
}

print ".\n";

print "Page code: $page_code\n";

print ".\n";

$page_code->();

print ".\n";

print "That seemed to work.\n";

