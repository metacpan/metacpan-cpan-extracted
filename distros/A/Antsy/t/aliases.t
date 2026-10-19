use utf8;
use Test::More;

my $class = 'Antsy';
BAIL_OUT( "Bail out! $class did not compile\n" ) unless use_ok( $class );

# Each group lists names that should be interchangeable. A plain name is
# called with no arguments. An array reference is a name followed by the
# arguments to call it with.
my @fixed_groups = (
	# attributes
	[ qw( reset reset_all normal ) ],
	[ qw( dark dim faint ) ],
	[ qw( reverse inverse reverse_video ) ],
	[ qw( normal_intensity no_bold no_dark no_dim no_faint ) ],
	[ qw( no_reverse no_inverse no_reverse_video ) ],
	[ qw( conceal hidden ) ],

	# colors
	[ qw( text_bright_black text_gray text_grey ) ],
	[ qw( bg_bright_black bg_gray bg_grey ) ],

	# showing and hiding the cursor
	[ qw( hide_cursor cursor_hide ) ],
	[ qw( show_cursor cursor_show ) ],

	# saving and restoring the cursor, DEC
	[ qw( cursor_save_state cursor_save_dec cursor_save_all decsc ) ],
	[ qw( cursor_restore_state cursor_restore_dec cursor_restore_all decrc ) ],

	# saving and restoring the cursor, SCO
	[ qw( save_cursor cursor_save cursor_save_position ) ],
	[ qw( restore_cursor cursor_restore cursor_restore_position ) ],

	# fixed cursor moves
	[ 'cursor_home', ['cursor_row_column'], ['cursor_position'], [ 'cursor_row_column', 1, 1 ] ],
	[ 'cursor_line_start', [ 'cursor_column', 1 ] ],

	# erasing
	[ 'erase_to_end_of_screen',      'clear_to_screen_end',   ['erase_in_display'], [ 'erase_in_display', 0 ] ],
	[ 'erase_to_start_of_screen',    'clear_to_screen_start', [ 'erase_in_display', 1 ] ],
	[ 'erase_screen',                'clear_screen',          [ 'erase_in_display', 2 ] ],
	[ 'erase_screen_and_scrollback',                          [ 'erase_in_display', 3 ] ],
	[ 'erase_to_end_of_line',        'clear_to_line_end',     ['erase_in_line'],    [ 'erase_in_line', 0 ] ],
	[ 'erase_to_start_of_line',      'clear_to_line_start',   [ 'erase_in_line', 1 ] ],
	[ 'erase_line',                  'clear_line',            [ 'erase_in_line', 2 ] ],
	);

# These take arguments, so compare each group for every argument list.
my @argument_groups = (
	[ [ qw( cursor_back cursor_left ) ],                    [], [0], [1], [5] ],
	[ [ qw( cursor_forward cursor_right ) ],                [], [0], [1], [5] ],
	[ [ qw( cursor_previous_line cursor_prev_line ) ],      [], [0], [1], [5] ],
	[ [ qw( cursor_row_column cursor_position ) ],          [], [3], [3, 7], [24, 80] ],
	);

sub call {
	my( $member ) = @_;
	my( $name, @args ) = ref $member ? @$member : $member;
	my $code = $class->can( $name ) or return;
	$code->( @args );
	}

sub label {
	my( $member ) = @_;
	return $member unless ref $member;
	my( $name, @args ) = @$member;
	"$name(" . join( ', ', @args ) . ")";
	}

foreach my $group ( @fixed_groups ) {
	my( $first, @rest ) = @$group;
	subtest label( $first ) => sub {
		my $expected = call( $first );
		ok( defined $expected && length $expected, label( $first ) . ' returns a sequence' )
			or return;
		foreach my $member ( @rest ) {
			is( call( $member ), $expected, label( $member ) . ' is the same as ' . label( $first ) );
			}
		};
	}

foreach my $group ( @argument_groups ) {
	my( $names, @arg_lists ) = @$group;
	my( $first, @rest ) = @$names;
	subtest join( '/', @$names ) => sub {
		foreach my $args ( @arg_lists ) {
			my $expected = call( [ $first, @$args ] );
			ok( defined $expected, label( [ $first, @$args ] ) . ' returns a value' ) or next;
			foreach my $name ( @rest ) {
				is( call( [ $name, @$args ] ), $expected,
					label( [ $name, @$args ] ) . ' is the same as ' . label( [ $first, @$args ] ) );
				}
			}
		};
	}

done_testing();

__END__

=encoding utf8

=head1 NAME

t/aliases.t - check that Antsy's aliases return the same thing

=head1 SYNOPSIS

	$ prove -l t/aliases.t

=head1 DESCRIPTION

Antsy often has several names for the same sequence, such as C<dark>,
C<dim>, and C<faint>, or C<cursor_back> and C<cursor_left>. For each
group of names, this checks that every name is defined and returns
exactly what the first name in the group returns. Names that take
arguments are compared for several argument lists, including none and
0.

The groups also include pairs that were never declared as aliases but
emit the same sequence, such as C<erase_line>, C<clear_line>, and
C<erase_in_line(2)>.

When you add an alias, add it to its group here.

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
