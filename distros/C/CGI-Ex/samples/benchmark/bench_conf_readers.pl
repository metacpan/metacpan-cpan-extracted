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

#           Rate  yaml2   yaml    xml    ini g_conf     pl    sto   sto2  yaml3
#yaml2     159/s     --    -1%   -72%   -80%   -91%   -95%   -98%   -98%  -100%
#yaml      160/s     1%     --   -72%   -80%   -91%   -95%   -98%   -98%  -100%
#xml       565/s   255%   253%     --   -28%   -68%   -84%   -93%   -94%  -100%
#ini       785/s   393%   391%    39%     --   -55%   -78%   -90%   -91%   -99%
#g_conf   1756/s  1004%   998%   211%   124%     --   -50%   -78%   -80%   -98%
#pl       3524/s  2115%  2103%   524%   349%   101%     --   -55%   -61%   -97%
#sto      7838/s  4826%  4799%  1288%   898%   346%   122%     --   -12%   -93%
#sto2     8924/s  5508%  5477%  1480%  1037%   408%   153%    14%     --   -92%
#yaml3  113328/s 71115% 70730% 19961% 14336%  6353%  3116%  1346%  1170%     -- #memory

my $str = '{
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
}';

my $str = '[
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
  foo     => [key1 => "bar",   key2 => "ralph"],
  pass    => [key1 => "word",  key2 => "ralph"],
  garbage => [key1 => "can",   key2 => "ralph"],
  mighty  => [key1 => "ducks", key2 => "ralph"],
  quack   => [key1 => "moo",   key2 => "ralph"],
  one1    => [key1 => "val1",  key2 => "ralph"],
  one2    => [key1 => "val2",  key2 => "ralph"],
  one3    => [key1 => "val3",  key2 => "ralph"],
  one4    => [key1 => "val4",  key2 => "ralph"],
  one5    => [key1 => "val5",  key2 => "ralph"],
  one6    => [key1 => "val6",  key2 => "ralph"],
  one7    => [key1 => "val7",  key2 => "ralph"],
  one8    => [key1 => "val8",  key2 => "ralph"],
]';

###----------------------------------------------------------------###

#           Rate   yaml  yaml2    xml g_conf     pl    sto   sto2  yaml3
#yaml      431/s     --    -2%   -61%   -91%   -94%   -97%   -98%  -100%
#yaml2     438/s     2%     --   -60%   -91%   -94%   -97%   -98%  -100%
#xml      1099/s   155%   151%     --   -78%   -85%   -92%   -94%   -99%
#g_conf   4990/s  1057%  1038%   354%     --   -33%   -64%   -72%   -96%
#pl       7492/s  1637%  1609%   582%    50%     --   -46%   -58%   -93%
#sto     13937/s  3130%  3078%  1169%   179%    86%     --   -22%   -88%
#sto2    17925/s  4055%  3988%  1532%   259%   139%    29%     --   -84%
#yaml3  114429/s 26423% 25996% 10316%  2193%  1427%   721%   538%     -- # memory

#$str = '{
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
#}';

###----------------------------------------------------------------###

my $conf = eval $str;

my %TESTS = ();

### do perl
my $file = tmpnam(). '.pl';
open OUT, ">$file";
print OUT $str;
close OUT;
$TESTS{pl} = sub {
  my $hash = $cob->read_ref($file);
};
$files{pl} = $file;

### do a generic conf_write
#my $file2 = tmpnam(). '.g_conf';
#&generic_conf_write($file2, $conf);
#local $CGI::Ex::Conf::EXT_READERS{g_conf} = \&generic_conf_read;
#$TESTS{g_conf} = sub {
#  my $hash = $cob->read_ref($file2);
#};
#$files{g_conf} = $file2;


if (eval {require JSON}) {
  my $_file = tmpnam(). '.json';
  my $str = JSON::objToJson($conf, {pretty => 1, indent => 2});
  open(my $fh, ">$_file");
  print $fh $str;
  $TESTS{json} = sub {
    my $hash = $cob->read_ref($_file);
  };
  $TESTS{json2} = sub {
    open(my $fh, "<$_file") || die "Couldn't open file: $!";
    read($fh, my $str, -s $_file);
    my $hash = JSON::jsonToObj($str);
  };
  $files{json} = $_file;
}


### load in the rest of the tests that we support
if (eval {require Storable}) {
  my $_file = tmpnam(). '.sto';
  &Storable::store($conf, $_file);
  $TESTS{sto} = sub {
    my $hash = $cob->read_ref($_file);
  };
  $files{sto} = $_file;
}

if (eval {require Storable}) {
  my $_file = tmpnam(). '.sto2';
  &Storable::store($conf, $_file);
  $TESTS{sto2} = sub {
    my $hash = &Storable::retrieve($_file);
  };
  $files{sto2} = $_file;
}

if (eval {require YAML}) {
  my $_file = tmpnam(). '.yaml';
  &YAML::DumpFile($_file, $conf);
  $TESTS{yaml} = sub {
    my $hash = $cob->read_ref($_file);
  };
  $files{yaml} = $_file;
}

if (eval {require YAML}) {
  my $_file = tmpnam(). '.yaml2';
  &YAML::DumpFile($_file, $conf);
  $TESTS{yaml2} = sub {
    my $hash = &YAML::LoadFile($_file);
  };
  $files{yaml2} = $_file;
}

if (eval {require YAML}) {
  my $_file = tmpnam(). '.yaml';
  &YAML::DumpFile($_file, $conf);
  $cob->preload_files($_file);
  $TESTS{yaml3} = sub {
    my $hash = $cob->read_ref($_file);
  };
  $files{yaml3} = $_file;
}

if (eval {require Config::IniHash}) {
  my $_file = tmpnam(). '.ini';
  &Config::IniHash::WriteINI($_file, $conf);
  $TESTS{ini} = sub {
    local $^W = 0;
    my $hash = $cob->read_ref($_file);
  };
  $files{ini} = $_file;
}

if (eval {require XML::Simple}) {
  my $_file = tmpnam(). '.xml';
  my $xml = XML::Simple->new->XMLout($conf);
  open  OUT, ">$_file" || die $!;
  print OUT $xml;
  close OUT;
  $TESTS{xml} = sub {
    my $hash = $cob->read_ref($_file);
  };
  $files{xml} = $_file;
}

### tell file locations
foreach my $key (sort keys %files) {
  print "$key => $files{$key}\n";
}

cmpthese timethese ($n, \%TESTS);

### comment out this line to inspect files
unlink $_ foreach values %files;

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

