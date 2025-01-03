#!perl

package App::unichar;

use 5.026;
use utf8;
use warnings;
use open qw(:std :utf8);
use experimental qw(signatures);

our $VERSION = '0.014';

=encoding utf8

=pod

=head1 NAME

App::unichar - get info about a character

=head1 SYNOPSIS

Call it as a program with a name, character, or hex code number:

	% perl lib/App/unichar.pm 'CHECK MARK'
	Processing CHECK MARK
		match type  name
		code point  U+2713
		decimal     10003
		name        CHECK MARK
		character   ✓

	% perl lib/App/unichar.pm ✓
	Processing ✓
		match type  grapheme
		code point  U+2713
		decimal     10003
		name        CHECK MARK
		character   ✓

	% perl lib/App/unichar.pm 0x2713
	Processing 0x2713
		match type  code point
		code point  U+2713
		decimal     10003
		name        CHECK MARK
		character   ✓

=head1 DESCRIPTION

I use this as a little command-line program to quickly convert between
values of characters.

=head1 AUTHOR

brian d foy, C<briandfoy@pobox.com>.

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/app-unichar

=head1 COPYRIGHT & LICENSE

Copyright 2011-2024 brian d foy

This module is licensed under the Artistic License 2.0.

=cut

use Encode qw(decode);
use I18N::Langinfo qw(langinfo CODESET);

use charnames ();
use List::Util;

binmode STDOUT, ':utf8';

my %r = (
	u => qr/(?:U\+?(?<hex>[0-9A-F]+))/i,
	h => qr/(?:0x(?<hex>[0-9A-F]+))/i,
	d => qr/(?:(?<int>[0-9]+))/,
	);

my %transformation = (
	'hex' => sub { hex $_[0] },
	'int' => sub { $_[0] },
	);

my $codeset = langinfo(CODESET);
@ARGV = map { decode $codeset, $_ } @ARGV;

run( @ARGV ) unless caller;

sub run (@args) {
	foreach ( @args ) {
		say "Processing $_";

		if( / \A (?: $r{u} | $r{h} | $r{d} ) \z /x ) {
			my( $key ) = keys %+;
			my $code = $transformation{$key}( $+{$key} );
			output( $code, 'code point' );
			}
		elsif( / \A ([A-Z\s]{2,}) \z /ix ) {
			my $code = eval { charnames::vianame( uc($1) ) };
			unless( defined $code ) {
				say "\tCouldn't match <$1> to a code name";
				next;
				}
			output( $code, 'name' );
			}
		elsif( / \A (\X) \z /x ) {
			output( ord( $1 ), 'grapheme' );
			}
		elsif( / \A r: ([A-Z\s]{2,}) \z /ix ) { # new regex mode
			state $names = name_list();
			say "In elsif";
			my $pattern = s/\Ar://r;
			$pattern = eval{ qr/$pattern/i };
			if( $@ ) {
			    warn "Invalid pattern --> $pattern ---> $@\n";
			    exit(4);
			    }

			foreach my $name ( keys $names->%* ) {
				say "Tring $name";
				next unless $name =~ m/$pattern/;
				output( $names->{$name}, 'pattern' );
				}
			}
		else {
			say "\tInvalid character, codepoint, or pattern --> $_\n";
			next;
			}
		}
	}

sub name_list () {
	state $names = { map { charnames::viacode($_), $_ } 0 .. 0x3FFFF };
	return $names;
	}

sub output ( $code, $match ) {
	my $hex  = sprintf 'U+%04X', $code;
	my $char = chr( $code );
	$char = '<unprintable>' if $char !~ /\p{Print}/;
	$char = '<whitespace>'  if $char =~ /\p{Space}/;
	$char = '<control>'     if $char =~ /\p{Control}/;

	my $name = charnames::viacode( $code ) // '<no name found>';

	print <<~"HERE";
		match type  $match
		code point  $hex
		decimal     $code
		name        $name
		character   $char

	HERE

	}
