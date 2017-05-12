package Data::TimeSeries::ChronoKey;
use strict;
use Date::Calc qw(Decode_Date_US Week_Number check_date Delta_Days Days_in_Month Monday_of_Week Add_Delta_Days Add_Delta_YM);
# Time Related
use constant HOUR => 1;
# Date Related
use constant DAY => 2; #day, month, year
use constant WEEK =>3; #week, year
use constant MONTH => 4;#month, year
use constant QUARTER=>5;#month, year
use constant YEAR=>6;#year

#Directions
use constant LOWEST=>DAY;



# Position Specification
use constant FIRST => 1;
use constant LAST => 2;
use Data::Dumper;

sub new
{
  my ($period, $value)=@_;
  die "ChronoKey not defined." if (!defined($period));
  die "Value not defined." if (!defined($value));
  my $self={};
  
  bless $self;
  $self->init( $period, $value);
  $self->verify();

  return $self;
}
sub copy
{
  my ($self)=@_;
  my %copy=%$self;
  my $self=\%copy;
  bless $self;
  return \%copy;
}


sub getPeriod
{
  my ($self)=@_;
  return $self->{period};
}

sub verify_date
{
  my ($self)=@_;
  my ($year, $month, $day)= Decode_Date($self->{value});
  if (!check_date(($year, $month, $day)) )
  {
    die "Date invalid:", $self->{value};
  }
  ($self->{year}, $self->{month}, $self->{day})=($year, $month, $day);
  undef $self->{week};
  undef $self->{hour};
  return 1;
}
sub verify_week
{
  my ($self)=@_;
  if ($self->{value} =~ /^\s*(\d\d\d\d)W(\d\d)\s*$/)
  {
     die "Week not correct for week"  if (($2 > 53) || ($2 < 01));
     $self->{year}=$1;
     $self->{week}=$2;
  }
  elsif (my ($year, $month, $day)=Decode_Date($self->{value}))
  {
     $self->{year}=$year;
     $self->{week}=Week_Number($year, $month, $day);
  }
  else
  {
    die "Invalid Week:",$self->{value};
  }
  undef $self->{month};
  undef $self->{day};
  undef $self->{hour};
  return 1;
}
sub verify_quarter
{
  my ($self)=@_;
  if ($self->{value} =~ /^\s*(\d\d\d\d)Q(\d)\s*$/)
  {
     die "Quarter not correct for week"  if (($2 > 4) || ($2 < 1));
     $self->{year}=$1;
     $self->{month}=($2*3)-2;
  }
  elsif (my ($year, $month, $day)=Decode_Date($self->{value}))
  {
     $self->{year}=$year;
     $self->{month}=int(($month-1)/3)*3+1;
  }
  else
  {
    die "Invalid Quarter";
  }
  undef $self->{week};
  undef $self->{day};
  undef $self->{hour};
  return 1;
}
sub verify_month
{
  my ($self)=@_;
  if ($self->{value} =~ /^\s*(\d\d\d\d)M(\d\d)\s*$/)
  {
     die "Month not correct for month"  if (($2 > 12) || ($2 < 01));
     $self->{year}=$1;
     $self->{month}=$2;
  }
  elsif (my ($year, $month, $day)=Decode_Date($self->{value}))
  {
     my ($year, $month, $day)=Decode_Date($self->{value});
     $self->{year}=$year;
     $self->{month}=$month;
  }
  else
  {
     die "Invalid for month";
  }
  undef $self->{day};
  undef $self->{week};
  undef $self->{hour};
  return 1;
}
sub verify_year
{
  my ($self)=@_;
  if ($self->{value} =~ /^\s*(\d\d\d\d)\s*$/)
  {
     $self->{year}=$1;
  }
  elsif (my ($year, $month, $day)=Decode_Date($self->{value}))
  {
     $self->{year}=$year;
  }
  else
  {
    die "Year invalid";
  }
  undef $self->{month};
  undef $self->{day};
  undef $self->{week};
  undef $self->{hour};
  return 1;
}
sub verify_hour
{
  my ($self, $value)=@_;
  if ($value !~ /^\s*(\d\d\d\d)(\d\d)(\d\d)H(\d\d)\s*$/)
  {
    die "Date invalid";
  }
  die "month not correct for Hour" if (($2 > 12) || $2<01);
  die "day not correct for Hour"  if (($3 > 31) || $3<01);
  die "hour not correct for Hour"  if (($3 > 24) || $3<01);
  $self->{year}=$1;
  $self->{month}=$2;
  $self->{day}=$3;
  undef $self->{week};
  $self->{hour}=$4;
  return 1;
}

