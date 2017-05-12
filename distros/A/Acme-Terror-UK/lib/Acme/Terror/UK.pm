package Acme::Terror::UK;

## Get and return the current UK terrorist threat status.
## Robert Price - http://www.robertprice.co.uk/

use 5.00503;
use strict;

use LWP::Simple;

use vars qw($VERSION);
$VERSION = '0.06';

use constant UNKNOWN		=> 0;
use constant CRITICAL		=> 1;
use constant SEVERE		=> 2;
use constant SUBSTANTIAL	=> 3;
use constant MODERATE		=> 4;
use constant LOW		=> 5;


sub new {
	my ($class, %args) = @_;
	$class = ref($class)	if (ref $class);
	return bless(\%args, $class);
}

sub fetch {
	my $self = shift;
	my $url = 'http://www.mi5.gov.uk/';
	my $html = get($url);
	return undef unless ($html);
	my ($lvl) = ($html =~ m!</a>Current UK threat level</strong></p>.+?<h3><font style="FONT-SIZE: 12pt">(.+?)</font></h3>!sgi);
	return $lvl;
}

sub level {
	my $self = shift;
	my $level = $self->fetch();
	return UNKNOWN	unless ($level);
	if ($level eq 'CRITICAL') {
		return CRITICAL;
	} elsif ($level eq 'SEVERE') {
		return SEVERE;
	} elsif ($level eq 'SUBSTANTIAL') {
		return SUBSTANTIAL;
	} elsif ($level eq 'MODERATE') {
		return MODERATE;
	} elsif ($level eq 'LOW') {
		return LOW;
	} else {
		return UNKNOWN;
	} 	
}


1;
__END__

=head1 NAME

Acme::Terror::UK - Fetch the current UK terror alert level

=head1 SYNOPSIS

  use Acme::Terror::UK;
  my $t = Acme::Terror::UK->new();  # create new Acme::Terror::UK object

  my $level = $t->fetch;
  print "Current terror alert level is: $level\n";

=head1 DESCRIPTION

Gets the currrent terrorist threat level in the UK.

The levels are either...
 CRITICAL - an attack is expected imminently 
 SEVERE - an attack is likely
 SUBSTANTIAL - an attack is a strong possibility
 MODERATE - an attack is possible but not likely
 LOW - an attack is unlikely

This module aims to be compatible with the US version, Acme::Terror

=head1 METHODS

=head2 new()

  use Acme::Terror::UK
  my $t = Acme::Terror::UK->new(); 

Create a new instance of the Acme:Terror::UK class.

=head2 fetch()

  my $threat_level_string = $t->fetch();
  print $threat_level_string;

Return the current threat level as a string.

=head2 level()

  my $level = $t->level();
  if ($level == Acme::Terror::UK::CRITICAL) {
    print "Help, we're all going to die!\n";
  }

Return the level of the current terrorist threat as a comparable value.

The values to compare against are,

  Acme::Terror::UK::CRITICAL
  Acme::Terror::UK::SEVERE
  Acme::Terror::UK::SUBSTANTIAL
  Acme::Terror::UK::MODERATE
  Acme::Terror::UK::LOW

If it can't retrieve the current level, it will return

  Acme::Terror::UK::UNKNOWN

=head1 BUGS

This module just screenscrapes the MI5 website so is vulnerable
to breaking if the page design changes.

=head1 SEE ALSO

Acme::Terror
http://www.mi5.gov.uk/
http://www.mi5.gov.uk/output/Page4.html
http://www.intelligence.gov.uk/
http://www.homeoffice.gov.uk/security/current-threat-level/

=head1 THANKS

Neil Stott for supplying a patch after MI5 site redesign
B10m for supplying a patch after an MI5 site redesign

=head1 AUTHOR

Robert Price, E<lt>rprice@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006-2010 by Robert Price

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut
