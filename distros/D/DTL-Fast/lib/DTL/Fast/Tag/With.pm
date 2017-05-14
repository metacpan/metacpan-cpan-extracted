package DTL::Fast::Tag::With;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Tag';

$DTL::Fast::TAG_HANDLERS{with} = __PACKAGE__;

#@Override
sub get_close_tag {return 'endwith';}

#@Override
sub parse_parameters
{
    my $self = shift;

    $self->{mappings} = { };
    if ($self->{parameter} =~ /^\s*(.+?)\s+as\s+(.+)\s*$/s)  # legacy
    {
        $self->{mappings}->{$2} = DTL::Fast::Expression->new($1);
    }
    else    # modern
    {
        my @parts = ();
        my $string = $self->backup_strings($self->{parameter});

        while ( $string =~ s{^
            \s*
            ([^\s\=]+)
            \s*\=\s*
            ([^\s\=]+)
            \s*
            }{}x
        )
        {
            $self->{mappings}->{$1} = $self->get_backup_or_variable($2);
        }

        if ($string) {
            die $self->get_parse_error(
                    "there is an error in `with` parameters"
                    , 'Passed parameters' => $self->{parameter}
                );
        }
    }

    return $self;
}

#@Override
sub render
{
    my $self = shift;
    my $context = shift;

    my %vars = ();
    foreach my $key (keys(%{$self->{mappings}}))
    {
        $vars{$key} = $self->{mappings}->{$key}->render($context);
    }

    $context->push_scope()->set(%vars);

    my $result = $self->SUPER::render($context);

    $context->pop_scope();

    return $result;
}

1;