# Copyright 2008, 2009, 2010, 2011, 2016 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Series::TA;
use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Locale::TextDomain ('App-Chart');

use base 'App::Chart::Series';

use Finance::TA;

# uncomment this to run the ### lines
#use Devel::Comments;

sub manual {
  my ($series) = @_;
  if (! $series) { return; }
  my $fi = $series->{'fi'};
  return "http://tadoc.org/indicator/$fi->{'name'}.htm";
}

sub parameter_info {
  my ($series) = @_;
  my $fi = $series->{'fi'};
  return [ map {
    my $i = $_;
    my ($retcode, $info);
    ($retcode = TA_GetOptInputParameterInfo ($fi, $i, \$info)) == $TA_SUCCESS
      or croak "Oops, cannot TA_GetOptInputParameterInfo $i: ",_retcode_str($retcode);

    { name => $info->{'displayName'},
        key  => $info->{'paramName'},
          # type => 'integer',
          # minimum  => 1
      }
  } (0 .. $fi->{'nbOptInput'}-1)
         ];
}

sub new {
  my ($class, $type, $parent, @args) = @_;
  ### TA new() ...
  ### $type
  ### parent: "$parent"

  my ($retcode, $fh, $fi);
  ($retcode = TA_GetFuncHandle ($type, \$fh)) == $TA_SUCCESS
    or croak "Cannot get TA function '$type': ",_retcode_str($retcode);
  ($retcode = TA_GetFuncInfo ($fh, \$fi)) == $TA_SUCCESS
    or croak "Cannot TA_GetFuncInfo for '$type': ",_retcode_str($retcode);
  ### FuncInfo hint: $fi->{'hint'}

  my $self = $class->SUPER::new (parent => $parent,
                                 fi     => $fi,
                                 args   => \@args);

  my $funcname = 'TA_' . $fi->{'name'};
  $self->{'func'} = Finance::TA->can($funcname)
    || croak "Oops, '$funcname' not found";

  {
    my $lookbackname = "${funcname}_Lookback";
    my $lookbackfunc = Finance::TA->can($lookbackname)
      || croak "Oops, function $lookbackname not found";
    my @lookbackargs = map {
      my $i = $_;
      $args[$i] // do {
        my $info;
        ($retcode = TA_GetOptInputParameterInfo ($fh, $i, \$info)) == $TA_SUCCESS
          or croak "Oops, cannot TA_GetOptInputParameterInfo '$type' $i: ",_retcode_str($retcode);
        $info->{'defaultValue'}
      } } (0 .. $fi->{'nbOptInput'}-1);
    $self->{'parameters'} = \@lookbackargs;
    ### @lookbackargs
    my $lookback = $self->{'lookback'} = $lookbackfunc->(@lookbackargs);
    ### $lookback
  }

  {
    my $info;
    ($retcode = TA_GetInputParameterInfo ($fh, 0, \$info)) == $TA_SUCCESS
      or croak "Oops, cannot TA_GetInputParameterInfo '$type' 0: ",_retcode_str($retcode);
    my $inname = $info->{'paramName'};
    ### input paramName: $inname
    my @inarrays = input_paramName_to_arrays($inname);
    ### @inarrays
    $self->{'inarrays'} = [ map {$parent->array($_)} @inarrays ];
  }

  {
    my $nbOutput = $fi->{'nbOutput'};
    ### $nbOutput
    my @outarrays;
    $self->{'outarrays'} = \@outarrays;
    my $arrays = $self->{'arrays'} = {};
    my $first_outname;
    foreach my $i (0 .. $nbOutput-1) {
      my $info;
      ($retcode = TA_GetOutputParameterInfo ($fh, $i, \$info)) == $TA_SUCCESS
        or croak "Oops, cannot TA_GetOutputParameterInfo '$type' $i: ",_retcode_str($retcode);
      my $outname = $info->{'paramName'};
      ### $outname
      $arrays->{$outname} = $outarrays[$i] = [];
      $first_outname //= $outname;
    }
    if (exists $arrays->{'outRealMiddleBand'}) {
      # hack to prefer middle line of TA_BBANDS
      $first_outname = 'outRealMiddleBand';
    }
    $self->{'array_aliases'} = { values => $first_outname };
  }

  return $self;
}

sub name {
  my ($self) = @_;
  my $name = $self->{'fi'}->{'hint'};

  my $parameters = join (__p('separator',',') . ' ',
                         @{$self->{'parameters'}});
  $name = join (' ', $name, $parameters);

  my $parent_name = $self->parent->name;
  if (defined $parent_name) {
    $name = join (' - ', $parent_name, $name);
  }
  return $name;
}

sub fill_part {
  my ($self, $lo, $hi) = @_;
  my $parent = $self->{'parent'};
  my $start = $parent->find_before ($lo, $self->{'lookback'});
  $parent->fill ($start, $hi);

  my $inarrays = $self->{'inarrays'};
  my $values = $parent->values_array;
  my $inpart_end = $hi - $start;
  my @inparts = map { my @x; $#x = $inpart_end; \@x } @$inarrays;
  my $inend = $#$inarrays;
  my @inmap; $#inmap = $inpart_end;
  my $inmap_lo_pos;
  my $upto = 0;
  foreach my $i ($start .. $hi) {
    $values->[$i] // next;
    foreach my $j (0 .. $inend) {
      $inparts[$j]->[$upto] = $inarrays->[$j]->[$i] // $values->[$i];
    }
    $inmap[$upto] = $i;
    if ($i >= $lo) { $inmap_lo_pos //= $upto; }
    $upto++;
  }
  $#inmap = $upto-1;

  # Crib: as of TA-Lib Jun11 start_idx/end_idx aren't range checked against
  # the actual array size, so bad values like -1 give segvs.
  #
  if (! defined $inmap_lo_pos) {
    ### no input values, nothing to fill ...
    return;
  }

  my $func = $self->{'func'};
  ### $func
  ### start_idx inmap_lo_pos: $inmap_lo_pos
  ### end_idx $#inmap: $#inmap
  ### @inmap
  ### @inparts
  ### args: $self->{'args'}

  my ($retcode, $out_lo, @gotarrays)
    = &$func ($inmap_lo_pos,  # start_idx
              $#inmap,        # end_idx
              @inparts,       # in_array
              @{$self->{'args'}});
  ### $retcode
  ### $out_lo
  $retcode == $TA_SUCCESS
    or croak "TA_$self->{'fi'}->{'name'} error ",_retcode_str($retcode);
  ### @gotarrays

  my $outarrays = $self->{'outarrays'};
  my $outend = $#$outarrays;

  splice @inmap, 0,$out_lo;
  $inmap_lo_pos -= $out_lo;
  ### gotarray for: $inmap[0]
  ### cf lo: $lo
  ### adjusted lopos: $inmap_lo_pos

  $inmap_lo_pos = max (0, $inmap_lo_pos);

  my @src = ($inmap_lo_pos .. $#inmap);
  my @dst = @inmap[@src];
  foreach my $j (0 .. $outend) {
    @{$outarrays->[$j]}[@dst] = @{$gotarrays[$j]}[@src];
  }
}

sub _retcode_str {
  my ($retcode) = @_;
  my $rci = Finance::TA::TA_RetCodeInfo->new ($retcode);
  return "[$rci->{'enumStr'}] $rci->{'infoStr'}";
}

my %inchar_to_array = ('O' => 'opens',
                       'H' => 'highs',
                       'L' => 'lows',
                       'C' => 'closes',
                       'V' => 'volumes');

# $inname like 'inReal' or 'inPriceHLCV' or 'inPriceHLC', coming from
# various TA_InputParameterInfo in ta_def_ui.c
#
sub input_paramName_to_arrays {
  my ($inname) = @_;
  if ($inname eq 'inReal') { return 'values'; }
  if ($inname =~ /^inPrice([OHLCV]+)$/) {
    my $parts = $1;
    return (map {$inchar_to_array{$_}
                   || die "Unrecognised input paramName '$inname'"}
            split //, $parts); # split into individual characters
  }
}

1;
__END__

=head1 NAME

App::Chart::Series::TA -- ...

=for test_synopsis my ($ta_name, $parent)

=head1 SYNOPSIS

 use App::Chart::Series::TA;
 my $series = App::Chart::Series::TA->new ($ta_name, $parent);

=head1 CLASS HIERARCHY

    App::Chart::Series
      App::Chart::Series::TA

=head1 DESCRIPTION

A C<App::Chart::Series::TA> series applies a TA-Lib indicator or average to a
given series.  You must have the TA-Lib C<Finance::TA> module available to
use this, see

=over

L<http://ta-lib.org/>

=back

=head1 FUNCTIONS

=over 4

=item C<< App::Chart::Series::TA->new ($ta_name, $parent) >>

C<$ta_name> is string name per C<TA_GetFuncHandle>, for example C<"SMA"> for
the C<TA_SMA()> function.

=back

=head1 SEE ALSO

L<App::Chart::Series>,
L<Finance::TA>,
L<App::Chart::Series::GT>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/chart/index.html>

=head1 LICENCE

Copyright 2008, 2009, 2010, 2011, 2016 Kevin Ryde

Chart is free software; you can redistribute it and/or modify it under the
terms of the GNU General Public License as published by the Free Software
Foundation; either version 3, or (at your option) any later version.

Chart is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
Chart; see the file F<COPYING>.  Failing that, see
L<http://www.gnu.org/licenses/>.

=cut
