use ExtUtils::MakeMaker;

sub MY::dist {
  package MY; # so that "SUPER" works right
  my $inherited = shift->SUPER::dist(@_);
  $inherited .= "\nSCP = scp\n";
  $inherited;
}

sub MY::dist_core {
  package MY;
  my $inherited = shift->SUPER::dist_core(@_);
  $inherited .= <<'EOT';

mydist : tardist copydist

copydist :
EOT
  $inherited .= "\t".'$(SCP) $(DISTVNAME).tar$(SUFFIX) s:/home/ftp/pub/perl/';
  $inherited;
}
   

WriteMakefile(
    'NAME'	=> 'Apache::DBILogger',
    'VERSION_FROM' => 'DBILogger.pm', # finds $VERSION
    'dist' =>  {COMPRESS => 'gzip', SUFFIX => '.gz'}

);
