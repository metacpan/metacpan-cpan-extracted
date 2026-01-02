# -*- cperl -*-
# ABSTRACT: MediaManager


package BeamerReveal::MediaManager;
our $VERSION = '20260101.1937'; # VERSION

use strict;
use warnings;

use Carp;

use POSIX;

use File::Which;
use File::Path;
use File::Copy;
use File::Basename;

use Data::UUID;

use IO::File;

use MCE::Hobo;
use MCE::Util;
use MCE::Shared::Scalar;

use Time::HiRes;

use BeamerReveal::TemplateStore;
use BeamerReveal::IPC::Run;
use IPC::Run qw(harness start pump finish); 

use BeamerReveal::Log;

sub min { $_[$_[0] > $_[1] ] }
sub nofdigits { length( "$_[0]" ) }


sub new {
  my $class = shift;
  my ( $jobname, $base, $presentationprms ) = @_;

  my $self = {
	      jobname    => $jobname,
	      base       => $base,
	     };
  $class = (ref $class ? ref $class : $class );
  bless $self, $class;

  $self->{presentationparameters} = $presentationprms;

  ########################
  # Prepare all the paths

  $self->{videos}     = "$self->{base}/media/Videos";
  $self->{audios}     = "$self->{base}/media/Audios";	
  $self->{images}     = "$self->{base}/media/Images";	
  $self->{animations} = "$self->{base}/media/Animations";	
  $self->{iframes}    = "$self->{base}/media/Iframes";	
  $self->{slides}     = "$self->{base}/media/Slides";
  $self->{reveal}     = "$self->{base}/libs";
  
  # create animation path, but don't remove contents
  File::Path::make_path( $self->{animations} );

  # create all the ohter paths and also clean them
  for my $item ( qw(reveal videos audios iframes images) ) {
    File::Path::rmtree( $self->{$item} );
    File::Path::make_path( $self->{$item} );
  }

  # read the relevant part of the preamble of the job
  my $texFileName = $self->{jobname};
  my $realTexFileName;
  foreach my $ext ( qw(tex ltx latex) ) {
    $realTexFileName = $texFileName . ".$ext";
    last if ( -r $realTexFileName );
  }

  my $logger = $BeamerReveal::Log::logger;
  
  my $texFile = IO::File->new();
  $texFile->open( "<$realTexFileName" )
    or $logger->fatal( "Error: could not open your original LaTeX source file '$realTexFileName'\n" );
  $self->{preamble} = '';
  my $line;
  do { $line = <$texFile> } until( $line =~ /\\usepackage[^{]*{beamer-reveal}/ );
  $line = "%% Preamble excerpt taken from $realTexFileName\n";
  until ( $line =~ /\\begin\{document\}/ ) {
    $self->{preamble} .= $line;
    $line = <$texFile>;
  }
  $texFile->close();
  $self->{preamble} .= "%% End of preamble excerpt\n";

  ####################################################
  # check all the preconditions for running our tools
  $self->{compiler} = File::Which::which( $self->{presentationparameters}->{compiler} )
    or $logger->fatal( "Error: your setup is incomplete, I cannot find your $self->{presentationparameters}->{compiler } compiler (should be part of your TeX installation)\n" .
	    "Make sure it is accessible in a directory on your PATH list variable\n" );
  
  $self->{pdftoppm} = File::Which::which( 'pdftoppm' )
    or $logger->fatal( "Error: your setup is incomplete, I cannot find pdftoppm (part of the poppler library)\n" .
	    "Install 'Poppler-utils' and make sure pdftoppm is accessible in a directory on your PATH list variable\n" );

  $self->{pdfcrop} = File::Which::which( 'pdfcrop' )
    or $logger->fatal( "Error: your setup is incomplete, I cannot find pdfcrop (should be part of your TeX installation)\n" .
	    "Make sure it is accessible in a directory on your PATH list variable\n" );
  $self->{ffmpeg} = File::Which::which( 'ffmpeg' )
    or $logger->fatal( "Error: your setup is incomplete, I cannot find ffmpeg\n" .
	    "Install 'FFmpeg' (from www.ffmpeg.org) and make sure ffmpeg is accessible in a directory on your PATH list variable\n" );

  ##########################################################################
  # We sell things, before we make the, so we need to keep a backorder list

  $self->{copyBackOrders}  = [];
  $self->{constructionBackOrders}  = [];

  return $self;
}


sub revealToStore {
  my $self = shift;

  my $revealTree = File::ShareDir::dist_dir( 'BeamerReveal' ) . '/libs';
  my $destTree = $self->{reveal};

  File::Copy::Recursive::dircopy( $revealTree, $destTree );
}


sub slideFromStore {
  my $self = shift;
  my ( $slide ) = @_;
  
  # copy file
  my $fullpathid = "$self->{slides}/$slide";
  # return store id
  return $fullpathid;
}


sub animationFromStore {
  my $self = shift;
  my ( $animation ) = @_;
  
  my $logger = $BeamerReveal::Log::logger;
  
  my $animid  = Digest::SHA::hmac_sha256_hex( $animation->{tex} );
  my $animdir = "$self->{animations}/$animid";
  my $fullpathid = $animdir . ".mp4";
  
  unless ( -r $fullpathid ) {
    File::Path::make_path( $animdir );

    my $templateStore = BeamerReveal::TemplateStore->new();
    my $tTemplate = $templateStore->fetch( 'tex', 'animation.tex' );
    my $tStamps =
      {
       'PREAMBLE'  => $self->{preamble},
       'FRAMERATE' => $animation->{framerate},
       'DURATION'  => $animation->{duration},
       'ANIMATION' => $animation->{tex},
      };
    my $fileContent = BeamerReveal::TemplateStore::stampTemplate( $tTemplate, $tStamps );
  
    my $nofFrames = floor( $animation->{framerate} * $animation->{duration} );
    my $nofCores  = MCE::Util::get_ncpu();
    if ( $nofCores > 4 ) {
      $nofCores = ceil( $nofCores / 2 );
    }

    push @{$self->{constructionBackOrders}},
      {
       animation   => $animation,
       fileContent => $fileContent,
       nofFrames   => $nofFrames,
       nofCores    => $nofCores,
       animid      => $animid,
      };
  }
  return $fullpathid;
}


sub processConstructionBackOrders {
  my $self = shift;
  my ( $progressId ) = @_;
  
  my $logger = $BeamerReveal::Log::logger;
  
  my $totalNofBackOrders = @{$self->{constructionBackOrders}};

  $logger->progress( $progressId, 1, 'reusing cached data', 1 ) unless $totalNofBackOrders;
  
  for( my $i = 0; $i < $totalNofBackOrders; ++$i ) {
    my $bo = $self->{constructionBackOrders}->[$i];

    my $animation   = $bo->{animation};
    my $fileContent = $bo->{fileContent};
    my $nofFrames   = $bo->{nofFrames};
    my $nofCores    = $bo->{nofCores};
    my $animid      = $bo->{animid};
    my $animdir     = "$self->{animations}/$animid";
    
    # I cannot get multithreading/multiprocessing to work reliably on MS-Windows
    my $progress;
    my $sliceSize = $nofFrames;
    if ( $^O eq 'MSWin32' ) {
      $logger->log( 6, "- Preparing media generation of $nofFrames (alas, no parallellization on MS-Windows)" );
      $nofCores = 1;
      $progress = MCE::Shared::Scalar->new( 0 );
    }
    elsif ( $nofCores == 1 ) {
      $progress = MCE::Shared::Scalar->new( 0 );
    }      
    else {
      $sliceSize = ceil( $nofFrames / $nofCores );
      $logger->log( 6, "- Preparing media generation of $nofFrames frames in $nofCores threads at $sliceSize frames per thread" );
      $progress = MCE::Shared->scalar( 0 );
    }

    # make planning
    my $frameCounter = 0;
    my $planning = [];
    for( my $core = 0; $core < $nofCores; ++$core ) {
      # make plan for core
      my $plan = { nstart => $frameCounter,
		   nstop  => min( $frameCounter + $sliceSize, $nofFrames ),
		   nr     => $core
		 };
      $plan->{slicestart} = 1;
      $plan->{slicestop}  = $plan->{nstop} - $plan->{nstart};
      $plan->{nstop}      -= 1;
      
      # register plan
      push @$planning, $plan;

      # prepare for next core
      $frameCounter += $sliceSize;
    }
    
    $logger->progress( $progressId, 0, "animation @{[$i+1]}/$totalNofBackOrders",
		       $nofFrames + $nofCores * 3 );
    
    if ( $nofCores == 1 ) {
      # single-threaded
      for( my $i = 0; $i < @$planning; ++$i ) {
	_animWork( $planning->[$i], $nofCores, $fileContent, $animdir, $self, $animation,
		   $sliceSize, $progress, $progressId );
      }
    }
    else {
      my @hobos;
      # multi-threaded
      for( my $i = 0; $i < @$planning; ++$i ) {
	push @hobos, MCE::Hobo->create
	  (
	   sub {
	     _animWork( @_ )
	   }, ( $planning->[$i], $nofCores, $fileContent, $animdir, $self, $animation,
		$sliceSize, $progress, $progressId )
	  );
      }
      
      my $activeworkers = @hobos;
      while ( $activeworkers ) {
	
	my @joinable = MCE::Hobo->list_joinable();
	foreach my $hobo ( @joinable ) {
	  $hobo->join();
	  --$activeworkers;
	}
	
 	$logger->progress( $progressId, $progress->get() );

	Time::HiRes::usleep(250);
      }
      
      $_->join for @hobos;
      $logger->log( 6, "- returning to single-threaded operation" );
    }
    
    # rename all files in order
    my $framecounter = 0;
    for( my $core = 0; $core < @$planning; ++$core ) {
      my $plan = $planning->[$core];
      my $coreId = sprintf( '%0' . nofdigits( $nofCores ) . 'd', $core );
      for( my $frameno = $plan->{slicestart}; $frameno <= $plan->{slicestop}; ++$frameno ) {
	my $frameId = sprintf( '%0' . nofdigits( $sliceSize ) . 'd', $frameno );
	# my $src = File::Spec->catfile( $animdir, "frame-$coreId-$frameId.jpg" );
	# my $dst = File::Spec->catfile( $animdir, sprintf( "frame-%06d.jpg", $framecounter++ ) );
	my $src = "$animdir/frame-$coreId-$frameId.jpg";
	my $dst = sprintf( "$animdir/frame-%06d.jpg", $framecounter++ );
	File::Copy::move( $src, $dst );
      }
    }
    
    # run ffmpeg or avconv
    my $cmd = [ $self->{ffmpeg}, '-r', "$animation->{framerate}", '-i', 'frame-%06d.jpg', 'animation.mp4' ];
    BeamerReveal::IPC::Run::run( $cmd, 0, 8, $animdir );
    File::Copy::move( "$animdir/animation.mp4",
		      "$animdir/../$animid.mp4" );

    File::Path::rmtree( $animdir );

    # all is done
    $logger->progress( $progressId, 1, "animation @{[$i+1]}/$totalNofBackOrders", 1 );
    
    ### issues:
    # - automatic derivation of dimensions (needs to be multiple of 2)
  }
}
    

sub imageFromStore {
  my $self = shift;
  my ( $image ) = @_;
  return $self->_fromStore( 'Images', $image );
}



sub videoFromStore {
  my $self = shift;
  my ( $video ) = @_;
  return $self->_fromStore( 'Videos', $video );
}


sub iframeFromStore {
  my $self = shift;
  my ( $iframe ) = @_;
  return $self->_fromStore( 'Iframes', $iframe );
}


sub audioFromStore {
  my $self = shift;
  my ( $audio ) = @_;
  return $self->_fromStore( 'Audios', $audio );
}


sub _fromStore {
  my $self = shift;
  my ( $type, $file ) = @_;

  # find extension
  my ( undef, undef, $ext ) = File::Basename::fileparse( $file, qr/\.[^.]+$/ );
  
  # create store id
  my $id = Data::UUID->new();
  my $fullpathid;
  do {
    my $uuid = $id->create();
    #$fullpathid = File::Spec->catfile( $self->{base}, 'media', $type, $id->to_string( $uuid ) . $ext );
    $fullpathid = "$self->{base}/media/$type/@{[$id->to_string( $uuid )]}$ext";
  } until( ! -e $fullpathid );

  # register backorder
  push @{$self->{copyBackOrders}},
    {
     type => $type,
     from => $file,
     to   => $fullpathid,
    };
  
  return $fullpathid;

  # # copy file
  # die( "Error: cannot find media file '$file'\n" ) unless( -r $file );
  # File::Copy::cp( $file, $fullpathid );
}


sub processCopyBackOrders {
  my $self = shift;
  my ( $progressId ) = @_;

  my $logger = $BeamerReveal::Log::logger;
  
  my $totalNofBackOrders = @{$self->{copyBackOrders}};

  for( my $i = 0; $i < $totalNofBackOrders; ++$i ) {
    my $bo = $self->{copyBackOrders}->[$i];

    # verify if source file exists
    $logger->fatal( "Error: cannot find media file '$bo->{from}'\n" ) unless( -r $bo->{from} );

    # report progress and copy
    $logger->progress( $progressId, $i, "file $i/$totalNofBackOrders", $totalNofBackOrders );
    File::Copy::cp( $bo->{from}, $bo->{to} );
  }
  $logger->progress( $progressId, 1, "file $totalNofBackOrders/$totalNofBackOrders", 1 );
}



sub _animWork {
  my ( $plan, $nofCores, $fileContent, $animdir, $self, $animation, $sliceSize, $progress, $progressId ) = @_;

  my $cmd;
  my $logFile = IO::File->new();
  my $coreId = sprintf( '%0' . nofdigits( $nofCores ) . 'd', $plan->{nr} );
  my $logFileName = "$animdir/animation-$coreId-overall.log";
  $logFile->open( ">$logFileName" )
    or die( "Error: cannot open logfile $logFileName" );

  say $logFile "- Generating TeX file";
  # generate TeX -file
  my $perCoreContent = BeamerReveal::TemplateStore::stampTemplate
    ( $fileContent,
      {
       SLICESTART  => $plan->{slicestart},
       SLICESTOP   => $plan->{slicestop},
       NSTART      => $plan->{nstart},
      }
    );
	   
  my $texFileName = "$animdir/animation-$coreId.tex";
  my $texFile = IO::File->new();
  $texFile->open( ">$texFileName" )
    or die( "Error: cannot open animation file '$texFileName' for writing\n" );
  print $texFile $perCoreContent;
  $texFile->close();

  say $logFile "- Running TeX";
  # run TeX
  $cmd = [ $self->{compiler},
	   "--output-directory=$animdir", "$texFileName" ];

  my $logger = $BeamerReveal::Log::logger;
  my $counter = 0;
  BeamerReveal::IPC::Run::runsmart( $cmd, 1, qr/\[(\d+)\]/,
				    sub {
				      while( scalar @_ ) {
					my $a = shift @_;
					while( $a > $counter ) {
					  ++$counter;
					  $progress->incr();
					  if ( $nofCores == 1 ) {
					    $logger->progress( $progressId, $progress->get() );
					  }
					}
				      }
				    },
				    $coreId,
				    8
				  );
  # my $in = '';
  # my $out;
  # my $err;
  # my $logger = $BeamerReveal::Log::logger;
  # my $h  = harness $cmd, \$in, \$out, \$err;
  # start $h;
  # while( $h->pumpable ) {
  #   pump $h;
  #   if( $out =~ /(\[\d+\])/ ) {
  #     $logger->log( 0, "================== $1 ====================\n\n" . $out . "\n" );
  #     # $logger->progress( $self->{progressId}, $1, "background $1/$2", $2 );
  #     $out = '';
  #   };
  # }
  # finish $h or die( "returned $?" );
  
  #BeamerReveal::IPC::Run::run( $cmd, $coreId, 8 );
  
  say $logFile "- Cropping PDF file";
  # run pdfcrop
  $cmd = [ $self->{pdfcrop}, '--margins', '-2', "animation-$coreId.pdf" ];
  BeamerReveal::IPC::Run::run( $cmd, $coreId, 8, $animdir );
  $progress->incr();

  # run pdftoppm
  my $xrange = 2 * int( $self->{presentationparameters}->{canvaswidth} * $animation->{width} );
  my $yrange = 2 * int( $self->{presentationparameters}->{canvasheight} * $animation->{height} );
	   
  say $logFile "- Generating jpg files";
  $cmd = [ $self->{pdftoppm},
	   '-scale-to-x', "$xrange",
	   '-scale-to-y', "$yrange",
	   "animation-$coreId-crop.pdf", "./frame-$coreId", '-jpeg' ];
  BeamerReveal::IPC::Run::run( $cmd, $coreId, 8, $animdir );
  $progress->incr();

  # correct for too short slicesize in filenames coming from pdftoppm
  say $logFile "- Cleaning up jpg files";
  my $currentDigitCnt = nofdigits( $plan->{slicestop} );
  my $desiredDigitCnt = nofdigits( $sliceSize );
  if ( $currentDigitCnt < $desiredDigitCnt ) {
    for ( my $i = 1; $i <= $plan->{slicestop}; ++$i ) {
      #	  my $src = File::Spec->catfile( $animdir, sprintf( "frame-$coreId-%0" . $currentDigitCnt . 'd.jpg', $i ) );
      #	  my $dst = File::Spec->catfile( $animdir, sprintf( "frame-$coreId-%0" . $desiredDigitCnt . 'd.jpg', $i ) );
      my $src = sprintf( "$animdir/frame-$coreId-%0${currentDigitCnt}d.jpg", $i );
      my $dst = sprintf( "$animdir/frame-$coreId-%0${desiredDigitCnt}d.jpg", $i );
      File::Copy::move( $src, $dst );
    }
  }
  $logFile->close();

  $progress->incr();
}

    
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

BeamerReveal::MediaManager - MediaManager

=head1 VERSION

version 20260101.1937

=head1 SYNOPSIS

Worker object to manage the media files generated for the Reveal HTML presentation.
Sometimes the management is just a matter of copying files (videos, images, iframe material)
in the media store under a unique ID.
Sometimes the file still needs to be generated (TikZ animations).
The former operations are cheap. Therefore they are copied at every invocation and stored under a unique ID.
The latter are expensive to generate. Therefore they are stored under an ID that is a secure hash value (SHA-standard)
based on the source data that is used to generate the animation.
This makes sure that whenever the animation does not change in between different runs,
we reuse the generated video file. If the source data has changed, we regenerate it.

=head1 METHODS

=head2 new()

  $mm = BeamerReveal::MediaManager->new( $jobname, $base, $presoparams, $id )

The constructor sets up the manager.

This involves: (a) the directory structure of the filesystemtree in which all objects will be
stored; we cal this the "media store", (b) reading the preamble of the original source file,
(c) checking whether all the auxiliary tools (your latex compiler, pdfcrop, pdftoppm, ffmpeg)
are available.

=over 4

=item . C<$jobname>

name of the job that can lead us back to the original LaTeX source file, such that
we can read the preamble for reuse in the TikZ animations.

=item . C<$base>

directory in shiche the media will reside. Typically, this is the base name of the final HTML
file, followed by the suffix '_files'.

=item . C<$presoparams>

parameters of the presentation. This is required to know the compiler and the resolution of the
presentation

=item . C<$mm>

return value: the mediamanager object

=back

=head2 revealToStore()

  $mm->revealToStore()

Fetches the original reveal support files and copies them into the media store.

=head2 slideFromStore()

  $path = $mm->slideFromStore( $slide )

Fetches the media store pathname of $slide. Slides are entered into the store by the
C<Frameconverter>.

=over 4

=item . C<$slide>

the slide to fetch

=item . C<$path>

the path of the slide (in the media store)

=back

=head2 animationFromStore()

  $path = $mm->animationFromStore( $animation )

Returns the media store path to the animation. If the animation is not yet constructed, it will be put in back order, such that it can be generated later by C<processConstructionBackOrders()>.

=over 4

=item . C<$animation>

the $animation object as it was read from the C<.rvl> file.

=item . C<$path>

the path of the animation (in the media store)

=back

=head2 processConstructionBackOrders()

  $mm->processConnstructionBackOrders( $id )

Generates all animations if they are not cached in the store.
The generation is done in parallel using multithreading. If the method fails
the temporary files are kept, otherwise they are removed. On MS-Windows there
is no working multithreading/multiprocessing.

=over 4

=item . C<$id>

progress ID (controls the corresonding progressbar)

=back

=head2 imageFromStore()

  $path = $mm->imageFromStore( $image )

Fetches the unique ID of the C<$image> and returns that ID (the filename of the oject in the media store). The object is put in back-order such that it can be copied later, using C<processCopyBackOrders>.

=over 4

=item . C<$image>

the $image file to store in the media store.

=item . C<$path>

the path to the image (in the media store)

=back

=head2 videoFromStore()

  $path = $mm->videoFromStore( $video )

Fetches the unique ID of the C<$video> and returns that ID (the filename of the oject in the media store). The object is put in back-order such that it can be copied later, using C<processCopyBackOrders>.

=over 4

=item . C<$video>

the $video file to store in the media store.

=item . C<$path>

the path to the video (in the media store)

=back

=head2 iframeFromStore()

  $path = $mm->iframeFromStore( $iframe )

Fetches the unique ID of the C<$iframe> and returns that ID (the filename of the oject in the media store). The object is put in back-order such that it can be copied later, using C<processCopyBackOrders>.

=over 4

=item . C<$iframe>

the $iframe file to store in the media store.

=item . C<$path>

the path to the iframe (in the media store)

=back

=head2 audioFromStore()

  $path = $mm->audioFromStore( $audio )

Fetches the unique ID of the C<$audio> and returns that ID (the filename of the oject in the media store). The object is put in back-order such that it can be copied later, using C<processCopyBackOrders>.

=over 4

=item . C<$audio>

the $audio file to store in the media store.

=item . C<$path>

the path to the audio (in the media store)

=back

=head2 _fromStore()

Helper function; do not use directly.

=head2 processCopyBackOrders()

  $mm->processCopyBackOrders( $id )

Copies the backordered files from their original location into the store, based on the backorder list.

=over 4

=item . C<$id>

progress ID (controls the corresponding progressbar)

=back

=head2 _animWork()

Worker function; do not use directly.

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
