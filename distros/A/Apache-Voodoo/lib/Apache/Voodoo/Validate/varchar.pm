package Apache::Voodoo::Validate::varchar;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo::Validate::Plugin");

use Email::Valid;

sub config {
	my ($self,$c) = @_;

	my @e;
	if (defined($c->{length})) {
		if ($c->{length} =~ /^\d+$/) {
			$self->{length} = $c->{length};
		}
		else {
			push(@e,"'length' must be positive integer");
		}
	}
	else {
		$self->{length} = 0;
	}

	if (defined($c->{valid})) {
		if ($c->{valid} =~ /^(url|email)$/ ) {
			$self->{'valid'} = $c->{valid};
		}
		elsif (ref($c->{valid}) ne "CODE") {
			push(@e,"valid must be either 'email','url', or a subroutine reference");
		}
	}

	if (defined($c->{regexp})) {
		$self->{regexp} = $c->{regexp};
	}

	return @e;
}

sub valid {
	my ($self,$v) = @_;

	my $e;
	if ($self->{'length'} > 0 && length($v) > $self->{'length'}) {
		$e = 'BIG';
	}
	elsif (defined($self->{'valid'}) && $self->{'valid'} eq 'email') {
		# Net::DNS pollutes the value of $_ with the IP of the DNS server that responsed to the lookup
		# request.  It's localized to keep Net::DNS out of my pool.
		local $_;

		my $addr;
		eval {
			$addr = Email::Valid->address('-address' => $v,
			                              '-mxcheck' => 1,
			                              '-fqdn'    => 1 );
		};
		if ($@) {
			Apache::Voodoo::Exception::Runtime->throw("Email::Valid produced an exception: $@");
			$e = 'BAD';
		}
		elsif(!defined($addr)) {
			$e = 'BAD';
		}
	}
	elsif (defined($self->{'valid'}) && $self->{'valid'} eq 'url') {
		if (length($v) && _valid_url($v) == 0) {
			$e = 'BAD';
		}
	}
	elsif (defined($self->{'regexp'})) {
		my $re = $self->{'regexp'};
		unless ($v =~ /$re/) {
			$e = 'BAD';
		}
	}

	return $v,$e;
}


#
# I saw this code fragment somewhere ages ago, I can't remember where.
# So, I can't attribute it to the proper author.  sorry!
#
# I've stripped out everthing not pertaining to HTTP URLs.  That
# was the part I really needed.
#

# Be paranoid about using grouping!
my $digits         =  '(?:\d+)';
my $dot            =  '\.';
my $qm             =  '\?';
my $hex            =  '[a-fA-F\d]';
my $alpha          =  '[a-zA-Z]';     # No, no locale.
my $alphas         =  "(?:${alpha}+)";
my $alphanum       =  '[a-zA-Z\d]';   # Letter or digit.
my $xalphanum      =  "(?:${alphanum}|%(?:3\\d|[46]$hex|[57][Aa\\d]))";
                       # Letter or digit, or hex escaped letter/digit.
my $alphanums      =  "(?:${alphanum}+)";
my $escape         =  "(?:%$hex\{2})";
my $safe           =  '[$\-_.+]';
my $extra          =  "[!*'(),]";
my $reserved       =  '[;/?:@&=]';
my $uchar          =  "(?:${alphanum}|${safe}|${extra}|${escape})";
   $uchar          =~ s/\Q]|[\E//g;  # Make string smaller, and speed up regex.

# URL schemeparts for ip based protocols:
my $user           =  "(?:(?:${uchar}|[;?&=])*)";
my $password       =  "(?:(?:${uchar}|[;?&=])*)";
my $hostnumber     =  "(?:${digits}(?:${dot}${digits}){3})";
my $toplabel       =  "(?:${alpha}(?:(?:${alphanum}|-)*${alphanum})?)";
my $domainlabel    =  "(?:${alphanum}(?:(?:${alphanum}|-)*${alphanum})?)";
my $hostname       =  "(?:(?:${domainlabel}${dot})*${toplabel})";
my $host           =  "(?:${hostname}|${hostnumber})";
my $hostport       =  "(?:${host}(?::${digits})?)";
my $login          =  "(?:(?:${user}(?::${password})?\@)?${hostport})";

# The predefined schemes:

## FTP (see also RFC959)
#my $fsegment       =  "(?:(?:${uchar}|[?:\@&=])*)";
#my $fpath          =  "(?:${fsegment}(?:/${fsegment})*)";
#my $ftpurl         =  "(?:ftp://${login}(?:/${fpath}(?:;type=[AIDaid])?)?)";


# HTTP
my $hsegment       =  "(?:(?:${uchar}|[;:\@&=])*)";
my $search         =  "(?:(?:${uchar}|[;:\@&=])*)";
my $hpath          =  "(?:${hsegment}(?:/${hsegment})*)";
my $httpurl        =  "(?:http(s)?://${hostport}(?:/${hpath}(?:${qm}${search})?)?)";

sub _valid_url {
	my $test = shift;

	return ($test =~ /^$httpurl$/o)?1:0;
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
