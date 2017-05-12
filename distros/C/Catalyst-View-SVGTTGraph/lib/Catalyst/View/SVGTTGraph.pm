package Catalyst::View::SVGTTGraph;

use strict;
use warnings;
use base qw(Catalyst::View);
use UNIVERSAL::require;


my($Revision) = '$Id: SVGTTGraph.pm,v 1.2 2006/02/18 03:03:28 takayama Exp $'; #'

our $VERSION = '0.02';

use Data::Dumper;

=head1 NAME

Catalyst::View::SVGTTGraph - SVG Graph View Component for Catalyst

=head1 SYNOPSIS

in your config.

  $c->config->{'View::SVGTTGraph'}->{image_format} = 'png';

Supported formats are 'Image::LibRSVG->getSupportedFormats()' call to see.

in your View.

  package MyApp::View::SVGTTGraph;
  use base 'Catalyst::View::SVGTTGraph';

in your controller.

  sub pie_graph : Local {
      my @fields = qw(Jan Feb Mar);
      my @data_sales_02 = qw(12 45 21);

      $c->svgttg->create('Pie',
                         {'height' => '500',
                          'width' => '300',
                          'fields' => \@fields,
                         });
      $c->svgttg->graph_obj->add_data({
                                       'data' => \@data_sales_02,
                                       'title' => 'Sales 2002',
                                      });
  }

  sub end : Private {
      my ( $self, $c ) = @_;
      $c->forward('Catalyst::View::SVGTTGraph');
  }

and see L<SVG::TT::Graph>.

=head1 DESCRIPTION

Catalyst::View::SVGTTGraph is Catalyst view handler of SVG::TT::Graph.

=cut

=head1 METHODS

=head2 new

this method makes method named $c->svgttg.
$c->svgttg is an accessor to the object of Catalyst::View::SVGTTGraphObj.
$c->svgttg uses $c->stash->{'Catalyst::View::SVGTTGraph'}.

=cut

sub new {
    my $class = shift;
    my $c     = shift;
    my $self;
    if( $Catalyst::VERSION >= 5.8 ) {
        MRO::Compat->use or die "can not use MRO::Compat : $@\n";
        $self = $class->maybe::next::method( $c, @_ );
    }
    else {
        NEXT->use or die "can not use NEXT : $@\n";
        $self = $class->NEXT::new( $c, @_ );
    }
    if( exists $c->config->{'View::SVGTTGraph'}->{image_format}
        and $c->config->{'View::SVGTTGraph'}->{image_format} ne 'svg' ) {
        Image::LibRSVG->use or die "can not use Image::LibRSVG : $@\n";
        die join( "\n",
                  '',
                  "this format is not support on this system : ".$c->config->{'View::SVGTTGraph'}->{image_format},
                  "please check support formats. call Image::LibRSVG->getSupportedFormats()",
                  '' )
            unless( Image::LibRSVG->isFormatSupported( $c->config->{'View::SVGTTGraph'}->{image_format} ) );
    }
    {
        no strict 'refs';
        my $accessor = sub {
            my $c = shift;
            unless( $c->stash->{'Catalyst::View::SVGTTGraph'} ) {
                my $obj = Catalyst::View::SVGTTGraphObj->new();
                # config
                if( exists $c->config->{'View::SVGTTGraph'} and ref( $c->config->{'View::SVGTTGraph'} ) eq 'HASH' ) {
                    $obj->config( $c->config->{'View::SVGTTGraph'} );
                    $obj->_rsvg( Image::LibRSVG->new )
                        if( exists $obj->config->{image_format} );
                }
                else {
                    $obj->config( {} );
                }
                $c->stash->{'Catalyst::View::SVGTTGraph'} = $obj;
                return $c->stash->{'Catalyst::View::SVGTTGraph'};
            }
        };
        *{"${c}::svgttg"} = $accessor;
        *{"${c}::_svgttg_accessor"} = $accessor;
    }
    return $self
}

=head2 process

create SVG Graph

