package DTL::Fast::Tag::Dump;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag::Simple';

$DTL::Fast::TAG_HANDLERS{dump} = __PACKAGE__;

#@Override
sub parse_parameters
{
    my $self = shift;

    die $self->get_parse_error("no variable specified for dumping") unless ($self->{parameter});
    $self->{variables} = $self->parse_sources($self->{parameter});

    return $self;
}

#@Override
sub render
{
    my ($self, $context) = @_;

    require Data::Dumper;
    my @result = ();
    foreach my $variable (@{$self->{variables}})
    {
        push @result,
            Data::Dumper->Dump(
                [ $variable->render($context, 'safe') ],
                [ 'context.'.$variable->{original} ]
            )
        ;
    }

    return join "\n", @result;
}

1;