package Data::TimeSeries;

use 5.006;
use strict;
use warnings;
use Date::Calc qw(Decode_Date_US );
use Data::TimeSeries::ChronoKey;

require Exporter;
our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Data::TimeSeries ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw( ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw( );
our $VERSION = '0.53';

=head1 NAME

Data::TimeSeries - Perl extension for Manipulation of Time Series of numbers. Data::TimeSeries supports all the periods of ChronoKey.

=head1 SYNOPSIS

  use Data::TimeSeries;

  my $start =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2004W48");
  my $stop =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2005W02");
  my $timeSeries=Data::TimeSeries::new($start, 
            $stop,Data::TimeSeries::ChronoKey::WEEK,'{3,4,5,6,7,8,9,10}');

  $ts->addPoint(Data::TimeSeries::FIRST, 2);
  $ts->addPoint(Data::TimeSeries::LAST, 12);

  $ts->seriesOperate(sub {$total+=$_;});

  $ts->removePoint(Data::TimeSeries::LAST);
  $ts->removePoint(Data::TimeSeries::FIRST);

  $ts->seriesOperate(sub {$total+=$_;});

  $copy=$timeSeries->copy();

  $ts->normalize();

  my $rstart =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2004W45");
  my $rstop =Data::TimeSeries::ChronoKey::new(Data::TimeSeries::ChronoKey::WEEK, "2004W51");
  $resized->resize($rstart, $rstop);

  $ts->stationize($station);
  $copy->remap(Data::TimeSeries::ChronoKey::DAY, Data::TimeSeries::SPREAD);

=head1 LIMITATIONS/TODO

TimeSeries assumes you are working with numeric data where there is a value for every target period.

=cut

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

#CONSTANTS
use constant FIRST => 1;
use constant LAST => 2;

#Remap Spreading Types
use constant SPREAD=> 4;   #replicate value down
use constant REPLICATE=> 5;   #replicate value down
use constant EVEN => 6;      #divide up value evenly when spreading

#Hash Mapping Methods
use constant INTERPOLATE => 3; #AVERAGE when aggregating.
use constant STEP => 4;        #Used only in new object


use Data::Dumper;


#################
# Methods associated with class not object.
##################
sub compare_dates($$)
{
  my ($date1, $date2)=@_;
  my ($y1,$m1,$d1,$y2,$m2,$d2);
  unless (($y1,$m1,$d1)=Decode_Date_US($date1))
  {
    die "Failed to parse ( $date1 ) \n";
  }
  unless (($y2,$m2,$d2)=Decode_Date_US($date2))
  {
    die "Failed to parse $date2\n";
  }
  return -1 if ($y1 <$y2);
  return 1 if ($y1 >$y2);
  return -1 if ($m1 <$m2);
  return 1 if ($m1 >$m2);
  return -1 if ($d1 <$d2);
  return 1 if ($d1 >$d2);
  return 0;

}

sub convertDatesToKeys
{
#Convert all the date strings in this array to Data::TimeSeries::ChronoKeys
   my ($arr,$period)=@_;
   my @result;
   foreach my $key(@$arr)
   {
     push @result, Data::TimeSeries::ChronoKey::new($period,$key);
   }
   return @result;
}

sub buildDateList
{
   my ($period,$sortedDatesRef)=@_;
   my $list=[];
   foreach my $date(@$sortedDatesRef)
   {
      my $cKey=Data::TimeSeries::ChronoKey::new($period,$date);
      push @$list,$cKey;
   }
   return $list;
}

sub synchronize
{
   my @tsList=@_;
   my $commonPeriod;
   foreach my $ts(@tsList)
   {
      die "One of the parameters is not a TimeSeries" 
                             if (ref($ts) ne 'Data::TimeSeries');
      if (defined($commonPeriod))
      {
         $commonPeriod=Data::TimeSeries::ChronoKey::commonPeriod($ts->period(), $commonPeriod);
      }
      else
      {
         $commonPeriod=$ts->period();
      }
   }
   my ($start,$end);
   foreach my $ts(@tsList) # Find the start and end dates.
   { 
      $ts->remap($commonPeriod,REPLICATE) 
                      if ($ts->period() != $commonPeriod);
      if (!defined($start)) #First Time Series.
      {
         $start=$ts->start();
      }
      else 
      { 
         my $startRI=$start->getRelativeIndex($ts->start());
         #If Current Start is earlier than ts start.
         $start=$ts->start() if ($startRI > 0);
      }
      if (!defined($end)) #First Time Series.
      {
         $end=$ts->end();
      }
      else
      { 
         my $endRI=$end->getRelativeIndex($ts->end());
         #If Current end is later than ts end.
         $end=$ts->end() if ($endRI < 0);
      }
   }
   #Verify Start < End 
   #Or in other words the series overlap.
   return 0 if ($start->getRelativeIndex($end) <= 0);

   foreach my $ts(@tsList) # Find the start and end dates.
   {
      $ts->clip($start,$end);
      $ts->stationize($start);
   }
   
   return 1;
}



#######################
# Constructor
#######################
sub new
{
   #Startdate, enddate, period and series
   if ((scalar(@_) == 4) )
   {
     my ( $start, $end, $period, $series)=@_;
     my $self={start=>'',end=>'',period=>'',series=>[]};
     bless $self;
     $self->start($start->copy());
     $self->end($end->copy());
     $self->period($period);
     $self->series($series);
     return $self;
   }
   #period and hash series in (date=>value) format.
   elsif ((scalar(@_)==3) && (ref($_[1]) eq "HASH") &&
         (($_[2] == INTERPOLATE) || ($_[2] == STEP)))
   {
      my ($period, $hashSeries, $method)=@_;
      my @keyDates = keys %$hashSeries;
      my @sortedDates=sort Data::TimeSeries::compare_dates  @keyDates;
      my @values;
      #Sort values by the dates order
      for (my $i=0;$i<scalar(@sortedDates);$i++)
      {
         $values[$i]=$hashSeries->{$sortedDates[$i]};
      }
     #Loop through every list of time periods and build
     #an array of chronoKeys.
      my @sortedChronoKeys=convertDatesToKeys(\@sortedDates, $period);
      my @builtSeries;
      #Get first key.
      my $beginKey = shift @sortedChronoKeys;
      my $start=$beginKey;
      my $position=0;
      my @buildSeries;
      my $valuePos=0;
      foreach my $key(@sortedChronoKeys)
      {
         my $count=$beginKey->getRelativeIndex($key);
         if ($method == STEP)
         {  for (my $i=$position;$i<$position+$count;$i++)
            {
               $buildSeries[$i]=$values[$valuePos];
            }
         }
         elsif ($method == INTERPOLATE)
         {  my $diff=$values[$valuePos+1]-$values[$valuePos];
            my $ratio=$diff/$count;
            for (my $i=$position;$i<$position+$count;$i++)
            {
               $buildSeries[$i]=$values[$valuePos]+$ratio*($i-$position);
            }
         }
         #Increment to where next date starts.
         $position =$position + $count;
         $beginKey=$key;
         $valuePos++;
      }
      #Set Last value in series.
      $buildSeries[$position ]=$values[$valuePos];
      my $self={start=>'',end=>'',period=>'',series=>[]};
      bless $self;
      $self->start($sortedChronoKeys[0]->copy());
      $self->end($sortedChronoKeys[scalar(@sortedChronoKeys)-1]->copy());
      $self->period($period);
      $self->series(\@buildSeries);
      return $self;
   }
   else
   {
      die "Parameters for new are incorrect.";
   }
}
sub start
{
   my ($self, $start)=@_;
   if ((defined $start) && (ref($start) eq "Data::TimeSeries::ChronoKey"))
   {
      $self->{start}=$start;
   }
   elsif (!defined $start)
   {
      return $self->{start};
   }
   else
   {
      die "start object not of type ChronoKey";
   }
}

sub end
{
   my ($self, $end)=@_;
   if ((defined($end)) && (ref($end) eq "Data::TimeSeries::ChronoKey"))
   {
      $self->{end}=$end;
   }
   elsif (!defined $end)
   {
      return $self->{end};
   }
   else
   {
      die "end object not of type ChronoKey";
   }
}

sub period
{
   my ($self, $period)=@_;
   if (defined $period)
   {
      $self->{period}=$period;
   }
   else
   {
      return $self->{period};
   }
}

sub getCalcLen
{
   my ($self)=@_;

   my $calcLen=$self->{start}->getRelativeIndex($self->{end})+1;
   return $calcLen;
}

sub getStrDateArray
{
   my ($self)=@_;
   my $len=$self->getCalcLen();
   my @result=();
   my $curr=$self->start();
   for (my $i=0;$i<=$len;$i++)
   {
      push @result, $curr->getDate();
      $curr->add(1);
   }
   return \@result;
}

sub series
{
   my ($self, $series)=@_;
   if (defined ($series))
   {
      my $refseries=ref($series);
      if (!ref($series) )
      {
         $series =~ s/[{}]//g ;

         my @arr=map {int($_)} split(",",$series);#Convert from strings to int.
         my $size=$self->{start}->getRelativeIndex($self->{end})+1;
         my $arrSize=scalar(@arr);
         if ($arrSize != $size)
         {
             die " Dates and array size does not match $arrSize, $size ";
         }
         $self->{series}=\@arr;
      }
      elsif(ref($series) eq "ARRAY") # Array
      {
         my @arr=@$series;
         $self->{series}=\@arr;
      }
      else
      {
         die "Unable to handle " ,ref($series), " series type";
      }
   }
   else
   {
      return $self->{series};
   }

}

sub addPoint
{
   my ($self, $position, $value)=@_;
   die "Not all parameters provided for add Point " if(!defined($value));
   #position[ FIRST, LAST, chronoKey]
 
   if ($position == Data::TimeSeries::FIRST)
   {
      unshift(@{$self->{series}}, $value);
      $self->{start}->add(-1);
      
   }
   elsif ($position eq Data::TimeSeries::LAST)
   {
      push(@{$self->{series}}, $value);
      $self->{end}->add();
   }
   elsif ((ref($position) eq "Data::TimeSeries::ChronoKey"))
   {
      my @data=();
      my $index=$self->{start}->getRelativeIndex($position);
      $self->{end}->add();
      for (my $i=0;$i<$self->{start}->getRelativeIndex($self->{end});$i++)
      {
         if ($i == $index)
         {
            push @data, $value;
         }
         push @data, $self->{series}->[$i];
         
      }
   }
   
   #chrono[ FIRST, LAST,date,datetime, mapping]
}

sub removePoint
{
   my ($self, $position)=@_;
   die "Not all parameters provided for add Point " if(!defined($position));
   if ($position == FIRST)
   {
      shift(@{$self->{series}});
      $self->{start}->add();
      
   }
   elsif ($position == LAST)
   {
      pop(@{$self->{series}});
      $self->{end}->add(-1);
   }
}

sub getPoint
{
   my ($self, $chronokey)=@_;
   #chronokey[ FIRST, LAST,date,datetime, mapping]
}

sub getLength
{
   my ($self)=@_;
   my $len=scalar(@{$self->{series}});
   return $len;
}
sub shift
{
  my ($self, $period, $units)=@_;
  $self->{start}->add($units);
  $self->{stop}->add($units);
}
sub seasonalize
{
  my ($self, $period)=@_;
}
sub stationize
{
  my ($self, $station)=@_;
  my $ckStation;
  if (ref $station ne "Data::TimeSeries::ChronoKey")
  {
    $ckStation=Data::TimeSeries::ChronoKey::new($self->period, $station);
  }
  else
  {
    $ckStation=$station;
  }
  if (($self->start->getRelativeIndex($ckStation) < 0) ||
     ($self->end->getRelativeIndex($ckStation) > 0))
  {
     die "Station not within range.";
  }
  my $position=$self->start->getRelativeIndex($station);
  my $divisor=$self->series->[$position];
  map {$_=$_/$divisor} @{$self->{series}} ;
}
sub normalize
{
  my ($self)=@_;
  my $total=0;
  map {$total+=$_} @{$self->{series}} ;
  map {$_=$_/$total} @{$self->{series}} ;
}
sub resize
{
  my ($self, $start, $end,$method)=@_;
  $method=INTERPOLATE if (!defined($method)); #default to interpolate method
  Data::TimeSeries::ChronoKey::verifyObj($start);
  Data::TimeSeries::ChronoKey::verifyObj($end);
  my @vals;
  my $targetLen=$start->getRelativeIndex($end)+1;
  $targetLen--;
  my $srcLen=$self->getLength();
  $srcLen--;
  my $gcd=_getGCD($srcLen, $targetLen);
  my $lcm=($srcLen/$gcd) * $targetLen;
  my $j=0;
  for (my $i=0;$i<($lcm);$i+=$gcd*$targetLen)
  {
   my $k;
     for ($k=$i;$k<=($i + ($gcd * $targetLen));$k++)
     {  
        $vals[$k]=((($self->series()->[$j+1] - $self->series()->[$j])/
            ($gcd * $targetLen))*($k-$i)) + $self->series()->[$j];
     }
   $j++;
  }
  my @result;
  for (my $i=0;$i<=$targetLen;$i++)
  {
     $result[$i]=$vals[$i*($lcm/$targetLen)]
  }
  my $seriesTotal=0;
  my $resTotal=0;
  if ($method == SPREAD)
  {
    for (my $i=0;$i<=$srcLen;$i++)
    {
      $seriesTotal+=$self->series()->[$i];
    }
    for (my $i=0;$i<=$targetLen;$i++)
    {
      $resTotal+=$result[$i];
    }
    for (my $i=0;$i<=$targetLen;$i++)
    {
      $result[$i]=($result[$i]/$resTotal)*$seriesTotal;
    }
  }
  $self->series(\@result);
  $self->start($start);
  $self->end($end);
  
}
sub seriesOperate
{
  my ($self,$closure)=@_;
  map {&$closure()} @{$self->series()};
}
sub remap
{
  my ($self, $period,$remapType )=@_;
  my @result;
  #Remap not handling period properly.
  return if ($self->period() == $period);
  return die "Period not below or common to self's period." 
                  if (Data::TimeSeries::ChronoKey::commonPeriod($self->period(), $period) != $period);
  my $start=$self->start()->copy();
  my $last=$self->end()->copy();
  my @dataCopy=@{$self->series()};
  for (my $topCurr=$start->copy();$topCurr->getRelativeIndex($last)>=0;$topCurr->add())
  {
     my $currVal=CORE::shift(@dataCopy);
     my $cstart=$topCurr->keyForPeriod($period, FIRST);
     my $clast=$topCurr->keyForPeriod($period, LAST);
     my $relidx=$cstart->getRelativeIndex($clast);
     for (my $iCurr=0;$iCurr<=$relidx;$iCurr++)
     {
        #Assume Replicate for now.
        if ($remapType == REPLICATE)
        {
           push @result, $currVal;
        }
        elsif($remapType == SPREAD)
        {
           push @result, $currVal/($relidx+1);
        }
        else
        {
          die "Did not recognize remap type $remapType \n";
        }
     }
  }
  $self->series(\@result);
  $self->period($period);
  $start=$self->start()->keyForPeriod($period, FIRST);
  $last=$last->keyForPeriod($period, LAST);
  $self->start($start);
  $self->end($last);
}
sub clip
{
  my ($self, $start, $end)=@_;
  if (!defined $end)
  {
    $end=$self->end();
  }
  my $startShift=$self->{start}->getRelativeIndex($start);
  die "Start before objects start" if ($startShift < 0);
  my $endShift=$self->{start}->getRelativeIndex($end);
  die "End before object's end. $endShift" if ($endShift > scalar(@{$self->{series}}));
  if ($endShift  < $startShift)
  {
     die "End Date before Start Date";
  }
  my @newSeries;
  for (my $i=$startShift;$i<=$endShift;$i++)
  {
    push(@newSeries, $self->{series}->[$i]);
  }
  $self->{start}=$start;
  $self->{end}=$end;
  $self->{series}=\@newSeries;
  

}
sub copy
{
  my ($self)=@_;
  my $copy=new($self->{start}, 
                       $self->{end}, $self->{period}, $self->{series});
  bless $copy;
  @{$copy->{series}}=@{$self->{series}};
  return $copy;
}

sub pack
{
   my ($self)=@_;
   my $count=$self->getCalcLen();
   return pack "d" x $count, @{$self->series()};
}
sub unpack
{
   my ($start, $end, $period,$packed) = @_;
   $start=~ s/(.*?) \d\d:\d\d:\d\d/$1/g;
   $end=~ s/(.*?) \d\d:\d\d:\d\d/$1/g;
   my $ckStart=Data::TimeSeries::ChronoKey::new($period, $start);
   my $ckEnd=Data::TimeSeries::ChronoKey::new($period, $end);
   my $count=$ckStart->getRelativeIndex($ckEnd) + 1;
   my @arr = unpack "d" x $count, $packed;
   my $ts=new($ckStart,$ckEnd,$period,\@arr);
   return $ts;
}
###################################################

sub _getGCD
{
   my ($v1, $v2)=@_;
   my ($largest, $smallest);
   if ($v1>$v2)
   {
      $largest=$v1;
      $smallest=$v2;
   }
   else
   {
      $largest=$v2;
      $smallest=$v1;
   }
   my $d=$largest;
   my $r=$smallest;
   while ($r!=0)
   { 
     $largest=$d;
     $d=$r;
     $r=$largest % $d;
   }
   return $d;
}
1;
__END__
# Below is stub documentation for your module. You better edit it!


=head1 METHODS


=item C<new>

 $ts = Data::TimeSeries::new($start, $end, $period, $series);

Creates and initalizes TimeSeries object.  C<new> dies if parameters are not legal.  $start - ChronoKey object. The position of the first element in the serines.  $end - ChronoKey object. The position of the last element in the series.  $period - A ChronoKey Period $series - An array or a string that has the following format {1,2,4}. Should be of integer or floating point numbers.

=item C<start>

 $ck = $ts->start();
 $ts->start($ck);

The C<start> method is the start position accesor. It can be used to get or set the start position.  Setting the start position directly is strongly discouraged. Use C<clip> or C<resize> instead.


=item C<end>

 $ck = $ts->end();
 $ts->end($ck);

The C<end> method is the end position accesor. It can be used to get or set the end position.  Setting the end position directly is strongly discouraged. Use C<clip> or C<resize> instead.

=item C<period>

 $period = $ts->period();
 $ts->period($period);

The C<period> method is the period of the time series. It can be used to get or set the  period.  Setting the end period directly is strongly discouraged. 

=item C<series>

 \@series = $ts->series();
 $ts->series(\@series);
 $ts->series("{1,2,3}");

The C<series> method is the series of the time series. It can be used to get or set the  series.  Setting the end series directly is somewhat discouraged. If you do set it, make sure it is the same length as the one you are replacing.


=item C<getCalcLen>

 $length = $ts->getCalcLen();

The C<getCalcLen> method is used to get the number of periods from the start and end positions (inclusive). It should be the same length as the series array.

=item C<addPoint>

 $ts->addPoint(Data::TimeSeries::FIRST, 10.00);
 $ts->addPoint(Data::TimeSeries::LAST, 15.00);
 $ts->addPoint($ck, 12.00);

C<addPoint> Method allows you to add a new point to the beginning or end of a timeseries.  Or you can add it somewhere within the series. The ChronoKey ($ck) must be within the existing range.  The series will be stretched forward to accomodate the new point.

=item C<removePoint>

 $ts->removePoint(Data::TimeSeries::FIRST);
 $ts->removePoint(Data::TimeSeries::LAST);
 $ts->removePoint($ck);

The inverse of addPoint.  Allows you to remove the first, last or a cnter point.

=item C<getPoint>

 $ts->getPoint(Data::TimeSeries::FIRST);
 $ts->getPoint(Data::TimeSeries::LAST);
 $ts->removePoint($ck);

C<getPoint> gets the point at the specified position.

=item C<getLength>

 $len=$ts->getLength();

C<getLength> gets the length of the time series.

=item C<shift>
 
 $ts->shift($units)

C<shift> shifts the time series by $units number of periods. 

=item C<seasonalize>

 $ts->seasonalize()


=item C<normalize>

 $ts->normalize()

Takes the time series and makes it sum to 1.

=item C<resize>

 $ts->resize($start, $end)

Stretches or shrinks the time series to fit the $start and $end chronokeys.  Linear Interpolation is used to build missing values.

=item C<seriesOperate>

 $ts->seriesOperate(sub {$_*=20;})

Runs an operation on every item in the series.

=item C<clip>

 $ts->clip($startCK,$endCK);

Cuts down the time series to the specified start and end positions.

=item C<copy>

 $ts2=$ts->copy();

Creates a copy of the time series.


Runs an operation on every item in the series.

TODO
=item C<regression>

($slope, $constant)=$ts->regression();

 Runs a regression algorithm on a time series.


=head1 DESCRIPTION

  Data::TimeSeries allows easy manipulation of timeseries related data.


=head2 EXPORT

None by default.


=head1 AUTHOR

ts(at)atlantageek.com

=head1 SEE ALSO

L<perl>.

=cut
