package Data::Frame::Autobox::Array;

# ABSTRACT: Additional Array role for Moose::Autobox

use 5.016;
use Moose::Role;
use Function::Parameters;

use List::AllUtils;
use POSIX qw(ceil);

use namespace::autoclean;


method isempty() { @{$self} == 0 }

method uniq() { [ List::AllUtils::uniq(@{$self}) ] }

method set($index, $value) { 
    $self->[$index] = $value;
}


method repeat($n) {
    return [ (@$self) x $n ];
}

method repeat_to_length($l) {
    return $self if @$self == 0;
    my $x = repeat($self, ceil($l / @$self));
    return [ @$x[0 .. $l-1] ];
}


method copy() { [ @{$self} ] }


method intersect ( $other ) { 
    my %hash = map { $_ => 1 } @$self;
    return [ grep { exists $hash{$_} } @$other ];
}

method union ($other) {
    return [ List::AllUtils::uniq( @$self, @$other ) ];
}

method setdiff ($other) {
    my %hash = map { $_ => 1 } @$other;
    return [ grep { not exists( $hash{$_} ) } @$self ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::Autobox::Array - Additional Array role for Moose::Autobox

=head1 VERSION

version 0.0047

=head1 SYNOPSIS

    use Moose::Autobox;
    
    Moose::Autobox->mixin_additional_role(
        ARRAY => "Data::Frame::Autobox::Array"
    );

    [ 1 .. 5 ]->isempty;    # false

=head1 DESCRIPTION

This is an additional Array role for Moose::Autobox, used by Data::Frame.

=head1 METHODS

=head2 isempty

    my $isempty = $array->isempty;

Returns a boolean value for if the array ref is empty.

=head2 uniq

    my $uniq_array = $array->uniq;

=head2 set($idx, $value)

    $array->set($idx, $value);

This is same as the C<put> method of Moose::Autobox::Array.

=head2 repeat

    my $new_array = $array->repeat($n);

Repeat for C<$n> times.

=head2 repeat_to_length

    my $new_array = $array->repeat_to_length($l);

Repeat to get the length of C<$l>. 

=head2 copy

Shallow copy.

=head2 intersect

    my $new_ary = $array->intersect($other)

=head2 union

    my $new_array = $array->union($other)

=head2 setdiff

    my $new_array = $array->setdiff($other)

=head1 SEE ALSO

L<Moose::Autobox>,
L<Moose::Autobox::Array>

=head1 AUTHORS

=over 4

=item *

Zakariyya Mughal <zmughal@cpan.org>

=item *

Stephan Loyd <sloyd@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014, 2019 by Zakariyya Mughal, Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
