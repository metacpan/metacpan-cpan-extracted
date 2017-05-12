package BZS::TestModule;

#require 5.005_62;
use strict;
#use warnings;

#use vars qw($VERSION $ptr2_License);
use vars qw($VERSION);
$VERSION = do { my @r = (q$Revision: 0.02 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use lib qw(.);

#$ptr2_License = {
#	'next'		=> 'any value',
#};

#require Nest1;

use AutoLoader 'AUTOLOAD';

sub prnt {
  print @_;
#   &BZS::Nest1::prnt(@_);
}

sub prnt_split;

1;
__END__

sub prnt_split {
  print @_;
}
