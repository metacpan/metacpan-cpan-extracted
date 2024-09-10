#! perl

use v5.10;

use Test2::V0;
use Test2::Tools::PDL 0.0004;

use Math::BigFloat try => 'GMP';

use Hash::Wrap ( { -lvalue => 1, -defined => 1, -exists => 'has' } );

use List::Util qw[ reduce ];

use CXC::PDL::Bin1D qw[ bin_on_index ];
use Set::Product    qw[ product ];
use Safe::Isa;

use Carp;
use PDL::Lite;

## no critic (Modules::ProhibitMultiplePackages)


# initialize, so can be reused in tests


## no critic (Variables::ProhibitPackageVars)
local $PDL::doubleformat = '%.20g';

local $Test2::Tools::PDL::TOLERANCE = 1e-12;

our $SLOW_BUT_CORRECT = 1;

{
    package DataBase;

    use Class::Tiny;
    use Scalar::Util;
    use Safe::Isa;

    sub _piddle_keys {
        my $self = shift;

        my @attrs = Class::Tiny->get_all_attributes_for( Scalar::Util::blessed( $self ) );

        grep { $self->$_->$_isa( 'PDL' ) } @attrs;
    }

    sub _piddle_values {
        my $self = shift;

        map { $self->$_ } $self->_piddle_keys;
    }

    sub copy {
        my $self = shift;
        my %copy = %{$self};
        $copy{$_} = $copy{$_}->copy for $self->_piddle_keys;

        return Scalar::Util::blessed( $self )->new( %copy );
    }

    sub extend {
        my ( $self, @shape ) = @_;
        $_ = $_->reshape( $_->dims, @shape ) for $self->_piddle_values;
    }

    sub squeeze {
        my ( $self ) = @_;
        $_ = $_->squeeze for $self->_piddle_values;
    }

    sub insert_1D {

        my ( $to, $from, @where ) = @_;

        for my $key ( $to->_piddle_keys ) {

            if ( $from->$key->ndims == 0 ) {
                $to->$key->set( @where, $from->$key );
            }
            else {
                Carp::croak( "from $key is not 1D\n" )
                  if $from->$key->ndims != 1;

                $to->$key->slice( [ 0, $from->$key->nelem - 1 ], @where ) .= $from->$key;
            }
        }
    }

    sub finalize { return $_[0] }
}

{
    package DataSet;

    use parent -norequire => 'DataBase';

    use Class::Tiny qw[ data weight index nelem nbins ], { imin => PDL::indx( 0 ) };
    use Scalar::Util;
    use List::Util;
    use Safe::Isa;

    sub BUILD {

        my ( $self, $args ) = @_;

        if (   exists $args->{data}
            || exists $args->{weight}
            || exists $args->{index} )
        {
            my $shape = $self->data->shape;
            ## no critic(BuiltinFunctions::ProhibitBooleanGrep)
            Carp::croak( "data, weight and index must have same shape\n" )
              if grep { PDL::any( $self->$_->shape != $shape ) } qw[ weight index ];

            my @shape = $shape->list;
            shift @shape;

            $self->nelem( PDL::indx( $self->nelem ) )
              unless $self->nelem->$_isa( 'PDL' );

            Carp::croak(
                "nelem has wrong shape.  expected @{[ PDL->new(@shape) ]}, got  @{[ $self->nelem->shape ]}\n" )
              unless PDL::all( $self->nelem->shape == PDL->new( @shape ) );
        }
        else {
            $self->nelem( PDL::indx( $self->nelem ) )
              unless $self->nelem->$_isa( 'PDL' );

            $self->nbins( PDL::indx( $self->nbins ) )
              unless $self->nbins->$_isa( 'PDL' );

            $self->imin( PDL::indx( $self->imin ) )
              unless $self->imin->$_isa( 'PDL' );

            $self->data( PDL->grandom( $self->nelem ) );
            $self->weight( PDL->grandom( $self->nelem )->abs );
            $self->index( $self->imin + PDL::indx( $self->nbins * PDL->random( $self->nelem ) ) );
            my ( $n, undef ) = $self->index->qsort->rle;
            Carp::croak( "asked for @{[ $self->nbins ]} bins, but got @{[ $n->nelem ]}\n" )
              if $n->nelem != $self->nbins;
        }
    }

    sub imax {
        my $self = shift;
        $self->imin + $self->nbins - 1;
    }

    sub where {
        my ( $self, $mask ) = @_;
        my %copy = %{$self};

        $copy{$_} = $copy{$_}->where( $mask ) for qw[ data weight index ];

        return Scalar::Util::blessed( $self )->new( \%copy );
    }

    # resize piddle so it has the correct extent
    sub resize {
        my ( $self ) = @_;

        Carp::croak( "data set is not 1D\n" )
          if $self->nelem->ndims > 1;

        $self->$_->reshape( $self->nelem ) for qw[ data weight index ];
    }

}

