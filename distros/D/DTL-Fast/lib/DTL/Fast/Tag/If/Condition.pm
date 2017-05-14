package DTL::Fast::Tag::If::Condition;
use strict;
use utf8;
use warnings FATAL => 'all';
use parent 'DTL::Fast::Renderer';
# this is a simple condition

use DTL::Fast::Utils qw(as_bool);

sub new
{
    my ( $proto, $condition, %kwargs ) = @_;

    $kwargs{condition} = ref $condition ?
        $condition
                                        : DTL::Fast::Expression->new($condition);

    my $self = $proto->SUPER::new(%kwargs);

    delete $self->{_template};

    return $self;
}

sub is_true
{
    my ( $self, $context ) = @_;

    return as_bool($self->{condition}->render($context));
}

1;