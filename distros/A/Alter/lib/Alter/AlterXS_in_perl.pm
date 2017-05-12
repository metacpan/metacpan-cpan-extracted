package Alter;
use strict; use warnings;

### basic functions corona(), alter() and ego()
use Scalar::Util qw( readonly reftype weaken);
no warnings 'redefine'; # in case we're called after the XS version was loaded

my %corona_tab;
my %ob_reg;

sub corona ($) {
    @_ == 1 or croak "Usage: Alter::corona(obj)";
    my $obj = shift;
    ref $obj or croak "Alter: Can't use a non-reference";
    reftype $obj eq 'SCALAR' and readonly( $$obj) and
        croak "Alter: Can't modify a read-only value";
    my $id = $obj + 0;
    $corona_tab{ $id} ||= do {
        weaken( $ob_reg{ $id} = $obj);
        {};
    };
}

sub alter ($$) {
    @_ == 2 or croak "Usage: Alter::alter(obj, val)";
    my ( $obj, $val) = @_;
    corona( $obj)->{ caller()} = $val;
    $obj;
}

sub ego ($) {
    @_ == 1 or die "Usage: Alter::ego(obj)";
    my $obj = shift;
    corona( $obj)->{ caller()} ||= _vivify( caller());
}

sub is_xs { 0 }

### Autovivification

my %type_tab;

sub _set_class_type {
    my ( $class, $type) = @_;
    $type_tab{ $class} = $type;
}

my %viv_tab = (
    SCALAR => sub { \ my $o },
    ARRAY  => sub { [] },
    HASH   => sub { {} },
);

sub _vivify {
    my $class = shift;
    return undef unless $type_tab{ $class};
    $viv_tab{ ref $type_tab{ $class}}->();
}

### Garbage collection and thread support

sub Alter::Destructor::DESTROY {
    my $id =  shift() + 0;
    delete $corona_tab{ $id};
    delete $ob_reg{ $id};
}

sub CLONE {
    return unless shift eq __PACKAGE__;
    for my $old_id ( keys %ob_reg ) {
        my $new_obj = delete $ob_reg{ $old_id};
        my $new_id = $new_obj + 0;
        weaken( $ob_reg{ $new_id} = $new_obj);
        $corona_tab{ $new_id} = delete $corona_tab{ $old_id};
    }
}

1;
