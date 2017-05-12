#!/usr/bin/perl -w

use strict;
use vars qw($PLACEHOLDER);
use Benchmark qw(cmpthese timethese);
use CGI::Ex::Conf;
use POSIX qw(tmpnam);

$PLACEHOLDER = chr(186).'~'.chr(186);

my $n = -2;

my $cob   = CGI::Ex::Conf->new;
my %files = ();

###----------------------------------------------------------------###

#         Rate   yaml  yaml2    sto     pl    xml g_conf    ini   sto2
#yaml    250/s     --    -1%   -14%   -14%   -61%   -77%   -95%   -95%
#yaml2   254/s     1%     --   -13%   -13%   -60%   -77%   -95%   -95%
#sto     292/s    17%    15%     --    -0%   -54%   -73%   -94%   -95%
#pl      292/s    17%    15%     0%     --   -54%   -73%   -94%   -95%
#xml     636/s   155%   151%   118%   118%     --   -42%   -88%   -88%
#g_conf 1088/s   335%   329%   273%   272%    71%     --   -79%   -80%
#ini    5144/s  1958%  1929%  1662%  1660%   708%   373%     --    -3%
#sto2   5321/s  2029%  1999%  1723%  1721%   736%   389%     3%     --

my $str = {
  foo     => {key1 => "bar",   key2 => "ralph"},
  pass    => {key1 => "word",  key2 => "ralph"},
  garbage => {key1 => "can",   key2 => "ralph"},
  mighty  => {key1 => "ducks", key2 => "ralph"},
  quack   => {key1 => "moo",   key2 => "ralph"},
  one1    => {key1 => "val1",  key2 => "ralph"},
  one2    => {key1 => "val2",  key2 => "ralph"},
  one3    => {key1 => "val3",  key2 => "ralph"},
  one4    => {key1 => "val4",  key2 => "ralph"},
  one5    => {key1 => "val5",  key2 => "ralph"},
  one6    => {key1 => "val6",  key2 => "ralph"},
  one7    => {key1 => "val7",  key2 => "ralph"},
  one8    => {key1 => "val8",  key2 => "ralph"},
};

###----------------------------------------------------------------###

#         Rate   yaml  yaml2     pl    sto    xml g_conf   sto2
#yaml    736/s     --    -3%   -20%   -21%   -62%   -72%   -89%
#yaml2   755/s     3%     --   -18%   -19%   -61%   -71%   -89%
#pl      923/s    25%    22%     --    -1%   -53%   -65%   -86%
#sto     928/s    26%    23%     1%     --   -53%   -65%   -86%
#xml    1961/s   166%   160%   113%   111%     --   -26%   -71%
#g_conf 2635/s   258%   249%   185%   184%    34%     --   -61%
#sto2   6824/s   827%   803%   639%   635%   248%   159%     --

#$str = {
#  foo     => "bar",
#  pass    => "word",
#  garbage => "can",
#  mighty  => "ducks",
#  quack   => "moo",
#  one1    => "val1",
#  one2    => "val2",
#  one3    => "val3",
#  one4    => "val4",
#  one5    => "val5",
#  one6    => "val6",
#  one7    => "val7",
#  one8    => "val8",
#};

###----------------------------------------------------------------###

my $conf = eval $str;

my %TESTS = ();

### do perl
my $dir = tmpnam;
mkdir $dir, 0755;
my $tmpnam = "$dir/bench";
my $file = $tmpnam. '.pl';
$TESTS{pl} = sub {
  $cob->write_ref($file, $str);
};
$files{pl} = $file;

### do a generic conf_write
my $file2 = $tmpnam. '.g_conf';
local $CGI::Ex::Conf::EXT_WRITERS{g_conf} = \&generic_conf_write;
$TESTS{g_conf} = sub {
  $cob->write_ref($file2, $str);
};
$files{g_conf} = $file2;


### load in the rest of the tests that we support
if (eval {require JSON}) {
  my $_file = tmpnam(). '.json';
  $TESTS{json} = sub {
    $cob->write_ref($file, $str);
  };
  $files{json} = $_file;
}

if (eval {require Storable}) {
  my $_file = $tmpnam. '.sto';
  $TESTS{sto} = sub {
    $cob->write_ref($file, $str);
  };
  $files{sto} = $_file;
}

if (eval {require Storable}) {
  my $_file = $tmpnam. '.sto2';
  $TESTS{sto2} = sub {
    &Storable::store($str, $_file);
  };
  $files{sto2} = $_file;
}

if (eval {require YAML}) {
  my $_file = $tmpnam. '.yaml';
  $TESTS{yaml} = sub {
    $cob->write_ref($_file, $str);
  };
  $files{yaml} = $_file;
}

