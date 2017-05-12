package DTL::Fast::Context;
use strict; use utf8; use warnings FATAL => 'all';

use Scalar::Util qw(reftype blessed);

sub new
{
    my( $proto, $context ) = @_;
    $context //= {};

    die  "Context should be a HASH reference"
        if ref $context ne 'HASH';

    return bless {
        'ns' => [$context]
    }, $proto;
}

sub get
{
    my( $self, $variable_path, $source_object ) = @_;

    if( ref $variable_path ne 'ARRAY' )    # suppose that raw variable invoked, period separated
    {
        $variable_path = [split /\.+/x, $variable_path];
    }
    else
    {
        $variable_path = [@$variable_path]; # cloning for re-use
    }

    my $variable_name = shift @$variable_path;

    # faster version
    my $namespace = $self->{'ns'}->[-1];
    my $variable = exists $namespace->{$variable_name} ?
        $namespace->{$variable_name}
        : undef;

    while( ref $variable eq 'CODE' )
    {
        $variable = $variable->();
    }

    $variable = $self->traverse($variable, $variable_path, $source_object)
        if
            defined $variable
            and scalar @$variable_path;

    return $variable;
}

# tracing variable path
sub traverse
{
    my( $self, $variable, $path, $source_object ) = @_;

    my $variable_original = $variable;
    
    foreach my $step (@$path)
    {
        my $current_type = reftype $variable;
        if(
            blessed($variable)
            and $variable->can($step) )
        {
            $variable = $variable->$step();
        }
        elsif( not defined $current_type )
        {
            die $self->get_error(
                $source_object
                , sprintf( "non-reference value encountered on step `%s` while traversing context path", $step // 'undef' )
                , 'Traversing path' => join( '.', @$path )
                , 'Traversed variable' => $self->dump_with_indent($variable_original)
            );
        }
        elsif( $current_type eq 'HASH' )
        {
            $variable = $variable->{$step};
        }
        elsif(
            $current_type eq 'ARRAY'
            and $step =~ /^\-?\d+$/x
        )
        {
            $variable = $variable->[$step];
        }
        else
        {
            die $self->get_error(
                $source_object
                , sprintf(
                    "don't know how continue traversing %s (%s) with step `%s`"
                    , ref $variable || 'SCALAR'
                    , reftype $variable // 'not blessed'
                    , $step // 'undef'
                )
                , 'Traversing path' => join( '.', @$path )
                , 'Traversable variable' => $self->dump_with_indent($variable_original)
            );
        }
    }

    while( ref $variable eq 'CODE' )
    {
        $variable = $variable->();
    }

    return $variable;
}

sub dump_with_indent
{
    my ($self, $object ) = @_;
    require Data::Dumper;
    my $result = Data::Dumper->Dump([$object]);
#    $result =~ s/^/                        /mg; # now done in Entity::compile_error_messages
    return $result;
}

sub set
{
    my( $self, @sets ) = @_;

    while( scalar @sets > 1 )
    {
        my $key = shift @sets;
        my $val = shift @sets;
        if( $key =~ /\./x )  # traversed set
        {
            my @key = split /\.+/x, $key;
            my $variable_name = pop @key;
            my $variable = $self->get([@key]);

            die  sprintf('Unable to set variable %s because parent %s is not defined.'
                , $key // 'undef'
                , join('.', @key) // 'undef'
            ) if not defined $variable;

            my $variable_type = ref $variable;
            if( $variable_type eq 'HASH' )
            {
                $variable->{$variable_name} = $val;
            }
            elsif(
                $variable_type eq 'ARRAY'
                and $variable_name =~ /^\-?\d+$/x
            )
            {
                $variable->[$variable_name] = $val;
            }
            else
            {
                die  sprintf("Don't know how to set variable %s for parent node of type %s"
                    , $variable_name // 'undef'
                    , $variable_type // 'undef'
                );
            }
        }
        else
        {
            $self->{'ns'}->[-1]->{$key} = $val;
        }
    }
    return $self;
}

sub get_error
{
    my ($self, $source_object, $message, @messages) = @_;
    
    my $result;
    if (
        blessed $source_object
        and $source_object->can('get_render_error')
    ){
        $result = $source_object->get_render_error(
            $self
            , $message
            , @messages
        );
    } else {
        $result = sprintf <<'_EOT_'
Rendering error: %s
%s
_EOT_
            , $message
            , join '', @messages
            ;
    }
    return $result;
}

sub push_scope
{
    my( $self ) = @_;
    push @{$self->{'ns'}}, {%{$self->{'ns'}->[-1] // {}}};
    return $self;
}

sub pop_scope
{
    my( $self ) = @_;
    die  "It's a last context layer available."
        if scalar @{$self->{'ns'}} ==  1;
    pop @{$self->{'ns'}};
    return $self;
}

1;
