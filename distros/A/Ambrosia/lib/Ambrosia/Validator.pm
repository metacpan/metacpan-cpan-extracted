package Ambrosia::Validator;
use strict;
use warnings;

use Ambrosia::Validator::Violation;
use Ambrosia::Meta;

class abstract
{
    protected => [qw/_prototype _violations _data/],
};

our $VERSION = 0.010;

sub _init
{
    my $self = shift;
    $self->SUPER::_init(@_);
    $self->_violations = new Ambrosia::Validator::Violation(prototype => $self->_prototype);
    $self->_data = {};
}

my $qr_trim = qr/(?:^\s+)|(?:\s+$)/;
sub get_value
{
    return (map { $_ =~ s/$qr_trim//sg; $_; } grep defined $_, @_);
}

sub validate
{
    my $self = shift;
    my %rules = @_;

    no strict 'refs';
    my $Constraints = \%{$self->_prototype . '::Constraints'};

    foreach ( keys %rules)
    {
        my $c = $Constraints->{$_};

        my $v = $c->check($rules{$_}->{value});
        unless ( $c->error )
        {
            if ($rules{$_}->{check})
            {
                $v = $rules{$_}->{check}->($self, $v, $c);
            }
        }
        if ($c->error)
        {
            $self->_violations->add($_, $v, $c);
        }
        else
        {
            $self->_data->{$_} = $v;
        }
    }
}

sub prepare_validate :Abstract
{
}

sub verify
{
    my $self = shift;
    $self->prepare_validate;

    if ( $self->_violations->count > 0 )
    {
        foreach ( keys %{$self->_data} )
        {
            $self->_violations->add($_ => $self->_data->{$_});
        }
        return $self->_violations;
    }

    return undef;
}

sub Instance
{
    my $self = shift;
    return $self->_prototype->new(%{$self->_data});
}

1;

__END__

=head1 NAME

Ambrosia::Validator - 

=head1 VERSION

version 0.010

=head1 SYNOPSIS


=head1 DESCRIPTION

C<Ambrosia::Validator> .

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
