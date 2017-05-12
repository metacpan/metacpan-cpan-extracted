package AI::Categorizer::Document::XML;

use strict;
use AI::Categorizer::Document;
use base qw(AI::Categorizer::Document);
use XML::SAX;

__PACKAGE__->contained_objects
  (
   xml_handler => 'AI::Categorizer::Document::XML::Handler',
  );

### Constructors

sub parse {
  my ($self, %args) = @_;

  # it is a string which contains the content of XML
  my $body= $args{content};			

  # it is a hash which includes a pair of <elementName, weight>
  my $elementWeight= $args{elementWeight};	

  # construct Handler which receive event of element, data, comment, processing_instruction
  # And convert their values into a sequence  of string and save it into buffer
  my $xmlHandler = $self->create_contained_object('xml_handler', weights => $elementWeight);

  # construct parser
  my $xmlParser= XML::SAX::ParserFactory->parser(Handler => $xmlHandler);

  # let's start parsing XML, where the methids of Handler will be called
  $xmlParser->parse_string($body);

  # extract the converted string from Handler
  $body= $xmlHandler->getContent;

  # Now, construct Document Object and return it
  return { body => $body };
}

##########################################################################
package AI::Categorizer::Document::XML::Handler;
use strict;
use base qw(XML::SAX::Base);

# Input: a hash which is weights of elements
# Output: object of this class
# Description: this is constructor
sub new{
  my ($class, %args) = @_;

  # call super class such as XML::SAX::Base
  my $self = $class->SUPER::new;

  # save weights of elements which is a hash for pairs <elementName, weight>
  # weight is times duplication of corresponding element
  # It is provided by caller(one of parameters) at construction, and
  # we must save it in order to use doing duplication at end_element
  $self->{weightHash} = $args{weights};

  # It is storage to store the data produced by Text, CDataSection and etc.
  $self->{content} = '';

  # This array is used to store the data for every element from root to the current visiting element.
  # Thus, data of 0~($levelPointer-1)th in the array is only valid.
  # The array which store the starting location(index) of the content for an element, 
  # From it, we can know all the data produced by an element at the end_element
  # It is needed at the duplication of the data produced by the specific element
  $self->{locationArray} = [];

  return $self;
}
	
# Input: None
# Output: None
# Description:
# 	it is called whenever the parser meets the document
# 	it will be called at once
#	Currently, confirm if the content buffer is an empty
sub start_document{
  my ($self, $doc)= @_;

  # The level(depth) of the last called element in XML tree
  # Calling of start_element is the preorder of the tree traversal.
  # The level is the level of current visiting element in tree.
  # the first element is 0-level
  $self->{levelPointer} = 0;

  # all data will be saved into here, initially, it is an empty
  $self->{content} = "";

  #$self->SUPER::start_document($doc);
}

# Input: None
# Output: None
# Description:
# 	it is called whenever the parser ends the document
# 	it will be called at once
#	Nothing to do
sub end_document{
  my ($self, $doc)= @_;

  #$self->SUPER::end_document($doc);
}

# Input
#	LocalName: 	$el->{LocalName}
#	NamespaceURI: 	$el->{NamespaceURI}
#	Name		$el->{Name}
#	Prefix		$el->{Prefix}
#	Attributes	$el->{Attributes}
#	for each attribute
#		LocalName: 	$el->{LocalName}
#		NamespaceURI: 	$el->{NamespaceURI}
#		Name		$el->{Name}
#		Prefix		$el->{Prefix}
#		Value		$el->{Value}
# Output: None
# Description:
# 	it is called whenever the parser meets the element
sub start_element{
  my ($self, $el)= @_;

  # find the last location of the content
  # its meaning is to append the new data at this location
  my $location= length $self->{content};

  # save the last location of the current content
  # so that at end_element the starting location of data of this element can be known
  $self->{locationArray}[$self->{levelPointer}] = $location;

  # for the next element, increase levelPointer
  $self->{levelPointer}++;

  #$self->SUPER::start_document($el);
}

# Input: None
# Output: None
# Description:
# 	it is called whenever the parser ends the element
sub end_element{
  my ($self, $el)= @_;

  $self->{levelPointer}--;
  my $location= $self->{locationArray}[$self->{levelPointer}];

  # find the name of element
  my $elementName= $el->{Name};

  # set the default weight
  my $weight= 1;

  # check if user give the weight to duplicate data
  $weight= $self->{weightHash}{$elementName} if exists $self->{weightHash}{$elementName};

  # 0 - remove all the data to be related to this element
  if($weight == 0){
    $self->{content} = substr($self->{content}, 0, $location);
    return;
  }

  # 1 - dont duplicate
  if($weight == 1){
    return;
  }
  
  # n - duplicate data by n times
  # get new content
  my $newContent= substr($self->{content}, $location);

  # start to copy
  for(my $i=1; $i<$weight;$i++){
    $self->{content} .= $newContent;
  }

  #$self->SUPER::end_document($el);
}

# Input: a hash which consists of pair <Data, Value>
# Output: None
# Description:
# 	it is called whenever the parser meets the text which comes from Text, CDataSection and etc
#	Value must be saved into content buffer.
sub characters{
  my ($self, $args)= @_;

  # save "data plus new line" into content
  $self->{content} .= "$args->{Data}\n";
}
	
# Input: a hash which consists of pair <Data, Value>
# Output: None
# Description:
# 	it is called whenever the parser meets the comment
#	Currently, it will be ignored
sub comment{
  my ($self, $args)= @_;
}

# Input: a hash which consists of pair <Data, Value> and <Target, Value>
# Output: None
# Description:
# 	it is called whenever the parser meets the processing_instructing
#	Currently, it will be ignored
sub processing_instruction{
  my ($self, $args)= @_;
}

# Input: None
# Output: the converted data, that is, content
# Description:
# 	return the content
sub getContent{
  my ($self)= @_;
  return $self->{content};
}

1;
__END__
