# $Id: XMLServer.pm,v 1.19 2005/11/15 22:03:01 mjb47 Exp $

use strict;
use warnings;
use XML::LibXML;
use XML::LibXSLT;

package DBIx::XMLServer;

our $VERSION = '0.02';

my $our_ns = 'http://boojum.org.uk/NS/XMLServer';

my $sql_ns = sub {
  my $node = shift;
  my $uri = shift || $our_ns;
  my $prefix;
  $prefix = $node->lookupNamespacePrefix($uri) and return $prefix;
  for($prefix = 'a'; $node->lookupNamespaceURI($prefix); ++$prefix) {}
  $node->setNamespace($uri, $prefix, 0);
  return $prefix;
};

package DBIx::XMLServer::Field;
use Carp;

our $VERSION = sprintf '%d.%03d', (q$Revision: 1.19 $ =~ /(\d+)\.(\d+)/);

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};
  $self->{XMLServer} = shift
    and ref $self->{XMLServer}
      and $self->{XMLServer}->isa('DBIx::XMLServer')
	or croak "No XMLServer object supplied";
  $self->{node} = shift
    and ref $self->{node}
      and $self->{node}->isa('XML::LibXML::Element')
	or croak "No XML element node supplied";
  $self->{node}->namespaceURI eq $our_ns
    and $self->{node}->localname eq 'field'
      or croak "The node is not an <sql:field> element";
  my $type = $self->{node}->getAttribute('type')
    or croak "<sql:field> element has no `type' attribute";
  $class = $self->{XMLServer}->{types}->{$type}
    or croak "Undefined field type: `$type'";
  bless($self, $class);
  $self->init if $self->can('init');
  return $self;
}

sub where { return '1'; }

sub select {
  my $self = shift;
  my $expr = $self->{node}->getAttribute('expr')
    or die "A <sql:field> element has no `expr' attribute";
  return $expr;
}

sub join {
  my $self = shift;
  return $self->{node}->getAttribute('join');
}

sub value {
  my $self = shift;
  return shift @{shift()};
}

sub result {
  my $self = shift;
  my $n = shift;

  my $value = $self->value(shift());

  do {
    $value = $n->ownerDocument->createElementNS($our_ns, 'sql:null');
    $value->setAttribute('type',
			 $self->{node}->getAttribute('null') || 'empty');
  } unless defined $value;

  do {
    my $x = $n->ownerDocument->createTextNode($value);
    $value = $x;
  } unless ref $value;

  my $attr = $self->{node}->getAttribute('attribute');

  if($attr) {
    my $x = $n->ownerDocument->createElementNS($our_ns, 'sql:attribute');
    $x->setAttribute('name', $attr);
    $x->appendChild($value);
    $value = $x;
  }

  $n->replaceNode($value);
}

1;

package DBIx::XMLServer::OrderSpec;

our $VERSION = sprintf '%d.%03d', (q$Revision: 1.19 $ =~ /(\d+)\.(\d+)/);

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = {};

  my ($xmlserver, $node, $dir) = @_;
  $self->{field} = new DBIx::XMLServer::Field($xmlserver, $node);
  $self->{dir} = $dir;

  bless($self, $class);
  return $self;
}

sub orderspec {
  my $self = shift;
  my $spec = $self->{field}->select;
  for ($self->{dir}) {
    defined $_ or last;
    /^ascending$/ && do {
      $spec .= ' ASC';
      last;
    };
    /^descending$/ && do {
      $spec .= ' DESC';
      last;
    };
  }
  return $spec;
}

1;

package DBIx::XMLServer::Request;
use Carp;
use Text::Balanced qw(extract_bracketed);

our $VERSION = sprintf '%d.%03d', (q$Revision: 1.19 $ =~ /(\d+)\.(\d+)/);

if ($ lt v5.7)
{
  require Exporter;
  our @ISA = qw(Exporter);
  our @EXPORT = qw(IsNCNameStartChar IsNCNameChar);
}

# Look for an initial segment of the string which looks like an XPath
# pattern
sub get_xpath {
  my $text = shift;

  # Repeatedly skip XPath-like stuff and bracketed things
  while( (extract_bracketed($text, "[(\"'",
			    '[-|@_./:[:alnum:][:space:]]*')) [0]) {};
  # Skip any more XPath-like stuff
  $text =~ m'\G[-|@_./:[:alnum:][:space:]]*'g;

  return substr($text, 0, pos $text), substr($text, pos $text);
}

BEGIN {
  # This hack is because Perl 5.6.1 appears to be buggy and not
  # allow unicode character properties to be declared in a package
  # pther than main.
  our $property_package = $ lt v5.8 ? 'main' : 'DBIx::XMLServer::Request';
  eval <<END_PROPERTIES;
  package $property_package;

  # These are the ranges defined by XML 1.1, as these
  # are more up-to-date w.r.t Unicode those defined by
  # XML 1.0 (3rd ed).  They're also much simpler to specify.
  sub IsNCNameStartChar {
      return <<END;
41	5A
5F
61	7A
C0	D6
D8	F6
F8	2FF
370	37D
37F	1FFF
200C	200D
2070	218F
2C00	2FEF
3001	D7FF
F900	FDCF
FDF0	FFFD
10000	EFFFF
END
  }

  sub IsNCNameChar {
      return <<END;
2D	2E
30	39
41	5A
5F
61	7A
B7
C0	D6
D8	F6
F8	2FF
300	36F
370	37D
37F	1FFF
200C	200D
203F	2040
2070	218F
2C00	2FEF
3001	D7FF
F900	FDCF
FDF0	FFFD
10000	EFFFF
END
  }

END_PROPERTIES
}

# Definition of NCName as per XML Namespaces 1.1
use utf8;
our $NCName = qr/(?:\p{IsNCNameStartChar}\p{IsNCNameChar}*)/;

