use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	      NAME	 => 'Bio::Das',
	      VERSION_FROM => 'Das.pm', # finds $VERSION
	      PREREQ_PM    => {
			       Compress::Zlib => 1.0,
			       HTML::Parser => 3.0,
			       LWP          => 5.0,
			       MIME::Base64 => 2.12,
			       Bio::Root::Root=>0,
			      },
	      AUTHOR   => 'Lincoln Stein (lstein@cshl.edu)',
	      ABSTRACT => 'Client-side library for Distributed Genome Annotation System',
	     );

sub MY::ppd {
  package MY;
  my $repository = 'http://www.gmod.org/ggb/ppm';
  my $arch       = 'MSWin32-x86-multi-thread';
  my $inherited = shift->SUPER::ppd(@_);

  my $implementation;
  my $newimp;
  my $oldMM =0;

#VERY irritating--different versions of ExtUtils::MakeMaker have
#different ways of generating the ppd file.
  if ($inherited =~ /qq\{(<S.*R>\\n)\}.*qq\{(\\t<I.*\/>\\n)\}.*qq\{(\\t\\t<O.*G>\\n)\}/sg){
    $oldMM=1;
    my $xml = $1.$2.$3;
    #warn "$xml\n";
    $inherited =~ s/qq\{.*>>/qq{$xml}" >/s;
  } elsif ($inherited =~ /NOECHO/) {
    my @la = split /\n/, $inherited;
    my $grab = 0;
    for (@la) {
      $grab++ if (m!<IMPLEMENTATION>!); 
      if ($grab and $_ =~ /\'(.*)\'/) {
        $implementation .= "$1\n";
      }
      $grab = 0 if (m!</IMPLEMENTATION>!);
    } 
  }

  if ($oldMM and $inherited =~ /(\s*\<IMPLEMENTATION\>.*\<\/IMPLEMENTATION\>)/m) {
    $implementation = $newimp = $1;
    $newimp      =~ s/ARCHITECTURE NAME=\\"\S+\\"/ARCHITECTURE NAME=\\"$arch\\"/;
    $newimp      =~ s/\$\(OSNAME\)/MSWin32/;
    my $impl58   = $newimp;
    $impl58      =~ s/\Q$arch\E/$arch\-5\.8/;
    $newimp      .= "\\n\\t\\t$impl58";
    $inherited   =~ s/\Q$implementation\E/$newimp/;
  } elsif (!$oldMM and $implementation) {
    $newimp      = $implementation;
    $newimp      =~ s/ARCHITECTURE NAME="\S+"/ARCHITECTURE NAME="$arch"/;
    $newimp      =~ s/\$\(OSNAME\)/MSWin32/;
    my $impl58   = $newimp;
    $impl58      =~ s/\Q$arch\E/$arch\-5\.8/;
    $newimp      .= $impl58;
    my @la       = split /\n/, $newimp;
    for my $line (@la) {
      $line = qq{\t\$(NOECHO) \$(ECHO) '$line' >> \$(DISTNAME).ppd}; 
    }

    my @inherit_array = split /\n/, $inherited;
    my @newinherit;
    $inherited = '';
    for (@inherit_array) {
      if (/<IMPLEMENTATION>/) {
        push @newinherit, @la;
        last;
      } else {
        push @newinherit, $_; 
      }
    }
    push @newinherit, qq{\t\$(NOECHO) \$(ECHO) '</SOFTPKG>' >> \$(DISTNAME).ppd\n};
    $inherited = join "\n", @newinherit;
  }

  $inherited .= <<END;

	\@echo "creating Bio-Das.ppd"
	\@echo "creating Biodas_ppm-\$(VERSION).tar.gz"
	\@\$(TAR) zvcf biodas_ppm-\$(VERSION).tar.gz --exclude man1 blib
	\@perl -pi -e 's!HREF=""!HREF="$repository/biodas_ppm-\$(VERSION).tar.gz"!' Bio-Das.ppd
	\@perl -pi -e 's!Bio-Perl!bioperl!' Bio-Das.ppd
END
;
}
