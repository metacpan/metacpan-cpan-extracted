package Config::Maker::Eval;

use utf8;
use warnings;
use strict;

use Carp;
use POSIX qw(strftime);

{
    my %cache;
    sub _dns_serial {
	my ($daily) = @_;
	my $file = Get1('META:output');
	my $serial;
	return $cache{$file} if $cache{$file};

	if(open IN, '<', $file) {
	    local $_; # WARNING! while does NOT auto-localize
	    while(<IN>) {
		if(/^\s*(\d+)\s*;\s*serial\s*$/) {
		    $serial = $1;
		    last;
		}
	    }
	    close IN;
	} else {
	    warn "Couldn't open $file: $!";
	    $serial = 0;
	}
  
	die "Serial not found" unless defined $serial;

	if($daily) {
	    my $now = strftime '%Y%m%d00', localtime;
	    $serial = $now if $serial < $now;
	}
	warn "Daily: $daily, Serial: $serial";

	return $cache{$file} = $serial + 1;
    }

    sub dns_serial { _dns_serial(0) }
    sub dns_daily_serial { _dns_serial(1) }

    sub lastbyte {
	my ($ip) = @_;
	$ip =~ /\.(\d+)$/ or die "IP $ip does not match \\.(\\d)\$";
	return $1;
    }
}

1;

__END__

=head1 NAME

Config::Maker::Eval::DNSSerial - Utility to generate DNS serials in configit

=head1 SYNOPSIS

    [{ require Config::Maker::Eval::DNSSerial }]
    @		IN SOA  example.com. admin.example.com. (
			[$ output no-cache $][{ dns_serial() }] [/]; serial
			3600	; refresh (1 hour)
			900	; retry (15 minutes)
			604800	; expire (1 week)
			86400	; minimum (1 day)
			)

=head1 DESCRIPTION

This defines two function, C<dns_serial> and C<dns_daily_serial>, that can
be used to generate serial number of DNS zone files. Just call the function as
in the example above. Note, that the comment C<serial> is B<important>, as the
function uses it to find the serial number in the old file.

The C<dns_serial> simply generates number one larger than in the existing file.
The C<dns_daily_serial> generates the date-based serial, that is commonly used
in DNS zones, though it does not seem to have any obvious advantages.

=head1 AUTHOR

Jan Hudec <bulb@ucw.cz>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 Jan Hudec. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

configit(1), perl(1), Config::Maker(3pm).

=cut
# arch-tag: 25a69b5c-ab60-4b6a-93e8-8c398d5e40d9
