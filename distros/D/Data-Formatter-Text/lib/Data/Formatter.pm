package Data::Formatter;
use strict;
use warnings;

use Attribute::Abstract;
use Scalar::Util qw(blessed);
use List::MoreUtils qw(all any);

######################################
# Constructor                        #
######################################
sub new
{
    my ($class, $outputHandle) = @_;
    $outputHandle ||= \*STDOUT;
    
    # Maintain a list of handles to output to
    my $self = bless {__OUTPUT_HANDLE => $outputHandle}, $class;
    
    return $self;
}

######################################
# Public Abstract Methods            #
######################################
sub heading: Abstract;
sub emphasized: Abstract;

######################################
# Protected Abstract Methods         #
######################################
sub _text: Abstract;
sub _heading: Abstract;
sub _emphasized: Abstract;
sub _table: Abstract;
sub _unorderedList: Abstract;
sub _orderedList: Abstract;
sub _definitionList: Abstract;

######################################
# Public Methods                     #
######################################
sub out
{
    my ($self, @args) = @_;
    
    foreach my $arg (@args)
    {
        $self->_write(join("\n", $self->_format($arg)) . "\n");
    }
}

sub format
{
    my ($self, @args) = @_;

    return join("\n", map { $self->_format($_) } @args) . "\n";
}

######################################
# Protected Methods                  #
######################################
sub _paragraph
{
   my ($self, $arg) = @_;
   
   return map { $self->_format($_) } (@{$arg});
}

sub _getStructType
{
    my ($self, $arg) = @_;
   
    # Plain text or blessed item that may have stringification overriden
    if (!ref($arg) || blessed($arg))
    {
        return 'TEXT';
    }
    
    # Container types
    elsif (ref($arg) =~ /ARRAY/ && all {ref($_) && ref($_) =~ /ARRAY/} (@{$arg}))
    {
        return 'TABLE';         
    }
    elsif (ref($arg) =~ /ARRAY/)
    {
        return 'UNORDERED_LIST';
    }
    elsif (ref($arg) =~ /REF/ && ref(${$arg}) =~ /ARRAY/)
    {
        return 'ORDERED_LIST';
    }
    elsif (ref($arg) =~ /REF/ && ref(${$arg}) =~ /REF/ && ref(${${$arg}}) =~ /ARRAY/)
    {
        return 'PARAGRAPH';
    }
    elsif (ref($arg) =~ /HASH/ && !any {ref($_)} (keys %{$arg}))
    {
        return 'DEFINITION_LIST';
    }
    
    # Invalid type
    else
    {
        return 'NONE';
    }
}

sub _format
{
    my ($self, $arg, %options) = @_;
    
    my $type = $self->_getStructType($arg);
    
    for ($type)
    {
        # Textual types
        /TEXT/ && do
        {
            return $self->_text("$arg", %options);
        };
        
        # Container types
        /TABLE/ && do
        {
            return $self->_table($arg, %options);
        };
        /UNORDERED_LIST/ && do
        {
            return $self->_unorderedList($arg, %options);
        };
        /ORDERED_LIST/ && do
        {
            return $self->_orderedList(${$arg}, %options);
        };
        /PARAGRAPH/ && do
        {
            return $self->_paragraph(${${$arg}}, %options);
        };
        /DEFINITION_LIST/ && do
        {
            return $self->_definitionList($arg, %options);
        };

        # Invalid type
        #print "Warning, bad syntax! Type is $type\n";
    }
    
    return ();
}

1;
