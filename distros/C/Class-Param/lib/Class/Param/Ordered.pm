package Class::Param::Ordered;

use strict;
use warnings;
use base 'Class::Param::Base';

use Params::Validate   qw[];
use Tie::Hash::Indexed qw[];

sub new {
    my $class = ref $_[0] ? ref shift : shift;

    my ( $hash ) = Params::Validate::validate_with(
        params  => \@_,
        spec    => [
            {
                type      => Params::Validate::HASHREF,
                default   => {},
                optional  => 1
            }
        ],
        called  => "$class\::new"
    );

    my $param = Tie::Hash::Indexed->TIEHASH( %{ $hash } );

    return bless( \$param, $class );
}

sub get {
    my ( $self, $name ) = @_;
    return $$self->FETCH($name);
}

sub set {
    my ( $self, $name, $value ) = @_;
    $$self->STORE( $name => $value );
    return 1;
}

sub has {
    my ( $self, $name ) = @_;
    return $$self->EXISTS($name);
}

sub count {
    my $self = shift;
    return scalar $self->names || 0;
}

sub remove {
    my ( $self, $name ) = @_;
    return $$self->DELETE($name);
}

sub clear {
    my $self = shift;
    $$self->CLEAR;
    return 1;
}

sub names {
    my $self  = shift;
    my @names = ( $$self->FIRSTKEY );

    return () unless defined $names[0];

    while ( defined ( $_ = $$self->NEXTKEY( $names[-1] ) ) ) {
        push @names, $_;
    }

    return @names;
}

1;

__END__

=head1 NAME

Class::Param::Ordered - Class Param Ordered

=head1 SYNOPSIS

   $param = Class::Param::Ordered->new;
   $param->param( D => 4 );
   $param->param( C => 3 );
   $param->param( B => 2 );
   $param->param( A => 1 );
   
   @names = $param->names; # ( D, C, B, A )

=head1 DESCRIPTION

A param class which remembers insertion order.

=head1 METHODS

=over 4

=item new

Constructor. Takes no arguments.

=back

The rest of the API is the same as L<Class::Param>.

=head1 SEE ASLO

L<Class::Param>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
