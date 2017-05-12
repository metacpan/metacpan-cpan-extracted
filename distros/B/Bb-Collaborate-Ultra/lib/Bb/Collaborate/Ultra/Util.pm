package Bb::Collaborate::Ultra::Util;

=head1 NAME

 Bb::Collaborate::Ultra::Util - Utility functions for Collaborate Ultra

=head1 DESCRIPTION

For internal use only.

=cut

use warnings; use strict;
use Scalar::Util;
use Date::Parse qw<str2time>;
sub _freeze {
    my ($val, $type) = @_;

    for ($val) {

	if (!defined) {
	    warn "undefined value of type $type\n"
	}
	else {
	    my $raw_val = $_;

	    if ($type =~ m{^Bool}ix) {

		#
		# DBize boolean flags..
		#
		$_ =  $_ ? 'true' : 'false';
	    }
	    elsif ($type =~ m{^(Str|enum)}ix) {

		#
		# low level check for taintness. Only applicable when
		# perl program is running in taint mode
		#
		die "attempt to freeze tainted data (type $type): $_"
		    if  Scalar::Util::tainted($_);
		#
		# l-r trim
		#
		$_ = $1
		    if m{^ \s* (.*?) \s* $}x;
		$_ = lc if $type =~ m{^enum};
	    }
	    elsif ($type =~ m{^Int}ix) {
		$_ = $_ + 0;
	    }
	    elsif ($type =~ m{^Date}) {
		my ($sec,$min,$hr,$day,$mon,$year) = gmtime $_;
		$_ = sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ",
		$year+1900, $mon+1, $day, $hr, $min, $sec;
	    }
	    elsif ($type =~ m{^Ref|Any|Hash}ix) {
		# pass through
	    }
	    else {
		die "unable to convert $raw_val to $type\n"
		    unless defined;
	    }
	}
    };

    return $val;
}

#
# thawing of elementary data-types
#

sub _thaw {
    my ($val, $type) = @_;

    return $val
        if !defined $val || $type =~ m{Ref|Array}i;

    for ($val) {

	if ($type =~ m{^Bool}i) {
	    #
	    # Perlise boolean flags..
	    #
	    $_ = m{^(true|1)$}i ? 1 : 0;
	}
	elsif ($type =~ m{^(Str|enum)}i) {
	    #
	    # l-r trim
	    #
	    $_ = $1
		if m{^ \s* (.*?) \s* $}x;
	    $_ = lc if $type =~ m{^enum}i;
	}
	elsif ($type =~ m{^Int}i) {
	    $_ = $_ + 0;
	}
	elsif ($type =~ m{^Date}) {
	    $_ = str2time $_;
	}
	elsif ($type =~ m{^Ref|Any|Hash}ix) {
	    # pass through
	}
	else {
	    die "unknown type: $type";
	}
    };

    return $val;
}

1;
