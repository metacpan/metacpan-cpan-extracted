use 5.008008;
use strict;
use warnings;

package Ask::Fallback;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.015';

use Moo;
use Carp qw(croak);
use Path::Tiny qw(path);
use namespace::autoclean;

with 'Ask::API';

sub quality {
	return 1;
}

sub info {
	my ( $self, %o ) = @_;
	print STDERR "$o{text}\n";
}

sub warning {
	my ( $self, %o ) = @_;
	print STDERR "WARNING: $o{text}\n";
}

sub error {
	my ( $self, %o ) = @_;
	print STDERR "ERROR: $o{text}\n";
}

sub question {
	my ( $self, %o ) = @_;
	exists $o{default} and return $o{default};
	croak "question (Ask::Fallback) with no default";
}

sub entry {
	my ( $self, %o ) = @_;
	exists $o{default} and return $o{default};
	croak "entry (Ask::Fallback) with no default";
}

sub file_selection {
	my ( $self, %o ) = @_;
	$o{multiple} and exists $o{default} and return map path( $_ ), @{ $o{default} };
	exists $o{default} and return path $o{default};
	croak "file_selection (Ask::Fallback) with no default";
}

sub single_choice {
	my ( $self, %o ) = @_;
	exists $o{default} and return $o{default};
	croak "single_choice (Ask::Fallback) with no default";
}

sub multiple_choice {
	my ( $self, %o ) = @_;
	exists $o{default} and return @{ $o{default} };
	croak "multiple_choice (Ask::Fallback) with no default";
}

1;

__END__

=head1 NAME

Ask::Fallback - backend for unattended scripts

=head1 SYNOPSIS

	my $ask = Ask::Fallback->new;
	
	$ask->info(text => "I'm Charles Xavier");
	if ($ask->question(
		text    => "Would you like some breakfast?",
		default => !!1,
	)) {
		...
	}

=head1 DESCRIPTION

This backend prints all output to STDERR; returns defaults for
C<question>, C<file_selection>, etc, and croaks if no defaults are
available.

This backend is used if the C<PERL_MM_USE_DEFAULT> or C<AUTOMATED_TESTING>
environemnt variables are set to true, or as a last resort if no other
Ask backend can be used.

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
