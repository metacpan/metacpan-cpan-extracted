package Data::Frame::PDL;

# ABSTRACT: A mixin to add some methods to PDL

use 5.016;
use warnings;

use Role::Tiny;

use List::AllUtils qw(pairmap);
use PDL::Core qw(pdl);
use PDL::Primitive qw(which);
use POSIX qw(ceil);
use Safe::Isa;


sub length { $_[0]->dim(0); }


sub diff {
    my ( $self, $lag ) = @_;
    $lag //= 1;

    my $idx = PDL->sequence( $self->length - $lag );
    return $self->slice( $idx + $lag ) - $self->slice($idx);
}


sub flatten { @{ $_[0]->unpdl }; }

sub flatten_deep { $_[0]->list; }


sub repeat {
    my ( $self, $n ) = @_;
    if ( $self->length == 0 or $n <= 1 ) {
        my $p = $self->copy;

        # Make sure we return a piddle of at least 1D. 
        $p->reshape(1) if ($self->ndims == 0);
        return $p;
    }

    my $class = ref($self);

    state $repeat = sub {
        my ($p, $n) = @_;
        
        my $data = [
            (
                $p->badflag
                ? ( map { $_ eq 'BAD' ? 0 : $_ } @{ $p->unpdl } )
                : ( @{ $p->unpdl } )
            ) x $n
        ];
        return $class->new($data);
    };

    my $p;
    if ( $self->$_DOES('PDL::SV') ) {
        $p = $class->new( [ ( @{ $self->unpdl } ) x $n ] );
    }
    elsif ( $self->$_DOES('PDL::Factor') ) {
        $p = $class->new( $self, levels => $self->levels );
        $p->{PDL} = $repeat->( $p->{PDL}, $n );
    }
    else {
        $p = $repeat->($self, $n);
    }

    if ( $self->badflag ) {
        $p = $p->setbadif( PDL::Core::pdl( [ ( $self->isbad->list ) x $n ] ) );
    }
    return $p;
}

sub repeat_to_length {
    my ( $self, $length ) = @_;
    return $self->copy if ( $self->length == 0 );

    my $x = $self->repeat( ceil( $length / $self->length ) );
    return ( $x->length == $length ? $x : $x->slice( "0:" . ( $length - 1 ) ) );
}

sub as_pdlsv {
    my ($self) = @_;

    my $new_pdlsv = sub {
        my ($x) = @_;
        my $new = PDL::SV->new($x);
        if ($self->badflag) {
            $new = $new->setbadif($self->isbad);
        }
        return $new;
    };

    if ($self->$_DOES('PDL::Factor')) {
        my $levels = $self->levels;
        my $is_bad = $self->badflag ? $self->isbad : undef;
        my @x = map {
            ( defined $is_bad and $is_bad->at($_) )
              ? 'BAD' 
              : $levels->[ $self->at($_) ];
        } ( 0 .. $self->length - 1 );
        return $new_pdlsv->(\@x);
    }
    elsif ($self->$_DOES('PDL::DateTime')) {
        return $new_pdlsv->($self->dt_unpdl);
    }
    else {
        return $self->copy;
    }
}


sub id {
    my ($self) = @_;

    my %uniq_values;    # value to row indices
    my @uniq_indices;   # first index for each set of uniq values
    for my $ridx ( which($self->isgood)->list ) {
        my $value = $self->at($ridx);
        if ( not exists $uniq_values{$value} ) {
            $uniq_values{$value} = [];
            push @uniq_indices, $ridx;
        }
        push @{ $uniq_values{$value} }, $ridx;
    }    

    my %index_to_value = pairmap { $b->[0] => $a } %uniq_values;

    my $rslt = PDL::Core::zeros( $self->length );
    $rslt .= -1;    # for BAD values
    for my $i ( 0 .. $#uniq_indices ) {
        my $value =
          $index_to_value{ $uniq_indices[ $i ] }; 
        my $indices = $uniq_values{$value};
        $rslt->slice( pdl($indices) ) .= $i;
    }
    return $rslt;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Frame::PDL - A mixin to add some methods to PDL

=head1 VERSION

version 0.0053

=head1 DESCRIPTION

This module provides a role that can add a few methods to the PDL class.

It's an internal module used by the Data::Frame library to add a few methods
to the PDL class. Do not directly use this module in your code, as the
module name may change in future.

=head1 METHODS

=head2 length

    length()

Returns the length of the first dimension.

=head2 diff

    length($lag=1)

=head2 flatten

    flatten()

This is same as C<@{$self-E<gt>unpdl}>.

=head2 flatten_deep

    flatten_deep()

This is same as C<list()>.

=head2 repeat

    repeat($n)

Repeat on the first dimension for C<$n> times.

Only works with 1D piddle.  

=head2 repeat_to_length

    repeat_to_length($length)

Repeat to have the given length.

Only works with 1D piddle.  

=head2 id

    id()

Compute a unique numeric id for each element in a piddle.

=head1 SEE ALSO

L<PDL>

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
