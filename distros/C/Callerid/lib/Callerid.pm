package Callerid;

use 5.006001;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration	use Callerid ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	parse_raw_cid_string format_phone_number
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.04';

=pod

=head1 NAME

Callerid - Perl extension for interpreting raw caller ID information (a la AT#CID=2)

=head1 SYNOPSIS

  use Callerid;
  my($hex) = "8024010830...";

  # OO-style
  my($cid) = new Callerid($hex);
  print $cid->{name}; # prints callers name

  -or-

  # Procedural style
  my(%cid) = Callerid::parse_raw_cid_string($hex);
  print $cid{name}; # prints callers name
  
  # prints phone number pretty
  print Callerid::format_phone_number($cid{number});

=head1 DESCRIPTION

The Callerid module aims to provide a quick and easy method (YMMV) of decoding 
raw caller ID information as supplied by a modem.

This module does not talk to modems. It also does not mangle input. If you 
don't supply a hex string of the right format then you lose.

=head2 Methods

=head3 C<< $cid = Callerid->new() >>

=head3 C<< $cid = Callerid->new($string_of_hex) >>

=over 4

Returns a newly created C<< Callerid >> object. If you supply it with a hex 
string then (assuming it's not malformed) it will populate data fields in the 
new C<< Callerid >> object appropriately.

Currently the (public) fields provided are: name number hour minute month day.

=back

=head3 C<< $cid->parse_raw_cid_string($string_of_hex) >>

=head3 C<< %info = Callerid::parse_raw_cid_string($string_of_hex) >>

=over 4

When called as an object method C<< parse_raw_cid_string() >> will fill the 
objects data fields with appropriate information. When called as a class method
C<< parse_raw_cid_string() >> will return a hash with the same data fields.

=back

=head3 C<< $pretty_number = $cid->format_phone_number() >>

=head3 C<< $pretty_number = Callerid::format_phone_number($number) >>

=over 4

When called as an object method, C<< format_phone_number() >> will return the 
object's number field formatted pretty. When called as a class method, 
C<< format_phone_number() >> will take a single argument and will do the same 
thing.

"Formatted pretty" means 7-digit phone numbers become ###-####, 10-digit numbers
become ###-###-####, 11-digit numbers become #-###-###-#### and everything else is passed through unchanged.

=back

=head2 EXPORT

None by default.

=head1 SAMPLE CODE

 use Callerid;

 # read in a list of raw caller ID codes
 while(<>) {
 	chomp;
 	s/#.*$//; # remove comments
 	s/^\s*//; # remove leading spaces
 	s/\s*$//; # remove trailing spaces
 	next unless $_; # skip if there's nothing left

 	my($cid);
 	eval {
 		$cid = new Callerid($_);
 	};

 	if($@) {
 		warn "error parsing $_: $@";
 	} else {
 		printf "%s parses to name=%s number=%s date=%02d/%02d time=%02d:%02d\n",
 			$_,
 			$cid->{name},
 			$cid->format_phone_number(),
 			$cid->{month},
 			$cid->{day},
 			$cid->{hour},
 			$cid->{minute};
 	}
 }

=head1 SEE ALSO

L<Device::Modem> to do I/O with a modem.

Modem command set for putting modem into caller ID mode

=head1 AUTHOR

Mike Carr, E<lt>mcarr@pachogrande.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Mike Carr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

use fields qw(_raw_cid_string name number hour minute month day);

sub new {
	my Callerid $self = shift;
	unless( ref $self ) {
		$self = fields::new($self);
	}
	my($raw_cid_string) = shift;
	if($raw_cid_string) {
		eval {
			my(%results);
			my($href) = $self->parse_raw_cid_string($raw_cid_string);
			if(ref $href) {
				%results = %{ $href };
			}
			for my $field qw(name number hour minute month day) {
				$self->{$field} = $results{$field} if($results{$field});
			}
			$self->{_raw_cid_string} = $raw_cid_string;
		};
		if($@) {
			warn $@;
			return $self->new();
		} else {
			return $self;
		}
	} else {
		$self->{_raw_cid_string} = "";
		for my $field qw(name number hour minute month day) {
			$self->{$field} = "";
		}
	}
	return $self;
}

sub parse_raw_cid_string(;$$) {
	my($_arg) = shift;
	my($self);
	my($c);
	if(ref $_arg) {
		$self = $_arg;
		$c = shift;
	} else {
		$self = {};
		$c = $_arg;
	}

	unless($c) {
		if($self->{_raw_cid_string}) {
			$c = $self->{_raw_cid_string};
		} else {
			warn( __PACKAGE__ . "::parse_raw_cid_string() can't find a string to parse");
			return { };
		}
	}
	
	chomp $c;
	
	unless($c =~ /^[0-9a-fA-F]*$/) {
		croak(__PACKAGE__ . "::parse_raw_cid_string() can't find a valid string to parse");
	}

	
	my(@c) = split //, $c;                    # break each character of the line into the array @c
#	die "nope" unless ($#c == 77);

	my($month, $day, $hour, $minute, $name, $number);
	$month    = (sprintf "%d", $c[9]  . $c[11]) if($#c > 11);
	$day      = (sprintf "%d", $c[13] . $c[15]) if($#c > 15);
	$hour     = (sprintf "%d", $c[17] . $c[19]) if($#c > 19);
	$minute   = (sprintf "%d", $c[21] . $c[23]) if($#c > 23);
	{{{ # name calculation
		if($#c > 57) {
			my $hex = join('', @c[28 .. 57]);        		# form a substring from the array
			if($hex =~ /^(.*?)03/) {
				$hex = $1;
			}
			my @parts = unpack("a2" x (length($hex)/2), $hex);      # break the substring 0x00's
			for my $p (@parts) {                               # go through the list of digits
				#       printf "%s becomes %c\n", $p, hex($p);
				$name .= sprintf "%c", hex($p);            # and convert each to a character
			}
		} else {
			if($c =~ /..0401/) {
				$name = "*PRIVATE";
				$number = "";
			} else {
				$name = "ERROR"; warn "error parsing name, too short, yet not private";
			}
		}
	}}}
	{{{ # number calculation
		if($c =~ /..0401/) {
			$number = "";
		} else {
			for my $n qw(11 7) {
				if($c =~ m/((3\d){$n})..$/) {
					my($three_coded) = $1;
					my(@three_coded) = split //, $three_coded;
					my($toggle) = 1;
					my(@number) = grep { $toggle = !($toggle) } @three_coded;
					$number ||= join('', @number);
				}
			}
			
			unless($number) { warn("didn't parse number, doesn't match as private"); }
		}
	}}}

	# Reset all fields that we should be filling. aka "sanity checking"
	for my $field qw(name number month day hour minute _raw_cid_string) {
		$self->{$field} = "";
	}

	$self->{name} = $name if $name;
	$self->{number} = $number if($number || $name =~ /^\*PRIVATE$/);
	$self->{month} = $month if $month;
	$self->{day} = $day if $day;
	$self->{hour} = $hour if $hour;
	$self->{minute} = $minute if $minute;
	$self->{_raw_cid_string} = $c;

	return $self;
}

sub format_phone_number(;$$) {
	my($_arg) = shift;
	my($self);
	my($number);

	if(ref $_arg) {
		$self = $_arg;
		if(@_) {
			$number = shift;
		} else {
			$number = $self->{number};
		}
	} else {
		$self = { };
		$number = $_arg;
	}

	if($number =~ /^(\d{3})(\d{4})$/) {
		return qq($1-$2);
	} elsif($number =~ /^(\d{3})(\d{3})(\d{4})$/) {
		return qq($1-$2-$3);
	} elsif($number =~ /^(1)(\d{3})(\d{3})(\d{4})$/) {
		return qq($1-$2-$3-$4);
	} else {
		return $number;
	}

}

1;

# vim: set ts=2:
