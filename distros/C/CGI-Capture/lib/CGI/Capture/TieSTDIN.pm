package CGI::Capture::TieSTDIN;

# Small class for replacing STDIN with a provided string

use 5.006;
use strict;
use warnings;
use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.14';
}

sub TIEHANDLE {
	my $class  = shift;
	my $string = shift;
	return bless {
		string => $string,
	};
}

sub READ {
	my $self   = shift;
	my $string = shift;
	unless ( defined $string ) {
		$_[0] = undef;
		return 0;
	}
	my $offset = $_[2] || 0;
	my $length = $_[1];
	my $buffer = substr( $string, $offset, $length );
	my $rv     = length $buffer;
	$_[0]      = $buffer;
	return $rv;
}

sub READLINE {
	my $self   = shift;
	my $string = $self->{string};
	unless ( defined $$string ) {
		return undef;
	}
	if ( wantarray ) {
		my @lines = split /(?<=\n)/, $$string;
		$$string = undef;
		return @lines;
	} else {
		if ( $$string =~ s/^(.+?\n)// ) {
			return "$1";
		} else {
			my $rv = $$string;
			$$string = undef;
			return $rv;
		}
	}
}

sub CLOSE {
	my $self = shift;
	return close $self;
}

1;
