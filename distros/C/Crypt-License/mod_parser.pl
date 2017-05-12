#!/usr/bin/perl

# version 2.01 12-19-02 michael@bizsystems.com
# Copyright Michael Robinton and BizSystems
# all rights reserved
#
use strict;

if (@ARGV) {
  &crypt_mod(@ARGV);
}

sub crypt_mod {

  my $seed	= 'BizSystems';

  my ( $in, $out, $end, $crypt, $discrypt ) = @_;

  eval qq{use Crypt::C_LockTite;};
  if ( $@ ) {
    $crypt = 0;
    $end = 'sorry charlie';
  }

  my $syntax = <<EOF;

syntax:	mod_parser.pl in out [END cutoff] [crypt key] [disable ENCRYPT]

  pod to STDOUT unless END cutoff is enabled

  END cutoff = save
	save comments to output to stripped .pm file

  do NOT use with C or xs files

EOF

  if (@_ < 2) {
    print $syntax;
    exit;
  }

  unlink $out if (-e $out && -l $out);		# don't OOPS if linked source
  my $slurp;

  unless (open (IN, "$in")) {
    print "ERROR, not found $in\n";
    $syntax;
    exit;
  }
  my $pod = 0;
  while (<IN>) {
    if ( $pod ) {
      if ( $_ =~ /^=cut/ ) {
        $pod = 0;			# kill pod printing
        next;
      }
      print $_ unless $end && $end ne 'save';
      next;
    }
    if ($_ =~ /^=\w/ && $_ !~ /^=cut/ ) {
      print $_ unless $end && $end ne 'save';
      $pod = 1;				# on if any =www except =cut
      next;
    }
    next if $end && $end ne 'save' &&
	( $_ =~ /^\s*#/ ||		# comment and blank only lines
	  $_ !~ /\S/ );
    last if $_ =~ /^__END__/ && $end && $end ne 'save';
    $slurp .= $_;
  }

  close IN; 

  unless (open(OUT, ">$out")) {
    print "open for output on $out failed\n";
    exit;
  }

  if ( $crypt ) {
    $slurp = "# Module $out\n" . $slurp;
    unless ( $discrypt ) {		# ENCRYPTION suspended for DEBUG
      my $p = Crypt::C_LockTite->new;
      my $tmp = $p->md5($crypt);				# md5 of client ID
      my $key = $p->new_md5_crypt($seed)->encrypt($tmp);	# encrypt with seed
      $p->new_crypt($key)->encrypt($slurp);
    }
    $slurp = "use Crypt::License;\n" . $slurp;
  }
  print OUT $slurp;
  close OUT;
}