sub verify
{
  my ($self)=@_;
  $self->verify_date() if ($self->{period} ==DAY);
  $self->verify_week() if ($self->{period} == WEEK);
  $self->verify_month() if ($self->{period} == MONTH);
  $self->verify_quarter() if ($self->{period} == QUARTER);
  $self->verify_year() if ($self->{period} == YEAR);
  $self->verify_hour() if ($self->{period} == HOUR);
}

sub init
{
  my ($self, $period, $value)=@_;
  my @ptype_lookup;
  $self->{period}=$period;
  $self->{value}=$value;
}
sub add
{
  my ($self,$units)=@_;
  if (!defined($units))
  {
    $units=1;
  }
  if ($self->getPeriod() == DAY)
  {
    my ($year,$month,$day) = 
        Add_Delta_Days($self->{year}, $self->{month}, $self->{day},1*$units);
    $self->{year}=$year;
    $self->{month}=$month;
    $self->{day}=$day;
  }
  elsif ($self->getPeriod() == WEEK)
  {
      my ($year,$month,$day)=Monday_of_Week($self->{week} , $self->{year});
      ($year,$month,$day)=Add_Delta_Days($year,$month,$day,7*$units);
      my $date=$month.'/'.$day.'/'.$year;
      $self->{year}=$year;
      $self->{week}=Week_Number($year, $month, $day);
  }
  elsif ($self->getPeriod() == MONTH)
  {
    my ($year, $month, $day) = 
        Add_Delta_YM($self->{year}, $self->{month}, '1',0,1*$units);
    $self->{year}=$year;
    $self->{month}=$month;
  }
  elsif ($self->getPeriod() == QUARTER)
  {
    my ($year, $month, $day) = 
        Add_Delta_YM($self->{year}, $self->{month}, '1',0,3*$units);
    $self->{year}=$year;
    $self->{month}=$month;
  }
  elsif ($self->getPeriod() == YEAR)
  {
    my ($year, $month, $day) = 
        Add_Delta_YM($self->{year},'1','1',1*$units,-0);
    $self->{year}=$year;
  }
}
sub  getRelativeIndex
{
  my ($self, $end)=@_;
  if (ref($end) eq ref($self))
  {
     die "Periods do not agree" 
         unless ($self->getPeriod() eq $end->getPeriod());
     
  }
  
  if ($self->getPeriod() == DAY)
  {
     my $days=Delta_Days(
          ($self->{year}, $self->{month}, $self->{day}),
          ($end->{year}, $end->{month}, $end->{day}));
     return $days;
    
  }
  elsif ($self->getPeriod() == WEEK)
  {
     my $weeks=(($end->{year} - $self->{year}) *53) +
           ($end->{week} - $self->{week});
     return $weeks;
  }
  elsif ($self->getPeriod() == MONTH)
  {
     my $months=(($end->{year} - $self->{year}) *12) +
           ($end->{month} - $self->{month});
     
     return $months;
  }
  elsif ($self->getPeriod() == QUARTER)
  {
     my $quarter=(($end->{year} - $self->{year}) *4) +
           int(($end->{month} - $self->{month})/3);
     
     return $quarter;
  }
  elsif ($self->getPeriod() == YEAR)
  {
     my $years=(($end->{year} - $self->{year}) ) ;
     
     return $years;
  }
  die "Hour not yet supported. " if ($self->getPeriod() == HOUR);
}
sub getDate
{
  my ($self, $position, $db) =@_;
  my $date;
  if (!defined($position)|| ($position == FIRST))
  {
    if ($self->{period} == YEAR)
    {
      $date='1/1/' . $self->{year};
    }
    elsif (($self->{period} == MONTH) ||
           ($self->{period} == QUARTER))
    {
      $date=$self->{month} .'/1/'.$self->{year};
    }
    elsif ($self->{period} == DAY)
    {
      $date=$self->{month} .'/'.$self->{day}."/".$self->{year};
    }
    elsif ($self->{period} == WEEK)
    {
      my ($year, $month, $day)=Monday_of_Week($self->{week}, $self->{year});
      $date=$month.'/'.$day.'/'.$year;
    }
    else
    {
      die "Period not recognized. ";
    }
    
  }
  else
  {
    if ($self->{period} == YEAR)
    {
      $date='12/31/' . $self->{year};
    }
    elsif ($self->{period} == MONTH) 
    {
      my $day=Days_in_Month($self->{year}, $self->{month});
      $date=($self->{month}) .'/'.$day.'/'.$self->{year};
    }
    elsif ($self->{period} == DAY)
    {
      $date=$self->{month} .'/'.$self->{day}."/".$self->{year};
    }
    elsif ($self->{period} == WEEK)
    {
      my ($year, $month, $day)=Monday_of_Week($self->{week}, $self->{year});
      ($year, $month, $day)=Add_Delta_Days($year, $month, $day,6);
      $date=$month.'/'.$day.'/'.$year;
      
    }
    elsif ($self->{period} == QUARTER)
    {
      my $day=Days_in_Month($self->{year}, $self->{month}+2);
      $date=($self->{month}+2) .'/'.$day.'/'.$self->{year};
    }
    else
    {
      die "Period not recognized. ";
    }
  }
  if ($db)
  {
     my ($mn, $day,$yr)=$date=~/(.*)\/(.*)\/(.*)/;
     $mn="0".$mn if ($mn < 10);
     $day="0".$day if ($day < 10);
     return "$yr-$mn-$day";
  }
  else
  {
     return $date;
  }
  
  
}

