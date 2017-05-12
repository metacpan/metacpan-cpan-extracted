package Acme::Terror::AU;

## Get and return the current AU terrorist threat status.

use 5.00503;
use strict;

use vars qw($VERSION);
$VERSION = '0.01';

use constant UNKNOWN		=> 0;
use constant CRITICAL		=> 1;
use constant SEVERE		=> 2;
use constant SUBSTANTIAL	=> 3;
use constant MODERATE		=> 4;
use constant LOW		=> 5;


sub new {
	my ($class, %args) = @_;
	$class = ref($class) if (ref $class);
	return bless(\%args, $class);
}

sub fetch {
	my $self = shift;
	return '';
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

=pod

=head1 NAME

Acme::Terror::AU - Fetch the current AU terror alert level

=head1 SYNOPSIS

  use Acme::Terror::AU;
  my $t = Acme::Terror::AU->new();  # create new Acme::Terror::AU object

  my $level = $t->fetch;
  print "Current terror alert level is: $level\n";

=head1 DESCRIPTION

Gets the currrent terrorist threat level in Australia.

The levels are either...

 CRITICAL    - an attack is expected imminently 
 SEVERE      - an attack is likely
 SUBSTANTIAL - an attack is a strong possibility
 MODERATE    - an attack is possible but not likely
 LOW         - an attack is unlikely
 UNKNOWN     - cannot determine threat level

HOWEVER, as the government has repeatedly stated that they think
triggering various security events off a single level system would be
damage flexibiliy by oversimplifying the situation, and in any case,
why on earth should they let the terrorists see what their alert status
is.

And so this module never returns any of the above status, and instead
always returns UNKNOWN. :)

This module aims to be compatible with the US version L<Acme::Terror>
and the UK version L<Acme::Terror::UK>.

=head1 METHODS

=head2 new()

  use Acme::Terror::AU
  my $t = Acme::Terror::AU->new(); 

Create a new instance of the Acme::Terror::AU class.

=head2 fetch()

  my $threat_level_string = $t->fetch();
  print $threat_level_string;

Return the current threat level as a string.

=head2 level()

  my $level = $t->level();
  if ($level == Acme::Terror::AU::CRITICAL) {
    print "Help, we're all going to die!\n";
  }

Return the level of the current terrorist threat as a comparable value.

The values to compare against are,

  Acme::Terror::AU::CRITICAL
  Acme::Terror::AU::SEVERE
  Acme::Terror::AU::SUBSTANTIAL
  Acme::Terror::AU::MODERATE
  Acme::Terror::AU::LOW

If it can't retrieve the current level, it will return

  Acme::Terror::AU::UNKNOWN

=head1 BUGS

This module may become buggy if Australia develops a simple public and
level-based terror alert system, like the ones the US and UK have.

=head1 SEE ALSO

L<Acme::Terror>, L<Acme::Terror::UK>

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Adam Kennedy.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut
