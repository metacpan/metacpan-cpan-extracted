package DTL::Fast::Tag::For;
use strict; use utf8; use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag';

$DTL::Fast::TAG_HANDLERS{'for'} = __PACKAGE__;

use DTL::Fast::Variable;
use Scalar::Util qw(blessed reftype);

#@Override
sub get_close_tag{ return 'endfor';}

#@Override
sub parse_parameters
{
    my( $self ) = @_;

    my(@target_names, $source_name, $reversed);
    if( $self->{'parameter'} =~ /^\s*(.+)\s+in\s+(.+?)\s*(reversed)?\s*$/si )
    {
        $source_name = $2;
        $reversed = $3;
        @target_names = map{
            die $self->get_parse_error("iterator variable can't be traversable: $_") if /\./;
            $_;
        } split( /\s*,\s*/, $1 );
    }
    else
    {
        die $self->get_parse_error("do not understand condition: $self->{'parameter'}");
    }

    $self->{'renderers'} = [];
    $self->add_renderer();

    $self->{'targets'} = [@target_names];

    $self->{'source'} = DTL::Fast::Variable->new($source_name);

    if( $reversed )
    {
        $self->{'source'}->add_filter('reverse');
    }

    if( not scalar @{$self->{'targets'}} )
    {
        die $self->get_parse_error("there is no target variables defined for iteration");
    }

    return $self;
}

#@Override
sub add_chunk
{
    my( $self, $chunk ) = @_;

    $self->{'renderers'}->[-1]->add_chunk($chunk);
    return $self;
}

#@Override
sub parse_tag_chunk
{
    my( $self, $tag_name, $tag_param, $chunk_lines ) = @_;

    my $result = undef;

    if( $tag_name eq 'empty' )
    {
        if( scalar @{$self->{'renderers'}} == 2 )
        {
            die $self->get_block_parse_error("there can be only one {% empty %} block, ingoring");
        }
        else
        {
            $self->add_renderer;
        }
        $DTL::Fast::Template::CURRENT_TEMPLATE_LINE += $chunk_lines;
    }
    else
    {
        $result = $self->SUPER::parse_tag_chunk($tag_name, $tag_param, $chunk_lines);
    }

    return $result;
}

#@Override
sub render
{
    my( $self, $context ) = @_;

    my $result = '';

    my $source_data = $self->{'source'}->render($context);
    my $source_ref = ref $source_data;
    my $source_type = reftype $source_data;

    if( # iterating array
        $source_ref eq 'ARRAY'
        or (
            UNIVERSAL::can($source_data, 'as_array')
            and ($source_data = $source_data->as_array($context))
        )
    )
    {
        $result = $self->render_array(
            $context
            , $source_data
        );
    }
    elsif( # iterating hash
        $source_ref eq 'HASH'
        or (
            UNIVERSAL::can($source_data, 'as_hash')
            and ($source_data = $source_data->as_hash($context))
        )
    )
    {
        $result = $self->render_hash(
            $context
            , $source_data
        );
    }
    else
    {
        die sprintf('Do not know how to iterate %s (%s, %s)'
            , $self->{'source'}->{'original'} // 'undef'
            , $source_data // 'undef'
            , $source_ref // 'SCALAR'
        );
    }

    return $result;
}

sub render_array
{
    my( $self, $context, $source_data ) = @_;

    my $result = '';

    if( scalar @$source_data )
    {
        $context->push_scope();

        my $source_size = scalar @$source_data;
        my $forloop = $self->get_forloop($context, $source_size);

        $context->{'ns'}->[-1]->{'forloop'} = $forloop;

        my $variables_number = scalar @{$self->{'targets'}};

        foreach my $value (@$source_data)
        {
            my $value_type = ref $value;
            if( $variables_number == 1 )
            {
                $context->{'ns'}->[-1]->{$self->{'targets'}->[0]} = $value;
            }
            else
            {
                if(
                    $value_type eq 'ARRAY'
                    or (
                        UNIVERSAL::can($value, 'as_array')
                        and ($value = $value->as_array($context))
                    )
                )
                {
                    if( scalar @$value >= $variables_number )
                    {
                        for( my $i = 0; $i < $variables_number; $i++ )
                        {
                            $context->{'ns'}->[-1]->{$self->{'targets'}->[$i]} = $value->[$i];
                        }
                    }
                    else
                    {
                        die sprintf(
                            'Sub-array (%s) contains less items than variables number (%s)'
                            , join(', ', @$value)
                            , join(', ', @{$self->{'targets'}})
                        );
                    }
                }
                else
                {
                    die "Multi-var iteration argument $value ($value_type) is not an ARRAY and has no as_array method";
                }
            }
            $result .= $self->{'renderers'}->[0]->render($context) // '';

            $self->step_forloop($forloop);
        }

        $context->pop_scope();
    }
    elsif( scalar @{$self->{'renderers'}} == 2 ) # there is an empty block
    {
        $result = $self->{'renderers'}->[1]->render($context);
    }

    return $result;
}

sub render_hash
{
    my( $self, $context, $source_data ) = @_;

    my $result = '';

    my @keys = keys %$source_data;
    my $source_size = scalar @keys;
    if( $source_size )
    {
        if( scalar @{$self->{'targets'}} == 2 )
        {
            $context->push_scope();
            my $forloop = $self->get_forloop($context, $source_size);
            $context->{'ns'}->[-1]->{'forloop'} = $forloop;

            foreach my $key (@keys)
            {
                my $val = $source_data->{$key};
                $context->{'ns'}->[-1]->{$self->{'targets'}->[0]} = $key;
                $context->{'ns'}->[-1]->{$self->{'targets'}->[1]} = $val;
                $result .= $self->{'renderers'}->[0]->render($context) // '';

                $self->step_forloop($forloop);
            }

            $context->pop_scope();
        }
        else
        {
            die $self->get_render_error("hash can be only iterated with 2 target variables");
        }
    }
    elsif( scalar @{$self->{'renderers'}} == 2 ) # there is an empty block
    {
        $result = $self->{'renderers'}->[1]->render($context);
    }

    return $result;
}

sub add_renderer
{
    my( $self ) = @_;
    push @{$self->{'renderers'}}, DTL::Fast::Renderer->new();
    return $self;
}

sub get_forloop
{
    my( $self, $context, $source_size ) = @_;

    return {
        'parentloop' => $context->{'ns'}->[-1]->{'forloop'}
        , 'counter' => 1
        , 'counter0' => 0
        , 'revcounter' => $source_size
        , 'revcounter0' => $source_size-1
        , 'first' => 1
        , 'last' => $source_size == 1 ? 1: 0
        , 'length' => $source_size
        , 'odd' => 1
        , 'odd0' => 0
        , 'even' => 0
        , 'even0' => 1
    };
}

sub step_forloop
{
    my( $self, $forloop ) = @_;

    $forloop->{'counter'}++;
    $forloop->{'counter0'}++;
    $forloop->{'revcounter'}--;
    $forloop->{'revcounter0'}--;
    $forloop->{'odd'} = $forloop->{'odd'} ? 0: 1;
    $forloop->{'odd0'} = $forloop->{'odd0'} ? 0: 1;
    $forloop->{'even'} = $forloop->{'even'} ? 0: 1;
    $forloop->{'even0'} = $forloop->{'even0'} ? 0: 1;
    $forloop->{'first'} = 0;
    if( $forloop->{'counter'} == $forloop->{'length'} )
    {
        $forloop->{'last'} = 1;
    }
    return $self;
}

1;
