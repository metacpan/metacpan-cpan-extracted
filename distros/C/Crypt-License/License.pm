package Crypt::License;

use Filter::Util::Call 1.04;
use Crypt::CapnMidNite 1.00;
use Time::Local;
use Sys::Hostname;
use vars qw($VERSION $ptr2_License);

$ptr2_License = {'next' => ''};

$VERSION = do { my @r = (q$Revision: 2.04 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

#	put the package name of the segement to print in DEBUG
#	or 'ALL' to print all packages
#
my $DEBUG	= 0;#'ALL';

##### pre-defines
my $seek_caller = sub {
  my ($i) = @_;                    # exclude call to this sub
  $i++;
  my $p;
  while(@_=caller($i)){
    $last = $i;
    ($p = $_[0]) =~ s#::#/#g;
# print STDERR ($i-1),' 0=',$_[0],' 2=', $_[2], ' 3=', $_[3], "\n";
    last if $_[2] > 2 && $_[0] !~ /AutoLoader/ &&
	$_[1] !~ /^\(eval/ && $_[1] !~ m|$p/.+\.al$|;

    ++$i;
  }
  return ($i-1,@_);
};

my $print_err = sub {
  print STDERR @_;
};

# useage: (callerlevel, @caller)
my $pcaller = sub {
  &$print_err('########## level ', (shift @_), "\n") if $DEBUG;
  my @caller = ('package','file','line','subr','hasargs','wantary','evaltxt','require',);
	# ignored => 'hints','bitmask');
  my $end = ($#_ < 7) ? $#_ : 7;
  foreach my $i(0..$end) {
    $_[$i] = '' unless $_[$i];
    &$print_err("$caller[$i]\t= $_[$i]\n") if $DEBUG;
  }
};

my ($user,$grp,$pwd);

$user_info = sub {
  ($pwd) = @_;
  $user = (getpwuid( (stat($pwd))[4] ))[0];
  $grp = (getgrgid( (stat($pwd))[5] ))[0];
  my $i;
  if ( $pwd !~ m|^/| ) {
    $i = `/bin/pwd`;
    $i =~ s/\s+//g;
    $pwd = $i .'/'. $pwd;
  }
  $pwd =~ s#/\./#/#g;
  @_ = split('/',$pwd);
  $pwd= '';
  $#_ -=1;
  while($i = pop @_) {
    do { pop @_; next; } if $i eq '..';
    $pwd = "/$i" . $pwd;
  }
};

##### code

my $host = &Sys::Hostname::hostname;
($host = "\L$host") =~ s/\s+//g;

&$user_info((caller)[1]);	# defaults

sub import {
  my ($alm) = ((caller)[1] =~ m|.+/auto/(.+)/.+\.al$|);
  my $level=0;
  my $i;
  my $ptr;
  while (1) {
    ($level, @_) = &$seek_caller($level);
# package name in [0]
###$i=0;
###while(caller($i)) { ++$i }
###@_ = caller($i-1);
      $ptr = (defined ${"$_[0]::ptr2_License"})
	? ${"$_[0]::ptr2_License"} : '';
      last unless $ptr;
      last unless exists $ptr->{next};
      ++$level;
  }
if($DEBUG){
&$print_err("\n\t\t\tXxXxXxXxXxXxXx $level\n");
$i=0;
while(@_=caller($i)){
&$pcaller($i,@_);
++$i;
}
}

  if ( $ptr ) {
    &$user_info($ptr->{path});
    (my @lic = &get_file($ptr->{path})) ||
	die "could not open license file for $user";
    my %parms;
    $#lic = &extract(\@lic,\%parms) -1;
    my $expire = 0;
    if ( exists $parms{EXP} ) {	# if the EXPiration is present
      ($expire = &date2time($parms{EXP})) ||
	die "invalid expiration date $user license";
    }
    @_ = split('/',(caller)[1]);	# last element
    if ( $_[$#_] =~ /\.pm$/ ) {
      @_ = split(/\./,$_[$#_]);		# remove extension
    }
    my $key = $_[$#_-1];

    unless ( exists $ptr->{$key} ) {
      @_ = ();
      if (exists $ptr->{private}) {
        @_ = split(',',$ptr->{private});
        foreach $i (0..$#_) {
	  $_[$i] = join('/',split('::',$_[$i]));
	}
      }
      my $match = (caller)[1];
      if (grep($match =~ /$_\.pm$/,@_)) {
        $ptr->{$key} = $parms{KEY} or die "missing private key $user";
      } else {
        $ptr->{$key} = $parms{PKEY} or die "missing public key $user";
      }
    }
    delete $parms{KEY};
    delete $parms{PKEY};
    my %chk;
    &get_vals(\%parms,\%chk);
    @_ = keys %chk;
    @{parms}{@_} = @{chk}{@_};
    @_ = sort keys %parms;
    push @lic,@_,@{parms}{@_},$expire,$ptr->{$key};
    my $bu = Crypt::CapnMidNite->new;
    my $expires = $bu->license(@lic);
    $ptr->{expires} = $expires if $expires;
    my $h = '# Module';
    my $f = length $h;
    my $s = '';
    filter_add(
    sub {
      my $status = filter_read;
      $bu->crypt($_);
      $s .= $_ if $f;
      $f = 0 if $s =~ /^$h/o;
      if ( $f && length($s) > $f) {
	$_ = '';
	$status = -1;
      }
      if (!$status && $alm) {
	$alm =~ s#/#::#g;
	unless (defined ${"${alm}::ptr2_License"}) {
	  %{"${alm}::_LicHash"} = ('next' => $alm);
	  ${"${alm}::ptr2_License"} = \%{"${alm}::_LicHash"};
	}
      }
      return $status;
    });
  }
}


#############################################################
# check each field for validity
#
# input:	parm
#
my $check = {
	'SERV'	=> sub {	# http server domain or input string
		return ( exists $ENV{SERVER_NAME} ) ? "\L$ENV{SERVER_NAME}" : $_[0]; },

	'HOST'	=> sub {	# local fqdn
		return $host; }, 

	'USER'	=> sub {	# local user name
		return $user; },

	'GROUP'	=> sub {	# local group name
		return $grp; },

	'HOME'	=> sub {	# check for match on working directory path to input string
		$pwd =~ /($_[0])/;	# contains the match string
		return $1 || ''; },
};

sub date2time {
  my ($ds) = @_;
  return 0 unless $ds;
  my %month = (
	'jan'	=> 0,
	'feb'	=> 1,
	'mar'	=> 2,
	'apr'	=> 3,
	'may'	=> 4,
	'jun'	=> 5,
	'jul'	=> 6,
	'aug'	=> 7,
	'sep'	=> 8,
	'oct'	=> 9,
	'nov'	=> 10,
	'dec'	=> 11,
  );

  $ds =~ s/\s+/ /g;		# all white space to space
  $ds =~ s/^\s+//;		# zap leading white space
  $ds =~ s/\s+$//;		# zap trailing white space
  $ds =~ s/,//g;		# zap commas
  $ds = "\L$ds";		# lower case

  return 0 unless $ds;

  my ($m,$d,$y) = split(m|[\- /]|,$ds);
  if ( $m =~ /\D/ ) {
    @_ = grep($m =~ /^$_/, keys %month);
    return 0 unless @_ && exists $month{$_[0]};
    $m = $month{$_[0]};
  } else {
    --$m;
  }
  return 0 if ($m . $d . $y) =~ /\D/;
  $y -= 1900 if $y > 1900;
#				# NOTE: Y 2070 problem <<<****
  $y += 100 if $y < 70;

# range check
  return 0 if ( "$m$d$y" =~ /\D/ ); # not numeric
#  return 0 if $y < 70;
  return 0 if $y > 169;		# NOTE: Y 2070 problem <<<****
  return 0 if $m > 11 || $m < 0;
  return 0 if $d > 31 || $d < 1;
  return timelocal(59,59,23,$d,$m,$y);
}

sub get_file {
  my($fd) = @_;
  my $i;
  return () unless (-e $fd) &&	# punt if the file is missing
	open(F,$fd);		# or won't open
  my @txt = ();
  my $started = 0;
  while ($i = <F>) {
    next unless $started || $i =~ /\S/;	# strip leading blank lines
    $started = 1 unless $started;
    $i =~ s/\t+/ /g;
    $i =~ s/\s+$//;		# strip trailing white space
    push(@txt, $i);
  }
  return @txt;
}

sub extract {
  my($txt,$parms) = @_;
  my ($i,$rv);
  foreach $i (0..$#{$txt}) {
    next unless $txt->[$i] =~ /:\s*:/;	# find lines with tags
    $rv = $i unless $rv;		# save first pointer
    my($tag,$val) = split(/:\s*:/, $txt->[$i], 2);
    $tag =~ s/\s+//;			# remove any white space in tag
    $val = '' unless $val;
    $val = "\L$val" if $tag eq 'HOST' || $tag eq 'SERV';
    $parms->{$tag} = $val;
  }
  return $rv;
}

# if check subroutine exists, return value with parms value as input
sub get_vals {
  my($parms,$chk_vals) = @_;
  foreach my $i (keys %$parms) {
    $chk_vals->{$i} = &{$check->{$i}}($parms->{$i}) if exists $check->{$i};
  }
}

1;
