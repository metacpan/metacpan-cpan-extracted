# -*- cperl -*-
# ABSTRACT: BeamerFrame object


package BeamerReveal::Object::BeamerFrame;
our $VERSION = '20260101.1937'; # VERSION

use parent 'BeamerReveal::Object';
use Carp;

use Data::Dumper;

use BeamerReveal::TemplateStore;
use BeamerReveal::MediaManager;

use BeamerReveal::Log;

use Digest::SHA;


our $maxRawPage;
sub nofdigits { length( "$_[0]" ) }

sub new {
  my $class = shift;
  my ( $chunkData, $lines, $lineCtr ) = @_;
  
  $class = (ref $class ? ref $class : $class );
  my $self = {};
  bless $self, $class;

  my $logger = $BeamerReveal::Log::logger;
  
  $self->{videos}     = [];
  $self->{audios}     = [];
  $self->{images}     = [];
  $self->{iframes}    = [];
  $self->{animations} = [];
  ++$lineCtr;
  for( my $i = 0; $i < @$lines; ++$i ) {
    ( $lines->[$i] =~ /^-(?<command>\w+):(?<payload>.*)$/ )
      or $logger->fatal( "Error: syntax incorrect in rvl file on line $lineCtr '$lines->[$i]'\n" );
    if ( $+{command} eq 'parameters' ) {
      $self->{parameters} = BeamerReveal::Object::readParameterLine( $+{payload} );
    }
    elsif ( $+{command} eq 'video' ) {
      push @{$self->{videos}}, BeamerReveal::Object::readParameterLine( $+{payload} );
    }
    elsif ( $+{command} eq 'audio' ) {
      push @{$self->{audios}}, BeamerReveal::Object::readParameterLine( $+{payload} );
    }
    elsif ( $+{command} eq 'image' ) {
      push @{$self->{images}}, BeamerReveal::Object::readParameterLine( $+{payload} );
    }
    elsif ( $+{command} eq 'iframe' ) {
      push @{$self->{iframes}}, BeamerReveal::Object::readParameterLine( $+{payload} );
    }
    elsif ( $+{command} eq 'animation' ) {
      push @{$self->{animations}}, BeamerReveal::Object::readParameterLine( $+{payload} );
      $self->{animations}->[-1]->{tex} = $lines->[++$i];
    }
    else {
      $logger->fatal( "Error: unknown BeamerFrame data on line @{[ $lineCtr + $i ]} '$lines->[$i]'\n" );
    }
  }

  # The correctness of this relies on the pages appearing in order in the .rvl file
  $maxRawPage = $self->{parameters}->{rawpage};
  
  return $self;
}


