use utf8;
use Test::More;

my $class = 'Antsy';
BAIL_OUT( "Bail out! $class did not compile\n" ) unless use_ok( $class );

my $start_of_line = "\e[1G";

my %moves = (
	# NAME                   COMMAND  WHAT 0 RETURNS
	cursor_back          => [ 'D', ''             ],
	cursor_column        => [ 'G', $start_of_line ],
	cursor_down          => [ 'B', ''             ],
	cursor_forward       => [ 'C', ''             ],
	cursor_next_line     => [ 'E', $start_of_line ],
	cursor_previous_line => [ 'F', $start_of_line ],
	cursor_row           => [ 'd', "\e[1d"        ],
	cursor_tab_back      => [ 'Z', ''             ],
	cursor_tab_forward   => [ 'I', ''             ],
	cursor_up            => [ 'A', ''             ],
	scroll_down          => [ 'T', ''             ],
	scroll_up            => [ 'S', ''             ],
	# aliases
	cursor_left          => [ 'D', ''             ],
	cursor_right         => [ 'C', ''             ],
	cursor_prev_line     => [ 'F', $start_of_line ],
	);

my %exportable = map { $_ => 1 } @Antsy::EXPORT_OK;

foreach my $name ( sort keys %moves ) {
	my( $command, $zero ) = $moves{$name}->@*;

	subtest $name => sub {
		my $code = $class->can( $name );
		ok( defined $code, "$name is defined" ) or return;
		ok( $exportable{$name}, "$name is in \@EXPORT_OK" );

		is( $code->(),   "\e[1$command",  "$name() defaults to 1" );
		is( $code->($_), "\e[$_$command", "$name($_)" ) for 1, 3, 12;
		is( $code->(0),  $zero,           "$name(0) never emits a count of 0" );
		is( $code->($_), $zero,           "$name('$_') counts as 0" ) for -2, 'x', 1.5;
		};
	}

foreach my $name ( qw( cursor_row_column cursor_position ) ) {
	subtest $name => sub {
		my $code = $class->can( $name );
		ok( defined $code, "$name is defined" ) or return;
		ok( $exportable{$name}, "$name is in \@EXPORT_OK" );

		is( $code->(),       "\e[1;1H",  "$name() defaults to 1, 1" );
		is( $code->(5),      "\e[5;1H",  "$name(5) defaults the column to 1" );
		is( $code->(5, 10),  "\e[5;10H", "$name(5, 10)" );
		};
	}

my %fixed = (
	cursor_home       => "\e[1;1H",
	cursor_line_start => $start_of_line,
	# DEC save and restore
	cursor_save_state       => "\e7",
	cursor_save_dec         => "\e7",
	cursor_save_all         => "\e7",
	decsc                   => "\e7",
	cursor_restore_state    => "\e8",
	cursor_restore_dec      => "\e8",
	cursor_restore_all      => "\e8",
	decrc                   => "\e8",
	# SCO save and restore
	save_cursor             => "\e[s",
	cursor_save             => "\e[s",
	cursor_save_position    => "\e[s",
	restore_cursor          => "\e[u",
	cursor_restore          => "\e[u",
	cursor_restore_position => "\e[u",
	hide_cursor       => "\e[?25l",
	cursor_hide       => "\e[?25l",
	show_cursor       => "\e[?25h",
	cursor_show       => "\e[?25h",
	cursor_position_request => "\e[6n",
	# cursor shapes (DECSCUSR)
	cursor_shape_default      => "\e[0 q",
	cursor_block_blinking     => "\e[1 q",
	cursor_block              => "\e[2 q",
	cursor_underline_blinking => "\e[3 q",
	cursor_underline          => "\e[4 q",
	cursor_bar_blinking       => "\e[5 q",
	cursor_bar                => "\e[6 q",
	);

foreach my $name ( sort keys %fixed ) {
	subtest $name => sub {
		my $code = $class->can( $name );
		ok( defined $code, "$name is defined" ) or return;
		ok( $exportable{$name}, "$name is in \@EXPORT_OK" );
		is( $code->(), $fixed{$name}, "$name returns the right sequence" );
		};
	}

subtest cursor_shape => sub {
	my $code = $class->can( 'cursor_shape' );
	ok( defined $code, 'cursor_shape is defined' ) or return;
	ok( $exportable{cursor_shape}, 'cursor_shape is in @EXPORT_OK' );

	is( $code->(),   "\e[0 q",  'cursor_shape() defaults to 0' );
	is( $code->($_), "\e[$_ q", "cursor_shape($_)" ) for 0 .. 6;

	foreach my $bad ( -1, 7, 'x' ) {
		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		is( $code->($bad), '', "cursor_shape($bad) returns the empty string" );
		is( scalar @warnings, 1, "cursor_shape($bad) warns" );
		}
	};

# cursor_get_position needs a real terminal to answer, so this checks
# that it's exported and that the reply parser works.
subtest cursor_get_position => sub {
	ok( defined &Antsy::cursor_get_position, 'cursor_get_position is defined' );
	ok( $exportable{cursor_get_position}, 'cursor_get_position is in @EXPORT_OK' );

	my $parse = \&Antsy::_parse_cursor_position_report;
	is_deeply( [ $parse->( "\e[12;34R" ) ],    [ 12, 34 ], 'parses a reply' );
	is_deeply( [ $parse->( "junk\e[1;1R" ) ],  [ 1, 1 ],   'ignores junk before the reply' );
	is_deeply( [ $parse->( '' ) ],             [],         'no reply returns the empty list' );
	is_deeply( [ $parse->( "\e[12;34" ) ],     [],         'a cut-off reply returns the empty list' );
	};

done_testing();

__END__

=encoding utf8

=head1 NAME

t/cursor.t - check Antsy's counted cursor and scroll moves

=head1 SYNOPSIS

	$ prove -l t/cursor.t

=head1 DESCRIPTION

For each cursor and scroll function that takes a count, checks that
it's defined and exportable, that the count defaults to 1, that it
returns the right sequence for several counts, and that a count of 0
(or anything that isn't a non-negative integer) never puts a 0 in the
sequence, because terminals treat that as 1.

Also checks the absolute moves C<cursor_row_column> and
C<cursor_position>, the fixed moves C<cursor_home> and
C<cursor_line_start>, hiding and showing the cursor under both of
their names (such as C<hide_cursor> and C<cursor_hide>), and every
name for saving and restoring the cursor, both the DEC versions (such
as C<cursor_save_state>) and the SCO versions (such as C<cursor_save>).

It checks C<cursor_shape> for each shape, its default, and bad values,
and each named shape such as C<cursor_bar>.

C<cursor_get_position> needs a real terminal to answer, so the test
only checks that it's exported and that its reply parser works.

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
