
package Biblio::SICI;
{
  $Biblio::SICI::VERSION = '0.04';
}

# ABSTRACT: Provides methods for assembling, parsing, manipulating and serialising SICIs

use strict;
use warnings;
use 5.010001;

use Moo;
use Sub::Quote;

use Biblio::SICI::ItemSegment;
use Biblio::SICI::ContributionSegment;
use Biblio::SICI::ControlSegment;

use Biblio::SICI::Util qw( calculate_check_char );


has 'item' => (
	is   => 'ro',
	lazy => 1,
	isa => quote_sub(q{ die unless ( defined $_[0] and $_[0]->isa('Biblio::SICI::ItemSegment') ) }),
	builder =>
		quote_sub(q{ my ($self) = @_; return Biblio::SICI::ItemSegment->new( _sici => $self ); }),
	init_arg => undef,
);


has 'contribution' => (
	is   => 'ro',
	lazy => 1,
	isa  => quote_sub(
		q{ die unless ( defined $_[0] and $_[0]->isa('Biblio::SICI::ContributionSegment') ) }),
	builder => quote_sub(
		q{ my ($self) = @_; return Biblio::SICI::ContributionSegment->new( _sici => $self ); }),
	init_arg => undef,
);


has 'control' => (
	is   => 'ro',
	lazy => 1,
	isa  => quote_sub(
		q{ my ($val) = @_; die unless ( defined $val and $val->isa('Biblio::SICI::ControlSegment') ) }
	),
	builder => quote_sub(
		q{ my ($self) = @_; return Biblio::SICI::ControlSegment->new( _sici => $self ); }),
	init_arg => undef,
);


has 'mode' => (
	is       => 'rw',
	isa      => quote_sub(q{ my ($val) = @_; die unless ( $val eq 'strict' or $val eq 'lax' ) }),
	required => 1,
	coerce   => sub {
		my ($val) = @_;
		$val = join( '', split( " ", lc($val) ) );
		return $val if ( $val eq 'strict' or $val eq 'lax' );
		return 'lax';
	},
	default => quote_sub(q{ "lax" }),
);


has 'parsedString' => ( is => 'rwp', init_arg => undef, );


