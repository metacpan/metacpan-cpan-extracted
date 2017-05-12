package Config::Irssi::Lexer;
use strict;
use warnings;

use base 'Exporter';

our $VERSION    = '0.01';
our @EXPORT     = qw( mklexer );
our @EXPORT_OK  = qw( mklexer );


sub mklexer {
	my ($fh) = @_;
	
	my $input = '';

	return sub {
		my $parser = shift;
		if ((not defined $input) or $input eq '') {
			my $s = <$fh>;
			if (defined $s) {
				$input = $s;
			} else {
				return('', undef);
			}
		}

		while (1) {
			# we keep trying until we match something.
			for ($input) {
			s/^([ \t\n]+)//;
			s/^#(.+?)$//m;

			s/^([0-9]+(?:\.[0-9]+)?)//
				and return(NUMBER => $1);
			
			s/^([A-Za-z][A-Za-z0-9_]*)//
				and return(SYMBOL => $1);

			if (s/^(["'])((?:\\.|(?!\1)[^\\])*)\1//) {
				my $s = $2;
				my $q = $1;
				$s =~ s/\\$q/$q/g;
				$s =~ s/\\\\/\\/g;
				return (STRING => $s);
			}

			s/^([{}()=;,])//s
				and return($1,$1);
			 }

			# We didn't match anything. Read more and append it to input.
			# 
			my $s = <$fh>;
			if (not defined $s) {
				# hmm, we didn't read anything, and $input doesn't match.
				# Let's give up.
				return('', undef);
			} else {
				$input .= $s;
			}
		}
	}
}



1;
__END__

=head1 NAME

Config::Irssi::Lexer - Yapp-compatible lexical analyzer for irssi-style config files.

=head1 SYNOPSIS

  use Config::Irssi::Lexer qw( mklexer );
  my $lexer = mklexer(\*STDIN);

  my ($tok, $val) = $lexer->();
  # $lexer is Yapp-compatible lexer.

=head1 DESCRIPTION

This is a lexical analyzer for Config::Irssi::Parser.
Well, actually, it has a function which returns a newly-created anonymous subroutine
that is the actual lexer (which behaves like a generator).

=head1 FUNCTIONS

=head2 mklexer($fh)

Returns an anonymous subroutine that will return ($tok, $val) pairs that
it reads from the file handle $fh...

=head1 EXPORTS

mklexer() by default.

=head1 TODO

Add support for lexing strings as well as filehandles.

=head1 AUTHOR

Dylan William Hardison E<lt>dhardison@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2004 by Dylan William Hardison

This module is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

