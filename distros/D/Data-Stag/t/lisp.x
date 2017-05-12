use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 14;
}
use Omicia::AppHandle;
use XML::NestArray qw(:all);
use strict;
use Data::Dumper;

my $tree =
  Node(top=>[
             Node('personset'=>[
                                Node('person'=>[
                                                Node('name'=>'davey'),
                                                Node('address'=>'here'),
                                                Node('description'=>[
                                                                     Node('hair'=>'green'),
                                                                     Node('eyes'=>'two'),
                                                                     Node('teeth'=>5),
                                                                    ]
                                                    ),
                                                Node('pets'=>[
                                                              Node('petname'=>'igor'),
                                                              Node('petname'=>'ginger'),
                                                             ]
                                                    ),
                                                                          
                                               ],
                                     ),
                                Node('person'=>[
                                                Node('name'=>'shuggy'),
                                                Node('address'=>'there'),
                                                Node('description'=>[
                                                                     Node('hair'=>'red'),
                                                                     Node('eyes'=>'three'),
                                                                     Node('teeth'=>1),
                                                                    ]
                                                    ),
                                                Node('pets'=>[
                                                              Node('petname'=>'thud'),
                                                              Node('petname'=>'spud'),
                                                             ]
                                                    ),
                                               ]
                                     ),
                               ]
                  ),
             Node('animalset'=>[
                                Node('animal'=>[
                                                Node('name'=>'igor'),
                                                Node('class'=>'rat'),
                                                Node('description'=>[
                                                                     Node('fur'=>'white'),
                                                                     Node('eyes'=>'red'),
                                                                     Node('teeth'=>50),
                                                                      ],
                                                      ),
                                                 ],
                                      ),
                               ]
                 ),

            ]
      );

print tree2xml($tree);

my @persons = findSubTree($tree, 'person');
print "@persons\n";
map {
    print tree2xml($_);
#    print Dumper $_;
#    print tree2xml($_->children);
} @persons;

my @set = findSubTree($tree, 'personset');
print "set=@set\n";
map {
#    print Dumper $_;
    map {print $_->xml} $_->children;
#    map {print tree2xml($_)} $_->children;
#    map {print Dumper($_)} $_->children;
#    print tree2xml($_->children);
} @set;

my $set = shift @set;
ok( scalar($tree->findSubTreeVal("name")), 3);
ok( $tree->testSubTreeMatch("name", "igor"));
ok(! $tree->testSubTreeMatch("name", "stravinsky"));


my @p =
  $tree->findSubTreeWhere("person",
                          Node('testSubTreeMatch' =>[
                                                     Node('arg' => 'name'),
                                                     Node('arg' => 'shuggy'),
                                                    ]
                              )
                         );
ok(scalar(@p),1);
my $p = shift @p;
print $p->xml;

my $eval =
  Node(findSubTreeWhere => [
                            Node(arg => 'person'),
                            Node(arg => [
                                         Node('testSubTreeMatch'=>[
                                                                   Node('arg' => 'name'),
                                                                   Node('arg' => 'shuggy'),
                                                                  ]
                                             )
                                        ]
                                )
                           ]
      );

#print $tree->evalTree($eval)->xml;

# even more advanced
my $eval =
  Node(findSubTreeWhere => [
                            Node(arg => 'person'),
                            Node(arg => [
                                         Node('testSubTreeMatch'=>[
                                                                   Node('arg' => 'petname'),
                                                                   Node('arg' => '?p'),
                                                                  ]
                                             )
                                        ]
                                )
                           ]
      );

print $eval->xml;
#print $tree->evalTree($eval)->xml;

my $lispy =<<EOM
(lambda
  (findSubTreeWhere
    "person"
    (lambda (testSubTreeMatch "name" "shuggy"))))
EOM
;

my $code = sxpr2tree($lispy);
print tree2xml($code);
print $code->xml;
my $r = $tree->evalTree($code);
print $r->xml;
die;

my $lispy2 =<<EOM
(lambda
  (findSubTreeWhere
    "person"
    (testSubTreeMatch "name" "shuggy")))



(personset
  (person
    (name shuggy))
  (person
    (name ecky)))


(forall (subTree x root)
  (exists (subTree y x)
          (pair y "name shuggy")))

(findSubTreeWhere 
  (list 
   (qt person) 
   (where (testSubTreeMatch
EOM
                            
;
                                 

print Dumper $p;
