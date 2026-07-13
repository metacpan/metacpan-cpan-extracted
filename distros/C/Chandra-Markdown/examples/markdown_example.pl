#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Spec;
use Chandra::Markdown::App;

my ($vol, $dirs) = (File::Spec->splitpath(File::Spec->rel2abs(__FILE__)))[0, 1];
my $docs_dir = File::Spec->catdir($vol ? "$vol$dirs" : $dirs, 'docs');

Chandra::Markdown::App->new(
    title    => 'Chandra::Markdown demo',
    docs_dir => $docs_dir,
)->run;
