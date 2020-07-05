package mymm;

use strict;
use warnings;
use 5.020;

sub myWriteMakefile
{
  my %args = @_;

  {
    local $@ = '';
    my $exe = eval { require './lib/Clang/CastXML/Find.pm'; Clang::CastXML::Find->where };
    if(my $error = $@)
    {
      $args{CONFIGURE_REQUIRES}->{'Alien::castxml'} = 0;
      say "casexml not found, falling back on Alien::castxml";
    }
    else
    {
      say "found castxml at:";
      say $exe;
    }
  }

  require ExtUtils::MakeMaker;
  ExtUtils::MakeMaker::WriteMakefile(%args);
}

1;
