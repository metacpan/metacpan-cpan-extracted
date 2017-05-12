use ExtUtils::MakeMaker;

# Big thanks to David Oswald for configuration ideas.
test_and_config();

WriteMakefile1(
    NAME         => 'Crypt::Random::TESHA2',
    ABSTRACT     => "Random numbers using timer/schedule entropy, aka userspace voodoo entropy",
    VERSION_FROM => 'lib/Crypt/Random/TESHA2.pm', # finds $VERSION
    LICENSE      => 'perl',
    AUTHOR       => 'Dana A Jacobsen <dana@acm.org>',

    BUILD_REQUIRES=>{
                      'Test::More'       => '0.45',
                    },
    PREREQ_PM     => {
                       'Exporter'        => '5.562',
                       'Digest::SHA'     => '5.22',
                       'Time::HiRes'     => '1.9711',
                       'base'            => 0,
                       'Carp'            => 0,
                     },

    META_MERGE    => {
                      resources  => {
                       homepage   => 'https://github.com/danaj/Crypt-Random-TESHA2',
                       repository => 'https://github.com/danaj/Crypt-Random-TESHA2',
                       },
                     },
    MIN_PERL_VERSION => 5.006002,
);

sub WriteMakefile1 {   # Cribbed from eumm-upgrade by Alexandr Ciornii
  my %params = @_;
  my $eumm_version = $ExtUtils::MakeMaker::VERSION;
  $eumm_version = eval $eumm_version;

  if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
      #EUMM 6.5502 has problems with BUILD_REQUIRES
      $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
      delete $params{BUILD_REQUIRES};
  }
  delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
  delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
  delete $params{META_MERGE} if $eumm_version < 6.46;
  delete $params{META_ADD} if $eumm_version < 6.46;
  delete $params{LICENSE} if $eumm_version < 6.31;
  delete $params{AUTHOR} if $] < 5.005;
  delete $params{ABSTRACT_FROM} if $] < 5.005;
  delete $params{BINARY_LOCATION} if $] < 5.005;

  WriteMakefile(%params);
}

sub test_and_config {
  local $| = 1;
  print "\n";
  print "Config: starting initial configuration.\n";
  # Test that we can create enough entropy.
  eval {
    require Time::HiRes;  Time::HiRes->import(qw/gettimeofday usleep/);
    require Digest::SHA;  Digest::SHA->import(qw/sha256/);
    1;
  } or do {
    print "Config: failed to load prerequisites.\n";
    return;
  };
  print "Config: gathering.";

  my @vars;
  foreach my $byte (1..200) {
    print "." unless $byte % 4;
    my ($start, $t1, $t2) = gettimeofday();
    my $str = pack("LL", $start, $t1);
    my %dummy;
    foreach my $bit (1 .. 8) {
      usleep(2+3*$bit);
      (undef, $t2) = gettimeofday();
      # Note this has nothing to do with the start time or the hash.
      my $diff = $t2 >= $t1 ? $t2-$t1 : $t2-$t1+1000000;
      push @vars, $diff - (2+3*$bit);
      $str .= pack("L", $t1 ^ $t2);
      $dummy{$str . $_}++ for 1..8;
      $t1 = $t2;
    }
  }
  print "done\n";
  my $H = calc_entropy(@vars);
  my $Hstr = sprintf("%.2f", $H);
  my $Hstr8 = sprintf("%.2f", 8 * $H);
  print "Config: Raw usleep 0-order entropy: $Hstr ($Hstr8 bits per byte).\n";
  # Be conservative and assume half what we measured.
  my $Hbyte = (8 * $H) / 2;
  # Also assume no more than 7 from a single round.
  $Hbyte = 7.0 if $Hbyte > 7.0;
  # Round up to two digits.
  $Hbyte = sprintf("%.02f", $Hbyte + 0.005);
  if ($Hbyte < 1.0) {
    print "Config:\n";
    print "Config:  ONLY $Hbyte BITS PER OUTPUT BYTE!\n";
    print "Config:\n";
    print "Config: You should use another source.\n";
    print "Config: Configuring for weak mode.\n";
    print "\n";
    $Hbyte = "1.00";
  }
  print "Config: choosing $Hbyte bits per output byte\n";
  print "Config: writing configuration.\n";

  my $config_path = 'lib/Crypt/Random/TESHA2/Config.pm';
  # One possibility is to use the DATA fh, allowing us to just append.
  # Instead, use DAOSWALD's method.  It's more work here, but less there.
  my $fh;
  open($fh, "<", $config_path) or
    do { print "Config: Can't open $config_path!\n$!"; return; };
  my @lines = <$fh>;
  close $fh;
  for (@lines) {
    s/^(my \$_entropy_per_byte =).*/$1 $Hbyte;/;
  }
  open($fh, ">", $config_path) or
    do { print "Config: Can't open $config_path!\n$!"; return; };
  print $fh @lines or
    do { print "Config: Can't write to $config_path!\n$!"; return; };
  close($fh) or
    do { print "Config: Can't close $config_path!\n$!"; return; };
  open(my $fh, ">>", $config_path) or
    do { print "Config: Can't open $config_path!\n$!"; return; };

  print "Config: configuration complete.\n";
  print "\n";
}

# calculate the 0-order entropy of an array.  Returns bits per input.
sub calc_entropy {
  my @vals = @_;
  my $total = scalar @vals;
  # Compute simple entropy H
  my %freq;
  $freq{$_}++ for @vals;
  my $H = 0;
  foreach my $f (values %freq) {
    my $p = $f / $total;
    $H += $p * log($p);
  }
  $H = -$H / log(2);
  return $H;
}
