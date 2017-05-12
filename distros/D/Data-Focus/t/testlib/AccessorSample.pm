package testlib::AccessorSample;
use strict;
use warnings;

my @scalar_fields = ();
my @list_fields = ();

sub _has {
    my ($name) = @_;
    my ($package) = caller;
    my $method = "${package}::${name}";

    no strict "refs";
    *{$method} = sub {
        my ($self, $v) = @_;
        $self->{$name} = $v if @_ > 1;
        return $self->{$name};
    };
    push @scalar_fields, $name;
}

## a little tricky "list" returning accessor
sub _has_list {
    my ($name) = @_;
    my ($package) = caller;
    my $method = "${package}::${name}";

    no strict "refs";
    *{$method} = sub {
        my ($self, @v) = @_;
        $self->{$name} = \@v if @_ > 1;
        return wantarray ? ( $self->{$name} ? @{$self->{$name}} : [] )
                         : ( $self->{$name} ? $self->{$name}[0] : undef );
    };
    push @list_fields, $name;
}

_has "foo";
_has "bar";
_has "buzz";
_has_list "list";

sub new {
    my ($class) = @_;
    return bless {
        (map { ($_ => undef) } @scalar_fields),
        (map { ($_ => []) } @list_fields)
    }, $class;
}

sub bomb {
    die "boom!";
}

1;

