package Data::Focus::Lens::Accessor;
use strict;
use warnings;
use parent qw(Data::Focus::Lens);
use Data::Focus::LensMaker ();
use Carp;

our @CARP_NOT = qw(Data::Focus::Lens Data::Focus);

sub new {
    my ($class, %args) = @_;
    croak "method is mandatory" if !defined($args{method});
    my $self = bless {
        method => $args{method}
    }, $class;
    return $self;
}

sub _getter {
    my ($self, $target) = @_;
    my $method = $self->{method};
    if(!eval { $target->can($method) }) {
        return ();
    }
    my $v = $target->$method;
    return $v;
}

sub _setter {
    my ($self, $target, $v) = @_;
    return $target if @_ <= 2;
    my $method = $self->{method};
    $target->$method($v);
    return $target;
}

Data::Focus::LensMaker::make_lens_from_accessors(\&_getter, \&_setter);


1;
__END__

=pod

=head1 NAME

Data::Focus::Lens::Accessor - lens for "typical" accessor methods

=head1 SYNOPSIS

    package Person;
    
    sub new {
        my ($class, $name) = @_;
        return bless { name => $name }, $class;
    }
    
    sub name {
        my ($self, $v) = @_;
        $self->{name} = $v if @_ > 1;
        return $self->{name};
    }
    
    package main;
    use Data::Focus qw(focus);
    use Data::Focus::Lens::Accessor;
    
    my $target = Person->new("john");
    my $name_lens = Data::Focus::Lens::Accessor->new(method => "name");
    
    focus($target)->get($name_lens);  ## => "john"
    focus($target)->set($name_lens, "JOHN");

=head1 DESCRIPTION

This is an implementation of L<Data::Focus::Lens>, which focuses on an accessor method of the target object.
It assumes the typical accessor method signature widely used in Perl:

    my $got_value = $target->accessor_method;  ## getter
    $target->accessor_method($set_value);      ## setter

It creates no focal points if the C<$target> is non-blessed or it doesn't have the specified accessor method.

=head1 CLASS METHOD

=head2 $lens = Data::Focus::Lens::Accessor->new(%args)

The constructor.

Fields in C<%args> are:

=over

=item C<method> => STR (mandatory)

Accessor method name.

=back

=head1 AUTHOR

Toshio Ito C<< <debug.ito at gmail.com> >>

=cut