sub parse {
	my ( $self, $string ) = @_;
	my $strictMode = $self->mode() eq 'strict' ? 1 : 0;

	if ( defined $string ) {
		$string =~ s/\r/ /go;
		$string =~ s/\n/ /go;
		$string = join( '', split( " ", $string ) );
	}

	unless ($string) {
		$strictMode ? die 'no string to parse' : return ( undef, undef, ['no string to parse'] );
	}
	$self->_set_parsedString($string);

	my $checkChar = '';
	if ( $string =~ /;([0-9])(?:-.)?\Z/ ) {
		if ( "$1" ne "2" ) {
			$strictMode
				? die 'unsupported SICI version'
				: return ( undef, undef, ['unsupported SICI version'] );
		}
		else {
			$self->control()->version(2);
			if ( $string =~ s/;2-(.)\Z// ) {
				$checkChar = $1;
			}
		}
	}

	my $parserProblems = [];

	my @chars = split( //, $string );
	my $tmp = '';
	while ( exists( $chars[0] ) and $chars[0] !~ /[(<]/ ) {
		$tmp .= shift @chars;
	}

	if ( $tmp and exists( $chars[0] ) ) {
		if ( $chars[0] eq '(' ) {

			# warn 'ISSN candidate: ' . $tmp;
			$self->item()->issn($tmp);
			shift @chars;
		}
		elsif ( $chars[0] eq '<' ) {
			push @{$parserProblems}, "item information missing";

			# warn 'Missing item info';
			# warn 'Enumeration candidate: ' . $tmp;
			if ( $tmp =~ /\A([A-Z0-9\/]+):([A-Z0-9\/]+)(?::([+*]))?\Z/ ) {
				$self->item()->volume($1);
				$self->item()->issue($2);
				$self->item()->supplOrIdx($3) if $3;
			}
			elsif ($tmp) {
				$self->item()->enumeration($tmp);
			}
			shift @chars;
			goto CONTRIB;
		}
		else {
			$strictMode ? die 'unparsable string' : return ( undef, undef, ['unparsable string'] );
		}
	} ## end if ( $tmp and exists( ...))
	else {
		$strictMode ? die 'unparsable string' : return ( undef, undef, ['unparsable string'] );
	}

	$tmp = '';
	while ( exists( $chars[0] ) and $chars[0] ne ')' ) {
		$tmp .= shift @chars;
	}
	if ( $tmp and exists( $chars[0] ) and $chars[0] eq ')' ) {

		# warn 'Chronology candidate: ' . $tmp;
		$self->item()->chronology($tmp);
		shift @chars;
	}
	elsif ( exists( $chars[0] ) and $chars[0] eq ')' ) {
		shift @chars;
	}
	else {
		$strictMode ? die 'unparsable string' : return ( undef, undef, ['unparsable string'] );
	}

	$tmp = '';
	while ( exists( $chars[0] ) and $chars[0] ne '<' ) {
		$tmp .= shift @chars;
	}
	if ( $tmp and exists( $chars[0] ) and $chars[0] eq '<' ) {

		# warn 'Enumeration candidate: ' . $tmp;
		if ( $tmp =~ /\A([A-Z0-9\/]+):([A-Z0-9\/]+)(?::([+*]))?\Z/ ) {
			$self->item()->volume($1);
			$self->item()->issue($2);
			$self->item()->supplOrIdx($3) if $3;
		}
		elsif ($tmp) {
			$self->item()->enumeration($tmp);
		}
		shift @chars;
	}
	elsif ( exists( $chars[0] ) and $chars[0] eq '<' ) {
		shift @chars;
	}
	else {
		$strictMode ? die 'unparsable string' : return ( undef, undef, ['unparsable string'] );
	}

	CONTRIB:
	$tmp = '';
	while ( exists( $chars[0] ) and $chars[0] ne '>' ) {
		$tmp .= shift @chars;
	}
	if ( $tmp and exists( $chars[0] ) and $chars[0] eq '>' ) {

		# warn 'Contribution candidate: ' . $tmp;
		if ( $tmp =~ /\A::(.+)\Z/ ) {
			$self->contribution()->localNumber($1);
		}
		elsif ( $tmp =~ /\A:([^:]+)(?::(.+))?\Z/ ) {
			$self->contribution()->titleCode($1);
			$self->contribution()->localNumber($2) if $2;
		}
		elsif ( $tmp =~ /\A([^:]+):([^:]+)(?::(.+))?\Z/ ) {
			$self->contribution()->location($1);
			$self->contribution()->titleCode($2);
			$self->contribution()->localNumber($3) if $3;
		}
		else {
			$self->contribution()->location($tmp);
		}
		shift @chars;
	}
	elsif ( exists( $chars[0] ) and $chars[0] eq '>' ) {
		shift @chars;
	}
	else {
		$strictMode ? die 'unparsable string' : return ( undef, undef, ['unparsable string'] );
	}

	my $csi = '';
	if ( exists( $chars[0] ) ) {
		$csi = shift @chars;
	}

	if ( exists( $chars[0] ) and $chars[0] eq '.' ) {
		shift @chars;
	}
	elsif ( exists( $chars[0] ) ) {
		shift(@chars) while ( $chars[0] ne '.' );
	}

	if ( exists( $chars[0] ) ) {
		$self->control()->dpi( shift @chars );
	}

	if ( exists( $chars[0] ) and $chars[0] eq '.' ) {
		shift @chars;
	}
	elsif ( exists( $chars[0] ) ) {
		shift(@chars) while ( $chars[0] ne '.' );
	}

	if ( exists( $chars[0] ) and exists( $chars[1] ) ) {
		$self->control()->mfi( join( '', splice( @chars, 0, 2 ) ) );
	}

	my $isValid = $self->is_valid();
	if ( $strictMode && !$isValid ) {
		die 'parsing failed: invalid SICI';
	}

	if ( $checkChar ne $self->checkchar() ) {
		push @{$parserProblems}, "wrong check char; was '$checkChar', should have been '$1'";
	}
	if ( $checkChar !~ /\A[0-9A-Z#]\Z/ ) {
		push @{$parserProblems}, 'invalid original check char';
	}

	if ( $self->control()->csi() ne $csi ) {
		push @{$parserProblems}, 'wrong csi in string input';
	}

	my $roundTrip = ( $self->parsedString() eq $self->to_string() ? 1 : 0 );
	return ( $isValid, $roundTrip, $parserProblems );
} ## end sub parse


sub to_string {
	my $self = shift;

	my $str = $self->_to_string();
	my $cs  = calculate_check_char($str);

	return $str . $cs;
}

sub _to_string {
	my $self = shift;

	my $item    = $self->item()->to_string();
	my $contrib = $self->contribution()->to_string();
	my $control = $self->control()->to_string();

	return sprintf( '%s<%s>%s-', $item, $contrib, $control );
}


sub checkchar {
	my $self = shift;

	my $siciAsString = $self->_to_string();

	return calculate_check_char($siciAsString);
}


sub reset {
	my $self = shift;
	$self->item()->reset();
	$self->contribution()->reset();
	$self->control()->reset();
	return;
}


sub is_valid {
	my $self = shift;

	my $itemIsValid    = $self->item()->is_valid();
	my $contribIsValid = $self->contribution()->is_valid();
	my $controlIsValid = $self->control()->is_valid();

	if ( $itemIsValid && $contribIsValid && $controlIsValid ) {
		return 1;
	}

	return 0;
}


sub list_problems {
	my $self = shift;

	my $hasProblems = 0;
	my %problems    = ();
	if ( not $self->item()->is_valid() ) {
		$hasProblems++;
		$problems{'item'} = { $self->item()->list_problems() };
	}
	if ( not $self->contribution()->is_valid() ) {
		$hasProblems++;
		$problems{'contribution'} = { $self->contribution()->list_problems() };
	}
	if ( not $self->control()->is_valid() ) {
		$hasProblems++;
		$problems{'control'} = { $self->control()->list_problems() };
	}

	if ($hasProblems) {
		return %problems;
	}
	return;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Biblio::SICI - Provides methods for assembling, parsing, manipulating and serialising SICIs

=head1 VERSION

version 0.04

=head1 SYNOPSIS

  use Biblio::SICI;

  my $sici = Biblio::SICI->new()->parse($someSICI);

  # or

  my $sici2 = Biblio::SICI->new();

  $sici2->item->issn('0361-526X');

  # ... setting more data attributes ...
  
  if ( $sici2->is_valid ) {
      say $sici->to_string;
  }

=head1 DESCRIPTION

A "Serial Item and Contribution Identifier" (SICI) is a code (ANSI/NISO
standard Z39.56) used to uniquely identify specific volumes, articles 
or other identifiable parts of a periodical.

This module provides methods for assembling, parsing, manipulating and
serialising SICIs.

Both internal implementation and public API are currently considered BETA
and may change without warning in a future release. For more information 
on this have a look at the L<TODO section|/TODO> below.

=head1 WARNING

This software is currently considered BETA. Things should work as intended
and documented but if you use it you should test your own software extensively
after any update to a new release of Biblio::SICI since both API and behaviour
might have changed.

=head1 CONFIGURATION

You may specify the following option when instantiating a SICI object
(i.e., when calling the "new()" constructor):

=over 4

=item C<mode>

Can be either C<strict> or C<lax>.

C<strict> mode means that any operation that gets called with an 
invalid (according to the standard) value for an attribute will
C<die()>.

C<lax> mode means that any value is accepted and that you can use
the C<is_valid()> and C<list_problems()> methods to analyze the 
object state.

=back

=head1 ATTRIBUTES

=over 4

=item C<item>

An instance of L<Biblio::SICI::ItemSegment>; this segment contains
information about the serial item itself.

=item C<contribution>

An instance of L<Biblio::SICI::ContributionSegment>; this segment
contains information about an individual contribution to the whole
item, e.g. an article in a journal issue.

=item C<control>

An instance of L<Biblio::SICI::ControlSegment>; this segment
contains some meta-information about the thing described by the
SICI and about the SICI itself.

=item C<mode>

Describes wether the object enforces strict conformance to
the standard or not.
Can be set to either C<strict> or C<lax>.
This attribute is the only one that can be specified directly
in the call of the constructor.

Please keep in mind that changing the value does B<not> mean
that the attributes already present are re-checked!

=item C<parsedString>

Returns the original string that was passed to the C<parse()> 
method or C<undef> if C<parse> was not called before.

=back

=head1 METHODS

=over 4

=item C<parse>( STRING )

Tries to disassemble a string passed to it into the various
components of a SICI.

If I<strict> mode is enabled, it will C<die()> if either the
string cannot be parsed or if no valid SICI can be derived 
from the string.

If I<lax> mode is enabled, it returns a list of three values:

The first value is C<undef> if parsing the string failed, or
C<0> if the string could be parsed but the SICI is invalid, or 
C<1> if a valid SICI was found.

The second value is also C<undef> if parsing the string failed,
or C<0> if the string could be parsed but serializing the SICI
does not result in the exact same string or C<1> if we get a full 
round-trip.

The third value is a (possibly empty) array ref with a list of 
problems the parser detected. B<Please note:> these problems
are distinct from those reported by the C<list_problems> method
and can be retrieved again later.

=item C<to_string>

Serializes the object to a string using the separator characters
specified in the standard and returns it together with the check
character appended.

Does B<not> verify if the resulting SICI is valid!

=item STRING C<checkchar>()

Stringifies the object first, then calculates (and returns) 
the checksum character.
Does B<not> check, if the stringified SICI is valid!

=item C<reset>()

Resets all attributes to their default values.

Does not modify the C<mode> attribute.

=item BOOL C<is_valid>()

Determines if all of the attribute values stored in the object
are valid and returns either a I<true> or I<false> value.

B<TODO> check if any required information is missing!

=item HASHREF C<list_problems>()

Returns either a hash of hashes of arrays containing the 
problems that were found when setting the various attributes
of the SICI segments or C<undef> if there are no problems.

The first hash level is indexed by the three SICI segments:
I<item>, I<contribution>, and/or I<control>.

The level below is indexed by the attribute names (cf. the
docs of the segment modules).

For every attribute the third level contains an array reference
with descriptive messages.

  {
      'contribution' => {
          'titleCode' => [
              'contains more than 6 characters',
          ],
      },
  };

B<TODO> check for meta problems (e.g. missing attributes).

=back

=head1 TODO

The parsing of SICI strings sort-of works but I need to find
out more about how the code copes with real world SICIs (i.e. 
especially those that are slightly malformed or invalid).

It would probably make for a better programming style if I were
using real type specifications for the attributes. On the other
hand doing so would make the module employ overly strict checks
when dealing with imperfect SICIs. 
Since type checks in Moo (or Moose) know nothing about the object, 
the only other solution I can think of would be using objects of 
type C<Biblio::SICI> act as frontend for instances of either 
I<Biblio::SICI::Strict> or I<Biblio::SICI::Lax>.
This would require two separate sets of type definitions and make 
everything more complicated - and I am not sure if would provide 
us with a better way to handle and report formal problems.

That said, I´m also not particularly happy with how 
C<list_problems()> works right now and I´d be grateful for any
suggestions for improvements (or for positive feedback if it works
for you).

Also for now only problems with the available data are detected
while missing or inconsistend data is not checked for.

And of course we need a more comprehensive test suite.

=head1 SEE ALSO

L<https://en.wikipedia.org/wiki/Serial_Item_and_Contribution_Identifier>

=head1 AUTHOR

Heiko Jansen <hjansen@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Heiko Jansen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
