package DBomb::Value::Key;

=head1 NAME

DBomb::Value::Key - The values for a DBomb::Meta::Key.

=head1 SYNOPSIS

=cut

use strict;
use warnings;
our $VERSION = '$Revision: 1.8 $';

use base qw(DBomb::Value);
use Carp qw(carp croak);
use Carp::Assert;
use Class::MethodMaker
    'new_with_init' => 'new',
    'get_set' => [ qw(value_list), ## [ value,...]
                   qw(key_info), ## Key object
                 ],
    ;


## new Key($key_info,[values...])
sub init
{
    my ($self,$key_info,$value) = @_;
        assert(UNIVERSAL::isa($self,__PACKAGE__));
        assert(@_ == 3, 'parameter count');
        assert(UNIVERSAL::isa($key_info , 'DBomb::Meta::Key'));
        assert(UNIVERSAL::isa($value , 'ARRAY'));

    $self->key_info($key_info);
    $self->value_list($value);
}


## mk_where
sub mk_where
{
    my $self = shift;
        assert(@_ == 0, 'parameter count');
    $self->key_info->where(@{$self->value_list});
}

1;
__END__
