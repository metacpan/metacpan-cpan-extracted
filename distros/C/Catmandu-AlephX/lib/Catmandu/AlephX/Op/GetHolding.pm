package Catmandu::AlephX::Op::GetHolding;
use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;

with('Catmandu::AlephX::Response');

has cdl_holdings => (
  is => 'ro',
  lazy => 1,
  isa => sub{
    check_array_ref($_[0]);
  },
  default => sub {
    [];
  }
);
sub op { 'get-holding' } 

sub parse {
  my($class,$str_ref) = @_;
  my $xpath = xpath($str_ref);

  my $op = op();

  my @cdl_holdings;

  for my $ch($xpath->find("/$op/cdl-holdings")->get_nodelist()){
    push @cdl_holdings,get_children($ch,1);
  }    
  
  __PACKAGE__->new(
    cdl_holdings => \@cdl_holdings,
    session_id => $xpath->findvalue("/$op/session-id"),
    errors => $class->parse_errors($xpath),
    content_ref => $str_ref
  );
}

1;
