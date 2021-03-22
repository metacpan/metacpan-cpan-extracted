# Copyright (C) 2004 Domingo Alcázar Larrea
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the version 2 of the GNU General
# Public License as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307

package DIME::Message;
$DIME::Message::VERSION = '0.05';
use 5.008;
use strict;
use warnings;

use Data::UUID;
use IO::Scalar;


# Preloaded methods go here.
sub new
{
	my $class = shift;
	my @payloads;
	my $this = {			
			_PAYLOADS => \@payloads,
		};
	return bless $this, $class;
}

# Add a payload to a Message
sub add_payload
{
	my $self = shift;
	my $payload = shift;
	my @payloads = @{$self->{_PAYLOADS}};
	my $last_payload;
	# If there is not payloads, we set it as the begin payload
	$payload->mb(1) if(@payloads == 0);
	# Set as the end payload
	$payload->me(1);
	$last_payload = $payloads[@payloads-1];
	$last_payload->me(0) if(defined($last_payload));
	push(@{$self->{_PAYLOADS}},$payload);
}

# Return array with the records
sub payloads
{
	my $self = shift;
	return @{$self->{_PAYLOADS}};
}

sub print
{
	my $self = shift;
	my $out = shift;
	my $howmany = $self->payloads();
	for(my $i=0;$i<$howmany;$i++)
	{
		$self->{_PAYLOADS}->[$i]->print($out);
	}
}

sub print_data
{
	my $self = shift;
	my $data;
	my $io = IO::Scalar->new(\$data);
	$self->print($io);
	$io->close();
	return \$data;
}

1;

=encoding UTF-8

=head1 NAME

DIME::Message - this class implements a DIME message

=head1 SYNOPSIS

  use DIME::Message;
  use DIME::Payload;

  my $payload = DIME::Payload->new;
  $payload->attach(Path => '/mydata/content.txt');

  $message->add_payload($payload);

  my $ref_dime_message = $message->print_data();
  print $$ref_dime_message;

=head1 DESCRIPTION

DIME::Message is a collection of DIME::Payloads. To get a valid Message object, you can generate one adding different DIME::Payloads objects, or use DIME::Parser class to parse an existing DIME message.

=head1 AUTHOR

Domingo Alcazar Larrea, E<lt>dalcazar@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 Domingo Alcázar Larrea

This program is free software; you can redistribute it and/or
modify it under the terms of the version 2 of the GNU General
Public License as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307

=cut
