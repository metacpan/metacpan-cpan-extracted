package CGI::Capture::TieSTDIN;

# Small class for replacing STDIN with a provided string

use 5.006;
use strict;
use warnings;

our $VERSION = '1.15';

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

__END__

=pod

=encoding UTF-8

=head1 NAME

CGI::Capture::TieSTDIN

=head1 VERSION

version 1.15

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=CGI-Capture>
(or L<bug-CGI-Capture@rt.cpan.org|mailto:bug-CGI-Capture@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
