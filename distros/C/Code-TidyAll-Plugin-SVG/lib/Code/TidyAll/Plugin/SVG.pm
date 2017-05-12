package Code::TidyAll::Plugin::SVG;

use strict;
use warnings;

use XML::Twig;
use String::Escape qw(escape);

use Moo;
use namespace::clean;

extends 'Code::TidyAll::Plugin';

our $AUTHORITY = 'cpan:JONASS';
our $VERSION   = '0.003';

has 'indent'   => ( is => 'ro', default => sub {"\t"} );
has 'style'    => ( is => 'ro', default => sub {'cvs'} );
has 'comments' => ( is => 'ro', default => sub {'keep'} );

sub transform_file
{
	my $self = shift;
	my $file = shift;

	my $svg = XML::Twig->new(
		keep_encoding => 1,
		pretty_print  => $self->style,
		comments      => $self->comments,
		twig_handlers => {
			_all_ => sub { $_[0]->flush; },
		}
	);

	$svg->set_indent(
		escape( 'unqqbackslash unsinglequote', $self->indent ) );

	$svg->parsefile_inplace($file);
}

1;

__END__

=pod

=head1 NAME

Code::TidyAll::Plugin::SVG - optimize SVG files with tidyall

=head1 VERSION

version 0.003

=head1 SYNOPSIS

   In configuration:

   [SVG]
   select = **/*.svg
   style = cvs

=head1 DESCRIPTION

Uses L<XML::Twig> to optimize internal structure of SVG files.

=head1 CONFIGURATION

=over

=item style

Indentation style (as defined by L<XML::Twig>.

Recommmended values are indented (more compact) or cvs (nicer for
line-based revision control systems).

=item indent

Indentation string.

Default is a single TAB (i.e. C<\t>).

=item comments

How to treat comments (as defined by L<XML::Twig>.

Default is to keep comments.

=back

=head1 SEE ALSO

L<Code::TidyAll|Code::TidyAll>

L<XML::Twig>

=head1 AUTHOR

Jonas Smedegaard <dr@jones.dk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2016 by Jonas Smedegaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