sub makeSlide {
  my $self = shift;
  my ( $i, $mediaManager ) = @_;

  my $logger = $BeamerReveal::Log::logger;
  $logger->log( 2, "- making slide $i" );
  
  my $templateStore = BeamerReveal::TemplateStore->new();
  my $content = '';
  
  #############################
  # process all video material
  foreach my $video (@{$self->{videos}}) {
    $logger->log( 4, "- adding video" );
    my $vTemplate = $templateStore->fetch( 'html', 'video.html' );
    my $vStamps =
      { X => _topercent( $video->{x} ),
	Y => _topercent( $video->{y} ),
	W => _topercent( $video->{width} ),
	H => _topercent( $video->{height} ),
	VIDEO => $mediaManager->videoFromStore( $video->{file} ),
	FIT => $video->{fit},
	AUTOPLAY => exists $video->{autoplay} ? 'data-autoplay' : '',
	CONTROLS => exists $video->{controls} ? 'controls' : '',
	LOOP => exists $video->{loop} ? 'loop' : '',
      };
    $content .= BeamerReveal::TemplateStore::stampTemplate( $vTemplate,
							    $vStamps );
  }

  #############################
  # process all audio material
  foreach my $audio (@{$self->{audios}}) {
    $logger->log( 4, "- adding audio" );
    my $aTemplate = $templateStore->fetch( 'html', 'audio.html' );
    my $aStamps =
      { X => _topercent( $audio->{x} ),
	Y => _topercent( $audio->{y} ),
	W => _topercent( $audio->{width} ),
	H => _topercent( $audio->{height} ),
	AUDIO => $mediaManager->audioFromStore( $audio->{file} ),
	FIT => $audio->{fit},
	AUTOPLAY => exists $audio->{autoplay} ? 'data-autoplay' : '',
	CONTROLS => exists $audio->{controls} ? 'controls' : '',
	LOOP => exists $video->{loop} ? 'loop' : '',
      };
    $content .= BeamerReveal::TemplateStore::stampTemplate( $aTemplate,
							    $aStamps );
  }

  #############################
  # process all image material
  foreach my $image (@{$self->{images}}) {
    $logger->log( 4, "- adding image" );
    my $iTemplate = $templateStore->fetch( 'html', 'image.html' );
    my $iStamps =
      { X => _topercent( $image->{x} ),
	Y => _topercent( $image->{y} ),
	W => _topercent( $image->{width} ),
	H => _topercent( $image->{height} ),
	IMAGE => $mediaManager->imageFromStore( $image->{file} ),
	FIT => $image->{fit}
      };
    $content .= BeamerReveal::TemplateStore::stampTemplate( $iTemplate,
							    $iStamps );
  }

  #############################
  # process all iframe material
  foreach my $iframe (@{$self->{iframes}}) {
    $logger->log( 4, "- adding iframe" );
    my $iTemplate = $templateStore->fetch( 'html', 'iframe.html' );
    my $iStamps =
      { X => _topercent( $iframe->{x} ),
	Y => _topercent( $iframe->{y} ),
	W => _topercent( $iframe->{width} ),
	H => _topercent( $iframe->{height} ),
	IFRAME => $mediaManager->iframeFromStore( $iframe->{file} ),
	FIT => $iframe->{fit}
      };
    $content .= BeamerReveal::TemplateStore::stampTemplate( $iTemplate,
							    $iStamps );
  }

  #########################
  # process all animations
  foreach my $animation (@{$self->{animations}}) {
    $logger->log( 4, "- adding animation" );

    # 1. Generate the animation
    my $file = $mediaManager->animationFromStore( $animation );
    
    # 2. Embed it into the html
    my $aTemplate = $templateStore->fetch( 'html', 'animation.html' );
    my $aStamps =
      { X => _topercent( $animation->{x} ),
	Y => _topercent( $animation->{y} ),
	W => _topercent( $animation->{width} ),
	H => _topercent( $animation->{height} ),
	AUTOPLAY  => exists $animation->{autoplay} ? 'data-autoplay' : '',
	CONTROLS  => exists $animation->{controls} ? 'controls' : '',
	LOOP      => exists $animation->{loop} ? 'loop' : '',
	ANIMATION => $file,
	FIT       => $animation->{fit}
      };
    $content .= BeamerReveal::TemplateStore::stampTemplate( $aTemplate,
							    $aStamps );
  }

  # process the frame itself  
  my $fTemplate = $templateStore->fetch( 'html', 'beamerframe.html' );

  $self->{parameters}->{title} = _modernize( $self->{parameters}->{title} );
  
  my $menuTitle;
  if ( exists $self->{parameters}->{toc} ) {
    if( $self->{parameters}->{toc} eq 'titlepage' ) {
      $menuTitle = "<span class='menu-title'>%s</span>";
    }
    elsif( $self->{parameters}->{toc} eq 'section' ) {
      $menuTitle = "<span class='menu-section'>&bull; %s</span>";
    }
    elsif( $self->{parameters}->{toc} eq 'subsection' ) {
      $menuTitle = "<span class='menu-subsection'>&SmallCircle; %s</span>";
    }
    else {
      $logger->fatal( "Error: invalid toc parameter in rvl file" );
    }
  }
  else {
    $menuTitle = "<span class='menu-slide'>&bullet; %s</span>";
  }
  $menuTitle = sprintf( $menuTitle,
			$self->{parameters}->{title} );
			# $self->{parameters}->{truepage} );
  my $fStamps =
    {
     'DATA-MENU-TITLE' => $menuTitle,
     SLIDEIMAGE   => $mediaManager->slideFromStore( sprintf( 'slide-%0' . nofdigits( $maxRawPage ) . 'd.jpg',
		                                           $self->{parameters}->{rawpage} ) ),
     SLIDECONTENT => $content,
     TRANSITION   => $self->{parameters}->{transition} || 'none',
    };

  return BeamerReveal::TemplateStore::stampTemplate( $fTemplate, $fStamps );
}

sub _topercent { return sprintf( "%.2f%%", $_[0] * 100 ); }

