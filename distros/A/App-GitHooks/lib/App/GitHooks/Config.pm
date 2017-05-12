package App::GitHooks::Config;

use strict;
use warnings;

# External dependencies.
use Carp;
use Config::Tiny;


=head1 NAME

App::GitHooks::Config - Configuration manager for App::GitHooks.


=head1 VERSION

Version 1.9.0

=cut

our $VERSION = '1.9.0';


=head1 SYNOPSIS

	my $config = App::GitHooks::Config->new();

	my $config = App::GitHooks::Config->new(
		file => '...',
	);

	my $value = $config->get( $section, $name );


=head1 METHODS

=head2 new()

Return a new C<App::GitHooks::Config> object.

	my $config = App::GitHooks::Config->new(
		file => $file,
	);

Arguments:

=over 4

=item * file I<(optional)>

A path to a config file to load into the object.

=item * source I<(optional)>

How the path of the config file to use was determined.

=back

=cut

sub new
{
	my ( $class, %args ) = @_;
	my $file = delete( $args{'file'} );
	my $source = delete( $args{'source'} );

	my $self = defined( $file )
		? Config::Tiny->read( $file )
		: Config::Tiny->new();

	bless( $self, $class );

	# Store meta-information for future reference.
	$self->{'__source'} = $source;
	$self->{'__path'} = $file;

	return $self;
}


=head2 get()

Retrieve the value for a given section and key name.

	my $value = $config->get( $section, $name );

Note that the C<App::GitHooks> configuration files are organized by sections,
with the main (default) section being '_'.

=cut

sub get
{
	my ( $self, $section, $name ) = @_;

	croak 'A section name is required as first argument'
		if !defined( $section ) || ( $section eq '' );
	croak 'A key name is required as second argument'
		if !defined( $name ) || ( $name eq '' );

	return defined( $self->{ $section } )
		? $self->{ $section }->{ $name }
		: undef;
}


=head2 get_regex()

Retrieve the specified regex for a given section and key name.

	my $regex = $config->get_regex( $section, $name );

Note that this is very much like C<get()>, except that it will treat the value as a regex and strip out outer '/' symbols so that the result is suitable for inclusion in a regex. For example:

	my $regex = $config->get_regex( $section, $name );
	if ( $variable =~ /$regex/ )
	{
		...
	}

=cut

sub get_regex
{
	my ( $self, $section, $name ) = @_;

	my $value = $self->get( $section, $name );
	return undef
		if !defined( $value ) || $value eq '';

	my ( $regex ) = $value =~ /^\s*\/(.*?)\/\s*$/;
	croak "The key $name in the section $section is not a regex, use /.../ to delimit your expression"
		if !defined( $regex );
	croak "The key $name in the section $section does not specify a valid regex, it has unescaped '/' delimiters inside it"
		if $regex =~ /(?<!\\)\//;

	return $regex;
}


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/App-GitHooks/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc App::GitHooks::Config


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
