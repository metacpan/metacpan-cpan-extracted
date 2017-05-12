package Acme::Lingua::Strine::Perl;

require 5.005_62;
use strict;
use warnings;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our $VERSION = '0.54';

use Filter::Simple sub 
{
	s/(\W)cadge/$1shift/g;
	s/(\W)spit the dummy/$1die/g;
	s/(\W)celador/$1\$_/g;

	s/(\W)bangers and mash/$1\$%/g;
	s/(\W)boast/$1print/g;
	s/(\W)shite/$1print/g;
	s/(\W)jeer/$1print/g;
	s/(\W)chyachk/$1warn/g;
	s/(\W)jack up/$1/g;
	s/(\W)nick off/$1exit/g;
	s/(\W)pash/$1uc/g;
	s/(\W)rack off/$1return/g;
	s/(\W)squib/$1lc/g;
	s/(\W)suss/$1study/g;
	#s/(\W)fossick\s*\(.+=?\)/$1m\/$2\//g;

	
	
};



1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Acme::Lingua::Strine::Perl - make Perl more like Damian

=head1 SYNOPSIS

  use Acme::Lingua::Strine::Perl;
  

  my $first_element = cadge @array; # same as shift
  open FILE, $filename or spit the dummy "strewth mate\n";
  
  boast "same as print\n";
  shite "also the same as print\n";
  jeer  "as is jeer\n";

  while (<>)
  {
	my ($kanger, $roo) = split /:/, celador; 
	# celador == dollar under score == $_ 
  }

  $FORMAT_PAGE_NUMBER = bangers and mash 
  # == dollar hash == $%

  chyack "... is the same as warn\n";

  jack up; # do nothing. Errm, a no-op


  pash  "uppercase this string";
  squib "AND LOWERCASE THIS ONE";
 
  my $yabber = "some scalar\n";
  suss $yabber; # same as 'study'

  sub throw_another_shrimp_on_the_barbie 
  {
	rack off "no worries, mate"; # return
  }

  nick off; # an we're out of here! == exit 

=head1 DESCRIPTION


Inspired by Ron Kimballs's skit on Damian at the 
p5p impressions BOF at TPC5 


=head1 AUTHOR

Simon Wistow <simon@twoshortplanks.com>

=head1 SEE ALSO

L<perl>, L<Filter::Simple> 

=cut