{
    package DataStats;

    use parent -norequire => 'DataBase';

    use Hash::Wrap ( { -lvalue => 1, -defined => 1, -exists => 'has' } );

    use Class::Tiny qw[ nalloc nbins count imin imax dmin dmax dsum mean dwsum wmean
      wtsum wt2sum dev2 wdev2 oob oob_imin oob_imax oob_nbins ];


    sub BUILD {
        my ( $self, $args ) = @_;

        return if !exists $args->{dset};

        my $opt = wrap_hash {
            nalloc => undef,
            nbins  => undef,
            imin   => undef,
            oob    => 0,
            %$args
        };

        my $dset  = $opt->dset;
        my $data  = $dset->data;
        my $wdata = $dset->data * $dset->weight;

        $self->oob( $opt->oob );

        my $index = $dset->index;

        my ( $n, $i ) = $index->qsort->rle;

        my ( $imin, $imax ) = $i->minmax;
        $imin = $opt->imin if defined $opt->imin;
        my $nbins = $opt->nbins // ( $imax - $imin + 1 );

        $self->nalloc( $opt->nalloc // $nbins );

        die( 'internal error: nalloc < nbins!' )
          if $self->nalloc < $nbins;

        $self->nbins( PDL::indx( [$nbins] ) );
        $self->count( PDL->zeroes( PDL::long, $self->nalloc ) );
        $self->count->index( $i - $imin ) .= $n;
        $self->imin( PDL::indx( [$imin] ) );
        $self->imax( $self->imin + $self->nbins - 1 );

        # min and max
        $self->dmin( PDL->zeroes( PDL::double, $self->nalloc ) );
        $self->dmax( $self->dmin->copy );

        for my $idx ( $imin .. $imax ) {
            my ( $min, $max ) = $data->where( $index == $idx )->minmax;
            $self->dmin->set( $idx - $imin, $min );
            $self->dmax->set( $idx - $imin, $max );
        }

        $self->$_( $self->$_->setbadif( $self->count == 0 ) ) for qw( dmin dmax );

        $self->dsum( $self->whist( $data, $index ) );
        $self->dwsum( $self->whist( $wdata,        $index ) );
        $self->wtsum( $self->whist( $dset->weight, $index ) );
        $self->wt2sum( $self->whist( $dset->weight**2, $index ) );

        $self->mean( $self->dsum / $self->count );
        ## no critic( ValuesAndExpressions::ProhibitMismatchedOperators)
        $self->mean->where( $self->count == 0 ) .= 0;

        $self->wmean( $self->dwsum / $self->wtsum );

        $self->dev2(
            $self->whist( ( $dset->data - $self->mean->index( $index - $self->imin ) )**2, $index ) );


        $self->wdev2(
            $self->whist(
                $dset->weight * ( $dset->data - $self->wmean->index( $index - $self->imin ) )**2, $index,
            ) );

        $self->mark_bad;
    }

    sub mark_bad {

        my $self = shift;
        my $bad  = $self->count == 0;
        $bad->inplace->setvaltobad( 1 );

        # not all attributes get marked as bad
        for my $key ( qw[ mean dev2 wdev2 dmin dmax ] ) {

            $self->$key->inplace->copybad( $bad );
        }
    }


    sub shape { return $_[0]->count->shape }

    sub reshape {
        my ( $self, @shape ) = @_;

        $_ = $_->reshape( @shape ) for grep { $_->dims > 0 } $self->_piddle_values;
    }

    sub whist {
        my ( $self, $data, $index ) = @_;

        ## no critic (Subroutines::ProtectPrivateSubs)
        main::_whist(
            data   => $data,
            index  => $index,
            imin   => $self->imin->sclr,
            nbins  => $self->nbins->sclr,
            nalloc => $self->nalloc,
        );
    }

    # shrink stats to minimum size needed to contain the number of bins
    sub shrink {
        my $self  = shift;
        my $nbins = $self->nbins->max + ( $self->oob ? 2 : 0 );
        my $shape = $self->count->shape;

        my @dims    = $self->count->dims;
        my @newdims = ( $nbins, @dims[ 1, -1 ] );

        for my $key ( $self->_piddle_keys ) {

            my $pdl = $self->$key;

            next
              unless PDL::all( $pdl->shape == $shape );

            my $new = $pdl->zeroes( @newdims );
            $new .= $pdl->slice( [ 0, $nbins - 1 ] );

            $self->$key( $new );
        }
    }
}

{

    package DataStats::OOB;

    use Scalar::Util;
    use Class::Tiny qw[ oob low inbnd high nalloc nbins imin imax ];
    use Hash::Wrap;

    sub BUILD {

        my $self = shift;
        $self->nbins( $self->inbnd->nbins );
        $self->imin( $self->inbnd->imin );
        $self->imax( $self->inbnd->imax );
    }

    sub finalize {
        my $self = shift;
        my $opt  = wrap_hash( { %{ shift() } } );
        $opt = wrap_hash( { %{ $opt->stats } } );

        my $type = $self->oob->type;
        my ( $low_start, $inbnd_start, $high_start ) = do {

            ## no critic( ControlStructures::ProhibitCascadingIfelse)
            if ( $type eq 'start-end' ) {
                ( 0, 1, 2 + $opt->nalloc - 1 );
            }

            elsif ( $type eq 'start-nbins' ) {
                ( 0, 1, $self->nbins + 1 );
            }

            elsif ( $type eq 'end' ) {
                ( $opt->nalloc, 0, $opt->nalloc + 1 );
            }

            elsif ( $type eq 'nbins' ) {
                ( $self->nbins, 0, $self->nbins + 1 );
            }

            else {
                die( 'illegal oob value: ', $type );
            }
        };

        my @attrs = Class::Tiny->get_all_attributes_for( Scalar::Util::blessed $self->inbnd );

        my %attrs;
        @attrs{@attrs} = ();

        delete @attrs{ 'nalloc', 'nelem', 'oob', 'imin', 'imax', 'oob_imin', 'oob_imax', 'oob_nbins' };

        # any will do
        my $tpl = $self->inbnd;

        for my $attr ( keys %attrs ) {

            $attrs{$attr} = $tpl->$attr->zeroes( $opt->nalloc + 2 );

            for my $part (
                [ $self->low,   $low_start ],
                [ $self->high,  $high_start ],
                [ $self->inbnd, $inbnd_start ],
              )
            {
                my ( $stats, $start ) = @$part;

                my $pdl = $stats->$attr;
                $attrs{$attr}->slice( [ $start, $start + $pdl->nelem - 1 ] )
                  .= $pdl;
            }
        }

        $attrs{nalloc}    = $opt->nalloc + 2;
        $attrs{nbins}     = PDL::indx( $self->nbins );
        $attrs{imin}      = PDL::indx( $self->imin );
        $attrs{imax}      = PDL::indx( $self->imax );
        $attrs{oob}       = $self->oob;
        $attrs{oob_imin}  = PDL::indx( $self->oob->imin );
        $attrs{oob_imax}  = PDL::indx( $self->oob->imax );
        $attrs{oob_nbins} = PDL::indx( $self->oob->nbins );

        return DataStats->new( \%attrs );
    }
}

{
    package Container1D;

    use Class::Tiny qw[ dset stats ], { idx => sub { [] } };

    sub copy {

        my $self = shift;
        return Scalar::Util::blessed( $self )->new(
            dset  => $self->dset->copy,
            stats => $self->stats->copy,
            idx   => [ @{ $self->idx } ],
        );
    }

    sub finalize {

        my $self = shift;

        return Scalar::Util::blessed( $self )->new(
            dset  => $self->dset->finalize( @_ ),
            stats => $self->stats->finalize( @_ ),
            idx   => $self->idx,
        );
    }

}


{
    package ContainerND;

    use parent -norequire => 'Container1D';

    use Scalar::Util;
    use Class::Tiny qw[ dset stats ];

    sub BUILD {
        my ( $self, $args ) = @_;

        return unless defined $args->{template};

        Carp::croak( "template must be 1D\n" )
          unless $args->{template}->isa( 'Container1D' );

        $self->dset( $args->{template}->dset->copy );
        $self->stats( $args->{template}->stats->copy );

        if ( defined $args->{extend} ) {
            $self->extend( @{ $args->{extend} } );
        }
    }

    sub extend {
        my $self  = shift;
        my @shape = @_;
        $self->dset->extend( @shape );
        $self->stats->extend( @shape );
        return $self;
    }

    sub insert_1D {
        my ( $to, $from, @where ) = @_;

        Carp::croak( "from must be 1D\n" )
          unless $from->isa( 'Container1D' );

        $to->dset->insert_1D( $from->dset, @where );
        $to->stats->insert_1D( $from->stats, @where );
    }

    sub finalize {
        my $self = shift;
        $self->dset->squeeze;
        $self->stats->squeeze;
        $self->stats->shrink;
        $self->stats->mark_bad;
    }
}



sub mk_1D_dataset {

    my $opt = wrap_hash {
        dset_imin    => 0,
        dset_nelem   => 1000,
        stats_nalloc => undef,
        stats_nbins  => undef,
        stats_imin   => undef,
        @_
    };

    if ( $opt->has( 'subset' ) ) {
        my $offset = 5 + int( 3 - rand( 6 ) );
        $opt->dset_imin( $opt->dset_imin + $offset );
        $opt->dset_nbins( $opt->dset_nbins - 2 * $offset );
    }

    my $dset = DataSet->new(
        nbins => $opt->dset_nbins,
        nelem => $opt->dset_nelem,
        imin  => $opt->dset_imin,
    );

    my $stats = DataStats->new(
        dset   => $dset,
        nalloc => $opt->stats_nalloc // $opt->dset_nbins,
        nbins  => $opt->stats_nbins,
        imin   => $opt->stats_imin,
    );

    if ( $opt->has( 'oob' ) ) {
        my $oob = wrap_hash( {} );

        $oob->{type}  = $opt->oob;
        $oob->{imin}  = $stats->imin + 2;
        $oob->{imax}  = $stats->imax - 3;
        $oob->{nbins} = $oob->imax - $oob->imin + 1;

        my @part;

        for my $bounds (
            [ $stats->imin,   $oob->imin - 1, 1 ],
            [ $oob->imin,     $oob->imax,     0 ],
            [ $oob->imax + 1, $stats->imax,   1 ] )
        {
            my ( $imin, $imax, $zero_index ) = @$bounds;

            my $mask = ( $dset->index >= $imin ) & ( $dset->index <= $imax );

            my ( $data, $weight ) = PDL::where( $dset->data, $dset->weight, $mask );
            my $index
              = $zero_index
              ? PDL->zeroes( PDL::indx, $data->nelem )
              : PDL::where( $dset->index, $mask );

            push @part,
              DataStats->new(
                dset => DataSet->new(
                    data   => $data,
                    weight => $weight,
                    index  => $index,
                    nelem  => $data->nelem,
                ) );
        }

        $stats = DataStats::OOB->new(
            oob    => $oob,
            nalloc => $stats->nalloc,
            low    => $part[0],
            inbnd  => $part[1],
            high   => $part[2],
        );
    }

    return Container1D->new( dset => $dset, stats => $stats, idx => $opt->idx );
}


sub mk_nD_dataset {

    my $opt = wrap_hash { @_ };

    my @shape = @{ $opt->shape };

    my @oneD;

    product {
        my ( @idx ) = @_;
        push @oneD, mk_1D_dataset( %$opt, idx => \@idx );
    }
    map { [ 0 .. $_ - 1 ] } @shape;

    my $nalloc = List::Util::max map { $_->stats->nbins } @oneD;

    my %finalize = ( stats => { nalloc => $nalloc } );
    $_ = $_->finalize( \%finalize ) foreach @oneD;

    my $template = $oneD[0]->copy;

    my $nD = ContainerND->new( template => $template, extend => \@shape );

    for my $oneD ( @oneD ) {
        $nD->insert_1D( $oneD, @{ $oneD->idx } );
    }

    $nD->finalize;

    return $nD;
}

sub dummy_up {
    my ( $tpl, $pdl ) = @_;

    while ( $pdl->dims < $tpl->dims ) {
        $pdl = $pdl->dummy( -1, ( $tpl->dims )[ 0+ $pdl->dims ] );
    }

    return $pdl;
}

sub _whist {
    # my ( $data, $index, $imin, $nbins, $nalloc ) = @_;
    my $opt = wrap_hash( {
        nalloc => undef,
        @_,
    } );

    $opt->nalloc( $opt->nalloc // $opt->nbins );

    # explicitly set output piddle so get the correct type. add a couple of bins
    # because whistogram puts out-of-bounds data at the ends.
    my $result = PDL->zeroes( PDL::double, $opt->nalloc + 2 );

    my $iuniq = $opt->index->uniq;

    Math::BigFloat->accuracy( 40 );

    my $sum;

    if ( $SLOW_BUT_CORRECT ) {

        ## no critic (BuiltinFunctions::ProhibitComplexMappings)
        $sum = PDL->new(
            map {
                my $idx = $_;
                my $my_sum
                  = reduce { $a + $b } Math::BigFloat->bzero,
                  map { Math::BigFloat->new( $_ ) } $opt->data->where( $opt->index == $idx )->list;
                $my_sum->numify;
            } $iuniq->list,
        );
    }

    else {
        ## no critic (BuiltinFunctions::ProhibitComplexMappings)
        $sum = PDL->new(
            map {
                my $idx = $_;
                my $my_sum
                  = reduce { $a + $b } 0,
                  $opt->data->where( $opt->index == $idx )->list;
            } $iuniq->list,
        );
    }

    $iuniq->double->whistogram(
        $sum, $result->slice( [ 0, $opt->nbins + 1 ] ),
        1,
        $opt->imin - 1,
        $opt->nbins + 2,
    );

    ## no critic( ValuesAndExpressions::ProhibitMismatchedOperators)
    # shouldn't have touched guard bins and anything above $Nbins
    my $untouched = $result->zeroes;
    $untouched->set( 0, 1 );
    $untouched->slice( [ $opt->nbins + 1, $opt->nalloc + 1 ] ) .= 1;

    # first and last elements of $result had better have no data in them!
    #
    die( "internal error: oob bins have data in them when they shouldn't\n" )
      if !PDL::all( ( !$result & $untouched ) == $untouched );

    $result = $result->slice( [ 1, $opt->nalloc ] )->sever;

    return $result;
}


sub test_bin {

    my $opt = wrap_hash( {
        weighted => 0,
        params   => {},
        @_,
    } );

    my $ctx = context();

    eval {

        for my $weighted ( 0, 1 ) {

            my $tcopy = $opt->data->copy;

            my $dset  = $tcopy->dset;
            my $stats = $tcopy->stats;

            my $label = $weighted ? 'weighted' : 'unweighted';

            subtest $label => sub {
                my $bins;

                my %params = (
                    data  => $dset->data,
                    index => $dset->index,

                );

                if ( $opt->weighted ) {
                    $params{weight}           = $dset->weight;
                    $params{want_sum_weight}  = 1;
                    $params{want_sum_weight2} = 1;
                }

                ok(
                    lives {
                        $bins = bin_on_index( %params, %{ $opt->params } );
                    },
                    'create histogram',
                ) or note $@;

              SKIP: {
                    skip 'bad histogram' unless defined $bins;

                    pdl_is( $bins->count, $stats->count, 'number of elements' )
                      or skip 'bad count';

                    $bins->{imin}  = dummy_up( $stats->imin,  $bins->imin );
                    $bins->{nbins} = dummy_up( $stats->nbins, $bins->nbins );

                    pdl_is( $bins->imin,  $stats->imin,  'imin' );
                    pdl_is( $bins->nbins, $stats->nbins, 'nbins' );
                    pdl_is( $bins->dmin,  $stats->dmin,  'dmin' );
                    pdl_is( $bins->dmax,  $stats->dmax,  'dmax' );

                    if ( $opt->weighted ) {

                        pdl_is( $bins->data, $stats->dwsum, 'sum' );
                        pdl_is( $bins->mean, $stats->wmean, 'mean' );

                        pdl_is( $bins->dev2, $stats->wdev2, 'sum of weighted square of deviation' );

                        pdl_is( $bins->weight,  $stats->wtsum,  'weight' );
                        pdl_is( $bins->weight2, $stats->wt2sum, 'weight2' );
                    }

                    else {

                        pdl_is( $bins->data, $stats->dsum, 'sum' );
                        pdl_is( $bins->mean, $stats->mean, 'mean' );

                        pdl_is( $bins->dev2, $stats->dev2, 'sum of square of deviation' );
                    }
                }
            };
        }
    };

    my $error = $@;
    $ctx->release;

    die $error if $error;

    return;
}

sub test_range {

    my $opt = wrap_hash( {
        params => {},
        @_,
    } );

    # copy some piddles for safety
    $opt->$_( $opt->$_->copy ) for grep { $opt->$_->$_isa( 'PDL' ) } qw( imin imax nbins );

    $opt->range( [ $opt->range ] ) unless 'ARRAY' eq ref $opt->range;

    my $ctx = context();

    eval {

        subtest 'range' => sub {

            for my $range ( @{ $opt->range } ) {

                subtest "$range,minmax" => sub {
                    test_bin(
                        data   => $opt->data,
                        params => {
                            range => "$range,minmax",
                            %{ $opt->params },
                        },
                    );
                };

                subtest "$range,min; nbins" => sub {
                    test_bin(
                        data   => $opt->data,
                        params => {
                            range => "$range,min",
                            nbins => $opt->nbins,
                            %{ $opt->params },
                        },
                    );
                };

                subtest "$range,min; imax" => sub {
                    test_bin(
                        data   => $opt->data,
                        params => {
                            range => "$range,min",
                            imax  => $opt->imax,
                            %{ $opt->params },
                        },
                    );
                };

                subtest "$range,max; nbins" => sub {
                    test_bin(
                        data   => $opt->data,
                        params => {
                            range => "$range,max",
                            nbins => $opt->nbins,
                            %{ $opt->params },
                        },
                    );
                };

                subtest "$range,max; imin" => sub {
                    test_bin(
                        data   => $opt->data,
                        params => {
                            range => "$range,max",
                            imin  => $opt->imin,
                            %{ $opt->params },
                        },
                    );
                };

            }
        };

    };

    my $error = $@;
    $ctx->release;

    die $error if $error;

    return;
}

# create a regular set of stats which have the same imin and number of bins.
subtest 'regular' => sub {

    my $nbins = 19;
    my $imin  = -9;
    my $imax  = $imin + $nbins - 1;

    my %mk_pars = (
        shape      => [ 2, 3 ],
        dset_imin  => $imin,
        dset_nbins => $nbins,

        # force 1D stats to have same number of bins and imin
        stats_imin  => $imin,
        stats_nbins => $nbins,

    );

    subtest 'in-bounds' => sub {

        my $tdata = mk_nD_dataset( %mk_pars );

        subtest 'nbins, imin' => sub {

            test_bin(
                data   => $tdata,
                params => {
                    nbins => $nbins,
                    imin  => $imin,
                },
            );

        };

        test_range(
            data  => $tdata,
            nbins => $nbins,
            imin  => $imin,
            imax  => $tdata->stats->imax,
            # range=slice and range=flat are the same for this dataset.
            range => [ 'slice', 'flat' ],
        );
    };


    subtest 'out-of-bounds' => sub {

        my @oob_types = qw(
          start-end
          end
          nbins
          start-nbins
        );

        for my $oob_type ( @oob_types ) {

            subtest $oob_type => sub {

                my $oob_imin  = $imin + 2;
                my $oob_imax  = $imax - 3;
                my $oob_nbins = $oob_imax - $oob_imin + 1;

                my $tdata = mk_nD_dataset(
                    %mk_pars,
                    oob      => $oob_type,
                    oob_imin => $imin + 2,
                    oob_imax => $imax - 3,
                );

                test_bin(
                    data   => $tdata,
                    params => {
                        imin  => $oob_imin,
                        nbins => $oob_nbins,
                        oob   => $oob_type,
                    },
                );

            };

        }

    };

};

# this generates 1D data sets which have different nbins and imin
subtest 'subset' => sub {

    my $nbins = 50;
    my $imin  = -9;

    my %mk_pars = (
        shape        => [ 2, 3 ],
        dset_imin    => $imin,
        dset_nbins   => $nbins,
        stats_nalloc => $nbins,
        subset       => 1,
    );

    subtest 'in-bounds' => sub {

        my $tdata = mk_nD_dataset( %mk_pars );


        # first, force nbins
        subtest 'nbins, imin' => sub {

            test_bin(
                data   => $tdata,
                params => {
                    nbins => $tdata->stats->nbins,
                    imin  => $tdata->stats->imin,
                },
            );
        };

        # now, let the range be dynamically determined
        test_range(
            data  => $tdata,
            nbins => $tdata->stats->nbins,
            imin  => $tdata->stats->imin,
            imax  => $tdata->stats->imax,
            range => 'slice',                # flat doesn't make sense for this comparison
        );

    };

    subtest 'out-of-bounds' => sub {

        my @oob_types = qw(
          end
          nbins
          start-nbins
          start-end
        );

        for my $oob_type ( @oob_types ) {

            subtest $oob_type => sub {

                # create a regular set of stats which have the same imin and number of bins.
                my $tdata = mk_nD_dataset( %mk_pars, oob => $oob_type, );

                my $stats = $tdata->stats;
                my $oob   = $tdata->stats->oob;
                test_bin(
                    data   => $tdata,
                    params => {
                        imin  => $stats->oob_imin,
                        nbins => $stats->oob_nbins,
                        oob   => $oob->type,
                    },
                );
            };
        }
    };
};

done_testing;

