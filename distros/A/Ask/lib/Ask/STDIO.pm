use 5.008008;
use strict;
use warnings;

{
	package Ask::STDIO;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.012';
	
	use Moo;
	use namespace::autoclean;
	
	with 'Ask::API';
	
	sub is_usable {
		my ($self) = @_;
		-t STDIN and -t STDOUT;
	}
	
	sub quality {
		(-t STDIN and -t STDOUT) ? 80 : 20;
	}
	
	sub entry {
		my ($self, %o) = @_;
		$self->info(text => $o{text}) if exists $o{text};
		
		my ( $line, $tio );
		
		if ( $o{hide_text} and do { require POSIX; $tio = 'POSIX::Termios'->new } ) {
			require POSIX;
			my $tio = POSIX::Termios->new;
			$tio->getattr(0);
			$tio->setlflag($tio->getlflag & ~POSIX::ECHO());
			$tio->setattr(0);
			chomp( $line = <STDIN> );
			$tio->setlflag($tio->getlflag | POSIX::ECHO());
			$tio->setattr(0);
		}
		else {
			chomp( $line = <STDIN> );
		}
		
		return $line;
	}
	
	sub info {
		my ($self, %o) = @_;
		print STDOUT "$o{text}\n";
	}
	
	sub warning {
		my ($self, %o) = @_;
		print STDERR "WARNING: $o{text}\n";
	}
	
	sub error {
		my ($self, %o) = @_;
		print STDERR "ERROR: $o{text}\n";
	}
}

1;

__END__

=head1 NAME

Ask::STDIO - use STDIN/STDOUT/STDERR to interact with a user

=head1 SYNOPSIS

	my $ask = Ask::STDIO->new;
	
	$ask->info(text => "I'm Charles Xavier");
	if ($ask->question(text => "Would you like some breakfast?")) {
		...
	}

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Ask>.

=head1 SEE ALSO

L<Ask>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013, 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