=cut

    my $content_types = {
        'png'      => 'image/png',
        'tga'      => 'image/targa',
        'ico'      => 'image/vnd.microsoft.icon',
        'xpm'      => 'image/x-xpixmap',
        'qtif'     => 'image/x-quicktime',
        'xbm'      => 'image/x-xbitmap',
        'icns'     => '',
        'wbmp'     => 'image/vnd.wap.wbmp',
        'bmp'      => 'image/x-bmp',
        'wmf'      => 'application/x-msmetafile',
        'tiff'     => 'image/tiff',
        'pcx'      => 'image/x-pcx',
        'ras'      => 'image/x-cmu-raster',
        'gif'      => 'image/gif',
        'ani'      => 'application/octet-stream',
        'jpeg'     => 'image/jpeg',
        'pnm'      => 'image/x-portable-anymap',
        'jpeg2000' => 'image/jpeg',
        'svg'      => 'image/svg+xml'
    };

sub process {
    my $self = shift;
    my $c = shift;
    
    die "Catalyst::View::SVGTTGraph : graph object is undefined !"
        unless( $c->svgttg->graph_obj );
    if( exists $c->svgttg->config->{image_format}
        and $c->config->{'View::SVGTTGraph'}->{image_format} ne 'svg'
        and Image::LibRSVG->isFormatSupported( $c->svgttg->config->{image_format} ) ) {
        $c->svgttg->graph_obj->compress( 0 );
        $c->svgttg->_rsvg->loadImageFromString( $c->svgttg->burn );

        
        $c->res->header( 'Content-Type' => $content_types->{ $c->svgttg->config->{image_format} } );
        $c->res->body( $c->svgttg->_rsvg->getImageBitmap( $c->svgttg->config->{image_format} ) );
    }
    else {
        $c->res->header('Content-Type' => 'image/svg+xml');
        $c->res->header('Content-Encoding' => 'gzip') if( $c->svgttg->graph_obj->compress );
        $c->res->body($c->svgttg->burn);
    }
    return 1;
}

1;


package Catalyst::View::SVGTTGraphObj;

use strict;
use base 'Class::Accessor::Fast';
use UNIVERSAL::require;

sub new {
    my $pkg = shift;
    my $c = shift;
    my $this = bless({}, $pkg);
    $this->mk_accessors(qw(graph_obj _c config _rsvg));
    $this->graph_obj(undef);
    $this->_c($c);
    return $this;
}

=head2 $c->svgttg->create

The object of new SVG::TT::Graph is made.
Please input the kind of the graph to the first argument.
Thereafter, it comes to be able to use $c->svgttg->graph_obj.

  $c->svgttg->create('Bar');
or
  $c->svgttg->create('Bar', {'height' => '500', 'width' => '300', 'fields' => \@fields});

=cut

sub create {
    my $this = shift;
    my $type = shift;
    
    my $opt = shift;

    my $graph_pkg = "SVG::TT::Graph::$type";
    $graph_pkg->use or die "Catalyst::View::SVGTTGraph : use error !\n$@";
    $this->graph_obj($graph_pkg->new($opt));
}

=head2 $c->svgttg->graph_obj

It accesses the object of SVG::TT::Graph.
Please use it after calling $c->svgttg->create.

  $c->svgttg->graph_obj->add_data(....);
  $c->svgttg->graph_obj->add_data(....);

=head2 $c->svgttg->burn

throws to SVG::TT::Graph->burn

  $c->svgttg->burn;

=cut

sub burn {
    my $this = shift;
    return $this->graph_obj->burn;
}

=head2 $c->svgttg->clear

clear $c->stash->{'Catalyst::View::SVGTTGraph'}

=cut

sub clear {
    my $this = shift;
    $this->_c->stash->{'Catalyst::View::SVGTTGraph'} = undef;
}

=head1 SEE ALSO

L<Catalyst>, L<SVG::TT::Graph>

=head1 AUTHOR

Shota Takayama, C<shot[atmark]bindstorm.jp>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Shanon, Inc. All Rights Reserved. L<http://www.shanon.co.jp/>

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
