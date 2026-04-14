########################################################################
package DarkPAN::Utils::Docs;
########################################################################

use strict;
use warnings;

use English qw(-no_match_vars);
use Data::Dumper;
use IO::Scalar;
use Pod::Extract qw(extract_pod);
use Scalar::Util qw(openhandle);
use Text::Markdown::Discount qw(markdown);

use Readonly;

Readonly::Scalar our $TRUE  => 1;
Readonly::Scalar our $FALSE => 0;

our %ATTRIBUTES = (
  text       => $TRUE,  # required
  pod        => $FALSE,
  code       => $FALSE,
  sections   => $FALSE,
  markdown   => $FALSE,
  html       => $FALSE,
  url_prefix => $FALSE,
);

__PACKAGE__->setup_accessors( keys %ATTRIBUTES );

use parent qw(Class::Accessor::Validated);

our $VERSION = '1.0.0';

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $self = $class->SUPER::new(@args);

  # text is required so we will alway have text
  my $text = $self->get_text;

  if ( ref $text && openhandle $text ) {
    my $fh = $text;

    local $RS = undef;
    $text = <$fh>;
    close $fh;
  }
  elsif ( ref $text ) {
    $text = ${$text};
  }

  $self->set_text($text);

  return $self->parse_pod();
}

########################################################################
sub parse_pod {
########################################################################
  my ($self) = @_;

  my $text = $self->get_text;

  my $fh = IO::Scalar->new( \$text );

  my @result = extract_pod( $fh, { markdown => $TRUE, url_prefix => $self->get_url_prefix } );

  close $fh;

  foreach my $attr (qw(pod code sections markdown)) {
    my $setter = "set_$attr";

    $self->$setter( shift @result );
  }

  if ( $self->get_pod ) {
    $self->set_html( Text::Markdown::Discount::markdown( $self->get_markdown ) );
  }

  return $self;
}

########################################################################
sub to_html {
########################################################################
  my ( $self, $markdown ) = @_;

  $markdown //= $self->get_markdown;
  $markdown =~ s/^\s+$//xsm;

  if ( !$markdown ) {
    $markdown = $self->get_text;
  }

  return
    if !$markdown;

  $self->set_html( Text::Markdown::Discount::markdown($markdown) );

  return $self->get_html;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

DarkPAN::Utils::Docs - extract and render POD from Perl module source

=head1 SYNOPSIS

 use DarkPAN::Utils::Docs;

 # From a source string (e.g. extracted from a tarball)
 my $docs = DarkPAN::Utils::Docs->new( text => $module_source );

 if ( $docs->get_pod ) {
   print $docs->get_html;
 }

 # With a URL prefix for cross-references in the rendered HTML
 my $docs = DarkPAN::Utils::Docs->new(
   text       => $module_source,
   url_prefix => 'https://cpan.openbedrock.net/orepan2/docs',
 );

 print $docs->get_html;

 # From a filehandle
 open my $fh, '<', 'lib/My/Module.pm' or die $!;
 my $docs = DarkPAN::Utils::Docs->new( text => $fh );
 print $docs->get_markdown;

 # From a scalar reference
 my $docs = DarkPAN::Utils::Docs->new( text => \$source_string );

 # Convert a plain Markdown string to HTML without POD extraction
 my $docs = DarkPAN::Utils::Docs->new( text => $readme_markdown );
 my $html = $docs->to_html;

=head1 DESCRIPTION

C<DarkPAN::Utils::Docs> accepts Perl module source (as a string, scalar
reference, or filehandle) and extracts its embedded POD documentation
using L<Pod::Extract>. The extracted POD is converted to Markdown and
then to HTML via L<Text::Markdown::Discount>.

The constructor always calls C<parse_pod> immediately, so all derived
attributes (C<pod>, C<code>, C<sections>, C<markdown>, C<html>) are
populated by the time C<new> returns.

The C<to_html> method provides a lighter-weight alternative when the
source text is already in Markdown format (e.g. a F<README.md>) and
POD extraction is not required.

=head1 CONSTRUCTOR

=head2 new

 my $docs = DarkPAN::Utils::Docs->new( text => $source );

Creates a new instance. The C<text> attribute is required. Immediately
normalises the text and calls C<parse_pod>, populating all derived
attributes.

=head3 Attributes

=over 4

=item text (required)

The source material to process. May be:

=over 4

=item * A plain string containing Perl source or Markdown.

=item * A scalar reference (C<\$source>) — dereferenced automatically.

=item * An open filehandle — read completely and closed automatically.

=back

=item url_prefix

Optional URL prefix prepended to cross-reference links in the rendered
HTML. Passed directly to L<Pod::Extract> and used to resolve
C<L<Module::Name>> links into browsable URLs within the DarkPAN site.

=item pod

Populated by C<parse_pod>. Contains the raw extracted POD text, or
C<undef> if no POD was found.

=item code

Populated by C<parse_pod>. Contains the non-POD (code) portions of the
source text.

=item sections

Populated by C<parse_pod>. A data structure describing the top-level
POD sections found in the source, as returned by L<Pod::Extract>.

=item markdown

Populated by C<parse_pod>. The POD rendered as a Markdown string.

=item html

Populated by C<parse_pod> (and by C<to_html>). The final HTML output
rendered from the Markdown.

=back

=head1 METHODS AND SUBROUTINES

=head2 parse_pod

 $docs->parse_pod;

Extracts POD from the stored C<text>, converts it to Markdown using
L<Pod::Extract>, and then renders the Markdown to HTML using
L<Text::Markdown::Discount>. Updates the C<pod>, C<code>, C<sections>,
C<markdown>, and C<html> attributes in place.

If no POD is found in the source, C<pod> remains C<undef> and C<html>
is not set.

Called automatically by C<new>; callers do not normally need to invoke
this directly unless the C<text> attribute has been changed after
construction.

Returns C<$self>.

=head2 to_html

 my $html = $docs->to_html;

 my $html = $docs->to_html($markdown_string);

Converts Markdown to HTML using L<Text::Markdown::Discount>. If a
Markdown string is passed as an argument it is used directly. Otherwise
the method falls back in order to: the stored C<markdown> attribute,
then the raw C<text> attribute.

Returns C<undef> if no usable content is found.

This method is intended for source text that is already in Markdown
format (such as a F<README.md>), where POD extraction via C<parse_pod>
is unnecessary.

Returns the rendered HTML string, and also sets the C<html> attribute
as a side effect.

=head1 AUTHOR

Rob Lauer - E<lt>rlauer@treasurersbriefcase.comE<gt>

=head1 SEE ALSO

L<DarkPAN::Utils>, L<Pod::Extract>, L<Text::Markdown::Discount>,
L<IO::Scalar>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
