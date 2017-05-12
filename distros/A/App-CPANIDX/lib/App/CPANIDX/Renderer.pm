package App::CPANIDX::Renderer;

use strict;
use warnings;
use YAML::Tiny;
use JSON::XS;
use XML::Simple;
use HTML::Tiny;
use vars qw[$VERSION];

$VERSION = '0.40';

my %types = (
  'yaml', 'application/x-yaml; charset=utf-8',
  'json', 'application/json; charset=utf-8',
  'xml',  'application/xml; charset=utf-8',
  'html', 'text/html',
);

my %renderers = (
  'yaml', sub {
                my $ref = shift;
                my $string;
                eval { $string = YAML::Tiny::Dump( $ref ); };
                return $string;
          },
  'json', sub {
                my $ref = shift;
                my $string;
                eval { $string = JSON::XS->new->utf8(1)->pretty(1)->encode( $ref ); };
                return $string;
          },
  'xml',  sub {
                my $ref = shift;
                my $type = shift || 'opt';
                my %data;
                $data{$type} = $ref;
                my $string;
                eval { $string = XMLout(\%data, RootName => 'results' ); };
                return $string;
          },
  'html', sub {
                my $ref = shift;
                return _gen_html( @{ $ref } );;
          },
);

sub renderers {
  return sort keys %renderers;
}

sub new {
  my $package = shift;
  my $data = shift;
  return unless $data and ref $data eq 'ARRAY';
  my $format = shift || 'yaml';
  $format = lc $format;
  return unless exists $types{ $format };
  bless { _data => $data, _format => $format }, $package;
}

sub render {
  my $self = shift;
  my $type = shift;
  my $contype = $types{ $self->{_format} };
  my $content  = $renderers{ $self->{_format} }->( $self->{_data}, $type );
  return ($contype, $content) if wantarray;
  return [ $contype, $content ];
}

sub _gen_html {
  my @results = @_;
  my $h = HTML::Tiny->new();
  my $data;
  if ( !scalar @results ) {
    $data = $h->p('There were no results, sorry');
  }
  else {
    my @th = sort keys %{ $results[0] };
    $data = $h->table( { border => 1, cellspacing => 0, width => '100%' },
          [
            \'tr',
            [ \'th', @th  ],
            map { my $href = $_;
               [ \'td', map { $href->{$_} } sort keys %$href ] } @results,
          ]
    );
  }
  return $h->html(
    [
      $h->head( $h->title( 'Results' ) ),
      $h->body(
        [
          $data
        ]
      )
    ]
  );
}

1;

__END__

=head1 NAME

App::CPANIDX::Renderer - Generates web content for App::CPANIDX

=head1 SYNOPSIS

  my @types = App::CPANIDX::Renderer->renderers;

  my $ren = App::CPANIDX::Renderer->new( \@data, 'yaml' );

  my ($content_type, $content) = $ren->render();

=head1 DESCRIPTION

App::CPANIDX::Renderer renders web content for L<App::CPANIDX>.

=head1 CONSTRUCTOR

=over

=item C<new>

Returns a new App::CPANIDX::Renderer object. Takes two parameters, an arrayref of
data to be rendered, which is required, and the format, either C<yaml>, C<json>, C<xml>
or C<html>, to render to, which defaults to C<yaml>.

=back

=head1 CLASS METHODS

=over

=item C<renderers>

Returns a list of the supported renderers.

  my @types = App::CPANIDX::Renderer->renderers;

=back

=head1 METHODS

=over

=item C<render>

Renders the previously supplied data to the format specified. Optionally takes one parameter,
which mainly has utility with the C<xml> format.

=back

=head1 AUTHOR

Chris C<BinGOs> Williams <chris@bingosnet.co.uk>

=head1 LICENSE

Copyright E<copy> Chris Williams

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<App::CPANIDX>

=cut
