package Catmandu::AlephX::Op::HoldReq;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;

with('Catmandu::AlephX::Response');

has reply => (
  is => 'ro',
  required => 1,
  isa => sub{
    check_string($_[0]);
  }
);

sub op { 'hold-req' } 

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);
  my $op = op();

  my %args;
  for(qw(session-id reply)){
    my $key = $_;
    $key =~ s/-/_/go;
    $args{$key} = $xpath->findvalue("/$op/$_");
  }

  $args{errors} = $class->parse_errors($xpath); 
  $args{content_ref} = $str_ref;

  __PACKAGE__->new(%args);
}

1;
