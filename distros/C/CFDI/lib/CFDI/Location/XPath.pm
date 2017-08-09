package CFDI::Location::XPath;
use strict;
use CFDI::Constants::Class;
require Exporter;
our @EXPORT = qw(xpath);
our @ISA = qw(Exporter);
our $VERSION = 0.4;

sub new{
  my $invocant = shift;
  my $class = ref $invocant || $invocant;
  my $content = shift;
  return unless defined $content && ref $content eq CONTENT;
  bless {_current=>'/',_rootRef=>$content,_currentRef=>$content},$class;
}

sub xpath($_){
  return unless $#_ == 1;
  local $_;
  my $self;
  $_[0] && ref $_[0] ? ($self,$_) : ($_,$self) = @_;
  return unless defined && !ref && length;
  return unless defined $self && $self->isa(__PACKAGE__);
  my $abs = ord '/' eq ord;
  substr $_,0,1,'' if $abs;
  my @path = m!([^/]+)!g;
  my $xpath;
  my ($hasAttr,$attr);
  while(@path){
    local $_ = shift @path;
    if(/@/){
      $hasAttr = 1;
      $attr = $1 if /^@(.*)/;
      last;
    }else{
      $xpath .= "/$_";
    }
  }
  return unless $#path == -1;
  return if $hasAttr && !defined $attr;
  @path = $xpath =~ m!([^/]+)!g;
  my ($refPath,$foundPath,$element) = ($$self{_rootRef},'');
  while(@path){
    last unless defined $refPath && ref $refPath eq CONTENT;
    my $elementName = shift @path;
    my @elements = grep ref eq ELEMENT && ${$$_[0]} eq $elementName,@$refPath;
    last unless @elements;
    $element = shift @elements;
    $foundPath .= "/$elementName";
    my @contents = grep ref eq CONTENT,@$element;
    last unless @contents;
    $refPath = shift @contents;
  }
  return unless $#path == -1 && $foundPath eq $xpath;
  if($attr){
    return unless defined $element;
    my @attributes = grep ref eq ATTRIBUTES,@$element;
    return unless @attributes;
    my %attr = @{shift @attributes};
    return $attr{$attr};
  }else{
    return $refPath;
  }
}

1;