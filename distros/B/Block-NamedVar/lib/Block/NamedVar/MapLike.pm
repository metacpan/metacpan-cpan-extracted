package Block::NamedVar::MapLike;
use strict;
use warnings;

use Devel::Declare::Interface;
use base 'Devel::Declare::Parser';

Devel::Declare::Interface::register_parser( 'map_var' );
__PACKAGE__->add_accessor( $_ ) for qw/dec var/;

sub rewrite {
    my $self = shift;

    if ( @{ $self->parts } > 2 ) {
        ( undef, my @bad ) = @{ $self->parts };
        $self->bail(
            "Syntax error near: " . join( ' and ',
                map { $self->format_part($_)} @bad
            )
        );
    }

    my ($first, $second) = @{ $self->parts };
    my ( $dec, $var ) = ("");
    if ( @{ $self->parts } > 1 ) {
        $self->bail(
            "Syntax error near: " . $self->format_part($first)
        ) unless grep { $first->[0] eq $_ } qw/my our/;
        $dec = $first;
        $var = $second;
    }
    else {
        $var = $first;
        $dec = ['my'] if ref $self->parts->[0];
    }

    $var = $self->format_var( $var );
    $self->dec( $dec );
    $self->var( $var );

    $self->new_parts([]);
    1;
}

sub format_var {
    my $self = shift;
    my ( $var ) = @_;
    if ( ref $var ) {
        $var = $var->[0];
    }
    return $var if $var =~ m/^\$\w[\w\d_]*$/;
    return "\$$var" if $var =~ m/^\w[\w\d_]*$/;
    $self->bail( "Syntax error, '$var' is not a valid block variable name" );
}

sub inject {
    my $self = shift;
    my $dec = $self->dec ? $self->dec->[0] : '';
    my $var = $self->var;
    return ( "$dec $var = \$_" );
}

sub _scope_end {
    my $class = shift;
    my ( $id ) = @_;
    my $self = Devel::Declare::Parser::_unstash( $id );

    my $linestr = $self->line;
    $self->offset( $self->_linestr_offset_from_dd() );
    substr($linestr, $self->offset, 0) = ', ';
    $self->line($linestr);
}

sub open_line {
    my $self = shift;
    return "";
}

1;

__END__

=head1 NAME

Block::NamedVar::MapLike - Parser for ngrep and nmap

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Chad Granum

Block-NamedVar is free software; Standard perl licence.

Block-NamedVar is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.
