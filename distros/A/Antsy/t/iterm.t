use utf8;
use Test::More;

# Only run these in iTerm2 on macOS.
unless( $^O eq 'darwin' and ( $ENV{TERM_PROGRAM} // '' ) eq 'iTerm.app' ) {
	plan skip_all => 'these tests run only in iTerm2 on macOS';
	}

my $class = 'Antsy';
BAIL_OUT( "Bail out! $class did not compile\n" ) unless use_ok( $class );

# The public iTerm2 functions remember their first answer, so check each
# one in a fresh perl, with and without TERM_PROGRAM set to iTerm2.
sub run_perl {
	my( $term_program, $code ) = @_;
	local $ENV{TERM_PROGRAM} = $term_program;
	delete local $ENV{TERM_PROGRAM} unless defined $term_program;
	my $output = `"$^X" -Ilib -MAntsy -e '$code' 2>&1`;
	$output;
	}

my %shapes = (
	iterm_set_block_cursor     => 0,
	iterm_set_bar_cursor       => 1,
	iterm_set_underline_cursor => 2,
	);

foreach my $name ( sort keys %shapes ) {
	subtest $name => sub {
		my $code = "print Antsy::$name() // q(UNDEF)";

		my $in_iterm = run_perl( 'iTerm.app', $code );
		is( $in_iterm, "\e]1337;CursorShape=$shapes{$name}\007",
			"$name returns the cursor shape sequence in iTerm2" );

		foreach my $other ( 'Apple_Terminal', undef ) {
			my $label = $other // 'no TERM_PROGRAM';
			my $output = run_perl( $other, $code );
			like( $output, qr/\AAntsy::$name only works in iTerm2 at /,
				"$name warns, naming itself, outside iTerm2 ($label)" );
			like( $output, qr/UNDEF\z/,
				"$name returns nothing outside iTerm2 ($label)" );
			unlike( $output, qr/uninitialized/,
				"$name doesn't warn about an unset TERM_PROGRAM ($label)" );
			}
		};
	}

subtest iterm_set_cursor_shape => sub {
	foreach my $n ( 0 .. 2 ) {
		my $output = run_perl( 'iTerm.app', "print Antsy::iterm_set_cursor_shape($n)" );
		is( $output, "\e]1337;CursorShape=$n\007", "iterm_set_cursor_shape($n) in iTerm2" );
		}

	my $bad = run_perl( 'iTerm.app', 'print Antsy::iterm_set_cursor_shape(3) // q(UNDEF)' );
	like( $bad, qr/\AThe cursor type can be 0, 1, or 2/, 'a bad shape warns' );
	like( $bad, qr/UNDEF\z/, 'a bad shape returns nothing' );

	my $other = run_perl( undef, 'print Antsy::iterm_set_cursor_shape(0) // q(UNDEF)' );
	like( $other, qr/\AAntsy::iterm_set_cursor_shape only works in iTerm2 at /,
		'outside iTerm2, it warns, naming itself' );
	like( $other, qr/UNDEF\z/, 'outside iTerm2, it returns nothing' );
	};

done_testing();

__END__

=encoding utf8

=head1 NAME

t/iterm.t - check Antsy's iTerm2 cursor shape functions

=head1 SYNOPSIS

	$ prove -l t/iterm.t

=head1 DESCRIPTION

Checks that C<iterm_set_block_cursor>, C<iterm_set_bar_cursor>, and
C<iterm_set_underline_cursor> return the cursor shape sequence when
C<TERM_PROGRAM> says the terminal is iTerm2, and that anywhere else
they warn (naming themselves) and return nothing, without an extra
warning when C<TERM_PROGRAM> isn't set. It checks the same for
C<iterm_set_cursor_shape>, plus that it rejects a shape other than 0,
1, or 2.

These functions remember their first answer, so each case runs in a
separate perl.

The whole file is skipped unless it runs on macOS in iTerm2 (when
C<TERM_PROGRAM> is C<iTerm.app>).

=head1 SOURCE AVAILABILITY

This source is in GitHub:

	https://github.com/briandfoy/antsy

=head1 AUTHOR

Claude Opus 5.5 (Anthropic), author

brian d foy, C<< <briandfoy@pobox.com> >>, supervisor

=head1 COPYRIGHT AND LICENSE

Copyright © 2026, brian d foy C<< <briandfoy@pobox.com> >>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut
