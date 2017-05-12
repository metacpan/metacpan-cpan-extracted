package Data::Dump::XML;

use Class::Easy;

use XML::LibXML ();

our $VERSION = '1.19'; # avoid locale issues by stringified version

require XSLoader;
XSLoader::load ('Data::Dump::XML', $VERSION);

our $defaults = {
	# xml configuration
	encoding            => 'utf-8',
	dtd_location        => '',
	namespace           => {},
	
	# xml tree namespace
	dump_config         => 1,
	root_name           => 'data',
	hash_element        => 'key',
	array_element       => 'item',
	ref_element         => 'ref',
	empty_array         => 'empty-array',
	empty_hash          => 'empty-hash',
	undef               => 'undef',
	key_as_hash_element => 1,
	hash_element_attribute_name => '_name',
	at_key_as_attribute => 1,
	
	# options
	sort_keys           => 0,
	granted_restore     => 1,
	ignore_bless        => 0,
	
	# internal structure
	doc_object          => undef,
	references          => {},
	ref_count           => 0,
	used                => {},
};

1;
############################################################
sub new {
	my $class   = shift;
	my $params  = {@_};
	
	my $config = {%$defaults};
	
	foreach my $key (keys %$params) {
		if (exists $config->{$key}) {
			$config->{$key} = $params->{$key};
		}
	}

	if (exists $config->{'@key_as_attribute'}) {
		$config->{at_key_as_attribute} = delete $config->{'@key_as_attribute'};
	}
	
	bless $config, $class;
	
	return $config;
}
############################################################
sub dump_xml {
	my $self = shift;

	my $structure;
	my $root;

	my $dom = XML::LibXML->createDocument ('1.0', $self->{encoding});
	$self->{doc_object} = $dom;
	
	
	if ($self->{dtd_location} ne '') { 
		$dom->createInternalSubset ('data', undef, $self->{dtd_location});
	}
		
	$root = $dom->createElement ($self->{root_name});
	$dom->setDocumentElement ($root);


	if ((scalar @_) == 1) {
		$structure = shift;

		if (blessed ($structure) and $structure->can ('TO_XML')) {
			$root->setAttribute (_class => blessed ($structure));
			$structure = $structure->TO_XML;
			$root->setAttribute (_to_xml => 1);
		}

	} else {
		$structure = \@_;
	}
	
	
	# dump config options if any
	foreach (qw(ref_element hash_element array_element empty_array empty_hash undef key_as_hash_element at_key_as_attribute)) {
		$root->setAttribute ("_$_", $self->{$_})
			if $self->{$_} ne $defaults->{$_};
	}
	
	if (scalar keys %{$self->{namespace}}) {
		foreach my $key (keys %{$self->{namespace}}) {
			$root->setAttribute ($key, $self->{namespace}->{$key});
			#debug "add '$key' namespace";
		}
	}
	
	$self->{references} = {};
	$self->{ref_count} = 0;
	$self->{used} = {};
	
	# $self->analyze ($structure);
	
	#my $refs = $self->{'references'};
	#
	#foreach (keys %$refs)
	#{
	#	delete $refs->{$_} unless ($refs->{$_});
	#}
	
	$self->simple_dump ($structure);
	
	return $self->{doc_object};
	
}
############################################################
sub simple_dump {
	my $self  = shift;
	my $rval  = \$_[0]; shift;
	
	my $dom   = $self->{doc_object};

	my $tag   = shift || $dom->documentElement;
	my $deref = shift;

	$rval = $$rval if $deref;
	
	my $ref_element   = $self->{ref_element};
	my $array_element = $self->{array_element};
	my $hash_element  = $self->{hash_element};
	my $empty_array   = $self->{empty_array};
	my $undef         = $self->{undef};
	my $empty_hash    = $self->{empty_hash};
	
	my ($class, $type, $id) = (
		blessed ($rval),
		reftype ($rval),
		refaddr ($rval)
	);
	
	if (defined $class) {
		if ($class eq 'XML::LibXML::Element') {
			
			if ($rval->localname eq 'include' and (
				$rval->lookupNamespacePrefix ('http://www.w3.org/2003/XInclude')
				or $rval->lookupNamespacePrefix ('http://www.w3.org/2001/XInclude')
			)) {
				#my $node = $tag->addNewChild ('', 'include');
				#$node->setNamespace ('http://www.w3.org/2003/XInclude', 'xi');
				#$node->setAttribute ('href', $rval->getAttribute ('href'));
				
				my $parser = XML::LibXML->new;
				$parser->expand_xinclude(0); # we try this later
				$parser->load_ext_dtd(0);
				$parser->expand_entities(0);
				
				my $include;
				eval {
					$include = $parser->parse_file ($rval->getAttribute ('href'));
				};
				#my $xinclude_result;
				#eval {$xinclude_result = $parser->process_xincludes ($include);};

				#debug "XInclude processing result is: $xinclude_result, error is: $@";
				
				$tag->addChild ($include->documentElement)
					if not $@ and defined $include;
			
			} else {
				$tag->addChild ($rval);
			}
			
			return;
		} elsif ($class ne '') {
			
			$tag->setAttribute (_class => $class);
			
			if ($rval->can ('TO_XML')) {
				$rval = $rval->TO_XML;
				$tag->setAttribute (_to_xml => 1);
				($class, $type, $id) = (
					blessed ($rval),
					reftype ($rval),
					refaddr ($rval)
				);
			}
			

		}
	}
	
	#if (my $ref_no = $self->refs ($id)) {
	#	if (defined $self->{'used'}->{$id}
	#		and $self->{'used'}->{$id} eq 'yea'
	#	) {
	#	  
	#		my $node = $tag->addNewChild ('', $ref_element);
	#		$node->setAttribute ('to', $ref_no);
	#		return;
	#	
	#	} else {
	#		
	#		$tag->setAttribute ('id', $ref_no);
	#		$self->{'used'}->{$id} = 'yea';
	#	
	#	}
	#}
	
	if ($type eq "SCALAR" || $type eq "REF"){
		
		my $rval_ref = ref $$rval;
		
		if ($rval_ref) {
		
			if (($rval_ref eq 'SCALAR') or ($rval_ref eq 'REF')) {
			
				my $node = $tag->addNewChild ('', $ref_element);
				return $self->simple_dump ($$rval, $node, 1);
			}
	  
			return $self->simple_dump ($$rval, $tag, 1);
		
		} elsif (
			not defined $$rval and defined $rval 
			and defined $class and $class ne ''
		) {
			# regexp. 100% ?
			# debug "has undefined deref '$$rval' and defined '$rval'";
			$tag->addNewChild ('', $rval);
		
		} elsif (not defined $$rval) {
		
			$tag->addNewChild ('', $self->{undef});
		
		} else {	
		
			$tag->appendText ($$rval);
		
		}
		
		#debug $rval, $$rval, ref $rval, ref $$rval;
		
		return;
	} elsif ($type eq "ARRAY") {
		my @array;
		
		unless (scalar @$rval){
			$tag->addNewChild ('', $self->{empty_array});
			return;
		}
		
		my $level_up = 0;
		my $option_attr = $tag->getAttribute ('_opt');
		if (defined $option_attr and $option_attr eq 'up') {
			$level_up = 1;
		}
		
		my $idx = 0;
		my $tag_name = $tag->nodeName;
		# debug "tag mane is : $tag_name, level up is : $level_up";
		
		foreach (@$rval) {
			my $node;
			if ($level_up) {
				if ($idx) {
					$node = $tag->parentNode->addNewChild ('', $tag_name);
				} else {
					$node = $tag;
					$tag->removeAttribute ('_opt');
				}
				# $tag->setAttribute ('idx', $idx);
			} else {
				$node = $tag->addNewChild ('', $array_element);
			}
			
			$idx++;
			$self->simple_dump ($_, $node);
		}
		
		return;
	} elsif ($type eq "HASH") {
		
		my @keys = keys %$rval;
		
		unless (scalar @keys) {
			$tag->addNewChild ('', $self->{empty_hash});
			return;
		}
			
		@keys = sort @keys
			if $self->{sort_keys};
		
		#$self->dump_hashref ($rval, \@keys, $tag);
		$self->dump_hashref_pp ($rval, \@keys, $tag);
		
		return;
	
	} elsif ($type eq "GLOB") {

		$tag->addNewChild ('', 'glob');
		return;

	} elsif ($type eq "CODE") {

		$tag->addNewChild ('', 'code');
		return;

	} else {
		my $comment = $dom->createComment ("unknown type: '$type'");
		$tag->addChild ($comment);
		return;
	}
	
	die "Assert";
}
############################################################
sub key_info_pp {
	my $self = shift;
	my ($rval, $key, $val_ref) = @_;
	
	my $key_prefix = substr $key, 0, 1;
	my $key_name   = substr $key, 1;
	
	if ($key_prefix ne '@' and $key_prefix ne '#' and $key_prefix ne '<') {
		$key_name = $key;
	}
	
	my $val_type = reftype ($val_ref);
	
	# [4]   	NameStartChar	   ::=   	":" | [A-Z] | "_" | [a-z] | [#xC0-#xD6] | [#xD8-#xF6] | [#xF8-#x2FF] | [#x370-#x37D] | [#x37F-#x1FFF] | [#x200C-#x200D] | [#x2070-#x218F] | [#x2C00-#x2FEF] | [#x3001-#xD7FF] | [#xF900-#xFDCF] | [#xFDF0-#xFFFD] | [#x10000-#xEFFFF]
	# [4a]   	NameChar	   ::=   	NameStartChar | "-" | "." | [0-9] | #xB7 | [#x0300-#x036F] | [#x203F-#x2040]
	my $key_can_be_tag = $key_name =~ /^[a-zA-Z\:\_][\w\d\_\-\:\.]$/;
	
	return ($key_prefix, $key_name, $val_type, $key_can_be_tag);
	
}
############################################################
sub dump_hashref_pp {
	my $self = shift;
	my ($rval, $keys, $tag) = @_;
	
	foreach my $key (@$keys) {
		
		my $val = \$rval->{$key};
		my $node;

		my ($key_prefix, $key_name, $val_type, $key_can_be_tag) =
			$self->key_info ($rval, $key, $$val);
		
		if ($key_can_be_tag) {
			if (defined $key_prefix and $key_prefix eq '@' and $self->{at_key_as_attribute}) {
				# TODO: make something with values other than scalar ref
				
				unless (defined $val_type) {
					$tag->setAttribute ($key_name, $$val);
					next;
				}
				
			} elsif (defined $key_prefix and $key_prefix eq '#' and $key_name eq 'text') {
				unless (defined $val_type) {
					$tag->appendText ($$val);
					next;
				}
			} elsif (
				$self->{key_as_hash_element}
				and $key ne $self->{array_element} # for RSS
				and $key ne $self->{hash_element}
				and $key ne $self->{ref_element}
				and $key ne $self->{empty_array}
				and $key ne $self->{empty_hash}
				and $key ne $self->{undef}
			) {
				$node = $tag->addNewChild ('', $key_name);
				if (defined $key_prefix and $key_prefix eq '<') {
					$node->setAttribute (_opt => 'up');
				}
			}
		} else {
			$node = $tag->addNewChild ('', $self->{hash_element});
			$node->setAttribute ($self->{hash_element_attribute_name}, $key);
		}
		
		$self->simple_dump ($$val, $node);
	}
	
}

