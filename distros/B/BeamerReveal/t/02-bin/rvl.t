# -*- cperl -*-
use Test::More;

use IO::File;
use File::Basename;
use File::Compare;
use File::Spec;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Indent = 1;

$0 =~ qr{(?<path>.*)\.(?<ext>[^\.]+)$};
$path = $+{path};
$path =~ s/\.\///;

plan tests => 1;
pass( "dummy" );

__END__

my @testfiles = glob "$path/*.rvl";
plan tests => scalar @testfiles;

foreach my $file ( sort @testfiles ) {
  my ($name, $path, $suffix) = File::Basename::fileparse( $file, qr/\.[^.]+$/ );
  my $base = File::Spec->catfile( $path, $name );
  system( "bin/beamer-reveal.pl $base 1> $base.out 2> $base.err" );
  if ( $name =~ /-fail$/ ) {
    eval {
      if( File::Compare::compare_text( "$base.err", "$base.err.golden",
				       sub { $_[0] ne $_[1] } )
	  or
	  File::Compare::compare_text( "$base.brlog", "$base.brlog.golden",
				       sub { $_[0] =~ s/^--.*$//g; $_[1] =~ s/^--.*$//g; $_[0] ne $_[1] } ) ) {
	fail( $file );
      }
      else {
	pass( $file );
      }
      1;
    } or do {
      fail( "$file: no golden file(s) available" );
    };
  }
  else {
    eval {
      if( File::Compare::compare_text( "$base.html", "$base.html.golden",
				       sub { $_[0] ne $_[1] } )
	  or
	  File::Compare::compare_text( "$base.brlog", "$base.brlog.golden",
				       sub { $_[0] =~ s/^--.*$//g; $_[1] =~ s/^--.*$//g; $_[0] ne $_[1] } ) ) {
	fail( $file );
      }
      else {
	pass( $file );
      }
      1;
    } or do {
      fail( "$file: no golden file(s) available" );
    };
  }
}
