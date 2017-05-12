# all 

*INITIALIZATION METHODS
/new

+args element str, data ANY
+returns XML::NestArray node
-$node = narr_new();
-$node = XML::NestArray->new;
-$node = XML::NestArray->new(person => [[name=>$n], [phone=>$p]]);

creates a new instance of a XML::NestArray node

/nodify

+args data array-reference
+returns XML::NestArray node
-$node = narr_nodify([person => [[name=>$n], [phone=>$p]]]);

turns a perl array reference into a XML::NestArray node.

similar to B<new>

/parse

+args file str, [format str], [handler obj]
+returns XML::NestArray node
-$node = narr_parse($fn);
-$node = XML::NestArray->parse(-file=>$fn, -handler=>$myhandler);

slurps a file or string into a XML::NestArray node structure. Will
guess the format from the suffix if it is not given.

The format can also be the name of a parsing module, or an actual
parser object

/from

+args format str, source str
+returns XML::NestArray node
-$node = narr_from('xml', $fn);
-$node = narr_from('xmlstr', q[<top><x>1</x></top>]);
-$node = XML::NestArray->from($parser, $fn);

Similar to B<parse>

slurps a file or string into a XML::NestArray node structure.

The format can also be the name of a parsing module, or an actual
parser object

/unflatten

+args data array
+returns XML::NestArray node
-$node = narr_unflatten(person=>[name=>$n, phone=>$p, address=>[street=>$s, city=>$c]]);

Creates a node structure from a semi-flattened representation, in
which children of a node are represented as a flat list of data rather
than a list of array references.

This means a structure can be specified as:

  person=>[name=>$n,
           phone=>$p, 
           address=>[street=>$s, 
                     city=>$c]]

Instead of:

  [person=>[ [name=>$n],
             [phone=>$p], 
             [address=>[ [street=>$s], 
                         [city=>$c] ] ]
           ]
  ]

The former gets converted into the latter for the internal representation

# recursive
* RECURSIVE SEARCHING

/findnode fn

+args element str
+returns node[]
-@persons = narr_findnode($struct, 'person');
-@persons = $struct->findnode('person');

recursively searches tree for all elements of the given type, and
returns all nodes found.

/findval fv

+args element str
+returns ANY[] or ANY
-@names = narr_findval($struct, 'name');
-@names = $struct->findval('name');

recursively searches tree for all elements of the given type, and
returns all data values found. the data values could be primitive
scalars or nodes.

/sfindval sfv

+args element str
+returns ANY
-$name = narr_sfindval($struct, 'name');
-$name = $struct->sfindval('name');

as findval, but returns the first value found

/findvallist fvl

+args element str[]
+returns ANY[]
-($name, $phone) = narr_findvallist($personstruct, 'name', 'phone');
-($name, $phone) = $personstruct->findvallist('name', 'phone');

recursively searches tree for all elements in the list

# nonrecursive
*DATA ACCESSOR METHODS

these allow getting and setting of elements directly underneath the
current one

/get g

+args element str
+return ANY[] or ANY
-$name = $person->get('name');
-@phone_nos = $person->get('phone_no');

gets the data value of an element for any node

the examples above would work on a data structure like this:

  [person => [ [name => 'fred'],
               [phone_no => '1-800-111-2222'],
               [phone_no => '1-415-555-5555']]]

will return an array or single value depending on the context

/sget sg

+args element str
+return ANY
-$name = $person->get('name');
-$phone = $person->get('phone_no');

as B<get> but always returns a single value

/gl getl getlist

+args element str[]
+return ANY[]
-($name, @phone) = $person->get('name', 'phone_no');

returns the data values for a list of sub-elements of a node

/getn gn getnode

+args element str
+return node[] or node
-$namestruct = $person->getn('name');
-@pstructs = $person->getn('phone_no');

as B<get> but returns the whole node rather than just the data valie

/sgetn sgn sgetnode

+args element str
+return node
-$pstruct = $person->sgetn('phone_no');

as B<getnode> but always returns a scalar

/set s

+args element str, datavalue ANY
+return ANY
-$person->set('name', 'fred');
-$person->set('phone_no', $cellphone, $homephone);

