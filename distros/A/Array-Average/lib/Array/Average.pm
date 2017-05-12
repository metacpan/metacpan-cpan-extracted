package Array::Average;
use strict;
use warnings;
use Scalar::Util qw{reftype};

our $VERSION='0.02';

BEGIN {
  use Exporter ();
  use vars qw(@ISA @EXPORT);
  @ISA    = qw(Exporter);
  @EXPORT = qw(average);
}

=head1 NAME

Array::Average - Calculates the average of the values passed to the function.

=head1 SYNOPSIS

  use Array::Average;
  print average(4,5,6);

=head1 DESCRIPTION

Array::Average is an L<Exporter> which exports exactly one function called average.

=head1 USAGE

  use Array::Average;
  print average(4,5,6);

  use Array::Average qw{};
  print Array::Average::average(4,5,6);

=head1 FUNCTIONS

=head2 average

Returns the average of all defined scalars and objects which overload "+".

  my $average=average(1,2,3);
  my $average=average([1,2,3]);
  my $average=average({a=>1,b=>2,c=>3}); #only values not keys

=cut

sub average {
  my @data=_flatten(@_);
  if (@data) {
    my $sum=0;
    $sum+=$_ foreach @data;
    return $sum/scalar(@data);
  } else {
    return undef;
  }

  sub _flatten {
    if (@_ == 0) {
      return @_;
    } elsif (@_ == 1)  {
      my $val=shift;
      if (!defined $val) {
        return ();
      } elsif (!defined reftype($val)) {
        return $val;
      } elsif (reftype($val) eq "HASH") {
        return _flatten(values %{$val});
      } elsif (reftype($val) eq "ARRAY") {
        return _flatten(@{$val});
      } elsif (reftype($val) eq "SCALAR") {
        return _flatten(${$val});
      } else {
        return $val;
      }
    } else {
      return _flatten(shift), _flatten(@_);
    }
  }
}

=head1 BUGS

Please log on RT and send an email to the author.

=head1 SUPPORT

DavisNetworks.com supports all Perl applications including this package.

=head1 AUTHOR

  Michael R. Davis
  CPAN ID: MRDVT
  Satellite Tracking of People, LLC
  mdavis@stopllc.com
  http://www.stopllc.com/

=head1 COPYRIGHT

This program is free software licensed under the...

  The BSD License

The full text of the license can be found in the LICENSE file included with this module.

=head1 SEE ALSO

L<Data::Average>

=cut

1;
