package DTL::Fast::Tag::Ssi;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Tag::Simple';

$DTL::Fast::TAG_HANDLERS{'ssi'} = __PACKAGE__;

use DTL::Fast::Expression;

#@Override
sub parse_parameters
{
    my $self = shift;
    if( $self->{'parameter'} =~ /^\s*(.+?)(?:\s*(parsed))?\s*$/ )
    {
        @{$self}{'template', 'parsed'} = (
            DTL::Fast::Variable->new($1)
            , $2 
        );
        warn $self->get_parse_warning('`ssi` tag is now depricated and will be removed in future versions. Please, use `include` tag');
    }
    else
    {
        die $self->get_parse_error("can't parse parameter: $self->{'parameter'}");
    }
    
    return $self;
}

#@Override
# @todo: recursion protection
sub render
{
    my ($self, $context, $result) = @_;
    
    my $ssi_dirs = $context->{'ns'}->[-1]->{'_dtl_ssi_dirs'};
    
    if( 
        defined $ssi_dirs
        and ref $ssi_dirs eq 'ARRAY'
        and scalar @$ssi_dirs
    )
    {
        my $template_path = $self->{'template'}->render($context);
        
        my $allowed = 0;
        
        foreach my $allowed_dir (@$ssi_dirs)
        {
            if( $template_path =~ /^\Q$allowed_dir\E/s )
            {
                $allowed = 1; 
                last;
            }
        }

        if( $allowed )
        {
            $result = DTL::Fast::__read_file($template_path);
            
            if( $self->{'parsed'} )
            {
                $result = DTL::Fast::Template->new($result)->render($context);
            }
        }
        else
        {
            die $self-get_render_error(
                $context, 
                sprintf(
                    "File %s is not in one of ssi_dirs:\n\t%s"
                    , $template_path // 'undef'
                    , join( "\n\t", @$ssi_dirs )
                )
            );
        }
    }
    else
    {
        die $self->get_render_error($context, 'in order to use ssi tag, you must provide ssi_dirs argument to the constructor');
    }
    
    return $result;
}

1;