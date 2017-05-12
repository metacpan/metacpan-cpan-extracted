package DSL::HTML::Parser;
use strict;
use warnings;

use Devel::Declare::Interface;
use base 'Exporter::Declare::Magic::Parser';
BEGIN { Devel::Declare::Interface::register_parser('dsl_html') }

our %NAMELESS;
sub nameless    { $NAMELESS{$_[-1]}++ }
sub is_nameless { $NAMELESS{shift->name} }

sub args { (qw/name/) }

sub inject {
    my $self = shift;
    return if $self->is_nameless;
    return if $self->has_fat_comma;
    return ('my $tag = shift;');
}

sub rewrite {
    my $self = shift;

    return 1 if $self->is_nameless;

    $self->strip_prototype;
    $self->_check_parts;

    my $is_arrow = $self->parts->[1]
        && ( $self->parts->[1] eq '=>' || $self->parts->[1] eq ',' );
    if ( $is_arrow && $self->parts->[2] ) {
        my $is_ref = ref( $self->parts->[2] );
        my $is_sub = $is_ref ? $self->parts->[2]->[0] eq 'sub' : 0;

        if ( !$is_ref ) {
            $self->new_parts( [$self->parts->[0], $self->parts->[2]] );
            return 1;
        }
        elsif ($is_sub) {
            $self->new_parts( [$self->parts->[0]] );
            return 1;
        }
        else {
            $self->bail('oops');
        }
    }

    my ( $names, $specs ) = $self->sort_parts();
    $self->new_parts(
        [
            @$names,
            @$specs
            ? (
                ( map { $_->[0] } @$specs ),
                ['block']
                )
            : ()
        ]
    );

    1;
}

1;

__END__

=head1 NAME

DSL::HTML::Parser - Exporter::Declare::Parser plugin for syntax.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

DSL-HTML is free software; Standard perl license (GPL and Artistic).

DSL-HTML is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the license for more details.
