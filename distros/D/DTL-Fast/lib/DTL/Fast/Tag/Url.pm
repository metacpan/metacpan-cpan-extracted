package DTL::Fast::Tag::Url;
use strict; use utf8; use warnings FATAL => 'all'; 
use parent 'DTL::Fast::Tag::Simple';

$DTL::Fast::TAG_HANDLERS{'url'} = __PACKAGE__;

use DTL::Fast::Utils;

#@Override
sub parse_parameters
{
    my( $self ) = @_;

    if( $self->{'parameter'} =~ /^\s*(.+?)(?:\s+as\s+([^\s]+))?\s*$/s )
    {
        $self->{'target_name'} = $2;
        my @params = split /\s+/, $self->backup_strings($1);
        
        $self->{'model_path'} = $self->get_backup_or_variable(shift @params);
        if( scalar @params )
        {
            if( $params[0] =~ /\=/ )
            {
                $self->parse_named_parameters(\@params);
            }
            else
            {
                $self->parse_positional_parameters(\@params);
            }
        }
    }
    else
    {
        die $self->get_parse_error("unable to parse url parameters: $self->{'parameter'}");
    }
    
    return $self;
}

#@Override
sub render
{
    my( $self, $context ) = @_;
    
    my $result = '';
    
    my $url_source = $context->{'ns'}->[-1]->{'_dtl_url_source'};
    
    if( 
        defined $url_source
        and ref $url_source eq 'CODE'
    )
    {
        my $model_path = $self->{'model_path'}->render($context);
        my $arguments = $self->render_arguments($context);
        my $url_template = $url_source->($model_path, $arguments);
        
        if( $url_template )
        {
            $result = $self->restore_url($url_template, $arguments);
        }
        else
        {
            die $self->get_render_error("url source returned false value by model path: $model_path");
        }
    }
    else
    {
        die $self->get_render_error("in order to render url's you must provide `url_source` argument to the template constructor");
    }
    
    return $result;
}

sub restore_url
{
    my( $self, $template, $arguments ) = @_;
    
    if( ref $arguments eq 'ARRAY' )
    {
        my $replacer = sub{
            return DTL::Fast::Utils::escape((shift @$arguments) // '');
        };
        $template =~ s/
            \(
                [^)(]+
            \)
            \??
        /$replacer->()/xge; # @todo: this one is dumb, need improve
    }
    else # MUST be a hash
    {        
        my $replacer =  sub{    
            my( $key ) = @_;
            return DTL::Fast::Utils::escape($arguments->{$key});
        };
        $template =~ s/
            \(\?<(.+?)>
                [^)(]+
            \)
            \??
        /$replacer->($1)/xge; # @todo: this one is dumb, need improve
    }
     
    # removing regexp remains
    $template =~ s/(
        ^\^
        |\$$
        |\(\?\:
        |\(
        |\)
    )//xgs;
    
    return '/'.$template;
}


sub render_arguments
{
    my( $self, $context ) = @_;
    
    my $result = [];

    if( $self->{'arguments'} )
    {
        if( ref $self->{'arguments'} eq 'ARRAY' )
        {
            $result = [];
            
            foreach my $argument (@{$self->{'arguments'}})
            {
                push @$result, $argument->render($context);
            }
        }
        else    # MUST be a HASH
        {
            $result = {};
            foreach my $key (keys( %{$self->{'arguments'}}))
            {
                $result->{$key} = $self->{'arguments'}->{$key}->render($context);
            }
        }
    }
    
    return $result;
}

sub parse_named_parameters
{
    my( $self, $params ) = @_;
    
    my $result = {};
    foreach my $param (@$params)
    {
        if( $param =~ /^(.+)\=(.+)$/ )
        {
            $result->{$1} = $self->get_backup_or_variable($2);
        }
        else
        {
            die $self->get_parse_error("you can't mix positional and named arguments in url tag: $self->{'parameter'}");
        }
    }
    $self->{'arguments'} = $result;
    return $self;
}

sub parse_positional_parameters
{
    my( $self, $params ) = @_;
    
    my $result = [];
    foreach my $param (@$params)
    {
        die $self->get_parse_error("you can't mix positional and named arguments in url tag: $self->{'parameter'}")
            if $param =~ /\=/;
            
        push @$result, $self->get_backup_or_variable($param);
    }
    $self->{'arguments'} = $result;
    return $self;
}

1;