if (eval {require YAML}) {
  my $_file = $tmpnam. '.yaml2';
  $TESTS{yaml2} = sub {
    &YAML::DumpFile($_file, $str);
  };
  $files{yaml2} = $_file;
}

if (eval {require Config::IniHash}) {
  my $_file = $tmpnam. '.ini';
  $TESTS{ini} = sub {
    local $^W = 0;
    $cob->write_ref($_file, $str);
  };
  $files{ini} = $_file;
}

if (eval {require XML::Simple}) {
  my $_file = $tmpnam. '.xml';
  $TESTS{xml} = sub {
    $cob->write_ref($_file, $str);
  };
  $files{xml} = $_file;
}

### tell file locations
foreach my $key (sort keys %files) {
  print "$key => $files{$key}\n";
}

foreach my $key (keys %TESTS) {
  eval { &{ $TESTS{$key} } };
  if ($@) {
    warn "Test for $key failed - skipping";
    delete $TESTS{$key};
  }
}


cmpthese timethese ($n, \%TESTS);

### comment out this line to inspect files
unlink $_ foreach values %files;
rmdir $dir;

###----------------------------------------------------------------###

sub generic_conf_read {
  my $_file = shift || die "No filename supplied";
  my $sep_by_newlines = ($_[0] && lc($_[0]) eq 'sep_by_newlines') ? 1 : 0;

  ### fh will now lose scope and close itself if necessary
  my $FH = do { local *FH; *FH };
  open ($FH, $_file) || return {};

  my $x = 0;
  my $conf = {};
  my $key  = '';
  my $val;
  my $line;
  my ($is_array,$is_hash,$is_multiline);
  my $order;
  $order = [] if wantarray;

  while( defined($line = <$FH>) ){
    last if ! defined $line;
    last if $x++ > 10000;

    next if index($line,'#') == 0;

    if ($line =~ /^\s/ && ($is_multiline || $line ne "\n")){
      next if ! length($key);
      $conf->{$key} .= $line;
      $is_multiline = 1;

    }else{
      ### duplicate trim section
      if( length($key) ){
        $conf->{$key} =~ s/\s+$//;
        if( $is_array || $is_hash ){
          $conf->{$key} =~ s/^\s+//;
          my $urldec = (index($conf->{$key},'%')>-1 || index($conf->{$key},'+')>-1);
          my @pieces;
          if ($sep_by_newlines) {
            @pieces = split(/\s*\n\s*/,$conf->{$key});
            @pieces = map {split(/\s+/,$_,2)} @pieces if $is_hash;
          } else {
            @pieces = split(/\s+/,$conf->{$key});
          }
          if( $urldec ){
            foreach my $_val (@pieces){
              $_val =~ y/+/ / if ! $sep_by_newlines;
              $_val =~ s/%([a-f0-9]{2})/chr(hex($1))/egi;
            }
          }
          if( $is_array ){
            foreach (@pieces){ $_="" if index($_,$PLACEHOLDER)>-1 }
            $conf->{$key} = \@pieces;
          }elsif( $is_hash ){
            foreach (@pieces){ $_="" if index($_,$PLACEHOLDER)>-1 }
            shift(@pieces) if scalar(@pieces) % 2;
            $conf->{$key} = {@pieces};
          }
        }elsif( ! $is_multiline ){
          $conf->{$key} =~ y/+/ / if ! $sep_by_newlines;
          $conf->{$key} =~ s/%([a-f0-9]{2})/chr(hex($1))/egi;
        }
      }

      ($key,$val) = split(/\s+/,$line,2);
      $is_array = 0;
      $is_hash = 0;
      $is_multiline = 0;
      if (! length($key)) {
        next;
      } elsif (index($key,'array:') == 0) {
        $is_array = $key =~ s/^array://i;
      } elsif (index($key,'hash:') == 0) {
        $is_hash = $key =~ s/^hash://i;
      }
      $key =~ y/+/ / if ! $sep_by_newlines;
      $key =~ s/%([a-f0-9]{2})/chr(hex($1))/egi;
      $conf->{$key} = $val;
      push @$order, $key if $order;
    }
  }

  ### duplicate trim section
  if( length($key) && defined($conf->{$key}) ){
    $conf->{$key} =~ s/\s+$//;
    if( $is_array || $is_hash ){
      $conf->{$key} =~ s/^\s+//;
      my $urldec = (index($conf->{$key},'%')>-1 || index($conf->{$key},'+')>-1);
      my @pieces;
      if ($sep_by_newlines) {
        @pieces = split(/\s*\n\s*/,$conf->{$key});
        @pieces = map {split(/\s+/,$_,2)} @pieces if $is_hash;
      } else {
        @pieces = split(/\s+/,$conf->{$key});
      }
      if( $urldec ){
        foreach my $_val (@pieces){
          $_val =~ y/+/ / if ! $sep_by_newlines;
          $_val =~ s/%([a-f0-9]{2})/chr(hex($1))/egi;
        }
      }
      if( $is_array ){
        foreach (@pieces){ $_="" if index($_,$PLACEHOLDER)>-1 }
        $conf->{$key} = \@pieces;
      }elsif( $is_hash ){
        foreach (@pieces){ $_="" if index($_,$PLACEHOLDER)>-1 }
        shift(@pieces) if scalar(@pieces) % 2;
        $conf->{$key} = {@pieces};
      }
    }elsif( ! $is_multiline ){
      $conf->{$key} =~ y/+/ / if ! $sep_by_newlines;
      $conf->{$key} =~ s/%([a-f0-9]{2})/chr(hex($1))/egi;
    }
  }


  close($FH);
  return $order ? ($conf,$order) : $conf;
}


