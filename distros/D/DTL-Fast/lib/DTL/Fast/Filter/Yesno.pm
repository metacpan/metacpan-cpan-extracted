package DTL::Fast::Filter::Yesno;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Filter';

$DTL::Fast::FILTER_HANDLERS{yesno} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;
    push @{$self->{parameter}}, DTL::Fast::Variable->new('"yes,no,maybe"')
        if (not scalar @{$self->{parameter}});
    $self->{mappings} = $self->{parameter}->[0];
    return $self;
}


#@Override
sub filter
{
    my $self = shift;  # self
    shift;  # filter_manager
    my $value = shift;
    my $context = shift;  # context

    my @mappings = split /\s*,\s*/s, $self->{mappings}->render($context);

    return $value ?
        $mappings[0]
                  : defined $value ?
            $mappings[1]
                                   : $mappings[2];
}

1;