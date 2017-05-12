#!/usr/bin/perl

use strict;
use warnings;

use lib qw(../lib ../../Wx-Perl-PodEditor/lib);

use App::Wx::PodEditor;

my $app = App::Wx::PodEditor->new;
$app->MainLoop;