sub generic_conf_write{
  my $_file = shift || die "No filename supplied";

  if (! @_) {
    return;
  }

  my $new_conf = shift || die "Missing update hashref";
  return if ! keys %$new_conf;


  ### do we allow writing out hashes in a nice way
  my $sep_by_newlines = ($_[0] && lc($_[0]) eq 'sep_by_newlines') ? 1 : 0;

  ### touch the file if necessary
  if( ! -e $_file ){
    open(TOUCH,">$_file") || die "Conf file \"$_file\" could not be opened for writing: $!";
    close(TOUCH);
  }

  ### read old values
  my $conf = &generic_conf_read($_file) || {};
  my $key;
  my $val;

  ### remove duplicates and undefs
  while (($key,$val) = each %$new_conf){
    $conf->{$key} = $new_conf->{$key};
  }

  ### prepare output
  my $output = '';
  my $qr = qr/([^\ \!\"\$\&-\*\,-\~])/;
  foreach $key (sort keys %$conf){
    next if ! defined $conf->{$key};
    $val = delete $conf->{$key};
    $key =~ s/([^\ \!\"\$\&-\*\,-9\;-\~\/])/sprintf("%%%02X",ord($1))/eg;
    $key =~ tr/\ /+/;
    my $ref = ref($val);
    if( $ref ){
      if( $ref eq 'HASH' ){
        $output .= "hash:$key\n";
        foreach my $_key (sort keys %$val){
          my $_val = $val->{$_key};
          next if ! defined $_val;
          $_val =~ s/$qr/sprintf("%%%02X",ord($1))/ego;
          $_key =~ s/$qr/sprintf("%%%02X",ord($1))/ego;
          if ($sep_by_newlines) {
            $_val =~ s/^(\s)/sprintf("%%%02X",ord($1))/ego;
            $_val =~ s/(\s)$/sprintf("%%%02X",ord($1))/ego;
            $_key =~ s/\ /%20/g;
          } else {
            $_val =~ tr/\ /+/;
            $_key =~ tr/\ /+/;
          }
          $_val = $PLACEHOLDER if ! length($_val);
          $output .= "\t$_key\t$_val\n";
        }
      }elsif( $ref eq 'ARRAY' ){
        $output .= "array:$key\n";
        foreach (@$val){
          my $_val = $_;
          $_val =~ s/$qr/sprintf("%%%02X",ord($1))/ego;
          if ($sep_by_newlines) {
            $_val =~ s/^(\s)/sprintf("%%%02X",ord($1))/ego;
            $_val =~ s/(\s)$/sprintf("%%%02X",ord($1))/ego;
          } else {
            $_val =~ tr/\ /+/;
          }
          $_val = $PLACEHOLDER if ! length($_val);
          $output .= "\t$_val\n";
        }
      }else{
        $output .= "$key\tbless('$val','$ref')\n"; # stringify the ref
      }
    }else{
      if( $val =~ /\n/ ){ # multiline values that are indented properly don't need encoding
        if( $val =~ /^\s/ || $val =~ /\s$/ || $val =~ /\n\n/ || $val =~ /\n([^\ \t])/ ){
          if ($sep_by_newlines) {
            $val =~ s/([^\!\"\$\&-\~])/sprintf("%%%02X",ord($1))/eg;
          } else {
            $val =~ s/([^\ \!\"\$\&-\*\,-\~])/sprintf("%%%02X",ord($1))/eg;
            $val =~ y/ /+/;
          }
        }
      }else{
        $val =~ s/([^\ \t\!\"\$\&-\*\,-\~])/sprintf("%%%02X",ord($1))/eg;
        $val =~ s/^(\s)/sprintf("%%%02X",ord($1))/eg;
        $val =~ s/(\s)$/sprintf("%%%02X",ord($1))/eg;
      }
      $output .= "$key\t$val\n";
    }
  }

  open (CONF,"+<$_file") || die "Could not open the file for writing ($_file) -- [$!]";
  print CONF $output;
  truncate CONF, length($output);
  close CONF;

  return 1;
}

1;

