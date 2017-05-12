package Data::Lotter;

use base qw( Class::Accessor::Fast );
use strict;
use warnings;
use Data::Dumper;
use constant DEBUG => $ENV{DATA_LOTTER_DEBUG};
use 5.8.1;

our $VERSION = '0.00004';

__PACKAGE__->mk_accessors(qw(lists available ));

*debug = DEBUG
  ? sub {
    my $mess = shift;
    print STDERR $mess, "\n";
  }
  : sub { };

sub new {
    my $class = shift;
    my %lists = @_;

    _scale_up(\%lists);

    my $cumulative = 0;
    foreach my $weight ( values %lists ) {
        $weight = int($weight);
        $cumulative += $weight;
    }

    return $class->SUPER::new( { available => $cumulative, lists => \%lists } );
}

sub _scale_up{
    my $lists_ref = shift;

    my ($i,$j);
    while ( my ( $key, $value ) = each %$lists_ref ) {
        $value =~ /\.(\d+)/;
        $1 and $i = length $1;
        if( !$j or $i > $j ){
            $j = $i;
        }
    }
    if($j){
        $j = 6 if $j > 6;
        my $scale = 10 ** $j;
        if($scale > 1){
            for(keys(%$lists_ref)){
                $lists_ref->{$_} *= $scale;
            }
        }
    }
}

sub pickup {
    my $self   = shift;
    my $num    = shift;
    my $remove = shift || '';
    my @ret;

    my $lists = $self->lists;
  OUTER:
    while ( $num-- ) {

        Dumper $lists; 
        # mysterious hack
        # If there is not this, I can't pass the test code. 

        my $n = int( rand( $self->available ) ) + 1;
        debug("-----------------------");
        debug("NUM: $num");
        debug("RANDOM: $n");
        debug( "BEFORE: " . Dumper($lists) );
        while ( my ( $item, $weight ) = each %$lists ) {
            if ( $weight > 0 && $weight >= $n ) {
                push @ret, $item;
                debug("HIT: $item");
                if ($remove) {
                    delete $lists->{$item};
                    $self->available( $self->available - $weight );
                }
                else {
                    $lists->{$item}--;
                    $self->available( $self->available - 1 );
                }
                debug( "AFTER: " . Dumper($lists) );
                next OUTER;
            }
            $n -= $weight;
        }
    }
    debug( "RETURN: " . join( ",", @ret ) );
    return @ret;
}

sub left_items {
    my $self  = shift;
    my @items = keys %{ $self->lists };
    return @items;
}

sub left_item_waits {
    my $self = shift;
    my $item = shift;
    return $self->lists->{$item};
}

1;

__END__


=head1 NAME

Data::Lotter - Data lottery module by its own weight

=head1 SYNOPSIS

  use Data::Lotter;

  # prepare a HASH data 
  my %candidates = (
    red    => 10,
    green  => 10,
    blue   => 10,
    yellow => 10,
    white  => 10, 
  );

  my $lotter = Data::Lotter->new(%candidates);

  # normal pickup 
  my $ret = $lotter->pickup(3);
  # ex. ( red, green, yellow ) = @ret

  # removal pickup ( => %candidates will be left 4 items )
  my @ret = $lotter->pickup(1, "REMOVE");
  
=head1 DESCRIPTION

Data::Lotter is data lottery module.
It provides both pattern such as the lottery and the election.


=head1 METHODS

=head2 new()

=head2 pickup()

=head2 left_items()

=head2 left_item_waits()

=head2 debug()

=head1 AUTHOR

Takeshi Miki E<lt>miki@cpan.orgE<gt>

Original idea was spawned by KANEGON

Special thanks to Daisuke Maki

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
