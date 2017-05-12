#!perl

use 5.008;
BEGIN {
  eval {
    require ModPerl::MM;
    require Apache::TestMM;
    require File::Spec;
  };
  if( $@ ) {
    warn $@;
    exit 0;
  }
  Apache::TestMM->import( qw(test clean) );
  File::Spec->import();
}

my $apxs;
for( my $i=0; $i<@ARGV; $i++ ) {
  if( $ARGV[$i] eq '-apxs' ) {
    $apxs=$ARGV[$i+1] if( $i<@ARGV );
    last;
  } elsif( $ARGV[$i]=~/^-apxs=(.+)/ ) {
    $apxs=$1;
    last;
  }
}

unless( length $apxs ) {
  foreach my $p (File::Spec->path,
		 qw!/usr/local/apache2/bin
		    /usr/local/apache2/sbin
		    /usr/local/apache/bin
		    /usr/local/apache/sbin
		    /usr/local/bin
		    /usr/local/sbin
		    /opt/apache2/bin
		    /opt/apache2/sbin
		    /opt/apache/bin
		    /opt/apache/sbin!) {
    if( -x File::Spec->catfile( $p, 'apxs2' ) ) {
      $apxs=File::Spec->catfile( $p, 'apxs2' );
      last;
    } elsif( -x File::Spec->catfile( $p, 'apxs' ) ) {
      $apxs=File::Spec->catfile( $p, 'apxs' );
      last;
    }
  }
  if( length $apxs ) {
    push @ARGV, '-apxs', $apxs;
  }
}

if( length $apxs ) {
  warn "# Using apxs at $apxs\n";
  my ($extra)=qx/$apxs -q EXTRA_INCLUDES/;
  chomp $extra;
  push @ARGV, "INC=$extra"
} else {
  die "Could not figure out which apxs to use. Try the -apxs option.\n";
}

# accept the configs from command line
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

ModPerl::MM::WriteMakefile(
  NAME          => 'Apache2::ModSSL',
  VERSION_FROM  => 'lib/Apache2/ModSSL.pm',
  PREREQ_PM     => {
		    mod_perl2 => 0,
		    'Crypt::SSLeay' => 0,
		   },
  dist          => {
		    COMPRESS => 'gzip -9f',
		    PREOP    => './mk_README.sh',
		   },
  clean         => {
		    FILES=>"t/TEST",
		   },
);

sub MY::postamble {
  return <<'EOF';
rpm: dist
	$(PERL) -i -pe 's/^(Version:\s*).*/$${1}$(VERSION)/' perl-Apache2-ModSSL.spec
	rpmbuild -ba perl-Apache2-ModSSL.spec
EOF
}
