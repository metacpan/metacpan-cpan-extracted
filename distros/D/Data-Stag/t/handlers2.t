use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 9;
}
use Data::Stag;
use FileHandle;

my $fn = "t/data/homol.itext";
my $stag = Data::Stag->new;

# test freeing
my %h =
  (
   species => sub {
       my ($self, $stag) = @_;
       my $clone = $stag->clone;
       $stag->free;
       ($clone, $clone);
   },
   gene_set => 0,
   similarity_set => sub {
       return
   },
  );
my $handler =
  Data::Stag->makehandler(%h);

$stag->parse(-file=>$fn, -handler=>$handler);
print "original:\n";
print $stag->xml;
print "remaining tree:\n";
print $handler->stag->sxpr;

ok(scalar($stag->kids) == 1);  # check gene_set and similarity_set are removed
my @sp = $stag->find_species;
ok(@sp == 6);

$sp[0]->add_foo(5);
ok ($sp[1]->get_foo == 5);    # sp 0 and 1 should be the same node
#print $handler->stag->sxpr;

my %geneh = ();
$handler =
  Data::Stag->makehandler(-NOTREE=>1,        
			  gene=>sub {
			      my ($self, $gene) = @_;
			      $geneh{$gene->sget_symbol} = $gene;
			      return;
			  },
			 );

$stag = Data::Stag->new(test=>[]);
my $result_tree =
  $stag->parse(-file=>$fn, -handler=>$handler);
print $result_tree->sxpr;
print $stag->sxpr;
ok(!$result_tree->name);
ok(!$result_tree->kids);
ok($result_tree->isnull);
ok($stag->isnull);
ok(keys %geneh == 2);


$handler =
  Data::Stag->makehandler(
			  gene=>sub {
			      my ($self, $gene) = @_;
                              my $sym = $gene->sget_symbol;
			      $geneh{$sym} = $gene if $sym;
			      return;
			  },
			 );
eval {
    require "XML/Parser/PerlSAX.pm";
};
if ($@) {
    skip("XML::Parser::PerlSAX not installed",1);
}
else {

    %geneh = ();
    # check handler doesn't barf for null nodes
    $result_tree =
      $stag->parse(-str=>"<set><gene></gene></set>", -handler=>$handler);
    print $result_tree->sxpr;
    ok(!%geneh);
}