############################################################
__END__

=head1 NAME

Data::Dump::XML - Dump arbitrary data structures
as XML::LibXML object

=head1 SYNOPSIS

 use Data::Dump::XML;
 my $dumper = Data::Dump::XML->new;
 $xml = $dumper->dump_xml (@list);

=head1 PROJECT

Project source code and repository available on L<http://sourceforge.net/projects/web-app>.

=head1 DESCRIPTION

This module completely rewritten from Gisle Aas
C<Data::DumpXML> to manage perl structures in XML using
interface to gnome libxml2 (package XML::LibXML).
Module provides a single method called dump_xml
that takes a list of Perl values as its argument.
Returned is an C<XML::LibXML::Document> object that represents
any Perl data structures passed to the function. Reference
loops are handled correctly.

Compatibility with Data::DumpXML is absent.

As an example of the XML documents produced, the following
call:

  $a = bless {a => 1, b => {c => [1,2]}}, "Foo";
  $dumper->dump_xml($a)->toString (1);

produces:

  <?xml version="1.0" encoding="utf-8"?>
  <data _class="Foo">
  	<a>1</a>
  	<b>
  		<c>
			<item>1</item>
			<item>2</item>
		</c>
	</b>
  </data>

Comparing to Data::DumpXML this module generates noticeably
more simple XML tree, based on assumption that links in perl
can be defined in implicit way, i.e.:
explicit: $a->{b}->{c}->[1];
implicit: $a->{b} {c} [1];

