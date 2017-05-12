# Copyright 2009 Kevin Ryde

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

package App::Chart::IndicatorInfo;
use 5.010;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');

use constant DEBUG => 0;

sub new {
  my ($class, $key) = @_;
  if (DEBUG) { say "IndicatorInfo $key"; }
  if ($key && $key =~ /^(GT|TA)_/p) {
    $key = ${^POSTMATCH};
    $class = "App::Chart::IndicatorInfo::$1";
  }
  if ($key && $key eq 'None') {
    $key = undef;
  }
  return bless { key => $key }, $class;
}

sub manual {
  my ($self) = @_;
  my $func = $self->module_func('manual') || return undef;
  return $func->();
}
sub parameter_info {
  my ($self) = @_;
  my $func = $self->module_func('parameter_info') || return [];
  return $func->();
}

sub module_func {
  my ($self, $funcname) = @_;
  my $module = $self->module_load || return;
  return $module->can($funcname);
}
my %warned;
sub module_load {
  my ($self) = @_;
  my $module = $self->module;
  require Module::Load;
  if (! eval { Module::Load::load($module); 1 }) {
    print "module_load(): Cannot load $module\n";
    $warned{$module} ||= do { warn "Cannot load $module: $@"; 1 };
    return undef;
  }
  return $module;
}
sub module {
  my ($self) = @_;
  return ($self->{'key'} && "App::Chart::Series::Derived::$self->{'key'}");
}

#------------------------------------------------------------------------------
package App::Chart::IndicatorInfo::GT;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');
our @ISA = ('App::Chart::IndicatorInfo');

# ENHANCE-ME: @DEFAULT_ARGS shows when OHLCV needed ...

use constant manual => __p('manual-node','Other Indicator Packages');

sub parameter_info {
  my ($self) = @_;
  my $module = $self->module_load || return;
  my @default_args = do { no strict 'refs'; @{"${module}::DEFAULT_ARGS"} };
  my @ret;
  foreach my $arg (@default_args) {
    if (Scalar::Util::looks_like_number ($arg)) {
      my $i = @ret;
      push @ret, { name    => "Arg$i",
                   key     => "GT-arg$i",
                   default => $default_args[$i],
                 };
    }
  }
  return \@ret;
}

sub module {
  my ($self) = @_;
  return 'GT::Indicators::' . $self->{'key'};
}

#------------------------------------------------------------------------------
package App::Chart::IndicatorInfo::TA;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');
our @ISA = ('App::Chart::IndicatorInfo');

use constant DEBUG => 0;

use constant { manual => __p('manual-node','Other Indicator Packages'),
               module => 'Finance::TA',
             };

sub parameter_info {
  my ($self) = @_;
  $self->module_load || return [];
  my @ret;

  my $func = $self->{'key'};
  my ($fh, $fi) = _funcbits ($self);
  foreach my $i (0 .. $fi->{'nbOptInput'} - 1) {
    my ($info, $retcode);
    ($retcode = Finance::TA::TA_GetOptInputParameterInfo ($fh, $i, \$info))
      == $Finance::TA::TA_SUCCESS
        or die "Function $func parameter $i ",_retcode_str ($retcode);

    my $elem = { key     => "TA_${func}_$info->{'paramName'}",
                 name    => $info->{'displayName'},
                 default => $info->{'defaultValue'},
                 type    => 'integer',
               };
    push @ret, $elem;

    my $dataset = $info->{'dataSet'};
    if (DEBUG) { say "dataSet $dataset"; }

    if ($info->{'type'} == $Finance::TA::TA_OptInput_RealRange) {
      $elem->{'type'} = 'float';
    }

    # TA_IntegerRange and TA_RealRange
    {
      ## no critic (RequireCheckingReturnValueOfEval)
      eval {
        $elem->{'minimum'} = $dataset->{'min'};
      };
      eval {
        # dummy 100_000 for no maximum
        if ((my $max = $dataset->{'max'}) != 100_000) {
          $elem->{'maximum'} = $max;
        }
      };
      # TA_RealRange
      eval {
        $elem->{'decimals'} = $dataset->{'precision'};
      };
    }

    # TA_RealRange and TA_IntegerRange 'suggested_increment',
    # 'suggested_start', 'suggested_end' are meant for mechanical searching
    # rather than user controls ...

    # TA_OPTIN_IS_PERCENT
    # TA_OPTIN_IS_DEGREE   angle
    # TA_OPTIN_IS_CURRENCY
    # TA_OPTIN_ADVANCED
  }
  return \@ret;
}

sub _funcbits {
  my ($self) = @_;
  my ($fh, $fi, $retcode);
  ($retcode = Finance::TA::TA_GetFuncHandle ($self->{'key'}, \$fh))
    == $Finance::TA::TA_SUCCESS
      or die "FuncHandle $self->{'key'} ",_retcode_str ($retcode);

  ($retcode = Finance::TA::TA_GetFuncInfo ($fh, \$fi))
    == $Finance::TA::TA_SUCCESS
      or die "FuncInfo $self->{'key'} ",_retcode_str ($retcode);

  return ($fh, $fi);
}
sub _retcode_str {
  my ($retcode) = @_;
  my $rci = Finance::TA::TA_RetCodeInfo->new ($retcode);
  return "[$rci->{'enumStr'}] $rci->{'infoStr'}";
}

#------------------------------------------------------------------------------
package App::Chart::IndicatorInfo::Undef;
use strict;
use warnings;

use constant
  { manual => undef,
    parameter_info => [],
  };

1;
__END__