sub _modernize {
  my $string = shift;
  my $dictionary = {		# a
		    qr/\\`\{?a\}?/ => 'à',
		    qr/\\'\{?a\}?/ => 'á',
		    qr/\\"\{?a\}?/ => 'ä',
		    qr/\\\^\{?a\}?/ => 'â',
		    qr/\\~\{?a\}?/ => 'ã',
		    qr/\\=\{?a\}?/ => 'ā',
		    qr/\\\.\{?a\}?/ => 'ȧ',
		    qr/\\u\{?a\}?/ => 'ă',
		    qr/\\v\{?a\}?/ => 'ǎ',
		    qr/\\c\{?a\}?/ => 'ą',
		    qr/\\r\{?a\}?/ => 'å',
		    qr/\\`\{?e\}?/ => 'è',
		    qr/\\'\{?e\}?/ => 'é',
		    qr/\\"\{?e\}?/ => 'ë',
		    qr/\\\^\{?e\}?/ => 'ê',
		    qr/\\~\{?e\}?/ => 'ẽ',
		    qr/\\=\{?e\}?/ => 'ē',
		    qr/\\\.\{?e\}?/ => 'ė',
		    qr/\\u\{?e\}?/ => 'ĕ',
		    qr/\\v\{?e\}?/ => 'ě',
		    qr/\\c\{?e\}?/ => 'ę',
		    qr/\\`\{?\\?i(?:\{\})?\}?/ => 'ì',
		    qr/\\'\{?\\?i(?:\{\})?\}?/ => 'í',
		    qr/\\"\{?\\?i(?:\{\})?\}?/ => 'ï',
		    qr/\\\^\{?\\?i(?:\{\})?\}?/ => 'î',
		    qr/\\~\{?\\?i(?:\{\})?\}?/ => 'ĩ',
		    qr/\\=\{?\\?i(?:\{\})?\}?/ => 'ī',
		    qr/\\u\{?\\?i(?:\{\})?\}?/ => 'ĭ',
		    qr/\\v\{?\\?i(?:\{\})?\}?/ => 'ǐ',
		    qr/\\c\{?\\?i(?:\{\})?\}?/ => 'į',
		    qr/\\`\{?o\}?/ => 'ò',
		    qr/\\'\{?o\}?/ => 'ó',
		    qr/\\"\{?o\}?/ => 'ö',
		    qr/\\\^\{?o\}?/ => 'ô',
		    qr/\\~\{?o\}?/ => 'õ',
		    qr/\\=\{?o\}?/ => 'ō',
		    qr/\\\.\{?o\}?/ => 'ȯ',
		    qr/\\u\{?o\}?/ => 'ŏ',
		    qr/\\v\{?o\}?/ => 'ǒ',
		    qr/\\c\{?o\}?/ => 'ǫ',
		    qr/\\`\{?u\}?/ => 'ù',
		    qr/\\'\{?u\}?/ => 'ú',
		    qr/\\"\{?u\}?/ => 'ü',
		    qr/\\\^\{?u\}?/ => 'û',
		    qr/\\~\{?u\}?/ => 'ũ',
		    qr/\\=\{?u\}?/ => 'ū',
		    qr/\\u\{?u\}?/ => 'ŭ',
		    qr/\\v\{?u\}?/ => 'ǔ',
		    qr/\\c\{?u\}?/ => 'ų',
		    qr/\\r\{?u\}?/ => 'ů',
		    qr/\\c\{?c\}?/ => 'ç',
		    qr/\\~\{?n\}?/ => 'ñ',
		    qr/\\oe/ => 'œ',
		    qr/\\OE/ => 'Œ',
		   };
  while( my ( $regexp, $rep ) = each ( %$dictionary ) ) {
    $string =~ s/$regexp/$rep/g;
  }
  return $string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::Object::BeamerFrame - BeamerFrame object

=head1 VERSION

version 20260101.1937

=head1 SYNOPSIS

Represents a BeamerFrame

=head1 METHODS

=head2 new()

  $bf = BeamerReveal::Object::BeamerFrame->new( $data, $lines, $linectr )

Generates a beamerframe from the correspond chunk data in the C<.rvl> file.

=over 4

=item . C<$data>

chunkdata to parse

=item . C<$lines>

body lines to parse

=item . C<$lineCtr>

starting line of the chunk (used for error reporting)

=item . C<$bf>

the beamerframe object

=back

=head2 makeSlide()

  $html = $bf->makeSlide( $mediaManager )

generate a HTML slides from this beamerframe.

=over 4

=item . C<$mediaManager>

mediamanager to use, to access all media files (and geneate animations when needed)

=item . C<$html>

HTML of the beamer frame, ready to be interpolated in the reveal framework.

=back

=head1 AUTHOR

Walter Daems <wdaems@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Walter Daems.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=head1 CONTRIBUTOR

=for stopwords Paul Levrie

Paul Levrie

=cut
