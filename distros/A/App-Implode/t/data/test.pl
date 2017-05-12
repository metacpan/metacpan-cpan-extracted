#!/usr/bin/env perl
use Mojo::Util;
print "INC=", join '|', @INC, "\n";
print "PERL5LIB=$ENV{PERL5LIB}\n";
print "PATH=$ENV{PATH}\n";
print "Mojo::Util=$INC{'Mojo/Util.pm'}\n";
print Mojo::Util::md5_sum(shift || 0), "\n";
