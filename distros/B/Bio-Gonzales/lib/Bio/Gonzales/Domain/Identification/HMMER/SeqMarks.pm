package Bio::Gonzales::Util::FunCon::Domains::Identification::HMMER::SeqMarks;

use Mouse;

use warnings;
use strict;
use Carp;
use List::MoreUtils;
use POSIX;
use Data::Dumper;

use 5.010;
our $VERSION = '0.0546'; # VERSION

# hat gruppen, die wiederum koordinaten haben
has marks => ( is => 'rw', lazy_build => 1, writer => '_write_marks' );
has num_marks => ( is => 'ro', required => 1 );
has mark_names => ( is => 'rw' );
has _extension => ( is => 'rw', lazy_build => 1 );
has boundaries => ( is => 'rw', lazy_build => 1 );

sub _build__extension {
    return [ 0, 0 ];
}

sub _build_boundaries {
    return [ INT_MIN, INT_MAX ];
}

sub _build_marks {
    my ($self) = @_;

    my @marks;
    for ( my $i = 0; $i < $self->num_marks; $i++ ) {
        $marks[$i] = { from => INT_MAX, to => INT_MIN }

    }

    return \@marks;
}

around 'marks' => sub {
    my $orig = shift;
    my $self = shift;

    if ( $self->_has_extension && !@_ ) {
        return [
            map {
                {
                    $self->_calc_ext_bound( $_->{from}, $_->{to} ), hit => $_->{hit}
                }
                } @{ $self->$orig() }
        ];
    } elsif ( $self->has_boundaries && !@_ ) {
        return [
            map {
                my ( $f, $t ) = $self->_to_boundaries( $_->{from}, $_->{to} );
                { from => $f, to => $t, hit => $_->{hit} }
                } @{ $self->$orig() }
        ];
    }
    return $self->$orig()
        unless @_;

    return $self->$orig(@_);

};

sub _calc_ext_bound {
    my ( $self, $from, $to ) = @_;

    my $new_from = $from - $self->_extension->[0];
    my $new_to   = $to + $self->_extension->[1];

    ( $new_from, $new_to ) = $self->_to_boundaries( $new_from, $new_to )
        if ( $self->has_boundaries );

    return ( from => $new_from, to => $new_to );
}

sub inverted_marks {
    my ($self) = @_;

    croak "no boundaries set"
        unless ( $self->has_boundaries );

    my @marks = sort { $a->{from} <=> $b->{from} } @{ $self->marks };

    my @imarks;
    push @imarks, shift @marks;

    #merge intervals
    for my $m (@marks) {
        if ( $imarks[-1]->{to} > $m->{from} ) {
            $imarks[-1]->{to} = $m->{to}
                if ( $m->{to} > $imarks[-1]->{to} );
        } else {
            push @imarks, $m;
        }
    }

    #invert
    my $start = $self->boundaries->[0] - 1;
    my @iimarks;
    for my $m (@imarks) {
        next if($start == $m->{from});
        push @iimarks, { from => $start + 1, to => $m->{from} - 1, hit => 1 }
            unless ( $m->{from} == $start + 1 );
        $start = $m->{to};
    }

    push @iimarks, { from => $start + 1, to => $self->boundaries->[1], hit => 1 }
        unless ( $start == $self->boundaries->[1] );

    return \@iimarks;
}

sub _to_boundaries {
    my ( $self, $from, $to ) = @_;

    $to = $self->boundaries->[1]
        if ( $to > $self->boundaries->[1] || $from > $to );

    $from = $self->boundaries->[0]
        if ( $from < $self->boundaries->[0] || $from > $to );

    return ( $from, $to );
}

around 'mark_names' => sub {
    my $orig = shift;
    my $self = shift;

    if ( @_ > 0 ) {
        my ($names) = @_;

        croak 'mark names not equal to number of marks'
            if ( @{$names} != $self->num_marks );
        my %names;
        for ( my $i = 0; $i < @{$names}; $i++ ) {
            $names{ $names->[$i] } = $i;
        }
        return $self->$orig( \%names );
    } else {
        return $self->$orig;
    }
};

sub update_mark {
    my ( $self, $mark, $from, $to ) = @_;

    $mark = $self->mark_from_name($mark)
        unless ( $mark =~ /^\d+$/ );

    $self->marks->[$mark]->{from} = $from
        if ( $self->marks->[$mark] > $from );

    $self->marks->[$mark]->{to} = $to
        if ( $self->marks->[$mark]->{to} < $to );
    $self->marks->[$mark]->{hit} = 1;
}

sub num_marks_hit {
    my ($self) = @_;

    return scalar grep { exists $_->{hit} } @{ $self->marks };
}

sub hit_in_every_mark {
    my ($self) = @_;

    return $self->num_marks_hit == $self->num_marks;
}

sub clear_extend {
    my ($self) = @_;
    $self->_clear_extension;
}

sub extend {
    my ( $self, $left, $right ) = @_;

    croak 'you have to supply parameters'
        unless ($left);
    $right = $left
        unless ($right);

    $self->_extension( [ $left, $right ] );
    return $self;
}

sub reset_extend {
    my ($self) = @_;

    $self->_clearer_extension;

    return $self;
}

sub spanning_region {
    my ($self) = @_;

    my ( $min, $max ) = ( INT_MAX, INT_MIN );

    for my $m ( @{ $self->marks } ) {
        $min = $m->{from}
            if ( $m->{from} < $min );

        $max = $m->{to}
            if ( $m->{to} > $max );
    }

    #$min -= $self->_extension->[0];
    #$max += $self->_extension->[1];

    return { from => $min, to => $max };
}

sub mark_from_name {
    my ( $self, $mark_name ) = @_;

    croak "there is no mark with name >>$mark_name<<"
        unless ( exists $self->mark_names->{$mark_name} );
    return $self->mark_names->{$mark_name};
}

1;