And make possible similar xpath expressions:
/data/b/c/*[count (preceding-sibling) = 1]

C<Data::Dump::XML::Parser> is a class that can restore
data structures dumped by dump_xml().


=head2 Configuration variables

The generated XML is influenced by a set of configuration
variables. If you modify them, then it is a good idea to
localize the effect. For example:

	my $dumper = new Data::Dump::XML {
		# xml configuration
		'encoding'            => 'utf-8',
		'dtd-location'        => '',
		'namespace'           => {},

		# xml tree namespace
		'dump-config'         => 1,
		'root-name'           => 'data',
		'hash-element'        => 'key',
		'array-element'       => 'item',
		'ref-element'         => 'ref',
		'empty-array'         => 'empty-array',
		'empty-hash'          => 'empty-hash',
		'undef'               => 'undef',
		'key-as-hash-element' => 1,
		'@key-as-attribute'   => 1,

		# options
		'sort-keys'           => 0,
		'granted-restore'     => 1,
	}

Data::DumpXML is function-oriented, but this module is rewritten
to be object-oriented, thus configuration parameters are passed
as hash into constructor.

The variables are:

=over

=item encoding

Encoding of produced document. Default - 'utf-8'.

=item dtd-location

This variable contains the location of the DTD.  If this
variable is non-empty, then a <!DOCTYPE ...> is included
in the output.  The default is "". Usable with
L<key-as-hash-element> parameter.

=item namespace

This hash contains the namespace used for the XML elements.
Default: disabled use of namespaces.

Namespaces provides as full attribute name and location. 
Example:

	...
	'namespace' => {
		'xmlns:xsl' => 'http://www.w3.org/1999/XSL/Transform',
		'xmlns:xi'  => 'http://www.w3.org/2001/XInclude',
	}
	...

=item root-name

This parameter define name for xml root element.

=item hash-element, array-element ref-element

This parameters provides names for hash, array items and
references.

Defaults:

	...
	'hash-element'  => 'key',
	'array-element' => 'item',
	'ref-element'   => 'ref',
	...

=item key-as-hash-element

When this parameter is set, then each hash key,
correspondending regexp /^(?:[^\d\W]|:)[\w:-]*$/ dumped as:

	<$keyname>$keyvalue</$keyname>

	instead of 

	<$hashelement name="$keyname">$keyvalue</$hashelement>

=item @key-as-attribute

TODO

=item granted_restore

TODO

=back

=head2 XML::LibXML Features

When dumping XML::LibXML::Element objects, it added by
childs to current place in document tree. 

=head1 BUGS

The content of globs and subroutines are not dumped.  They are
restored as the strings "** glob **" and "** code **".

LVALUE and IO objects are not dumped at all.  They simply
disappear from the restored data structure.

=head1 SEE ALSO

L<Data::DumpXML>, L<XML::Parser>, L<XML::Dumper>, L<Data::Dump>, L<XML::Dump>

=head1 AUTHORS

The C<Data::Dump::XML> module is written by
Ivan Baktsheev <dot.and.thing@gmail.com>, based on C<Data::DumpXML>.

The C<Data::Dump> module was written by Gisle Aas, based on
C<Data::Dumper> by Gurusamy Sarathy <gsar@umich.edu>.

	Copyright 2003-2009 Ivan Baktcheev.
	Copyright 1998-2003 Gisle Aas.
	Copyright 1996-1998 Gurusamy Sarathy.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

L<http://perlhug.com>

=cut