sets the data value of an element for any node. if the element is
multivalued, all the old values will be replaced with the new ones
specified.

ordering will be preserved, unless the element specified does not
exist, in which case, the new tag/value pair will be placed at the
end.

/unset u

+args element str, datavalue ANY
+return ANY
-$person->unset('name');
-$person->unset('phone_no');

prunes all nodes of the specified element from the current node

/add a

+args element str, datavalue ANY[]
+return ANY
-$person->add('phone_no', $cellphone, $homephone);

adds a datavalue or list of datavalues. appends if already existing,
creates new element value pairs if not already existing.

/element e name

+args
+return element str
-$element = $struct->element

returns the element name of the current node

/kids k children

+args
+return ANY or ANY[]
-@nodes = $person->kids
-$name = $namestruct->kids

returns the data value(s) of the current node; if it is a terminal
node, returns a single value which is the data. if it is non-terminal,
returns an array of nodes

/addkid ak addchild

+args kid node
+return ANY
-$person->addkid('job', $job);

adds a new child node to a non-terminal node, after all the existing child nodes

# querying
*QUERYING AND ADVANCED DATA MANIPULATION

/njoin nj j

+args element str
+return undef

does a relational style natural join - see previous example in this doc

/normalise norm

+args 
+return node or node[]

normalises denormalised tables/rows

/qmatch qm

+args return-element str, match-element str, match-value str
+return node[]
-@persons = $s->qmatch('name', 'fred');

queries the node tree for all elements that satisfy the specified key=val match

/tmatch tm

+args element str, value str
+return bool
-@persons = grep {$_->tmatch('name', 'fred')} @persons

returns true if the the value of the specified element matches

/tmatchhash tmh

+args match hashref
+return bool
-@persons = grep {$_->tmatchhash({name=>'fred', hair_colour=>'green'})} @persons

returns true if the node matches a set of constraints, specified as hash

/tmatchnode tmn

+args match node
+return bool
-@persons = grep {$_->tmatchhash([person=>[[name=>'fred'], [hair_colour=>'green']]])} @persons

returns true if the node matches a set of constraints, specified as node

/cmatch cm

+args element str, value str
+return bool
-$n_freds = $personset->cmatch('name', 'fred');

counts the number of matches

/where w

+args element str, test CODE
+return Node[]
-@rich_persons = $data->where('person', sub {shift->get_salary > 100000});

the tree is queried for all elements of the specified type that
satisfy the coderef (must return a boolean)

  my @rich_dog_or_cat_owners =
    $data->where('person',
                 sub {my $p = shift;
                      $p->get_salary > 100000 &&
                      $p->where('pet',
                                sub {shift->get_type =~ /(dog|cat)/})});

/iterate i

+args code CODE
+return
-my @nodes=(); $data->iterate(sub {push(@nodes, shift->name}));

iterates through tree depth first, executing code

# experimental
#run
#collapse
#merge

#misc
*MISCELLANEOUS METHODS
/duplicate d

+args
+return Node
-$node2 = $node->duplicate;

/isanode

+args
+return bool
-if (narr_isanode($node)) { ... }

really only useful in non OO mode...

/hash

+args
+return hash
-$h = $node->hash;

turns a tree into a hash. all data values will be arrayrefs

/pairs

turns a tree into a hash. all data values will be scalar (IMPORTANT:
this means duplicate values will be lost)

*EXPORT

/write 

+args filename str, format str[optional]
+return
-$node->write("myfile.xml");
-$node->write("myfile", "itext");

will try and guess the format from the extension if not specified

/xml

+args filename str, format str[optional]
+return
-$node->write("myfile.xml");
-$node->write("myfile", "itext");

# xml

+args
+return xml str
-print $node->xml;

*XML METHODS
/sax

+args saxhandler SAX-CLASS
+return
-$node->sax($mysaxhandler);

turns a tree into a series of SAX events

/xpath xp tree2xpath

+args
+return xpath object
-$xp = $node->xpath; $q = $xp->find($xpathquerystr);

/xpquery xpq xpathquery

+args xpathquery str
+return Node[]
-@nodes = $node->xqp($xpathquerystr);


# PROC ONLY: narr_load
