package Database::BI::Command::password;

use strict;
use warnings;

our $VERSION = '0.022.0';

use Mojo::Base 'Mojolicious::Command';

use Carp qw(croak);
use Database::BI::Password qw(hash_password);
use Database::BI::I18N ();
use Readonly;

# What the command stops with.  Each ends in a newline, so croak prints it as
# it is, without the line it was raised at: they are for a person at a shell.
Readonly our %MESSAGES => (
	error_no_password => "password: no password given\n",
	error_mismatch    => "password: the two did not match\n",
);

# _text($key) -> the template for $key in the language the locale names.
sub _text { return Database::BI::I18N::text(__PACKAGE__, \%MESSAGES, $_[0]) }

has description => 'Make the password_hash line that turns on the login';
has usage       => sub { shift->extract_usage };

# _interactive() -> bool: whether a person is typing (STDIN is a terminal),
# who is asked twice.  A sub of its own so a test can be that person.
sub _interactive { return -t STDIN ? 1 : 0 }

# Reads one line from STDIN.  At a terminal the echo is turned off, so the
# password is not left on the screen or in a recording of it.
sub _read_secret {
	my ($prompt) = @_;
	my $tty = _interactive();
	my ($termios, $lflag);
	if ($tty) {
		print STDERR $prompt;
		require POSIX;
		$termios = POSIX::Termios->new;
		if ($termios->getattr(0)) {
			$lflag = $termios->getlflag;
			$termios->setlflag($lflag & ~(POSIX::ECHO() | POSIX::ECHONL()));
			$termios->setattr(0, POSIX::TCSANOW());
		}
	}
	my $line = <STDIN>;
	if (defined $lflag) {
		$termios->setlflag($lflag);
		$termios->setattr(0, POSIX::TCSANOW());
		print STDERR "\n";
	}
	return unless defined $line;
	$line =~ s/\r?\n\z//;
	return $line;
}

sub run {
	my ($self, @args) = @_;
	# A person at a shell: messages in the language their locale names.
	local $Database::BI::I18N::LANGUAGE = $Database::BI::I18N::LANGUAGE // Database::BI::I18N::from_locale();
	croak $self->usage if @args;

	my $password = _read_secret('Password: ');
	croak _text('error_no_password') unless defined $password && length $password;
	if (_interactive()) {
		my $again = _read_secret('Again: ');
		croak _text('error_mismatch') unless defined $again && $again eq $password;
	}

	my $hash = hash_password($password);
	print "Put this line in database_bi.conf, then restart the server:\n" if -t STDOUT;
	print "    password_hash => '$hash',\n";
	return;
}

1;

=encoding utf8

=head1 NAME

Database::BI::Command::password - Make the password_hash for the login

=head1 VERSION

0.022.0

=head1 SYNOPSIS

  Usage: script/database-bi password

    script/database-bi password                  # asks twice, without echo
    printf '%s\n' "$PW" | script/database-bi password   # from a script

=head1 DESCRIPTION

Asks for a password and prints the C<password_hash> line for
F<database_bi.conf>.  With that line in place, every page asks for the
password (see L<Database::BI/Logging in>).  Only the hash is printed; the
password is not stored anywhere.

=head1 METHODS

=head2 run

=head3 API SPECIFICATION

=head4 INPUT

    @args: none

=head4 OUTPUT

Prints C<< password_hash => '...', >> on STDOUT.  Croaks with the usage when
given arguments, and with a message from C<%Database::BI::Command::password::MESSAGES>
when no password is given or when the two typed at a terminal differ.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