sub keyForPeriod
{
  my ($self, $target_period, $position)=@_;
  my $result;
  if ( ($position == FIRST))
  {
    $result= new($target_period, $self->getDate(FIRST));
  }
  else
  {
    $result= new($target_period, $self->getDate( LAST));
  }

}
################################################
#Common Methods
################################################
sub verifyObj
{
   my ($obj)=@_;
   die "Not defined " if (!defined($obj) );
   die "Not a ChronoKey " if (ref($obj) ne "Data::TimeSeries::ChronoKey");
  
}
sub commonPeriod
{
   my ($period1, $period2)=@_;
   my $iter1=$period1;
   my $iter2=$period2;
   while ((!defined($iter1)) || ($iter1 != $iter2))
   {
      if (!defined($iter1))
      {
         $iter2=neighbor($iter2);
         $iter1=$period1;
      }
      else
      {
        $iter1=neighbor($iter1);
      }
     
   }
   return $iter1;
}
sub neighbor
{
   my ($period)=@_;
   if ($period eq DAY)
   {
      return undef;
   }
   elsif ($period eq WEEK)
   {
      return DAY;
   }
   elsif ($period eq MONTH)
   {
      return DAY;
   }
   elsif ($period eq QUARTER)
   {
      return MONTH;
   }
   elsif ($period eq YEAR)
   {
      return QUARTER;
   }
}
sub Decode_Date
{
   my ($date)=shift;
   my ($year, $month, $day);
   if ($date =~ /(\d\d\d\d)-(\d\d)-(\d\d)/)
   {
      $year=$1;
      $month=$2;
      $day=$3;
      return ($year, $month, $day);
   }
   elsif (($year, $month, $day)=Decode_Date_US($date))
   {
      return ($year, $month, $day);
   }
   else
   {
      return undef;
   }
}

1;
