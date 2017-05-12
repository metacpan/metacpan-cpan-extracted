# $Id: test-utils.pl,v 1.4 2005/10/05 20:39:34 mjb47 Exp $

our $write_files;
our $debug;

sub get_db {
  $write_files = !!$ENV{DBIX_TEST_WRITE};
  $debug = !!$ENV{DBIX_TEST_DEBUG};

  ok(open(FILE, '<t/dbname'), "Finding out which database to use")
    or diag "Couldn't open configuration file `dbname': $!.\nThis "
      . "file should have been created by `make'.";

  our ($db, $user, $pass) = split /,/, <FILE>;
  chomp $pass;
}

sub open_db {
  use_ok('DBI');
  my $dbh = DBI->connect($db, $user || undef, $pass || undef, 
	{ RaiseError => 0, PrintError => 0 });
  ok($dbh, "Opening database") or diag $DBI::errstr;
  my $foo = $DBI::errstr; # Avoid warning
  return $dbh;
}

sub close_db {
}

sub try_query {
  my $doc;
  my ($xml_server, $q, $f, %args) = @_;
  $args{query} = $q;
  eval { $doc = $xml_server->process(%args) };
  ok(!$@, "Execute query '$q'") or diag $@;
  SKIP: {
    isa_ok($doc, 'XML::LibXML::Document')
      or do {
        diag $doc;
        skip "Query didn't return a document", 2;
      };

    do {
      $doc->toFile($f, 1);
      skip "Writing $f", 2;
    } if $write_files;
    
    ok(my $cmp = new XMLCompare($doc, $f), 
       "Create XMLCompare object for file $f");
    my $msg = $cmp->compare;
    ok(!$msg, "Check results of query '$q'") or do {
      diag $msg;
      $doc->toFile($f . '.d') if $debug;
    }
  }
};

sub try_error {
  my $error;
  my ($xml_server, $q, $re, %args) = @_;
  $args{query} = $q;
  eval { $error = $xml_server->process(%args) };
  ok(!$@, "Execute query '$q'") or diag $@;
  ok(!ref($error), "Query '$q' correctly returned an error");
  like($error, $re, "Query '$q' returned correct error message");
}

package XMLCompare;

use XML::LibXML;

sub new {
  my $proto = shift;
  my $class = ref $proto || $proto;
  my $self = { };
  my $parser = new XML::LibXML;
  $parser->keep_blanks(0);
  my ($a, $b) = @_;
  $self->{a} = (ref $a) ? $a : $parser->parse_file($a);
  $self->{b} = (ref $b) ? $b : $parser->parse_file($b);
  bless $self, $class;
  return $self;
}

sub qname { 
  return '{' . ($_[0]->namespaceURI || ''). '}' . $_[0]->localname; 
}

sub qname_cmp { qname($a) cmp qname($b) }

sub compare {
  my ($self, $a, $b) = @_;
  $a = $self->{a}->getDocumentElement unless $a;
  $b = $self->{b}->getDocumentElement unless $b;

  if($a->isa('XML::LibXML::Element')) {
    my $aname = qname($a);
    if($b->isa('XML::LibXML::Element')) {

      # Compare element names
      my $bname = qname($b);

      return "Expected element $bname but found $aname"
	unless $aname eq $bname;

      # Compare attributes
      my @aa = sort qname_cmp 
	grep { $_->isa('XML::LibXML::Attr') } $a->attributes;
      my @ba = sort qname_cmp
	grep { $_->isa('XML::LibXML::Attr') } $b->attributes;
      foreach my $x (@aa) {
	my $y = shift @ba;
	return "Unexpected attribute " . qname($x)
	  if qname($x) lt qname($y);
	return "Missing attribute " . qname($y)
	  if qname($x) gt qname($y);
	my $xv = $x->value;
	my $yv = $y->value;
	return "Attribute " . qname($x) . ": expected '$yv' but found '$xv'"
	  unless $xv eq $yv;
      };
      do {
	my $y = shift @ba;
	return "Missing attribute " . qname($y);
      } if @ba;

      # Compare children
      $a->normalize;
      $b->normalize;
      my @ac = grep { $_->isa('XML::LibXML::Element') 
			|| $_->isa('XML::LibXML::Text') } $a->childNodes;
      my @bc = grep { $_->isa('XML::LibXML::Element') 
			|| $_->isa('XML::LibXML::Text') } $b->childNodes;
      foreach my $x (@ac) {
	my $y = shift @bc;
	my $r = $self->compare($x, $y);
	return $r if $r;
      };
      return undef;
    } elsif($b->isa('XML::LibXML::Text')) {
      return "Expected text node but found $aname";
    } else {
      die "Unexpected node type: " . ref $b;
    }
  } elsif($a->isa('XML::LibXML::Text')) {
    if($b->isa('XML::LibXML::Text')) {
      my $av = $a->data;
      my $bv = $b->data;
      return "Expected: <<\n$bdata\n>>  but found <<\n$adata\n>>"
	unless $av eq $bv;
      return undef;
    } elsif($b->isa('XML::LibXML::Element')) {
      return "Expected element " . qname($b) . " but found text node";
    } else {
      die "Unexpected node type: " . ref $b;
    }
  } else {
    die "Unexpected node type: " . ref $a;
  }
}

1;
