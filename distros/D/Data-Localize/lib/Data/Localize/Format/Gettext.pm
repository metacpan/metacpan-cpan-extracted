package Data::Localize::Format::Gettext;
use Moo;

extends 'Data::Localize::Format';

has functions => (
    is => 'ro',
    default => sub { {} }
);

sub format {
    my ($self, $lang, $value, @args) = @_;

    if ( index($value, '(') > -1 ) {
        $value =~ s|%(\w+)\(([^\)]+)\)|
            $self->_call_function_or_method( $lang, $1, $2, \@args )
        |gex;
    }
    if (@args) {
        $value =~ s/%(\d+)/ defined $args[$1 - 1] ? $args[$1 - 1] : '' /ge;
    }

    return $value;
}

sub _call_function_or_method {
    my ($self, $lang, $method, $embedded, $args) = @_;

    my $code;
    my $is_method;
    if ( $code = $self->functions->{$method} ) {
        $is_method = 0;
    } elsif ( $code = $self->can($method) ) {
        $is_method = 1;
    }
    if (! $code) {
        Carp::confess(Scalar::Util::blessed($self) . " does not implement method '$method'");
    }

    my @embedded_args = split /,/, $embedded;
    for (@embedded_args) {
        if ( $_ =~ /%(\d+)/ ) {
            $_ = $args->[ $1 - 1 ];
        }
    }

    my @args = ( $lang, \@embedded_args );
    if ($is_method) {
        unshift @args, $self;
    }
    return $code->(@args);
}

1;

__END__

=head1 NAME

Data::Localize::Format::Gettext - Gettext Formatter

=head1 SYNOPSIS

    # Used by Data::Localize::Gettext by default, but if you want to
    # customize ( maybe include function calls "%myfunc(...)" ), then
    # do this:

    $loc = Data::Localize->new();
    $loc->add_localizer(
        Data::Localize::Gettext->new(
            formatter => Data::Localize::Format::Gettext->new(
                functions => {
                    foo => sub {
                        my ($lang, $args) = @_;
                        # $lang isa 'Str',
                        # $args isa 'ArrayRef'
                        return "localized text";
                    },
                    bar => sub { ... },
                    baz => sub { ... },
                }
            )
        )
    );

=head1 METHODS

=head2 format

=cut

