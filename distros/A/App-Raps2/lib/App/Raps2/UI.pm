package App::Raps2::UI;

use strict;
use warnings;
use 5.010;

use Carp qw(cluck confess);
use POSIX;
use Term::ReadLine;

our $VERSION = '0.54';

sub new {
	my ($obj) = @_;

	my $ref = {};

	return bless( $ref, $obj );
}

sub list {
	my ( $self, @list ) = @_;

	my $format = "%-20s %-20s %s\n";

	if ( not $self->{list}->{header} ) {
		printf( $format, map { $_->[0] } @list );
		$self->{list}->{header} = 1;
	}
	printf( $format, map { $_->[1] // q{} } @list );

	return 1;
}

sub read_line {
	my ( $self, $str, $pre ) = @_;

	# Term::ReadLine->new() takes quite long but is not always required.
	# So create it here (if needed) instead of in ->new
	if ( not $self->{term_readline} ) {
		$self->{term_readline} = Term::ReadLine->new('App::Raps2');
	}

	my $input = $self->{term_readline}->readline( "${str}: ", $pre );

	return $input;
}

sub read_multiline {
	my ( $self, $str ) = @_;

	my $in;

	say "${str} (^D or empty line to quit)";

	while ( my $line = $self->read_line('multiline') ) {
		$in .= "${line}\n";
	}

	return $in;
}

sub read_pw {
	my ( $self, $str, $verify ) = @_;

	my ( $in1, $in2 );
	my $term = POSIX::Termios->new();

	$term->getattr(0);
	$term->setlflag( $term->getlflag() & ~POSIX::ECHO );
	$term->setattr( 0, POSIX::TCSANOW );

	print "${str}: ";
	$in1 = readline(STDIN);
	print "\n";

	if ($verify) {
		print 'Verify: ';
		$in2 = readline(STDIN);
		print "\n";
	}

	$term->setlflag( $term->getlflag() | POSIX::ECHO );
	$term->setattr( 0, POSIX::TCSANOW );

	if ( $verify and $in1 ne $in2 ) {
		confess('Input lines did not match');
	}

	chomp $in1;

	return $in1;
}

sub to_clipboard {
	my ( $self, $str, $cmd ) = @_;

	$cmd //= 'xclip -l 1';

	open( my $clipboard, q{|-}, $cmd )
	  or return;

	print $clipboard $str;

	close($clipboard)
	  or cluck("Failed to close pipe to ${cmd}: ${!}");

	return 1;
}

sub output {
	my ( $self, @out ) = @_;

	for my $pair (@out) {
		printf( "%-8s : %s\n", $pair->[0], $pair->[1] // q{}, );
	}

	return 1;
}

1;

__END__

=head1 NAME

App::Raps2::UI - App::Raps2 User Interface

=head1 SYNOPSIS

    my $ui = App::Raps2::UI->new();

    my $input = $ui->read_line('Say something');

    my $password = $ui->read_pw('New password', 1);

    $ui->to_clipboard('stuff!');

=head1 VERSION

This manual documents B<App::Raps2::UI> version 0.54

=head1 DESCRIPTION

App::Raps2::UI is used by App::Raps2 to interface with the user, i.e. do input
and output on the terminal.

=head1 METHODS

=over

=item $ui = App::Raps2::UI->new()

Returns a new App::Raps2::UI object.

=item $ui->list(I<\@item1>, I<\@item2>, I<\@item3>)

Print the list items neatly formatted to stdout. Each I<item> looks like B<[>
I<key>, I<value> B<]>. When B<list> is called for the first time, it will
print the keys as well as the values.

=item $ui->read_line(I<$question>, [I<$prefill>])

Print "I<question>: " to stdout and wait for the user to input text followed
by a newline.  I<prefill> sets the default content of the answer field.

Returns the user's reply, excluding the newline.

=item $ui->read_multiline(I<$message>)

Like B<read_line>, but repeats I<message> each time the user hits return.
Input is terminated by EOF (Ctrl+D).  Returns a string concatenation of all
lines (including newlines).

=item $ui->read_pw(I<$message>, I<$verify>)

Prompt the user for a password. I<message> is displayed, the user's input is
noch echoed.  If I<verify> is set, the user has to enter the same input twice,
otherwise B<read_pw> dies.  Returns the input.

=item $ui->to_clipboard(I<$string>, [I<command>])

Call I<command> to place I<string> in the primary X Clipboard.  I<command>
defaults to C<< xclip -l 1 >>.

Returns true upon success, undef if the operation failed. Use $! to get the
error message.

=item $ui->output(I<\@pair>, I<...>)

I<pair> consinsts of B<[> I<key>, I<value> B<]>. For each I<pair>, prints
"     key : value" to stdout.

=back

=head1 DIAGNOSTICS

When App::Raps2::UI encounters an error, it uses Carp(3pm)'s B<confess>
function to die with a backtrace.

=head1 DEPENDENCIES

This module requires B<Term::ReadLine> and the B<xclip> executable.

=head1 BUGS AND LIMITATIONS

Unknown.

=head1 SEE ALSO

App::Raps2(3pm).

=head1 AUTHOR

Copyright (C) 2011-2015 by Daniel Friesel E<lt>derf@finalrewind.orgE<gt>

=head1 LICENSE

  0. You just DO WHAT THE FUCK YOU WANT TO.
