package Class::Date::Rel;
use strict;
use warnings;

use vars qw(@NEW_FROM_SCALAR);
use Class::Date::Const;
use Scalar::Util qw(blessed);

our $VERSION = '1.1.15';

use constant SEC_PER_MONTH => 2_629_744;

# see the ClassDateRel const in package Class::Date
use constant ClassDate => "Class::Date";

use overload 
  '0+'     => "sec",
  '""'     => "sec",
  '<=>'    => "compare",
  'cmp'    => "compare",
  '+'      => "add",
  'neg'    => "neg",
  fallback => 1;
                
sub new { my ($proto,$val)=@_;
  my $class = ref($proto) || $proto;
  return undef if !defined $val;
  if (blessed($val) && $val->isa( __PACKAGE__ )) {
    return $class->new_copy($val);
  } elsif (ref($val) eq 'ARRAY') {
    return $class->new_from_array($val);
  } elsif (ref($val) eq 'HASH') {
    return $class->new_from_hash($val);
  } elsif (ref($val) eq 'SCALAR') {
    return $class->new_from_scalar($$val);
  } else {
    return $class->new_from_scalar($val);
  };
}

sub new_copy { my ($s,$val)=@_;
  return bless([@$val], ref($s)||$s);
}

sub new_from_array { my ($s,$val) = @_;
  my ($y,$m,$d,$hh,$mm,$ss) = @$val;
  return bless([ ($y || 0) * 12 + $m , ($ss || 0) + 
    60*(($mm || 0) + 60*(($hh || 0) + 24* ($d || 0))) ], ref($s)||$s);
}

sub new_from_hash { my ($s,$val) = @_;
  $s->new_from_array(Class::Date::_array_from_hash($val));
}

sub new_from_scalar { my ($s,$val)=@_;
  for (my $i=0;$i<@NEW_FROM_SCALAR;$i++) {
    my $ret=$NEW_FROM_SCALAR[$i]->($s,$val);
    return $ret if defined $ret;
  }
  return undef;
}

sub new_from_scalar_internal { my ($s,$val)=@_;
  return undef if !defined $val;
  return bless([0,$1],ref($s) || $s) 
    if $val =~ / ^ \s* ( \-? \d+ ( \. \d* )? ) \s* $/x;

  if ($val =~ m{ ^\s* ( \d{1,4} ) - ( \d\d? ) - ( \d\d? ) 
      ( \s+ ( \d\d? ) : ( \d\d? ) ( : ( \d\d? )? (\.\d+)? )?  )? }x ) {
    # ISO date
    my ($y,$m,$d,$hh,$mm,$ss)=($1,$2,$3,$5,$6,$8);
    return $s->new_from_array([$y,$m,$d,$hh,$mm,$ss]);
  }

  my ($y,$m,$d,$hh,$mm,$ss)=(0,0,0,0,0,0);
  $val =~ s{ \G \s* ( \-? \d+) \s* (Y|M|D|h|m|s) }{
    my ($num,$cmd)=($1,$2);
    if ($cmd eq 'Y') {
      $y=$num;
    } elsif ($cmd eq 'M') {
      $m=$num;
    } elsif ($cmd eq 'D') {
      $d=$num;
    } elsif ($cmd eq 'h') {
      $hh=$num;
    } elsif ($cmd eq 'm') {
      $mm=$num;
    } elsif ($cmd eq 's') {
      $ss=$num;
    }
    "";
  }gexi;
  return $s->new_from_array([$y,$m,$d,$hh,$mm,$ss]);
}

push @NEW_FROM_SCALAR,\&new_from_scalar_internal;

sub compare { my ($s,$val2,$reverse) = @_;
  my $rev_multiply=$reverse ? -1 : 1;
  if (blessed($val2) && $val2->isa( __PACKAGE__ )) {
    return ($s->sec <=> $val2->sec) * $rev_multiply;
  } else {
    my $date_obj=$s->new($val2);
    return ($s->sec <=> 0) * $rev_multiply if !defined $date_obj;
    return ($s->sec <=> $date_obj->sec) * $rev_multiply;
  }
}

sub add { my ($s,$val2)=@_;
  if (my $reldate=$s->new($val2)) {
    my $months=$s->[cs_mon] + $reldate->[cs_mon];
    my $secs  =$s->[cs_sec] + $reldate->[cs_sec];
    return $s->new_from_hash({ month => $months, sec => $secs }) if $months;
    return $secs;
  } else {
    return $s;
  }
}

sub neg { my ($s)=@_;
  return $s->new_from_hash({
      month => -$s->[cs_mon],
      sec   => -$s->[cs_sec]
  });
}

sub year     { shift->sec / (SEC_PER_MONTH*12) }
sub mon      { shift->sec / SEC_PER_MONTH }
*month       = *mon;
sub day      { shift->sec / (60*60*24) }
sub hour     { shift->sec / (60*60)  }
sub min      { shift->sec / 60  }
*minute      = *min;
sub sec { my ($s)=@_; $s->[cs_sec] + SEC_PER_MONTH * $s->[cs_mon]; }
*second      = *sec;

sub sec_part { shift->[cs_sec] }
*second_part = *sec_part;
sub mon_part { shift->[cs_mon] } 
*month_part  = *mon_part;

1;

