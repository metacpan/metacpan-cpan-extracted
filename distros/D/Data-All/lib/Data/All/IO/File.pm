package Data::All::IO::File;


use strict;
use warnings;

use Data::Dumper;
use Data::All::IO::Base;
use IO::File;
use FileHandle;


our $VERSION = 0.11;

internal 'IO';
internal 'fh';

attribute 'format';
attribute 'fields';
attribute 'ioconf';
attribute   'path';

attribute 'is_open'             => 0;

internal 'FORMAT';
internal 'curpos'               => -1;
internal 'added_fields'         => {};


sub create_path()
{
    my $self = shift;
    return join '', @{ $self->path };
}

sub open($)
{
    my $self = shift;
    my $path = $self->create_path();
    
    unless ($self->is_open())
    {
        #warn " -> Opening $path for ", $self->ioconf()->{'perm'};
        #warn " -> path:", join ', ', @{ $self->path() };
        #warn " -> format:", $self->format()->{'type'};
        #warn " -> io:", $self->ioconf->{'type'};
    
        die("The file: $path does not exist")
            if (($self->ioconf()->{'perm'} eq 'r') && !(-f $path));
    
        #   We create out own filehandle for better read/write control
        my $fh = FileHandle->new($self->create_path(), $self->ioconf()->{'perm'});        
        
        $self->__IO( $fh );
        $self->__fh( $fh );
        
        $self->is_open(1);
    
        $self->_extract_fields();             #   Initialize field names
    }
    
    return $self->is_open();
}

sub close()
{
    my $self = shift;
    
	$self->__fh()->close();
	
    $self->__IO()->close();
    $self->is_open(0);
}

sub nextrecord() 
{  
    my $self = shift;
    my $r;
    
    #   TODO: Write an actual solution for converting from
    #   one line terminator to another.

    #   Incrememnt cursor and remove trailing line
    if ($r = $self->__fh()->getline())
    {  
        $r =~ s/\r\n/\n/g;      #   NOTE: a quick hack to convert DOS to UNIX
        chomp($r);  
        $self->_next();
    }
    
    return $r;
}

sub hash_to_record()
{
    my ($self, $hash) = @_;
	
    #   we do it like this to make sure the order is the same
    return $self->array_to_record($self->hash_to_array($hash));
}

sub array_to_record()
{
    my ($self, $array) = @_;
    return $self->__FORMAT()->contract($array);
}



sub getrecord_array() 
#   With original = include original record from file
{ 
    my ($self, $with_original) = @_;
    my $raw;
    
    return undef unless ($raw = $self->nextrecord());
    
    #   We return the original record first b/c if we do it
    #   last and there are empty values at the end the order will be confused
    my $rec_arrayref = ($with_original)
        ? [$raw, $self->__FORMAT()->expand($raw)]
        : [$self->__FORMAT()->expand($raw)];
    
    return !wantarray ? $rec_arrayref : @{ $rec_arrayref };
}
 
sub putfields()
{
    my $self = shift;
    $self->__IO()->print($self->array_to_record($self->fields));
}

sub putrecord($)
{
    my $self = shift;
    my $record = shift;
	
    $self->__IO()->print($self->hash_to_record($record));
    
    return 1;
}


sub _extract_fields()
{
    my $self = shift;
    return if ($self->fields());
    $self->fields([$self->getrecord_array(0)]);
}

sub count()     
{ 
    my $self = shift;
    my $count;
    
    #   From the Perl Cookbook. It doesn't actually replace every
    #   new line with a new new line -- it's a legacy feature. 
    $count += tr/\n/\n/ while sysread($self->__fh(), $_, 2 ** 20);
    
    return $count;
}
sub _next()      { $_[0]->__curpos( $_[0]->__curpos() + 1) }


1;