sub add_prefix($$) {

  my ( $xpath, $prefix ) = @_;

  while ( $xpath =~ s/
            ^( (?:[^'"]*(?:"[^"]*"|'[^']*'))*[^'"]*
               (?: (?<!attribute|namespace)(?<!\s)\s*::\s*
                 | (?: (?: (?<=[\@([,\/|+-=<>])
                         | (?<=[<>!]=|\/\/|::) 
                         | ^) 
                       (?: $NCName\s+ $NCName\s+ )*
                     | (?: (?<=[.\])"'])
                         | [0-9]+(?:\.[0-9]+)?\s
                         | \$$NCName(?::$NCName)?\s ) 
                       \s* $NCName\s+
                       (?: $NCName\s+ $NCName\s+ )* )
                   (?<![:\$\@]|\p{IsNCNameChar}) ) )
            ($NCName)
            (\s+[^:(\s]|\s*(?![:(\s])\P{IsNCNameChar}|$)
          /$1$prefix:$2$3/x ) {}

  return $xpath;
}

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self;
  if($#_ <= 1) {
    $self = {};
    $self->{XMLServer} = shift;
    $self->{template} = shift;
  } else {
    $self = { @_ };
  };
  ref $self->{XMLServer}
    and $self->{XMLServer}->isa('DBIx::XMLServer') 
      or croak "No XMLServer object supplied";

  $self->{template} or $self->{template} = $self->{XMLServer}->{template};
  $self->{template}->isa('XML::LibXML::Element')
    or croak "Template is not a XML::LibXML::Element";

  $self->{template}->localname eq 'template'
    && $self->{template}->namespaceURI eq $our_ns
      or croak "Template is not <sql:template>";
  $self->{main_table} = $self->{template}->getAttribute('table')
    or croak "The <sql:template> element has no `table' attribute";
  $self->{ns} = $self->{template}->getAttribute('default-namespace');
  my $p = &$sql_ns($self->{template});
  $self->{record} = $self->{template}->findnodes(".//$p:record/*[1]")->shift
    or croak "The <sql:template> element contains no <sql:record> element";

  $self->{criteria} = [];
  $self->{page} = 0;
  $self->{pagesize} = $self->{XMLServer}->{maxpagesize}
    unless defined $self->{pagesize};
  $self->{rowcount} = $self->{XMLServer}->{rowcount}
    unless defined $self->{rowcount};
  bless($self, $class);
  return $self;
}

sub real_parse {
  my $self = shift;
  my $query = shift or croak "No query string supplied";
  foreach(split /&/, $query) {
    # Un-URL-encode the string
    tr/+/ /;
    s/%([0-9A-Fa-f][0-9A-Fa-f])/chr(hex($1))/eg;
    # Split it into key and condition
    my ($key, $condition) = get_xpath($_);
    $key or return "Unrecognised condition: '$condition'";
    for ($key) {
      /^fields$/ && do {
	$condition =~ s/^=// 
	  or return "Expected '=' after 'fields' but found '$condition'";
	$self->{fields} = $condition;
	last; 
      };
      /^order$/ && do {
	$condition =~ s/^=//
	  or return "Expected '=' after 'order' but found '$condition'";
	$self->{order} = $condition;
	last;
      };
      /^page$/ && do { # The page number
        $condition =~ /^=([1-9]\d*)$/
	  or return "Unrecognised page number: $condition";
	$self->{page} = $1 - 1;
	last;
      };
      /^pagesize$/ && do { # The page size
        $condition =~ /^=(\d+)$/
	  or return "Unrecognised page size: $condition";
	$self->{pagesize} = $1;
	defined($self->{XMLServer}->{maxpagesize})
	  && $self->{XMLServer}->{maxpagesize} > 0
          and ( ($1 > 0 && $1 <= $self->{XMLServer}->{maxpagesize})
	    or return "Invalid page size: Must be between 1 " .
	      "and $self->{XMLServer}->{maxpagesize}");
	last;
      };
      /^format$/ && $self->{userformat} && do {
          $condition =~ s/^=// 
            or return "Expected '=' after 'format' but found '$condition'";
          my $root = $self->{XMLServer}->{doc}->documentElement;
          my $p = &$sql_ns($root);
	  $self->{template} = $root->findnodes("/$p:spec/$p:template[@" 
					       . "id='$condition']")->shift
	    or return "Invalid format.  Must be one of "
	      . join(', ', map("'" . $_->value . "'", 
			       $root->findnodes("/$p:spec/$p:template/@"."id")))
              . ".";
	  $self->{template}->localname eq 'template'
	    && $self->{template}->namespaceURI eq $our_ns
	    or croak "Template is not <sql:template>";
	  $self->{main_table} = $self->{template}->getAttribute('table')
	    or croak "The <sql:template> element has no `table' attribute";
	  $self->{ns} = $self->{template}->getAttribute('default-namespace');
	  $p = &$sql_ns($self->{template});
	  $self->{record} = $self->{template}->findnodes(".//$p:record/*[1]")
	    ->shift
	    or croak "The <sql:template> element contains no <sql:record> element";
	  last;
	};
      # Anything else we treat as a search criterion
      push @{$self->{criteria}}, [$key, $condition];
    }
  }
  return undef;
}

sub do_criteria {
  my $self = shift;

  my $prefix = $self->{ns};
  $prefix = &$sql_ns($self->{record}, $self->{ns})
    if defined $self->{ns} && $self->{ns} ne '*';
  my $p = &$sql_ns($self->{record});
  foreach(@{$self->{criteria}}) {
    my $key = $_->[0];
    # Fix up a default namespace
    $key = add_prefix($key, $prefix) if $prefix;
    # Find the field
    my @nodelist = $self->{record}->findnodes($key);
    my $node;
    if(@nodelist eq 1 && $nodelist[0]->isa('XML::LibXML::Attr')) {
      my $name = $nodelist[0]->nodeName;
      my $owner = $nodelist[0]->getOwnerElement;
      my $q = &$sql_ns($owner);
      $node = $owner->findnodes("$q:field[@"."attribute='$name']")->shift
	or return "Attribute '$key' isn't a field";
    } else {
      my @nodes = $self->{record}->findnodes 
	($key . "//$p:field[not(@"."attribute)]")
	or return "Unknown field: '$key'";
      @nodes eq 1 or return "Expression '$key' selects more than one field";
      $node = shift @nodes;
    }
    $_->[0] = new DBIx::XMLServer::Field($self->{XMLServer}, $node);
  }
  return undef;
}

sub _prune {
  my $element = shift;
  if($element->getAttributeNS($our_ns, 'keepme')) {
    foreach my $child ($element->childNodes) {
      _prune($child) if $child->isa('XML::LibXML::Element');
    }
  } else {
    $element->unbindNode
      unless ($element->namespaceURI || '') eq $our_ns # Hack to avoid pruning 
	&& $element->localname eq 'field'      # attribute fields
	  && $element->getAttribute('attribute');
  }
}

sub build_output {
  my $self = shift;
  my $doc = shift;

  # Create the output structure
  my $new_template = $self->{template}->cloneNode(1);
  $doc->adoptNode($new_template);
  $doc->setDocumentElement($new_template);
  my $p = &$sql_ns($new_template);
  my $record = $new_template->findnodes(".//$p:record")->shift
    or croak "There is no <sql:record> element in the template";
  $self->{newrecord} = $record->findnodes('*')->shift
    or croak "The <sql:record> element has no child element";

  $self->{rowcount} = 'NONE'
    unless $new_template->findnodes(".//$p:meta[@ type='rows']")->size();

  # Find the nodes to return
  if(defined $self->{fields}) {
    my $prefix = $self->{ns};
    $prefix = &$sql_ns($self->{newrecord}, $self->{ns})
      if defined $self->{ns} && $self->{ns} ne '*';
    my ($r, $s) = get_xpath($self->{fields});
    return "Unexpected text: '$s'" if $s;
    $r = add_prefix($r, $prefix) if $prefix;
    $self->{fields} = $r;
  } else {
    $self->{fields} = '.';
  }
  my @nodeset = $self->{newrecord}->findnodes
    ("($self->{fields})/descendant-or-self::*");
  @nodeset > 0 or return "No elements match expression $self->{fields}";

  # Mark the subtree containing them
  $self->{newrecord}->setAttributeNS($our_ns, 'keepme', 1);
  foreach my $node (@nodeset) {
    until($node->isa('XML::LibXML::Element') && 
	  $node->getAttributeNS($our_ns, "keepme")) {
      $node->setAttributeNS($our_ns, "keepme", 1)
	if $node->isa('XML::LibXML::Element');
      $node = $node->parentNode;
    }
  }

  # Find the nodes to order by
  if(defined $self->{order}) {
    my $prefix = $self->{ns};
    $prefix = &$sql_ns($self->{newrecord}, $self->{ns})
      if defined $self->{ns} && $self->{ns} ne '*';
    my $order = $self->{order};
    my @order;
    while ( $order ne '' ) {
      my ($xpath, $more) = get_xpath($order);
      $xpath = add_prefix($xpath, $prefix) if $prefix;
      $xpath =~ s/ +(ascending|descending) *$//;
      my $dir = $1;
      my @o = $self->{newrecord}->findnodes($xpath)
	or return "Invalid field in order clause: $xpath\n";
      foreach (@o) {
	my @f = $_->findnodes(
	  $_->nodeType == XML::LibXML::XML_ATTRIBUTE_NODE
	    ? "../$p:field[\@attribute='".$_->nodeName."']"
	    : ".//$p:field" )
	  or return "No non-static data matched by order clause: $xpath\n";
	foreach (@f) {
	  push @order,
	    new DBIx::XMLServer::OrderSpec($self->{XMLServer}, $_, $dir);
	}
      }
      return "Unexpected order: '$order'" 
	unless $more eq '' || $more =~ s/^,//;
      $order = $more;
    }
    $self->{order} = \@order;
  }

  # Prune away what we don't want to return
  _prune($self->{newrecord});

  return undef;
}

sub build_fields {
  my $self = shift;
  my @fields;
  my $p = &$sql_ns($self->{newrecord});
  foreach($self->{newrecord}->findnodes(".//$p:field")) {
    push @fields, new DBIx::XMLServer::Field($self->{XMLServer}, $_);
  }
  $self->{fields} = \@fields;
  return undef;
}

sub add_join {
  my ($self, $table) = @_;
  return unless $table;
  do {
    my $root = $self->{XMLServer}->{doc}->documentElement;
    my $p = &$sql_ns($root);
    my $tabledef = $root->find("/$p:spec/$p:table[@"."name='$table']")->shift
      or croak "Unknown table reference: $table";
    my $jointo = $tabledef->getAttribute('jointo');
    my $join = '';
    do {
      $self->add_join($jointo);
      $join = uc $tabledef->getAttribute('join') || '';
      $join .= ' JOIN ';
    } if $jointo;
    my $sqlname = $tabledef->getAttribute('sqlname')
      or croak "Table `$table' has no `sqlname' attribute";
    $join .= "$sqlname AS $table";
    do {
      if(my $using = $tabledef->getAttribute('using')) {
	$join .= " ON $jointo.$using = $table.$using";
      } elsif(my $ref = $tabledef->getAttribute('refcolumn')) {
	my $key = $tabledef->getAttribute('keycolumn')
	  or croak "Table $table has `refcolumn' without `keycolumn'";
	$join .= " ON $jointo.$ref = $table.$key";
      } elsif(my $on = $tabledef->getAttribute('on')) {
	$join .= " ON $on";
      }
    } if $jointo;
    push @{$self->{jointext}}, $join;
    $self->{joinhash}->{$table} = 1;
  } unless $self->{joinhash}->{$table};
}

sub parse {
  my ($self, $arg) = @_;
  my $err;

  $self->{doc} = new XML::LibXML::Document;
  $self->{arg} = $arg;
  $err = $self->real_parse($arg) and return $err;
  $err = $self->do_criteria and return $err;
  $err = $self->build_output($self->{doc}) and return $err;
  $err = $self->build_fields and return $err;

  $self->{jointext} = [];
  $self->{joinhash} = {};
  $self->add_join($self->{main_table});
  foreach my $x (@{$self->{criteria}}) {
    foreach($x->[0]->join) {
      $self->add_join($_);
    }
  }

  my $select;
  my $from;
  my $where;
  my $order;
  my $limit;

  eval {
    $where = join(' AND ', map($_->[0]->where($_->[1]),
				      @{$self->{criteria}})) || '1';
    $from = join(' ', @{$self->{jointext}});
  };
  return $@ if $@;

  $self->{count_query} = "SELECT COUNT(*) FROM $from WHERE $where";

  foreach my $f (@{$self->{fields}}) {
    foreach ($f->join) {
      $self->add_join($_);
    }
  }

  foreach my $o (@{$self->{order}}) {
    foreach ($o->{field}->join) {
      $self->add_join($_);
    }
  }

  eval {
    $select = join(',', map($_->select, @{$self->{fields}})) || '0';
    $order = (defined $self->{order} && scalar @{$self->{order}}) ? 
      ' ORDER BY ' . join(',', map($_->orderspec, @{$self->{order}})) 
        : '';
    $limit = ($self->{pagesize} > 0) ? 
      ' LIMIT ' . ($self->{page} * $self->{pagesize}) . ", $self->{pagesize}"
	: '';
    $from = join(' ', @{$self->{jointext}});
  };
  return $@ if $@;

  $self->{query} = "SELECT $select FROM $from WHERE $where$order$limit";

  return undef;
}

# Process a request
# $results = $xmlout->process();
sub process {
  my $self = shift;
  my %args = @_;
  my $err;

  $self->{query} 
    or croak "DBIx::XMLServer::Request: must call parse before process";

  $args{rowcount} = $self->{rowcount} unless $args{rowcount};

  # Do the query
  my $query = $self->{query};
  $query =~ s/^SELECT/SELECT SQL_CALC_FOUND_ROWS/ 
    if $args{rowcount} eq 'FOUND_ROWS';
  my $sth = $self->{XMLServer}->{dbh}->prepare($query);
  $sth->execute or croak $sth->errstr;

  # Put the data into the result tree
  my $r = $self->{newrecord}->parentNode;
  my @row;
  while(@row = $sth->fetchrow_array) {

    # Clone the template record and insert after the previous record
    $r = $r->parentNode->insertAfter($self->{newrecord}->cloneNode(1), $r);

    # Fill in the values
    my $p = &$sql_ns($self->{newrecord});
    my @n = $r->findnodes(".//$p:field");
    foreach(@{$self->{fields}}) {
      eval { $_->result(shift @n, \@row); };
      return $@ if $@;
    }

  }

  my $rows = 0;
  do {
    my @r;
    @r = $self->{XMLServer}->{dbh}->selectrow_array('SELECT FOUND_ROWS()')
      or croak $self->{XMLServer}->{dbh}->errstr;
    $rows = $r[0];
  } if $args{rowcount} eq 'FOUND_ROWS';
  do {
    my @r;
    @r = $self->{XMLServer}->{dbh}->selectrow_array($self->{count_query})
      or croak $self->{XMLServer}->{dbh}->errstr;
    $rows = $r[0];
  } if $args{rowcount} eq 'COUNT';

  my %params = (
    'args' => $self->{arg},
    'page' => $self->{page},
    'pagesize' => $self->{pagesize},
    'query' => $self->{query},
    'rows' => $rows,
  );		

  # Process through XSLT to produce the result
  return $self->{XMLServer}->{xslt}->transform($self->{doc}, 
    XML::LibXSLT::xpath_to_string(%params));
}

1; 

package DBIx::XMLServer;
use Carp;

sub add_type {
  my $self = shift;
  my $type = shift;
  my $name = $type->getAttribute('name') 
    or croak("Field type found with no name");
  
  my $p = &$sql_ns($type);
  my $package_name = $type->findnodes("$p:module");
  if($package_name->size) {
    $package_name = "$package_name";
    eval "use $package_name;";
    croak "Error loading module `$package_name' for field type"
      . " definition `$name':\n$@" if $@;
  } else {
    $package_name = "DBIx::XMLServer::Types::$name";
    my $where = $type->findnodes("$p:where");
    $where = $where->size ? "sub where { $where }" : '';
    my $select = $type->findnodes("$p:select");
    $select = $select->size ? "sub select { $select }" : '';
    my $join = $type->findnodes("$p:join");
    $join = $join->size ? "sub join { $join }" : '';
    my $value = $type->findnodes("$p:value");
    $value = $value->size ? "sub value { $value }" : '';
    my $init = $type->findnodes("$p:init");
    $init = $init->size ? "sub init { $init }" : '';
    my $isa = $type->findnodes("$p:isa");
    $isa = $isa->size ? "$isa" : 'DBIx::XMLServer::Field';
    $isa =~ s/\s+//g;
    eval <<EOF;
package $package_name;
use XML::LibXML;
our \@ISA = ('$isa');
$init
$select
$where
$join
$value
1;
EOF
    croak "Error compiling field type definition `$name':\n$@" if $@;
  }
  $self->{types}->{$name} = $package_name;
}

# Object constructor
# $xmlout = new DBIx::XMLServer($dbh, $doc[, $template]);
sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self;
  my $doc;

  # Deal with the parameters
  if(ref $_[0]) { # dbh, doc [, template]
    $self = {};
    $self->{dbh} = shift or croak "No database handle supplied";
    $doc = shift or croak "No template file supplied";
    $self->{template} = shift;
  } else { # Named parameters
    $self = { @_ };
    $self->{dbh} or croak "No database handle supplied";
    $doc = $self->{doc} or croak "No template file supplied";
  }
  bless($self, $class);

  my $parser = new XML::LibXML;
  ref $doc or $doc = $parser->parse_file($doc)
    or croak "Couldn't parse template file '$doc'";
  $doc->isa('XML::LibXML::Document')
    or croak "This isn't a XML::LibXML::Document";
  $self->{doc} = $doc;

  my $root = $doc->documentElement;
  $root->localname eq 'spec' && $root->namespaceURI eq $our_ns
    or croak "Document element is not <sql:spec>";

  my $p = &$sql_ns($root);

  # Find all the field type definitions and parse them
  $self->{types} = {};
  foreach($doc->findnodes("/$p:spec/$p:type")) {
    $self->add_type($_);
  }

  # Find the template
  $self->{template}
    or $self->{template} = $doc->find("/$p:spec/$p:template")
        ->shift
      or croak "No <sql:template> element found";

  $self->{template}->isa('XML::LibXML::Element')
    or croak "Template is not a XML::LibXML::Element";

  $self->{template}->localname eq 'template'
    && $self->{template}->namespaceURI eq $our_ns
      or croak "Template is not <sql:template>";

  # Parse our XSLT stylesheet
  my $xslt = new XML::LibXSLT;
  my $f = $INC{'DBIx/XMLServer.pm'};
  $f =~ s/XMLServer\.pm/XMLServer\/xmlout\.xsl/;
  my $style_doc = $parser->parse_file($f)
    or croak "Couldn't open stylesheet '$f'";
  $self->{xslt} = $xslt->parse_stylesheet($style_doc)
    or croak "Error parsing stylesheet '$f'";

  $self->{maxpagesize} = 0 unless $self->{maxpagesize};
  $self->{rowcount} = 'NONE' unless defined $self->{rowcount};

  return $self;
}

sub process {
  my $self = shift;
  my %args;
  my $err;

  # Process arguments
  if($#_ <= 1 && $_[0] ne 'query') {
    $args{query} = shift
      or croak "No query string given";
  } else { # Named parameters
    %args = @_;
  }

  $args{XMLServer} = $self;
  my $request = new DBIx::XMLServer::Request(%args);
  $err = $request->parse($args{query}) and return $err;
  return $request->process();
}

1;
__END__

=head1 NAME

DBIx::XMLServer - Serve data as XML in response to HTTP requests

=head1 SYNOPSIS

  use XML::LibXML;
  use DBIx::XMLServer;

  my $xml_server = new DBIx::XMLServer($dbh, "template.xml");

  my $doc = $xml_server->process($QUERY_STRING);
  die "Error: $doc" unless ref $doc;

  print "Content-type: application/xml\r\n\r\n";
  print $doc->toString(1);

=head1 DESCRIPTION

This module implements the whole process of generating an XML document
from a database query, in response to an HTTP request.  The mapping
from the DBI database to an XML structure is defined in a template
file, also in XML; this template is used not only to turn the data
into XML, but also to parse the query string.  To the user, the format
of the query string is very natural in relation to the XML data which
they will receive.

All the methods of this object can take a hash of named parameters instead
of a list of parameters.

One C<DBIx::XMLServer> object can process several queries.  The
following steps take place in processing a query:

=over

=item 1.

The query string is parsed.  It contains search criteria together with
other options about the format of the returned data.

=item 2.

The search criteria from the query string are converted, using the XML
template, into an SQL SELECT statement.

=item 3.

The results of the SQL query are translated into XML, again using the
template, and returned to the caller.

=back

=head1 METHODS

=head2 Constructor

  my $xml_server = new DBIx::XMLServer( $dbh, $template_doc 
                                        [, $template_node] );

  my $xml_server = new DBIx::XMLServer( dbh => $dbh,
                                        doc => $template_doc,
                                        template => $template_node,
                                        maxpagesize => $maxpagesize );

The constructor for C<DBIx::XMLServer> takes two mandatory arguments
and two optional arguments.

=over

=item C<$dbh>

This is a handle for the database; see L<DBI> for more information.

=item C<$template_doc>

This is the XML document containing the template.  It may be either an
C<XML::LibXML::Document> object or a string, which is taken as a file
name.

=item C<$template_node>

One template file may contain several individual templates; if so,
this argument may be used to pass an C<XML::LibXML::Element> object
indicating which template should be used.  By default the first
template in the file is used.

=item C<$maxpagesize>

This option may be used to limit the number of records than will be
returned in a query.  The user can choose a page size smaller than
this by using the C<pagesize> option on their query (see below), but 
they will not be allowed to request a page size larger than this 
maximum.

=back

=head2 process()

  my $result = $xml_server->process( $query [, $template_node] );

  my $result = $xml_server->process( query => $query,
                                     template => $template_node,
                                     rowcount => $rowcount,
                                     userformat => $userformat );

This method processes an HTTP query and returns an XML document
containing the results of the query.  There are one mandatory argument
and two optional arguments.

=over

=item C<$query>

This is the HTTP GET query string to be processed.

=item C<$template_node>

As above, this may indicate which of several templates is to be used
for this query.  It is an C<XML::LibXML::Element> object.

=item C<$rowcount>

It is possible to limit the number of rows returned in one query, either
in response to a user request (by using the C<pagesize> option, see below)
or by passing the C<maxpagesize> option when creating the C<DBIx::XMLServer>
object.  In these cases it may be useful to know the total number of rows 
that would have been returned had no limit been in place.  The number of
rows can be put into the output XML document using the
B<< <sql:meta type="rows"> >> element in the template (see below).  This
argument chooses how this information should be obtained from the database.

=over

=item FOUND_ROWS

Passing C<< rowcount => 'FOUND_ROWS' >> tells the module to use the
B<SQL_COUNT_FOUND_ROWS> option and the B<FOUND_ROWS> function.  If
your database supports these, use this option.

=item COUNT

Passing C<< rowcount => 'COUNT' >> means that a second query will be
done after the main database query, of this form:

  SELECT COUNT(*) FROM ... WHERE ...

=back

=item C<$userformat>

Setting this to a true value allows the user to choose between several
templates in the file by specifying the C<format> option in the query
string.

=back

The return value of this method is either an C<XML::LibXML::Document>
object containing the result, or a string containing an error message.
An error string is only returned for errors caused by the HTTP query
string and thus the user's fault; other errors, which are the
programmer's fault, will B<croak>.

=head1 EXAMPLE

This example is taken from the tests included with the module.  The
database contains two tables.

  Table dbixtest1:

  +----+--------------+---------+------+
  | id | name         | manager | dept |
  +----+--------------+---------+------+
  |  1 | John Smith   |    NULL |    1 |
  |  2 | Fred Bloggs  |       3 |    1 |
  |  3 | Ann Other    |       1 |    1 |
  |  4 | Minnie Mouse |    NULL |    2 |
  |  5 | Mickey Mouse |       4 |    2 |
  +----+--------------+---------+------+

  Table dbixtest2:

  +----+----------------------+
  | id | name                 |
  +----+----------------------+
  |  1 | Widget Manufacturing |
  |  2 | Widget Marketing     |
  +----+----------------------+

The template file (in F<t/t10.xml>) contains the following three table
definitions:

  <sql:table name="employees" sqlname="dbixtest1"/>
  <sql:table name="managers" sqlname="dbixtest1"
    join="left" jointo="employees" refcolumn="manager" keycolumn="id"/>
  <sql:table name="departments" sqlname="dbixtest2"
    join="left" jointo="employees" refcolumn="dept" keycolumn="id"/>

The template element is as follows:

  <sql:template table="employees">
    <employees>
      <sql:record>
	<employee id="foo">
	  <sql:field type="number" attribute="id" expr="employees.id"/>
	  <name>
	    <sql:field type="text" expr="employees.name"/>
	  </name>
	  <manager>
	    <sql:field type="text" expr="managers.name" join="managers"
              null='nil'/>
	  </manager>
          <department>
	    <sql:field type="text" expr="departments.name" join="departments"/>
	  </department>
	</employee>
      </sql:record>
    </employees>
  </sql:template>

The query string B<name=Ann*> produces the following output:

  <?xml version="1.0"?>
  <employees>
    <employee id="3">
      <name>Ann Other</name>
      <manager>John Smith</manager>
      <department>Widget Manufacturing</department>
    </employee>
  </employees>

The query string B<department=Widget%20Marketing&fields=name> produces
the following output:

  <?xml version="1.0"?>
  <employees>
    <employee id="4">
      <name>Minnie Mouse</name>
    </employee>
    <employee id="5">
      <name>Mickey Mouse</name>
    </employee>
  </employees>

=head1 HOW IT WORKS: OVERVIEW

The main part of the template file which controls DBIx::XMLServer is
the template element.  This element gives a skeleton for the output
XML document.  Within the template element is an element, the record
element, which gives a skeleton for that part of the document which is
to be repeated for each row in the SQL query result.  The record element
is a fragment of XML, mostly not in the B<sql:> namespace, which contains
some B<< <sql:field> >> elements.

Each B<< <sql:field> >> element corresponds to a point in the record
element where data from the database will be inserted.  Often, this
means that one B<< <sql:field> >> element corresponds to one column in
a table in the database.  The field has a I<type>; this determines the
mappings both between data in the database and data in the XML
document, and between the user's HTTP query string and the SQL WHERE
clause.

The HTTP query which the user supplies consists of search criteria,
together with other special options which control the format of the
XML output document.  Each criterion in the HTTP query selects one
field in the record and gives some way of limiting data on that field,
typically by some comparison operation.  The selection of the field is
accomplished by an XPath expression, normally very simply consisting
just of the name of the field.  After the field has been selected, the
remainder of the criterion is processed by the Perl object
corresponding to that field type.  For example, the built-in text
field type recognises simple string comparisons as well as regular
expression comparisons; and the build-in number field type recognises
numeric comparisons.

All these criteria are put together to form the WHERE clause of the
SQL query.  The user may also use the special B<fields=...> option to
select which fields appear in the resulting XML document; the value of
this option is again an XPath expression which selects a part of the
record template to be returned.

Other special options control how many records are returned on each
page, which page of the results should be returned, and may choose one
of several templates in the file.

The template to use for a query is chosen as follows:

=over

=item 1.

If the B<userformat> option is set when calling C<DBIx::XMLServer::process()>
and the user has chosen a template with the B<format> option in the query
string, that template is used.

=item 2.

Otherwise, if a template was specified when calling 
C<DBIx::XMLServer::process()>, then that template is used.

=item 3.

Otherwise, if a template was specified when constructing the 
C<DBIx::XMLServer> object, then that template is used.

=item 4.

Otherwise, the first template in the file is used.

=back

=head1 THE TEMPLATE FILE

The behaviour of DBIx::XMLServer is determined entirely by the
template file, which is an XML document.  This section explains the
format and meaning of the various elements which can occur in the
template file.

=head2 Namespace

All the special elements used in the template file are in the
namespace associated to the URI B<http://boojum.org.uk/NS/XMLServer>.
In this section we will suppose that the prefix B<sql:> is bound to
that namespace, though of course any other prefix could be used
instead.

=head2 The root element

The document element of the template file must be an B<< <sql:spec> >>
element.  This element serves only to contain the other elements in
the template file.

Contained in the root element are elements of three types:

=over

=item *

Field type definition elements;

=item *

Table definition elements;

=item *

One or more template elements.

=back

We now describe each of these in more detail.

=head2 Field type definitions

A field type definition is given by a B<< <sql:type> >> element.  Each
field in the template has a type.  That type determines: how a
criterion from the query string is converted to an SQL WHERE clause
for that field; how the SQL SELECT clause to retrieve data for that
field is created; and how the resulting SQL data is turned into XML.
For example, the standard date field type can interpret simple date
comparisons in the query string, and puts the date into a specific
format in the XML.

Each field type is represented by a Perl object class, derived from
C<DBIx::XMLServer::Field>.  For information about the methods which
this class must define, see L<DBIx::XMLServer::Field>.  The class may
be defined in a separate Perl module file, as for the standard field
types; or the methods of the class may be included verbatim in the XML
file, as follows.

The B<< <sql:type> >> element has one attribute, B<name>, and four
element which may appear as children.

=over

=item attribute: B<name>

The B<name> attribute defines the name by which this type will be
referred to in the templates.

=item element: B<< <sql:module> >>

If the Perl code implementing the field type is contained in a Perl
module in a separate file, this element is used to give the name
of the module.  It should contain the Perl name of the module (for
example, C<DBIx::XMLServer::NumberField>).

=back

=head3 Example

  <sql:type name="number">
    <sql:module>DBIx::XMLOut::NumberField</sql:module>
  </sql:type>

Instead of the B<< <sql:module> >> element, the B<< <sql:type> >>
element may have separate child elements defining the various facets
of the field type.

=over

=item element: B<< <sql:isa> >>

This element contains the name of a Perl module from which the field
type is derived.  The default is C<DBIx::XMLServer::Field>.

=item element: B<< <sql:select> >>

This element contains the body of the C<select> method (probably
inside a CDATA section).

=item element: B<< <sql:where> >>

This element contains the body of the C<where> method (probably inside
a CDATA section).

=item element: B<< <sql:join> >>

This element contains the body of the C<join> method (probably inside
a CDATA section).

=item element: B<< <sql:value> >>

This element contains the body of the C<value> method (probably inside
a CDATA section).

=item element: B<< <sql:init> >>

This element contains the body of the C<init> method (probably inside
a CDATA section).

=back

=head2 Table definitions

Any SQL table which will be accessed by the template needs a table
definition.  As a minimum, a table definition associates a local name
for a table with the table's SQL name.  In addition, the definition
can specify how this table is to be joined to the other tables in the
database.

Note that one SQL table may often be joined several times in different
ways; this can be accomplished by several table definitions, all
referring to the same SQL table.

A table definition is represented by the B<< <sql:table> >> element,
which has no content but several attributes.

=over

=item attribute: B<name>

This mandatory attribute gives the name by which the table will be
referred to in the template, and also the alias by which it will be
known in the SQL statement.

=item attribute: B<sqlname>

This mandatory attribute gives the SQL name of the table.  In the
SELECT statement, the table will be referenced as <sqlname> AS <name>.

=item attribute: B<jointo>

This attribute specifies the name of another table to which this table
is joined.  Whenever a query involves a column from this table, this
and the following attributes will be used to add an appropriate join
to the SQL SELECT statement.

=item attribute: B<join>

This attribute specifies the type of join, such as B<LEFT>, B<RIGHT>,
B<INNER> or B<OUTER>.

=item attribute: B<on>

This attribute specifies the ON clause used to join the two tables.  In
the most common case, the following two attributes may be used instead.

=item attribute: B<keycolumn>

This attribute gives the column in this table used to join to the other 
table.

=item attribute: B<refcolumn>

This attribute gives the column in the other table used for the join.
Specifying B<keycolumn> and B<refcolumn> is equivalent to giving the
B<on> attribute value

  <this table's name>.<keycolumn> = <other table's name>.<refcolumn> .

=back

=head2 The template element

A template file must contain at least one B<< <sql:template> >>
element.  This element defines the shape of the output document.  It
may contain arbitrary XML elements, which are copied straight to the
output document.  It also contains one B<< <sql:record> >> element,
which defines that part of the output document which is repeated for
each row returned from the SQL query.

Further, the template element may contain B<< <sql:meta> >> elements
which indicate that certain information about the query should be
inserted into the output document.

As the output document is formed from the content of the B<<
<sql:template> >> element, it follows that this element must have
exactly one child element.

The B<< <sql:template> >> may have the following attributes:

=over

=item attribute: B<id>

This optional attribute gives a unique identifier to the template.  The
user may, if allowed, choose which template to use by specifying the
B<format> option in the query string together with this identifier.

=item attribute: B<table>

This mandatory attribute specifies the main table for this template, to
which any other tables will be joined.

=item attribute: B<default-namespace>

In the HTTP query string, the user must refer to parts of the template.
To avoid them having to specify namespaces for these, this attribute
gives a default namespace which will be used for unqualified names
in the query string.

=back

=head2 The record element

Each template contains precisely one B<< <sql:record> >> element among
its descendants.  This record element defines that part of the output
XML document which is to be repeated once for each row in the result
of the SQL query.  The content of the record element consists of a
fragment of XML containing some B<< <sql:field> >> elements; each of
these defines a point at which SQL data will be inserted into the
record.  The B<< <sql:record> >> must have precisely one child element.

It is also to the structure inside the B<< <sql:record> >> element
that the user's HTTP query refers.

The B<< <sql:record> >> element has no attributes.

=head2 The field element

The record element will contain several B<< <sql:field> >> elements.
Each of these field elements defines what the user will think of as a
B<field>; that is, a part of the XML record which changes from one
record to the next.  Normally this will correspond to one column in an
SQL table, though this is not obligatory.

A field has a B<type>, which refers to one of the field type
definitions in the template file.  This type determines the mappings
both between SQL data and XML output data, and between the user's
query and the SQL WHERE clause.

The B<< <sql:field> >> element may have the following attributes:

=over

=item attribute: B<type>

This mandatory attribute gives the type of the field.  It is the name
of one of the field types defined in the template file.

=item attribute: B<join>

This attribute specifies which table needs to be joined to the main
table in order for this field to be found.  (Note: this attribute is
only read by the field type class's C<join> method.  If that method is
overridden, this attribute may become irrelevant.)

=item attribute: B<attribute>

If this attribute is set, the contents of the field will not be
returned as a text node, but rather as an attribute on the B<<
<sql:field> >> node's parent node.  The value of the B<attribute>
attribute gives the name of the attribute on the parent node which
should be filled in with the value of this field.  When this attribute
is set, the parent node should always have an attribute of that name
defined; the contents are irrelevant.

=item attribute: B<expr>

This attribute gives the SQL SELECT expression which should be
evaluated to find the value of the field.  (Note: this attribute is
only ever looked at in the field type class's C<select> method.  If
this method is overridden, this attribute need not necessarily still
be present.)

=item attribute: B<null>

This attribute determines the action when the field value is null.  There
are three possible values:

=over

=item B<empty> (default)

The field is omitted from the result, but the parent element remains.

=item B<omit>

The parent element is omitted from the record

=item B<nil>

The parent element has the B<xsi:nil> attribute set.

=back

=back

=head2 The sql:omit attribute

Any element in the record may have the Boolean attribute B<sql:omit>.
If this attribute is set, then this element will be omitted from any
record in which the element is empty (because child elements have been
omitted).

=head2 The meta element

The B<< <sql:meta> >> element is used for putting information about the
query into the output document.  The information is selected by the
B<type> attribute of the element.  The following B<type> attributes
are recognised:

=over

=item type='args'

This gives the original query string passed to B<DBIx::XMLServer>.

=item type='page'

This gives the page number within the results, as selected by the
B<page=> option in the query string.

=item type='pagesize'

This gives the page size, as selected by the B<pagesize=> option in 
the query string.

=item type='query'

This gives the SQL query which was executed to produce the results.

=item type='rows'

This gives the number of rows which the query would have returned, had
it not been for the B<page=> and B<pagesize=> options.  To tell the
module how to find this information, set the B<rowcount> option when
processing the request (see above).

=back

The B<< <sql:meta> >> element in the template will be replaced by the
corresponding string in the output document.  Alternatively, it is
possible to place the string into the output document as an attribute
to the parent element of the B<< <sql:meta> >> element.  To do this,
include an attribute B<attribute="name"> on the B<< <sql:meta> >> element,
where B<name> is the local name of the attribute.  To add a namespace
to the attribute, additionally include an attribute B<namespace="foo">
on the B<< <sql:meta> >> element, replacing B<foo> with whatever
namespace should be used.

=head1 SPECIAL OPTIONS IN THE QUERY STRING

The HTTP query string may contain certain special options which are
not interpreted as criteria on the records to be returned, but instead
have some other effect.

=over

=item fields = <expression>

This option selects which part of each record is to be returned.  In
the absence of this option, an entire record is returned for each row
in the result of the SQL query.  If this option is set, its value
should be an XPath expression.  The expression will be evaluated in
the context of the single child of the B<< <sql:record> >> element and
should evaluate to a set of nodes; the part of the record returned is
the smallest subtree containing all the nodes selected by the
expression.

=item pagesize = <number>, page = <number>

These options give control over how many records are returned in one
query, and which of several pages is returned.  To put a limit on the
page size which can be requested, use the B<maxpagesize> option when
creating the C<DBIx::XMLServer> object.  By default there is no limit.

=item order = <list>

This option controls how records are ordered in the output document.
The B<< <list> >> should be a comma-separated list of XPath
expressions, each optionally followed by a space and the string
B<ascending> or B<descending>.  Each of these XPath expressions is
evaluated within the context of the single child of the 
B<< <sql:record> >> element and should select one or more fields;
these fields are used to order the result records.  Fields are used in
the order that they appear in the list; if a single list element
selects more than one field, they are used in document order.

=back

=head1 HOW IT REALLY WORKS

When a C<DBIx::XMLServer> object is created, the template file is
parsed.  A new Perl module is compiled for each field type defined.

The C<process()> method performs the following steps.

=over

=item 1.

The HTTP query string is parsed.  It is split at each `&' character,
and each resulting fragment is un-URL-escaped.  Each fragment is then
examined, and a leading part removed which matches a grammar very
similar to the B<Pattern> production in XSLT (see
L<http://www.w3.org/TR/xslt>).  This leading part is assumed to be an
expression referring to a field in the B<< <sql:record> >> element of
the template, unless it is one of the special options B<fields>,
B<pagesize> or B<page>.  If the B<< <sql:template> >> has a
B<default-namespace> attribute, then any unqualified name in this
expression has that default namespace added to it.

=item 2.

Each criterion in the query string is turned into part of the WHERE
clause.  The leading part of each fragment of the query string is
evaluated as an XPath expression in the context of the single child of
the B<< <sql:record> >> element.  The result must be either a nodeset
having a unique B<< <sql:field> >> descendant; or an attribute on an
element having a child B<< <sql:field> >> element whose B<attribute>
attribute matches.  In either case, a single B<< <sql:field> >>
element is found.  That field's type is looked up and the resulting
field type class's C<where> method called, being passed the remainder
of the fragment of the HTTP query string.  The result of the C<where>
method is added to the WHERE clause; all criteria are combined by AND.

=item 3.

A new result document is created whose document element is a clone of
the B<< <sql:template> >> element.  The B<< <sql:record> >> in this
new document is located.  The value of the special B<fields> option is
evaluated, as an XPath expression, within the unique child of that
element, and the smallest subtree containing the resulting fields is
formed.  The rest of the record is pruned away.  The SQL SELECT clause
is now created by calling the C<select> method of each of the B<<
<sql:field> >> elements left after this pruning.

=item 4.

The `tables' part of the SELECT statement is formed by calling the
C<join> methods of all the tables which are referred to either in the
search criteria, or by any of the field to be returned.

=item 5.

The SELECT statement is executed.  For each result row, a copy of the
pruned result record is created.  Each field in this record is filled in
by calling the C<value> method of the corresponding field type.

=item 6.

The resulting document is passed through an XSL transform for tidying
up before being returned to the caller.

=back

=head1 BUGS

There are quite a lot of stray namespace declarations in the output.
They make no difference to the semantic meaning of the markup, but
they are ugly.  I gather that XML::LibXML will provide the means to
remove them in the near future.

The way we build JOIN expressions isn't very clever, and probably
doesn't work for anything more than the simplest situations.

The way we add a default prefix to every XPath expression is a bit of
a hack.  I think the only way to fix this is to wait for XPath 2.0 to
be widely available.

This module has been written to use MySQL and has only been tested on
that platform.  I would be interested to hear from users who have been
able to make it work on other platforms.

=head1 SEE ALSO

L<DBIx::XMLServer::Field>

=head1 AUTHOR

Martin Bright E<lt>martin@boojum.org.ukE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2003-4 Martin Bright

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
