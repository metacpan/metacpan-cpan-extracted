use utf8;
use Test::More;

my $class = 'Antsy';
BAIL_OUT( "Bail out! $class did not compile\n" ) unless use_ok( $class );

my %exportable = map { $_ => 1 } @Antsy::EXPORT_OK;

my %general = (
	# SUB                COMMAND  ALLOWED
	erase_in_display => [ 'J',    0 .. 3 ],
	erase_in_line    => [ 'K',    0 .. 2 ],
	);

foreach my $name ( sort keys %general ) {
	my( $command, @allowed ) = $general{$name}->@*;

	subtest $name => sub {
		my $code = $class->can( $name );
		ok( defined $code, "$name is defined" ) or return;
		ok( $exportable{$name}, "$name is in \@EXPORT_OK" );

		is( $code->(), "\e[0$command", "$name() defaults to 0" );
		is( $code->($_), "\e[$_$command", "$name($_)" ) for @allowed;

		foreach my $bad ( -1, $allowed[-1] + 1, 'x' ) {
			my @warnings;
			local $SIG{__WARN__} = sub { push @warnings, @_ };
			is( $code->($bad), '', "$name($bad) returns the empty string" );
			is( scalar @warnings, 1, "$name($bad) warns" );
			}
		};
	}

my %helpers = (
	erase_to_end_of_screen      => "\e[0J",
	erase_to_start_of_screen    => "\e[1J",
	erase_screen                => "\e[2J",
	erase_screen_and_scrollback => "\e[3J",
	erase_to_end_of_line        => "\e[0K",
	erase_to_start_of_line      => "\e[1K",
	erase_line                  => "\e[2K",
	);

foreach my $name ( sort keys %helpers ) {
	subtest $name => sub {
		my $code = $class->can( $name );
		ok( defined $code, "$name is defined" ) or return;
		ok( $exportable{$name}, "$name is in \@EXPORT_OK" );
		is( $code->(), $helpers{$name}, "$name returns the right sequence" );
		};
	}

done_testing();

__END__

=encoding utf8

=head1 NAME

t/erase.t - check Antsy's erase functions

=head1 SYNOPSIS

	$ prove -l t/erase.t

=head1 DESCRIPTION

Checks that C<erase_in_display> and C<erase_in_line> return the right
sequence for each allowed argument and for no argument, and that a bad
argument warns and returns the empty string. Also checks that each
named shortcut, such as C<erase_to_end_of_screen>, is defined, is in
C<@EXPORT_OK>, and returns the right sequence.

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
