package t::Mock;
use strict;
use warnings;

use Carp qw/croak/;

sub new {
    my ($class, $isa, $method) = @_;
    return bless {
        isa    => $isa,
        called => {},
        method => $method,
    } => $class;
}

sub can {
    my ($invocant, $method) = @_;
    if (ref $invocant) {
        my $self = $invocant;
        return $self->{method}->{$method} if $self->{method}->{$method};
    }
    return $invocant->SUPER::can($method);
}

sub isa {
    my ($invocant, $pkg) = @_;
    if (ref $invocant) {
        my $self = $invocant;
        return 1 if $self->{isa} eq $pkg;
    }
    return $invocant->SUPER::isa($pkg);
}

sub set_method {
    my ($self, $name, $code) = @_;
    $self->{method}->{$name} = $code;
}

sub called_count {
    my ($self, $method) = @_;
    return $self->{called}->{$method} || 0;
}

sub DESTROY {} # no autoload it

our $AUTOLOAD;
sub AUTOLOAD {
    my ($invocant) = @_;
    (my $method = $AUTOLOAD) =~ s/^.*://;

    if (ref $invocant) {
        my $self = $invocant;
        $self->{called}->{$method}++;
        if (my $code = $self->{method}->{$method}) {
            goto $code;
        }
    }

    my $class = ref $invocant || $invocant;
    croak qq!Can't locate object method "$method" via package "$class"!;
}

1;
__END__
