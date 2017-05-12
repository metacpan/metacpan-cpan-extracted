#!/usr/bin/env perl
# Example - minimal and naive CGI application.
# Try also Mojolicious + Mojolicious::Plugin::DSC
#See My::App
use 5.10.1;
use strict;
use warnings;
use utf8;
BEGIN {
  use File::Basename 'dirname';
  use Cwd;
  $ENV{users_HOME} = Cwd::abs_path(dirname(__FILE__));
}

#Replace with your own library directories
#use lib('/home/berov/opt/perl5/lib/perl5','/home/berov/opt/perl5/lib/perl5/x86_64-linux-gnu-thread-multi');
use lib (Cwd::abs_path($ENV{users_HOME}.'/../lib'));
use lib ($ENV{users_HOME}.'/lib');
use My::App;

My::App->run();
