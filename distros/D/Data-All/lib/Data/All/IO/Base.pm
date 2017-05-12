package Data::All::IO::Base;

#   Base package for all format modules

#   $Id: Base.pm,v 1.1.1.1 2005/05/10 23:56:20 dmandelbaum Exp $

use strict;
use warnings;


use Data::All::Base;
use Data::All::Format;

our $VERSION = 0.13;

use base 'Exporter';
our @EXPORT = qw(new internal attribute populate error init	_load_format 
				 getrecords putrecords array_to_hash hash_to_array getrecord_hash
				_add_field
	);

#   Interface
sub count();
sub array_to_hash(\@);




sub _add_field()
{
    my ($self, $name) = @_;
    
    return if (defined($self->__added_fields()->{'_ORGINAL'}));
    
    unshift(@{ $self->fields() }, '_ORIGINAL');
    $self->__added_fields()->{'_ORGINAL'}++;
}

sub array_to_hash(\@)
{
    my ($self, $record) = @_;
    my %hash;
    
    $self->_add_field('_ORIGINAL') if ($self->ioconf->{'with_original'});
        
    my @fields = @{ $self->fields() };
    @hash{ @fields } = @{ $record };
    
    return \%hash;
}

sub hash_to_array()
{
    my ($self, $hash) = @_;
    return [@{ $hash }{@{ $self->fields() }}];
}


sub getrecord_hash()
{
    my $self = shift;
    my $rec = $self->getrecord_array($self->ioconf->{'with_original'});

    return ($rec)
        ?  $self->array_to_hash($rec)
        : undef;
}

sub getrecords(;$$)
{
    my $self = shift;
    #   TODO:   Enable running COUNT records only

    my (@records);
    
    #warn ' -> using fields:', join(',', @{ $self->fields });
    
    while (my $record = $self->getrecord_hash())
    { 
        push(@records, $record);
    }
    
    return wantarray ? @records : \@records;
}



sub putrecords()
{
    my $self = shift;
    my ($records, $options) = @_;

    my $start = 0;
    my $count = $#{ $records }+1;

    die("$self->putrecords() needs records") unless ($#{ $records }+1);
        
    #warn "Writing $count records from $start";
    
    my $record;
    while ($count--)
    {
        $self->putrecord($records->[ $start++ ], $options);
    }
}


sub _load_format()
{
    my $self = shift;
    my $format = shift || $self->format();
    
    return Data::All::Format->new($format->{'type'}, $format);
}


sub init()
#   Called in Data::All::IO::new
#   TODO: Create Format::Hash
{
    my ($self, $args) = @_;
    use Data::Dumper;
	
    populate $self => $args;
	
    $self->__FORMAT($self->_load_format())  
        #   Override the loading of a Format reader for Hash types
        unless ($self->ioconf()->{'type'} eq 'db');
    
    return $self;
}


1;

