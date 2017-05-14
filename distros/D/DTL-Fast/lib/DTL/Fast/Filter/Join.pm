package DTL::Fast::Filter::Join;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{join} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my ( $self ) = @_;

    die $self->get_parse_error("no separator passed to the join filter")
        if (
            ref $self->{parameter} ne 'ARRAY'
                or not scalar @{$self->{parameter}}
        );

    $self->{sep} = $self->{parameter}->[0];

    return $self;
}

#@Override
sub filter
{
    my ( $self, $filter_manager, $value, $context ) = @_;

    my $value_type = ref $value;
    my $result = undef;
    my $separator = $self->{sep}->render($context, 1);

    my @source = ();
    if ($value_type eq 'HASH')
    {
        @source = (%$value);
    }
    elsif ($value_type eq 'ARRAY')
    {
        @source = @$value;
    }
    else
    {
        die $self->get_render_error(
                $context,
                sprintf( "Unable to apply join filter to the %s value"
                    , $value_type || 'SCALAR'
                )
            );
    }

    if ($filter_manager->{safeseq})
    {
        $separator = DTL::Fast::html_protect($separator)
            if (not $context->{ns}->[- 1]->{_dtl_safe});

        $filter_manager->{safe} = 1;
    }

    return join $separator, @source;
}

1;