# Copyrights 2009-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Data::DublinCore;
use vars '$VERSION';
$VERSION = '1.00';

use base 'XML::Compile::Cache';
our $VERSION = '0.01';

use Log::Report 'data-dublincore', syntax => 'SHORT';

use XML::Compile::Util  qw/type_of_node unpack_type pack_type SCHEMA2001/;
use XML::LibXML::Simple qw/XMLin/;
use Scalar::Util        qw/weaken/;


use Data::DublinCore::Util;
use XML::Compile::Util  qw/XMLNS/;

# map namespace always to the newest implementation of the protocol
my $newest     = '20080211';
my %ns2version = (&NS_DC_ELEMS11 => $newest);

my %info =
  ( 20020312 => {}
  , 20021212 => {}
  , 20030402 => {}
  , 20060106 => {}
  , 20080211 => {}
  );

# there are no other options yet
my @prefixes =
  ( dc      => NS_DC_ELEMS11
  , dcterms => NS_DC_TERMS
  , dcmi    => NS_DC_DCMITYPE
  , xml     => XMLNS
  );

#----------------


sub new($)
{   my $class = shift;
    $class->SUPER::new(direction => 'RW', @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{allow_undeclared} = 1
        unless exists $args->{allow_undeclared};

    my $r = $args->{opts_readers} ||= {};
    $r = $args->{opts_readers} = +{ @$r } if ref $r eq 'ARRAY';

    $r->{mixed_elements}   = 'XML_NODE';
    my $s = $self; 
    weaken $s;      # avoid memory leak
#   $r->{mixed_elements}   = sub { $s->_handle_any_type(@_) };
    $r->{any_type}         = sub { $s->_handle_any_type(@_) };
    $args->{any_element} ||= 'ATTEMPT';

    $self->SUPER::init($args);

    my $version = $args->{version} || $newest;

    unless(exists $info{$version})
    {   exists $ns2version{$version}
            or error __x"DC version {v} not recognized", v => $version;
        $version = $ns2version{$version};
    }
    $self->{version} = $version;
    my $info = $info{$version};

    $self->addPrefixes(@prefixes);
    $self->addKeyRewrite('PREFIXED(dc,xml,dcterms)');

    (my $xsd = __FILE__) =~ s!\.pm!/xsd!;
    my @xsds;
    if($version lt 2003)
    {   @xsds = glob "$xsd/dc$version/*";
    }
    else
    {   @xsds = glob "$xsd/dc$version/{dcmitype,dcterms,dc}.xsd";

        # tricky... the application will load the following two,
        # specifying the targetNamespace.  Use with
        #   $self->importDefinitions('qualifieddc', target_namespace => );
        $self->knownNamespace($_ => "$xsd/dc$version/$_.xsd")
            for qw/qualifieddc simpledc/;
    }

    $self->importDefinitions(\@xsds);
    $self->importDefinitions(XMLNS);

    $self->addHook
      ( action => 'READER'
      , type   => 'dc:SimpleLiteral'
      , replace => sub { $self->_simple_literal(@_) }
      );

    $self;
}

sub _simple_literal($$$)   # stupid mixed anytype
{   my ($self, $node, $args, $path, $type, $r) = @_;
    XMLin $node, ContentKey => '_';
}


# Business::XPDL shows how to create conversions here... but all
# DC versions are backwards compatible
sub from($@)
{   my ($thing, $source, %args) = @_;

    my $xml  = XML::Compile->dataToXML($source);
    my $top  = type_of_node $xml;
    my ($ns, $topname) = unpack_type $top;
    my $version = $ns2version{$ns}
       or error __x"unknown DC version with namespace {ns}", ns => $ns;

    my $self = ref $thing ? $thing : $thing->new(version => $version);
    my $r    = $self->reader($top, %args)
        or error __x"root node `{top}' not recognized", top => $top;

    ($top, $r->($xml));
}


sub version()   {shift->{version}}
sub namespace() {shift->{namespace}}

1;
