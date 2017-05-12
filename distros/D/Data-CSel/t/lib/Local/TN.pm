package # hide from PAUSE
    Local::TN;

use Role::Tiny::With;

with 'Role::TinyCommons::Tree::NodeMethods';
with 'Role::TinyCommons::Tree::FromStruct';

sub import { }

sub new {
    my $class = shift;
    my %attrs = @_;
    $attrs{parent} //= undef;
    $attrs{children} //= [];
    bless \%attrs, $class;
}

sub parent {
    my $self = shift;
    if (@_) {
        $self->{parent} = $_[0];
    }
    $self->{parent};
}

sub children {
    my $self = shift;

    if (@_) {
        if (@_ == 1 && ref($_[0]) eq 'ARRAY') {
            $self->{children} = $_[0];
        } else {
            $self->{children} = \@_;
        }
    }

    # we deliberately do this for testing, to make sure that the node methods
    # can work with both children returning arrayref or list
    if (rand() < 0.5) {
        return $self->{children};
    } else {
        return @{ $self->{children} };
    }
}

sub id {
    my $self = shift;
    $self->{id} = $_[0] if @_;
    $self->{id};
}

sub int1 {
    my $self = shift;
    $self->{int1} = $_[0] if @_;
    $self->{int1};
}

sub str1 {
    my $self = shift;
    $self->{str1} = $_[0] if @_;
    $self->{str1};
}

sub bool1 {
    my $self = shift;
    $self->{bool1} = $_[0] if @_;
    $self->{bool1};
}

sub defined1 {
    my $self = shift;
    $self->{defined1} = $_[0] if @_;
    $self->{defined1};
}

sub obj1 {
    my $self = shift;
    $self->{obj1} = $_[0] if @_;
    $self->{obj1};
}

1;
