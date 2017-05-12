#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Catmandu::Sane;
use Catmandu::AlephX;
use open qw(:std :utf8);
use Data::Dumper;

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

my $file = "-";
my($library,$bor_id,$verification);

print "library: ";
$library = read_str();

print "bor_id: ";
$bor_id = read_str();

print "verification: ";
$verification = read_password();

print "file: ";
$file = read_str();
$file = "/dev/stdout" if $file eq "-";

open STDOUT,">:utf8",$file or die($!);

my %args = (
  library => $library,
  bor_id => $bor_id,
  verification => $verification,
  loans => 'P'
);
my $info = $aleph->bor_info(%args);
if($info->is_success){

  for my $type(qw(z303 z304 z305)){
    say "$type:";
    my $data = $info->$type();
    for my $key(keys %$data){
      say "\tkey: $key";
      say "\t$key : $data->{$key}" if $data->{$key};
    }
  }
  say "fine:";
  print Dumper($info->fine);

  print Dumper($info->item_l);

}else{
  say STDERR "error: ".join('',@{$info->errors});
  exit 1;
} 
