package App::RoboBot::Type::Function;
$App::RoboBot::Type::Function::VERSION = '4.004';
use v5.20;

use namespace::autoclean;

use Moose;

extends 'App::RoboBot::Type';

has '+type' => (
    default => 'Function',
);

has '+value' => (
    is        => 'rw',
    isa       => 'Str | ArrayRef',
    required  => 1,
);

sub evaluate {
    my ($self, $message, $rpl, @args) = @_;

    return $self->bot->commands->{lc($self->value)}->process(
        $message,
        $self->value,
        $rpl,
        @args
    );
}

sub flatten {
    my ($self, $rpl) = @_;

    # Simple function names (referencing something from a plugin or macro) just
    # get returned plain. Anonymous functions, represented by ArrayRefs, get a
    # bit of extra processing for their textual representation.
    return $self->value unless ref($self->value);

    my @v = @{$self->value};
    my $ret = '(fn ';

    if (!ref($v[0])) {
        # First function element is a docstring.

        $ret .= App::RoboBot::Type::String->new( value => shift(@v) )->flatten . ' ';
    }

    # If the now-first element is a vector, then we have explicit args, and if
    # not then we just tack on an empty vector for the arg list.
    if (ref($v[0]) eq 'App::RoboBot::Type::Vector') {
        $ret .= $v[0]->flatten . ' ';
    } else {
        $ret .= '[] ';
    }

    # Now we can just flatten everything else. If there's nothing left, though,
    # just tack on an empty expression.
    if (@v > 0) {
        $ret .= join(' ', map { $_->flatten($rpl) } @v);
    } else {
        $ret .= '()';
    }

    # And finally, close the expression's form and return;
    return $ret . ')';
}

__PACKAGE__->meta->make_immutable;

1;
