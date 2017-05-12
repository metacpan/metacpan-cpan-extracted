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

my($library,$bor_id,$verification);

print "library: ";
$library = read_str();

print "bor_id: ";
$bor_id = read_str();

print "verification: ";
$verification = read_password();

my %args = (
  library => $library,
  bor_id => $bor_id,
  verification => $verification
);
my $auth = $aleph->bor_auth(%args);
if($auth->is_success){

  for my $type(qw(z303 z304 z305)){
    say "$type:";
    my $data = $auth->$type();
    for my $key(keys %$data){
      next unless($data->{$key});
      say "\t$key : '$data->{$key}'";
    }
  }

}else{
  say STDERR "error: ".join('',@{$auth->errors});
  exit 1;
} 
