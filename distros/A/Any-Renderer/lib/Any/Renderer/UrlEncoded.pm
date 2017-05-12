package Any::Renderer::UrlEncoded;

# $Id: UrlEncoded.pm,v 1.11 2006/09/04 12:15:53 johna Exp $

use strict;
use vars qw($VERSION);

use Hash::Flatten;
use URI::Escape;

$VERSION = sprintf"%d.%03d", q$Revision: 1.11 $ =~ /: (\d+)\.(\d+)/;

use constant FORMAT_NAME => "UrlEncoded";

sub new
{
  my ( $class, $format, $options ) = @_;
  die("Invalid format $format") unless($format eq FORMAT_NAME);

  $options ||= {};
  my $self = {
    'options' => $options,
    'delim' => $options->{Delimiter} || '&',
  };

  bless $self, $class;
  return $self;
}

sub render
{
  my ( $self, $data ) = @_;
  TRACE ( "Rendering data as UrlEncoded" );

  my $flat = Hash::Flatten::flatten ( $data, $self->{options}{FlattenOptions} );
  DUMP ( $flat );

  my $rv = join ( $self->{delim}, map { URI::Escape::uri_escape($_) . "=" . URI::Escape::uri_escape($flat->{$_}) } keys %$flat );
  TRACE($rv);
  
  return $rv;
}

sub requires_template
{
  return 0;
}

sub available_formats
{
  return [ FORMAT_NAME ];
}

sub TRACE {}
sub DUMP {}

1;

=head1 NAME

Any::Renderer::UrlEncoded - convert data structures into a UrlEncoded string

=head1 SYNOPSIS

  use Any::Renderer;

  my %options = ('FlattenOptions' => {'HashDelimiter' => '->'});
  my $format = "UrlEncoded";
  my $r = new Any::Renderer ( $format, \%options );

  my $data_structure = {...};
  my $string = $r->render ( $data_structure );

You can get a list of all formats that this module handles using the following syntax:

  my $list_ref = Any::Renderer::UrlEncoded::available_formats ();

Also, determine whether or not a format requires a template with requires_template:

  my $bool = Any::Renderer::UrlEncoded::requires_template ( $format );

=head1 DESCRIPTION

Any::Renderer::UrlEncoded renders a Perl data structure as a URI encoded string.
Keys and values are escaped via URI::Escape::uri_escape.  For example:

  perl -MAny::Renderer -e "print Any::Renderer->new('UrlEncoded')->render({a => 1, b => [2,3]})"

results in:

  a=1&b%3A1=3&b%3A0=2

This can be passed as a query string to a CGI script and reconstituted using Hash::Flatten::unflatten:

  use CGI;
  use Hash::Flatten;
  my $data_structure = Hash::Flatten::unflatten( CGI->new()->Vars() );

B<NB. the top-level of the data structure must be a hashref.>

=head1 FORMATS

=over 4

=item UrlEncoded

=back

=head1 METHODS

=over 4

=item $r = new Any::Renderer::UrlEncoded($format,\%options)

C<$format> must be C<UrlEncoded>.
See L</OPTIONS> for a description of valid C<%options>.

=item $string = $r->render($data_structure)

The main method.

=item $bool = Any::Renderer::UrlEncoded::requires_template($format)

False in this case.

=item $list_ref = Any::Renderer::UrlEncoded::available_formats()

Just the one - C<UrlEncoded>.

=back

=head1 OPTIONS

=over 4

=item Delimiter

The character separating each key=value pair.  Defaults to &.  You might want to change to ; if you are embedding values in XML documents.

=item FlattenOptions

A hashref passed to Hash::Flatten (see L<Hash::Flatten> for the list of options it supports).

=back

=head1 SEE ALSO

L<Hash::Flatten>, L<URI::Escape>, L<Any::Renderer>

=head1 VERSION

$Revision: 1.11 $ on $Date: 2006/09/04 12:15:53 $ by $Author: johna $

=head1 AUTHOR

Matt Wilson and John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut
