package Business::EDI::Object;

use strict;
use warnings;

use Carp;
use UNIVERSAL::require;
use Data::Dumper;

use Business::EDI::DataElement;
use Business::EDI::CodeList;

our $AUTOLOAD;

our $VERSION = 0.01;
our $debug = 1;

sub carp_error {
    carp __PACKAGE__ . ': ' . shift;
    return;    # undef: do not change!
}

sub add_pair {
    my ($self, $key, $val) = @_;
    $self->{_permitted}->{$key} = 1;
    exists($self->{$key}) and carp "Key $key already found in self!  Overwriting.";
    $self->{$key} = $val;
}

# This is recursive!
sub new {
    my $class = shift;
    my $body  = @_ ? shift : return;
    my $depth = @_ ? shift : 0;     # Track recursion depth

    $depth > 100 and croak "Recursion depth in " . __PACKAGE__ . "->new() exceeds limit (100)";   # safety first
    
    my $ref = ref($body);
    return $body unless $ref;     # Values are just values
    
    my $self = bless({}, $class);
    $self->add_pair('debug', $debug);
    $debug and warn __PACKAGE__ . " ref at depth $depth: $ref ==> " . Dumper($body);

    if ($ref eq 'HASH') {
        foreach my $key (keys(%$body)) {
            my $val = $body->{$key};
            $self->add_pair($key, ref($val) ? $class->new($val, $depth+1) : Business::EDI::DataElement->new($key, $val));
        }
    } elsif ($ref eq 'ARRAY') {
        if (scalar(@$body) == 2 and (not ref($body->[0]))
            and ref($body->[1]) eq 'HASH'
            )
        {
            # it's a pseudo hash segment
            my $val = $class->new($body->[1], $depth+1);
            $self->add_pair($body->[0], $val);
            return { $body->[0] => $val };
        }
        return [ map {$class->new($_, $depth+1)} @$body ];
    } elsif ($ref eq 'SCALAR') {
        carp "For some reason, got a reference to SCALAR instead of just a scalar value";
        return eval ($body);
    } else {
        carp "Unexpected data: includes ref to $ref";
        return $ref;
    }
    # $self->{$_} = Business::EDI::DataElement->new($_, $body->{$_});
    return $self;
}

sub DESTROY {}  #
sub AUTOLOAD {
    my $self  = shift;
    my $class = ref($self) or croak "AUTOLOAD error: $self is not an object";
    my $name  = $AUTOLOAD;

    $name =~ s/.*://;   #   strip leading package stuff
    $name =~ s/^s(eg(ment)?)?//i;  #   strip segment (to avoid numerical method names)

    unless (exists $self->{_permitted}->{$name}) {
        croak "Cannot access '$name' field of class '$class'"; 
    }

    if (@_) {
        return $self->{$name} = shift;
    } else {
        return $self->{$name};
    }
}

1;
__END__

