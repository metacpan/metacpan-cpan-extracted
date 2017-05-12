#!perl
use Test::More tests => 4;

BEGIN {
      use_ok ("Astro::NED::Response::Objects");
}


my @bad_files = qw( data/bad_ra.html );

for my $file ( @bad_files )
{

    my $objs = eval { Astro::NED::Response::Objects->new(); };
    ok ( !$@, "create object" ) or diag( $@ );

    my $html = read_html( $file );

    eval { $objs->parseHTML( $html ); };
    ok ( $@, "parse $file" );
}


sub read_html
{
    my ( $file ) = @_;

    my $html = 
      eval {
          local $/ = undef;
          open( HTML, '<', $file ) 
            or die( "internal error: unable to open $file");
          $html = <HTML>;
          close HTML;

          return $html;
      };

    ok ( !$@, "read $file" ) or diag( $@ );

    return $html;
}
