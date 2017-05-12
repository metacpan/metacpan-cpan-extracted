package Ambrosia::Validator::Violation;
use strict;
use warnings;

use Ambrosia::error::Exceptions;
use Ambrosia::Validator::Constraint;

use Ambrosia::Meta;

class sealed
{
    public => [qw/prototype count/],
    private => [qw/__data/],
};

our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    $self->__data = {};
    $self->SUPER::_init(@_);
    $self->count = 0;

    #no strict 'refs';
    #*{__PACKAGE__ . '::fields'} = sub() { keys %{$_[0]->__data} };
}

sub add
{
    my $self = shift;
    my $f = shift;
    my $v = shift;
    my Ambrosia::Validator::Constraint $constraint = shift;

    $self->__data->{$f} = new Ambrosia::Validator::Violation::Result(
            value => $v,
            errorMessage => ($constraint ? $constraint->errorMessage : undef),
        );
    $self->count++ if $constraint;
}

sub errorSummary
{
    my $self = shift;
    return (map { @{$self->__data->{$_}->errorMessage} } keys %{$self->__data});
}

sub AUTOLOAD
{
    my $self = shift;
    my @param = @_;

    my $type = ref($self) or return;
    my ($func) = our $AUTOLOAD =~ /(\w+)$/
        or throw Ambrosia::error::Exception 'Error: cannot resolve AUTOLOAD: ' . $AUTOLOAD;

    my $p = $self->__data;

    my $val = undef;
    if ( exists $p->{$func} && scalar @param == 0 )
    {
        $val = $p->{$func}->value;
    }
    elsif( !exists $p->{$func} && eval {$self->prototype->can($func)} )
    {
        $val = $self->prototype->$func($self, @param );
    }
    elsif ( scalar @param > 0 )
    {
        throw Ambrosia::error::Exception 'Error: cannot assign new value for violation object ' . $self->prototype;
    }

    return $val;
}

sub DESTROY
{
    #warn "DESTROY: @_\n";
}

1;

package Ambrosia::Validator::Violation::Result;
use strict;
use warnings;

use Ambrosia::Meta;

class
{
    public    => [qw/value errorMessage/],
};
our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->errorMessage ||= [];
}

1;

__END__

=head1 NAME

Ambrosia::Validator::Violation - it is used for a wrapping of checked object in case of a bad data.

=head1 VERSION

version 0.010

=head1 DESCRIPTION

C<Ambrosia::Validator::Violation> it is used for a wrapping of checked object in case of a bad data.

=head1 CONSTRUCTOR

=head1 THREADS

Not tested.

=head1 BUGS

Please report bugs relevant to C<Ambrosia> to <knm[at]cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 Nickolay Kuritsyn. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nikolay Kuritsyn (knm[at]cpan.org)

=cut
