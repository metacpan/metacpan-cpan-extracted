#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use Data::Dumper;
use open qw(:std :utf8);

sub read_str {
  my $line = <STDIN>;
  chomp $line;
  $line;
}
sub read_password {
    use Term::ReadKey;
    ReadMode 'noecho';
    my $password = ReadLine 0;
    ReadMode 'normal';
    chomp $password;
    print "\n";
    return $password;
}

my $aleph = Catmandu::AlephX->new(url => "http://aleph.ugent.be/X");

my $file;
my($library,$bor_id,$verification);

print "library: ";
$library = read_str();

print "bor_id: ";
$bor_id = read_str();

print "verification: ";
$verification = read_password();

print "file: ";
$file = read_str();

say "file is '$file'";

$file = "/dev/stdout" if $file eq "-";

open STDOUT,">:utf8",$file or die($!);

my %args = (
  library => $library,
  bor_id => $bor_id,
  verification => $verification
);
my $info = $aleph->bor_info(%args);
if($info->is_success){

  my $z304 = $info->z304();
  my @keys = qw(z304-address-0 z304-address-1 z304-address-2 z304-address-3 z304-address-4 z304-email-address z304-date-from z304-date-to z304-zip z304-telephone z304-telephone-1 z304-telephone-2 z304-telephone-3 z304-telephone-4);

  for my $key(@keys){
    my $val = $z304->{$key} // "<not defined>";
    say sprintf("\t%20s : %s",$key,$val);
  }

  my $z305 = $info->z305();
  @keys = qw(z305-no-cash z305-no-hold z305-no-loan z305-no-photo);
  for my $key(@keys){
    my $val = $z305->{$key} // "<not defined>";
    say sprintf("\t%20s : %s",$key,$val);
  }

  
}else{
  say STDERR "error: ".join('',@{$info->errors});
  exit 1;
} 
