package Acme::XKCD::DebianRandom;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Acme::XKCD::DebianRandom ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	getRandomNumber	
);

our $VERSION = '2.00';

# Choosen by fair dice roll!!!!!1!
our $randomNumber = 4;
sub getRandomNumber {
	return $randomNumber;
}


1;
__END__

=head1 NAME

Acme::XKCD::DebianRandom - Fair dice roll RNG

=head1 SYNOPSIS

  use Acme::XKCD::DebianRandom;
  my $foo = getRandomNumber(); # "4"

=head1 DESCRIPTION

This is self-explanatory. See http://xkcd.com/221/

=head2 EXPORT

getRandomNumber()

=head1 Custom dice rolls

You can set $Acme::XKCD::DebianRandom::randomNumber to override our fairly chosen dice roll.

=head1 AUTHOR

Softwarefreedomday Graz 2012, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Softwarefreedomday 2012

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
