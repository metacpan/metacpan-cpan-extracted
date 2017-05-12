package App::GitHooks::Terminal;

use strict;
use warnings;

# External dependencies.
use Carp;
use Term::Encoding ();
use Term::ReadKey ();


=head1 NAME

App::GitHooks::Terminal - Information about the current terminal in which App::GitHook is running.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 SYNOPSIS

	use App::GitHooks::Terminal;

	my $terminal = App::GitHooks::Terminal->new();
	my $get_encoding = $terminal->get_encoding();
	my $get_width = $terminal->get_width();
	my $is_interactive = $terminal->is_interactive();
	my $is_utf8 = $terminal->is_utf8();


=head1 METHODS

=head2 new()

Return a new C<App::GitHooks::Terminal> object.

	my $terminal = App::GitHooks::Terminal->new();

=cut

sub new
{
    my ( $class ) = @_;

    return bless(
        {},
        $class,
    );
}


=head2 get_encoding()

Determine the current terminal's encoding.

	my $get_encoding = $terminal->get_encoding();

=cut

sub get_encoding
{
	my ( $self ) = @_;

	$self->{'encoding'} //= Term::Encoding::term_encoding();

	return $self->{'encoding'};
}


=head2 get_width()

Get the width (in the number of characters) of the current terminal.

	my $get_width = $terminal->get_width();

=cut

sub get_width
{
	my ( $self ) = @_;

	if ( $self->is_interactive() && !defined( $self->{'width'} ) )
	{
		my $output_width = (Term::ReadKey::GetTerminalSize())[0];
		$output_width //= 80;
		$self->{'width'} = $output_width;
	}

	return $self->{'width'};
}


=head2 is_interactive()

Determine whether the current terminal is interactive or not.

	my $is_interactive = $terminal->is_interactive();

=cut

sub is_interactive
{
	my ( $self ) = @_;

	if ( !defined( $self->{'is_interactive'} ) )
	{
		$self->{'is_interactive'} = -t STDOUT ? 1 : 0; ## no critic (InputOutput::ProhibitInteractiveTest)
	}

	return $self->{'is_interactive'};
}


=head2 is_utf8()

Determine if the current terminal supports utf-8.

	my $is_utf8 = $terminal->is_utf8();

Optionally, you can override the utf-8 support by passing an extra boolean
argument:

	$terminal->is_utf8(1); # Force utf-8 output.
	$terminal->is_utf8(0); # Force non-utf-8 output.

=cut

sub is_utf8
{
	my ( $self, $value ) = @_;

	if ( defined( $value ) )
	{
		croak "Invalid override value"
			if $value !~ /^(?:0|1)$/;

		$self->{'is_utf8'} = $value;
	}
	elsif ( !defined( $self->{'is_utf8'} ) )
	{
		my $terminal_encoding = $self->get_encoding();
		$self->{'is_utf8'} = $terminal_encoding =~ /^utf-?8$/xi ? 1 : 0;
	}

	return $self->{'is_utf8'};
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Terminal


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/App-GitHooks/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/app-githooks>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/app-githooks>

=item * MetaCPAN

L<https://metacpan.org/release/App-GitHooks>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2013-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
