#!/usr/local/bin/perl

package CGI::Thin::Cookies;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT);
	$VERSION = 0.52;
	@ISA		= qw (Exporter);
	@EXPORT		= qw (&Parse_Cookies &Set_Cookie);
}

########################################### main pod documentation begin ##

=pod

=head1 NAME

CGI::Thin::Cookies - A very lightweight way to read and set Cookies

=head1 SYNOPSIS

C<use CGI::Thin::Cookies;>

C<my %cookie = &Parse_Cookies ();>

C<print &Set_Cookie (VALUE => 'a cookie value', EXPIRE => '+12h);>

=head1 DESCRIPTION

This module is a very lightweight parser and setter of cookies.  And
it has a special feature that it will return an array if the same key
is used twice for different cookies with the ame name.  And you can
force an array to avoid complications.

=head1 USAGE

    * 'CGI::Thin::Cookies::Parse_Cookies(@keys)'
        The optional @keys will be used to force arrays to be returned.

		The function returns a hash of the cookies available to the script. It
		can return more than one cookie if they exist.

    * 'CGI::Thin::Cookies::Set_Cookie (%options)VALUE => 'a cookie value', EXPIRE => '+12h);'

		The %options contain the the following information for the cookie:

		NAME: the name of the cookie
		VALUE: a string with the value of the cookie
		DOMAIN: the domain for the cookie, default is the '.secondaryDomain.toplevelDomain'
		PATH: the path within the domain, default is '/'
		SECURE: true or false value for setting the SECURE flag
		EXPIRE: when to expire including the following options

			"delete" -- expire long ago (the first second of the epoch)
			"now"    -- expire immediately
			"never"  -- expire in 2038 (the last second of the epoch in 31 bits)

			"+180s"  -- in 180 seconds
			"+2m"    -- in 2 minutes
			"+12h"   -- in 12 hours
			"+1d"    -- in 1 day
			"+3M"    -- in 3 months
			"+2y"    -- in 2 years
			"-3m"    -- 3 minutes ago(!)

			If $time is false (0 or '') then don't send an expiration, it will expire
			with the browser being closed

			If you don't supply one of these forms, we assume you are
			specifying the date yourself

=head1 BUGS

=head2 Fixed

=over 4

=back

=head2 Pending

=over 4

=back

=head1 SEE ALSO

CGI::Thin

=head1 SUPPORT

    Visit CGI::Thin::Cookies' web site at
        http://www.PlatypiVentures.com/perl/modules/cgi_thin.shtml
    Send email to
        mailto:cgi_thin@PlatypiVentures.com

=head1 AUTHOR

    R. Geoffrey Avery
    CPAN ID: RGEOFFREY
    modules@PlatypiVentures.com
    http://www.PlatypiVentures.com/perl

=head1 COPYRIGHT

This module is free software, you may redistribute it or modify in under the same terms as Perl itself.

=cut

############################################# main pod documentation end ##

################################################ subroutine header begin ##
################################################## subroutine header end ##

sub Parse_Cookies
{
	my (%cookie);
	foreach (split(/; /, $ENV{'HTTP_COOKIE'})) {
		tr/+/ /;
		my ($chip, $val) = split(/=/, $_, 2);
		$chip =~ s/%([A-Fa-f0-9]{2})/chr(hex($1))/ge;
		$val  =~ s/%([A-Fa-f0-9]{2})/chr(hex($1))/ge;

		if ( defined($cookie{$chip})) {
			$cookie{$chip} = [$cookie{$chip}] unless (ref ($cookie{$chip}) eq "ARRAY");
			push (@{$cookie{$chip}}, $val);
		} else {
			$cookie{$chip} = $val;
		}
	}

	foreach (@_) {
		$cookie{$_} = &Force_Array ($cookie{$_}) if ($cookie{$_});
	}

	return (%cookie);
}

################################################ subroutine header begin ##
################################################## subroutine header end ##

sub Set_Cookie
{
	my (%cookie) = @_;

	$cookie{'VALUE'} =~ s/ /+/g;
	$cookie{'VALUE'} = 'deleted' if ($cookie{'EXPIRE'} eq 'delete');

	$cookie{'EXPIRE'} = &Expire ($cookie{'EXPIRE'});

	$cookie{'PATH'}	= '/' unless $cookie{'PATH'};

	unless ($cookie{'DOMAIN'}) {
		my @where = split ('\.', $ENV{'SERVER_NAME'});
		$cookie{'DOMAIN'} = '.' . join ('.', splice (@where, -2));
	}

	return (join ('; ',
				  "Set-Cookie: $cookie{'NAME'}\=$cookie{'VALUE'}",
				  $cookie{'EXPIRE'},
				  "path\=$cookie{'PATH'}",
				  "domain\=$cookie{'DOMAIN'}",
				  (($cookie{'SECURE'}) ? 'secure' : '')
				 ) . "\n");
}

################################################ subroutine header begin ##
# Loosely based on &expire_calc from CGI.pm
################################################### subroutine header end ##

sub Expire
{
	my($time) = @_;

	return ('') unless ($time);

	my(%mult) = ('s'=>1,
				 'm'=>60,
				 'h'=>60*60,
				 'd'=>60*60*24,
				 'M'=>60*60*24*30,
				 'y'=>60*60*24*365);

	if ($time eq 'now') {
		$time = time;
	} elsif ($time eq 'delete') {
		$time = 1;
	} elsif ($time eq 'never') {
		$time = 2147483647;
	} elsif ($time=~/^([+-]?\d+)([mhdMy]?)/) {
		$time = time + (($mult{$2} || 1)*$1);
	}

	my ($seconds,$min,$hour,$mday,$mon,$year,$wday) = gmtime ($time);

	my (@days) = qw (Sun Mon Tue Wed Thu Fri Sat);
	my (@months) = qw (Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	$seconds	= "0" . $seconds if $seconds < 10;
	$min		= "0" . $min     if $min	 < 10; 
	$hour		= "0" . $hour    if $hour	 < 10; 
	$year	   += 1900; 

	return ("expires\=$days[$wday], $mday-$months[$mon]-$year $hour:$min:$seconds GMT");
}

################################################ subroutine header begin ##
################################################## subroutine header end ##

sub Force_Array
{
	my ($item) = @_;

	$item = [$item] unless( ref($item) eq "ARRAY" );

	return ($item);
}

###########################################################################
###########################################################################
###########################################################################
###########################################################################

1;

__END__
