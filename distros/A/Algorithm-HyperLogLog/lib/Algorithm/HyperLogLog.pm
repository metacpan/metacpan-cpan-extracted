package Algorithm::HyperLogLog;
use strict;
use warnings;
use 5.008008;
use Carp qw(croak);

our $VERSION = '0.23';

our $PERL_ONLY;
if ( !defined $PERL_ONLY ) {
    $PERL_ONLY = $ENV{PERL_HLL_PUREPERL} ? 1 : 0;
}

if ( !exists $INC{'Algorithm/HyperLogLog/PP.pm'} ) {
    if ( !$PERL_ONLY ) {
        require XSLoader;
        $PERL_ONLY = !eval { XSLoader::load( __PACKAGE__, $VERSION ); };
    }
    if ($PERL_ONLY) {
        require 'Algorithm/HyperLogLog/PP.pm';
    }
}

sub new_from_file {
    my ( $class, $filename ) = @_;
    open my $fh, '<', $filename or die $!;
    my $on_error = sub { close $fh; croak "Invalid dump file($filename)"; };

    binmode $fh;
    my ( @dumpdata, $buf, $readed );

    # Read register size data
    $readed = read( $fh, $buf, 1 );
    $on_error->() if $readed != 1;
    my $k = unpack 'C', $buf;

    # Read register content data
    my $m = 2**$k;
    $readed = read $fh, $buf, $m;
    $on_error->() if $readed != $m;
    close $fh;
    @dumpdata = unpack 'C*', $buf;
    my $self = $class->_new_from_dump( $k, \@dumpdata );
    return $self;
}

sub dump_to_file {
    my ( $self, $filename ) = @_;
    my $k        = log( $self->register_size ) / log(2);    # Calculate log2(register_size)
    my $dumpdata = $self->_dump_register();
    open my $fh, '>', $filename or die $!;
    binmode $fh;
    my $buf = pack 'C', $k;
    print $fh $buf;
    $buf = pack 'C*', @$dumpdata;
    print $fh $buf;
    close $fh;
}

sub XS {
    !$PERL_ONLY;
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Algorithm::HyperLogLog - Implementation of the HyperLogLog cardinality estimation algorithm

=head1 SYNOPSIS

  use Algorithm::HyperLogLog;
  
  my $hll = Algorithm::HyperLogLog->new(14);
  
  while(<>){
      $hll->add($_);
  }
  
  my $cardinality = $hll->estimate(); # Estimate cardinality
  $hll->dump_to_file('hll_register.dump');# Dumps internal data

Construct object from dumped file.

  use Algorithm::HyperLogLog;
  
  # Restore internal state 
  my $hll = Algorithm::HyperLogLog->new_from_file('hll_register.dump');

=head1 DESCRIPTION

This module is implementation of the HyperLogLog algorithm.

HyperLogLog is an algorithm for estimating the cardinality of a set.

=head1 METHODS

=head2 new($b)

Constructor.

`$b` is the parameter for determining register size. (The register size is 2^$b.)

`$b` must be a integer between 4 and 16.

=head2 new_from_file($filename)

This method constructs object and restore the internal data of object from dumped file(dumped by dump_to_file() method).

=head2 dump_to_file($filename)

This method dumps the internal data of an object to a file.

=head2 add($data)

Adds element to the cardinality estimator.

=head2 estimate()

Returns estimated cardinality value in floating point number.

=head2 merge($other)

Merges the estimate from 'other' into this object, returning the estimate of their union.

=head2 register_size()

Return number of register.(In the XS implementation, this equals size in bytes)

=head2 XS()

If using XS backend, this method return true value.

=head1 SEE ALSO

Philippe Flajolet, Éric Fusy, Olivier Gandouet and Frédéric Meunier. HyperLogLog: the analysis of a near-optimal cardinality estimation algorithm. 2007 Conference on Analysis of Algorithms, DMTCS proc. AH, pp. 127–146, 2007. L<http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf>

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 THANKS TO

MurmurHash3(L<https://github.com/PeterScott/murmur3>)

=over 4

=item Austin Appleby

=item Peter Scott

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
