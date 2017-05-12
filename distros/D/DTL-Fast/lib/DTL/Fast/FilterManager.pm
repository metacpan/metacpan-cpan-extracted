package DTL::Fast::FilterManager;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Replacer';

use DTL::Fast::Template;
use Scalar::Util qw(weaken);

sub new
{
    my( $proto, %kwargs ) = @_;
    
    $proto = ref $proto || $proto;
    
    my $self = $proto->SUPER::new(
        'filters' => [],
        'filters_number' => 0,
        'replacement' => $kwargs{'replacement'},    # if strings were back-uped before
    );
    
    if( $self->{'replacement'} )
    {
        weaken($self->{'replacement'});
    }
    
    if( $kwargs{'filters'} )
    {
        if( ref $kwargs{'filters'} eq 'ARRAY' )
        {
            $self->add_filters($kwargs{'filters'});
        }
        else
        {
            $self->parse_filters($kwargs{'filters'});
        }
    }
    
    return $self;
}

sub filter
{
    my $self = shift;
    my $value = shift;
    my $context = shift;
    
    $self->{'safe'} = 0;
    
    foreach my $filter (@{$self->{'filters'}})
    {
        $value = $filter->filter($self, $value, $context)
            if defined $filter;
    }
    
    return $value;
}

sub parse_filters
{
    my $self = shift;
    my $filter_string = shift;
    
    $filter_string =~ s/(^\s+|\s+$)//gsi;
    return $self->add_filters([split /\s*\|+\s*/x, $filter_string]);
}

sub add_filters
{
    my $self = shift;
    my $filter_names = shift;

    foreach my $filter_name (@$filter_names)
    {
        $self->add_filter($filter_name);
    }
    return $self;
}

sub add_filter
{
    my $self = shift;
    my $filter_name = shift;
  
    my @arguments = split /\s*\:\s*/x, $self->backup_strings($filter_name);
    $filter_name = shift @arguments;

    if( 
        not exists $DTL::Fast::FILTER_HANDLERS{$filter_name} 
        and exists $DTL::Fast::KNOWN_FILTERS{$filter_name}
    )
    {
        require Module::Load;
        Module::Load::load($DTL::Fast::KNOWN_FILTERS{$filter_name});
        $DTL::Fast::LOADED_MODULES{$DTL::Fast::KNOWN_FILTERS{$filter_name}} = time;            
    }

    if( exists $DTL::Fast::FILTER_HANDLERS{$filter_name} )
    {
        my $args = [];
        
        foreach my $argument (@arguments)
        {
            push @$args, $self->get_backup_or_variable($argument) // $argument;
        }
        
        push @{$self->{'filters'}}, $DTL::Fast::FILTER_HANDLERS{$filter_name}->new($args);
        
        $self->{'filters_number'}++;
    }
    else
    {
        warn $self->get_parse_error( "unknown filter $filter_name" );
    }
    
    return $self;
}

1;