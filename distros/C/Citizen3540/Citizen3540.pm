#!/usr/bin/perl
package Device::Citizen3540;
use warnings;
use strict;
use Fcntl;
use Text::ASCIITable::Wrap qw/wrap/;
use Data::Dumper;

use vars qw/$VERSION %EXPORT_TAGS @ISA/;
use Exporter ();
@ISA = qw/Exporter/;
%EXPORT_TAGS = (constants => [qw/RED BIG ULINE CENTER/]);
$VERSION = 0.61;

Exporter::export_ok_tags('constants');

use constant RED 	=> 1 << 0;
use constant BIG 	=> 1 << 1;
use constant ULINE 	=> 1 << 2;
use constant CENTER => 1 << 3;

use constant COLS	=> 40; # Number of columns the printer supports

my $lpDev = $ENV{'LPDEV'} || '/dev/ttyS0';

# These are taken from page 33 of the user manual
our %chars = (
	'feedn'			=> "\x0C",
	'enlarge'		=> "\x0E",
	'clrenlarge'	=> "\x0F",
	'lnfeed'		=> "\x0A",
	'print'			=> "\x0D",
	'init'			=> "\x11",
	'invert'		=> "\x12",
	'red'			=> "\x13",
	'clear'			=> "\x18",
	'fcut'			=> "\x1B\x50\x00",
	'pcut'			=> "\x1B\x50\x01",
	'uline'			=> "\x1B\x2D\x01",
	'clruline'		=> "\x1B\x2D\x00",
	'buzzer'		=> "\x1E"
);


sub new
{
	my $invocant = shift;
	my $class = ref($invocant) || $invocant;
	my $self = { @_ };
	bless ($self, $class);
	return $self;
}

sub print
{
	my $self = shift;
	my @lines = split("\n", wrap(shift, COLS - 2)); # Wrap shorter to prevent weird breaking issues
	my $modes = shift || 0;

	sysopen(LP, $lpDev, O_WRONLY | O_APPEND);

	print LP $chars{'enlarge'} if ($modes & BIG);
	print LP $chars{'uline'} if ($modes & ULINE);

	foreach my $line (@lines)
	{
		$line = $self->centerText($line) if ($modes & CENTER);

		print LP $chars{'red'} if ($modes & RED);
		print LP $line;
		print LP "\n";
	}

	print LP $chars{'clruline'} if ($modes & ULINE);
	print LP $chars{'clrenlarge'} if ($modes & BIG);
	
	close(LP);
}


sub cut
{
	my $self = shift;
	my $partial = shift;

	sysopen(LP, $lpDev, O_WRONLY | O_APPEND);
	if (defined($partial))
	{
		print LP $chars{'pcut'};
	}
	else
	{
		print LP $chars{'fcut'};
	}

	close(LP);
}

sub feed
{
	my $self = shift;
	my $num = shift || 1;

	sysopen(LP, $lpDev, O_WRONLY | O_APPEND);
	print LP $chars{'lnfeed'} x $num;
	close(LP);
}

sub beep
{
	sysopen(LP, $lpDev, O_WRONLY | O_APPEND);
	print LP $chars{'buzzer'};
	close(LP);
}

sub centerText
{
	my $self = shift;
	my $text = shift;

	my $len = length($text);

	return $text if($len >= COLS); #TODO: this might want to warn/croak
	
	return (' ' x ((COLS - $len) / 2) . $text);
}

# make us eval true
1;

__END__

=head1 NAME

Device::Citizen3540 - Advanced printing to Citizen 3540/3541 reciept printers

=head1 SYNOPSIS
	
	use Device::Citizen3540;
	my $printer = new Device::Citizen3540();
	$printer->print("This is simple text");

	use Device::Citizen3540 qw/:constants/;
	$printer->print("This is title text", BIG | CENTER | ULINE);
	$printer->print("This is red text", RED);

=head1 DESCRIPTION

This module allows the user to easily output to a Citizen iDP3540/3541 Dot Matrix POS printer.  This receipt printer
supports enlarged text, underlining, red text and graphics.  This module supports most of the text features.  This
module was written with the serial version of the printer in mind, but should work with other interfaces as long
as your operating system allows interaction via a device file.  Written and tested on a Linux 2.6 machine, but with
exception of the default device file should be cross platform (with notable exception of Windows, but there is a
native print driver for that platform)


=head1 ENVIRONMENT

=over 4

=item LPDEV

If this environmental variable is set, the value of it is used as the device to
write printer commands/text to.

=back

=head1 AUTHOR

Scott Peshak E<speshak@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Scott Peshak.

This program is free software, you may redistribute it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

The user manual for the Citizen idp3540/3541 is available (at the time of this writing) online
at L<http://www.quad.de/ftp/data/citizen/3540-u.pdf> If that site no longer exists when you read 
this, try a web search, there seem to be a lot of mirrors of that file.

=cut
