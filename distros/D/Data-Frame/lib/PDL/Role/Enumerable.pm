package PDL::Role::Enumerable;
$PDL::Role::Enumerable::VERSION = '0.006003';
use 5.010;
use strict;
use warnings;

use failures qw/levels::number/;

use Role::Tiny;
use Safe::Isa;
use List::AllUtils ();

with qw(PDL::Role::Stringifiable);

requires 'levels';

sub element_stringify_max_width {
    my ($self, $element) = @_;
    my @where_levels = @{ $self->{PDL}->uniq->unpdl };
    my @which_levels = @{ $self->levels }[@where_levels];
    my @lengths = map { length $_ } @which_levels;
    List::AllUtils::max( @lengths );
}

sub element_stringify {
    my ($self, $element) = @_;
    $self->levels->[ $element ];
}

sub number_of_levels {
    my ($self) = @_;
    return scalar( @{ $self->levels } );
}

sub uniq {
    my $self  = shift;
    my $class = ref($self);
 
    my $new = $class->new( $self->levels, levels => $self->levels );
    $new->{PDL} = $self->{PDL}->uniq;
    return $new;
}

around qw(slice dice) => sub {
    my $orig = shift;
    my $self = shift;
    my $class = ref($self);

    my $pdl = $self->{PDL}->$orig(@_);
    my $ret = bless( { PDL => $pdl }, $class );

    # TODO levels needs to be copied
    $ret->levels( $self->levels );
    return $ret;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PDL::Role::Enumerable

=head1 VERSION

version 0.006003

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019-2022 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
