package DTL::Fast::Tag::Cycle;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag::Simple';

$DTL::Fast::TAG_HANDLERS{cycle} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;

    $self->{parameter} =~ /^\s*(.+?)\s*(?:as (.+?)\s*(silent)?)?\s*$/;
    @{$self}{'source', 'destination', 'silent', 'sources', 'current_sources'} = ($1 // '', $2 // '', $3 // '', [ ],
        [ ]);
    $self->{sources} = $self->parse_sources($self->{source});

    return $self;
}

#@Override
sub render
{
    my ( $self, $context, $global_safe) = @_;
    my $result = '';

    my $source = $self->get_next_source();
    my $current_value = $source->render($context, $global_safe);

    if (not $self->{silent})
    {
        $result = $current_value;
    }

    if ($self->{destination})
    {
        $context->set( $self->{destination} => $current_value );
    }

    return $result;
}

sub get_next_source
{
    my $self = shift;

    if (not scalar @{$self->{current_sources}})    # populate for current cycle
    {
        push @{$self->{current_sources}}, @{$self->{sources}};
    }

    return shift @{$self->{current_sources}};
}

1;