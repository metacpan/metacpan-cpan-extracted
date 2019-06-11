package Chart::GGPlot::Geom::Path;

# ABSTRACT: Class for path geom

use Chart::GGPlot::Class qw(:pdl);
use namespace::autoclean;
use MooseX::Singleton;

our $VERSION = '0.0005'; # VERSION

use List::AllUtils qw(reduce);
use PDL::Primitive qw(which);

use Chart::GGPlot::Aes;
use Chart::GGPlot::Layer;
use Chart::GGPlot::Util qw(:all);
use Chart::GGPlot::Util::Pod qw(layer_func_pod);

with qw(Chart::GGPlot::Geom);

has '+non_missing_aes' => ( default => sub { [qw(size shape color)] } );
has '+default_aes'     => (
    default => sub {
        Chart::GGPlot::Aes->new(
            color    => PDL::SV->new( ['black'] ),
            size     => pdl(0.5),
            linetype => PDL::SV->new( ['solid'] ),
            alpha    => NA(),
        );
    }
);

classmethod required_aes () { [qw(x y)] }

my $geom_path_pod = layer_func_pod(<<'EOT');

        geom_path(:$mapping=undef, :$data=undef, :$stat='identity',
                  :$position='identity', :$na_rm=false, :$show_legend=undef,
                  :$inherit_aes=true, 
                  %rest)

    The "path" geom connects the observations in the order in which they
    appear in the data.

    =over 4

    %TMPL_COMMON_ARGS%

    =back

EOT

my $geom_path_code = fun (
        :$mapping = undef, :$data = undef,
        :$stat = 'identity', :$position = 'identity',
        :$na_rm = false,
        :$show_legend = undef, :$inherit_aes = true,
        %rest )
{
    return Chart::GGPlot::Layer->new(
        data        => $data,
        mapping     => $mapping,
        stat        => $stat,
        position    => $position,
        show_legend => $show_legend,
        inherit_aes => $inherit_aes,
        geom        => 'path',
        params      => { na_rm => $na_rm, %rest },
    );
};

classmethod ggplot_functions() {
    return [
        {
            name => 'geom_path',
            code => $geom_path_code,
            pod => $geom_path_pod,
        }
    ];
}

method handle_na ($data, $params) {

    # Drop missing values at the start or end of a line - can't drop in the
    # middle since you expect those to be shown by a break in the line

    # are each row all good or not?
    state $complete_cases = sub {
        my @piddles = @_;

        my @isgood = map { $_->badflag ? $_->isgood : () } @piddles;
        if ( @isgood == 0 ) {
            return PDL::Core::ones( $piddles[0]->length );
        }
        else {
            return ( reduce { $a & $b } ( shift @isgood ), @isgood );
        }
    };

    # group by $grouping and average by $fun
    state $ave = sub {
        my ( $x, $grouping, $fun ) = @_;
        my $new = $x->copy;
        for my $g ( $grouping->uniq->flatten ) {
            my $sliced   = $new->where( $x == $g );
            my $averaged = $fun->($sliced);
            $sliced .= $averaged;
        }
        return $new;
    };

    my $complete =
      $complete_cases->( map { $data->at($_) } qw(x y size color linetype) );
    my $kept = $ave->( $complete, $data->at('group'),
        sub { $self->_keep_mid_true(@_) } );

    if ( not $kept->all and not $params->{na_rm} ) {
        warn sprintf( "Removed %s rows containing missing values (geom_path).",
            ( !$kept )->sum );
    }

    return ( $kept->all ? $data : $data->select_rows( which($kept) ) );
}

# Trim false values from left and right: keep all values from
# first TRUE to last TRUE
classmethod _keep_mid_true ($x) {
    my $is_true = which($x);
    unless ( $is_true->length ) {
        return PDL::Core::zeros( $x->length );
    }
    my $first = $is_true->at(0);
    my $last  = $is_true->at(-1);

    return pdl(
        ( (0) x $first ),
        ( (1) x ( $last - $first ) ),
        ( (0) x ( $x->length - $last ) )
    );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Geom::Path - Class for path geom

=head1 VERSION

version 0.0005

=head1 SEE ALSO

L<Chart::GGPlot::Geom>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
