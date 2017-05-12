use Test::More tests => 2;

use File::Temp;
use Carp;

use Astro::FITS::CFITSIO;

use_ok( 'Astro::FITS::CFITSIO::CheckStatus' );

SKIP : {
  eval { require Log::Log4perl };

  skip 'Log::Log4perl not installed', 1 if $@;

  my $file = new File::Temp( UNLINK => 1 );
  Log::Log4perl::easy_init( { layout => '%l %m %n',
			      file => $file,
			    } );

  $logger = Log::Log4perl->get_logger;
  tie my $status, 'Astro::FITS::CFITSIO::CheckStatus', $logger;
  my $line;

  eval {
    $line = __LINE__ + 1;
    Astro::FITS::CFITSIO::open_file( 'file_does_not_exist.fits', 
				     Astro::FITS::CFITSIO::READONLY(),$status );
  };

  seek($file,0,0);
  local $/ = undef;
  my $txt = <$file>;

  ok( $@ && 
      $@ =~ /line $line/ && 
      $txt =~ m{t/log4perl.t \($line\)}, 'Log::Log4perl' );

}

      

