# -*- cperl -*-
use Test::More;

my @modules = map { $_ =~ s/lib\/(.+)\.pm$/$1/;
		    $_ =~ s/\//::/g;
		    $_
		  } glob( "lib/BeamerReveal/*.pm lib/BeamerReveal/*/*.pm" );

plan tests => scalar @modules;

foreach my $module ( @modules ) {
  {
    # say STDERR $module;
    use_ok( "$module" );
  }
}

