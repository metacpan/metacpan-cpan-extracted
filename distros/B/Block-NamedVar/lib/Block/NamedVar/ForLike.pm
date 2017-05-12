package Block::NamedVar::ForLike;
use strict;
use warnings;

use Devel::Declare::Interface;
use base 'Devel::Declare::Parser';

Devel::Declare::Interface::register_parser( 'for_var' );
__PACKAGE__->add_accessor( $_ ) for qw/dec vars list var_count/;

sub is_contained{ 0 }

sub rewrite {
    my $self = shift;

    if ( @{ $self->parts } > 3 ) {
        ( undef, undef, my @bad ) = @{ $self->parts };
        $self->bail(
            "Syntax error near: " . join( ' and ',
                map { $self->format_part($_)} @bad
            )
        );
    }

    my ($first, $second, $third) = @{ $self->parts };
    my ( $dec, $vars, $list ) = ("");
    if ( @{ $self->parts } > 2 ) {
        $self->bail(
            "Syntax error near: " . $self->format_part($first)
        ) unless grep { $first->[0] eq $_ } qw/my our/;
        $dec = $first;
        $vars = $second;
        $list = $third;
    }
    elsif ( @{ $self->parts } < 2 ) {
        $dec = ['local'];
        $vars = [' $a, $b ', '('];
        $list = $first;
    }
    else {
        $vars = $first;
        $list = $second;
    }

    $self->vars( $self->format_vars( $vars ));
    $self->var_count( $self->count_vars );
    $self->dec( $dec );
    $self->list( $list );

    $self->new_parts([]);
    1;
}

sub format_vars {
    my $self = shift;
    my ( $vars ) = @_;
    return $vars if ref $vars;
    return [ $vars, '(' ];
}

sub count_vars {
    my $self = shift;
    my @sigils = ($self->vars->[0] =~ m/\$/g);
    my @bad = $self->vars->[0] =~ m/[\@\*\%]/g;
    die( "nfor can only use a list of scalars, not " . join( ', ', @bad ))
        if @bad;
    return scalar @sigils;
}

sub close_line {''};

sub open_line {
    my $self = shift;
    my $dec = $self->dec ? $self->dec->[0] : '';
    my $vars = $self->vars;
    return "; for my \$__ ( "
         . __PACKAGE__
         . '::_nfor('
         . $self->var_count
         . ", "
         . $self->list->[0]
         . ")) { "
         . "$dec ($vars->[0]) = \@\$__; ";
}

sub _nfor {
    return unless @_;
    my ( $num, @list ) = @_;
    my $i = 0;
    my @out;
    while ( $i < @list ) {
        push @out => [ @list[ $i .. ($i + $num - 1)] ];
        $i += $num;
    }
    return @out;
}

1;

__END__

=head1 NAME

Block::NamedVar::ForLike - Parser for 'nfor'

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Block-NamedVar is free software; Standard perl licence.

Block-NamedVar is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
