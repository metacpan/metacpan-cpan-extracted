#!/usr/bin/perl
########################################################
#
#
# This example shows the following:
# 
# How to calculate outages that happen durring
# regular business hours excluding holidays.
#
# Outages are defined as  each intersection of:
#    @link_a_down, @link_b_down, @link_c_down
#   

use strict;
use warnings;
use lib qw(../lib);

use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream::Iterator::Compare::Asc;
use Data::Range::Compare::Stream::Iterator::Compare::LayerCake;


my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc(
  new_from=>'Data::Range::Compare::Stream::DateTime'
);



# generate the holidays
my @holidays=(
  #YYYY-MM-DD
  '2012-01-01',  # New years day
  '2012-01-02',  # New years celebratoin
  '2012-01-16',  # Birthday of Martin Luther King, Jr.
  '2012-01-20',  # Washington's Birthday
);

my $hd=Holidays->new(holidays=>[@holidays]);
my $holiday_column=$cmp->add_consolidator($hd);


# generate the business hours
my $bh=new BusinessHours(
  #            YYYY-MM-DD
  start_date=>'2012-01-01',
  end_date=>  '2012-01-31'
);
my $bh_coumn=$cmp->add_consolidator($bh);

my @link_a_down=(
  #YYYY-MM-DD-HH-mm-SS YYYY-MM-DD HH:mm:SS
  '2012-01-01 23:34:55 2012-01-02 23:34:56',
  '2012-01-03 09:34:25 2012-01-03 09:38:25',
  '2012-01-15 13:34:25 2012-01-16 09:38:24',
  '2012-01-18 14:34:25 2012-01-18 16:38:35',
  '2012-01-19 04:34:25 2012-01-20 06:31:15',
  '2012-01-28 04:34:25 2012-01-28 04:47:02',
);

my @link_b_down=(
  #YYYY-MM-DD-HH-mm-SS YYYY-MM-DD HH:mm:SS
  '2012-01-01 23:34:55 2012-01-02 23:34:56',
  '2012-01-03 09:36:25 2012-01-03 09:37:01',
  '2012-01-15 13:35:40 2012-01-16 01:07:36',
  '2012-01-28 04:34:25 2012-01-28 04:47:02',
);

my @link_c_down=(
  #YYYY-MM-DD-HH-mm-SS YYYY-MM-DD HH:mm:SS
  '2012-01-01 23:34:55 2012-01-02 23:34:56',
  '2012-01-03 09:34:25 2012-01-03 09:38:25',
  '2012-01-15 13:34:25 2012-01-16 09:38:24',
  '2012-01-18 14:34:25 2012-01-18 16:38:35',
  '2012-01-19 04:34:25 2012-01-20 06:31:15',
  '2012-01-28 04:34:25 2012-01-28 04:47:02',
);


sub filter {
  my ($result)=@_;
  
  return $result->is_full;
}

my $wan_outages=new Data::Range::Compare::Stream::Iterator::Compare::LayerCake(
  filter=>\&filter,
  new_from=>'Data::Range::Compare::Stream::DateTime'
);
{
  foreach my $src (\(@link_a_down,@link_b_down,@link_c_down)) {
    
    my $outages=Data::Range::Compare::Stream::Iterator::Array->new;
    
    foreach my $string (@$src) {
       $outages->add_range(parse_outage($string));
    }
    $outages->set_sorted(1);
    $wan_outages->add_consolidator($outages);
  }
}


my $outage_column=$cmp->add_consolidator($wan_outages);

sub format_downtime {
  my ($time)=@_;
  
  # used to help format our outage strings
  my $day=60 * 60 * 24;
  my $hour=60 * 60;
  my $min=60;

  my $mod_day=$time % $day;
  my $days=($time - $mod_day)/$day;
  my $mod_hour=$mod_day % $hour;
  my $hours=($mod_day - $mod_hour)/$hour;
  my $mod_min=$mod_hour % $min;
  my $mins=($mod_hour - $mod_min)/$min;
  my $seconds=$mod_min;

  sprintf('days="%02d" hours="%02d" min="%02d" sec="%02d"',$days,$hours,$mins,$seconds);
}

# use to track our downtime
my $total_network_downtime=0;
my $total_business_dowmtime=0;
my $total_business_hours=0;

while($cmp->has_next) {
  my $result=$cmp->get_next;
  next if $result->is_empty;
  if($result->get_overlap_ids->[0]==$holiday_column) {
    # this is on a holiday!
    if($result->get_overlap_count==3) {
      # this is an outage on a holiday
      print $result->get_common," Downtime: ",format_downtime($result->get_common->duration_in_seconds);
      print " Holiday Outage Durring normal Busness hours\n";
      $total_network_downtime +=$result->get_common->duration_in_seconds;
    } elsif($result->get_overlap_count==$outage_column) {
      if($result->get_overlap_ids->[1]==$outage_column) {
        
        print $result->get_common," Downtime: ",format_downtime($result->get_common->duration_in_seconds);
        print " Non Business hours Holiday Outage\n";
        $total_network_downtime +=$result->get_common->duration_in_seconds;
      }
    }
  } elsif($result->get_overlap_count==2) {
    # down time durring regular business hours!
    print $result->get_common," Downtime: ",format_downtime($result->get_common->duration_in_seconds);
    print " Outage Durring Busines Hours!!\n";
    $total_business_dowmtime+=$result->get_common->duration_in_seconds;
    $total_network_downtime +=$result->get_common->duration_in_seconds;
    $total_business_hours +=$result->get_common->duration_in_seconds;

    
  } elsif($result->get_overlap_count==1) {
    if($result->get_overlap_ids->[0]==$outage_column) {
      print $result->get_common," Downtime: ",format_downtime($result->get_common->duration_in_seconds);
      print " Non Business hours Outage\n";
      $total_network_downtime +=$result->get_common->duration_in_seconds;
    } else {
      $total_business_hours +=$result->get_common->duration_in_seconds;
    }
  }
}


print "Total of ",($bh->total_days - scalar(@holidays))," Business days between $bh\n";
print "Total of ",scalar(@holidays)," Holidays between $bh\n";
print "\nTotal Downtime ",format_downtime($total_network_downtime),"\n";
print "Total Downtime durring business hours: ",format_downtime($total_business_dowmtime),"\n";
printf 'Business hours Downtime as a percentage: %2.6f%% %s',($total_business_dowmtime/$total_business_hours),"\n";


sub parse_outage {
  my ($line)=@_;
  my @data=($line=~ /(\d+)/g);
  # Y M D H m S Y M D H m S
  my @args;
  while(my @values=splice(@data,0,6)) {
    my %args;
    @args{qw(year month day hour minute second )}=@values;
    my $date=DateTime->new(%args);
    push @args,$date;
  }
  return Data::Range::Compare::Stream::DateTime->new(@args);
}


{
  package BusinessHours;

  # package just generates mon-fri 9am - 5pm
  use strict;
  use warnings;
  use DateTime;
  use base qw(Data::Range::Compare::Stream::Iterator::Base);
  use overload
    '""'=>\&to_string,
    fallback=>1;

  sub to_string {
    my ($self)=@_;
    $self->{start_date}.' and '.$self->{end_date}
  }

  sub total_days {
    $_[0]->{total_days}
  }

  sub new {
    my ($class,%args)=@_;

    my $self=$class->SUPER::new(%args);
    my $start=$self->parse_date($args{start_date});
    my $end=$self->parse_date($args{end_date});

    my $start_date=new DateTime(%$start);
    my $end_date=new DateTime(%$end);

    if($end_date->day_of_week==7) {
      $end_date->subtract(days=>1);
    } elsif($end_date->day_of_week==6) {
      $end_date->subtract(days=>2);
    }

    if($start_date->day_of_week==7) {
      $start_date->add(days=>1);
    } elsif($start_date->day_of_week==6) {
      $start_date->add(days=>2);
    }

    if(DateTime->compare($start_date,$end_date)==1) { 
      $self->{has_next}=0;
    } else {
      $self->{has_next}=1;
    }

    $self->{e_date}=$end_date;
    $self->{s_date}=$start_date;

    return $self;
  }

  sub has_next { $_[0]->{has_next} }

  sub get_next {
    my ($self)=@_;

    my $start=$self->{s_date}->clone;
    $start->add(hours=>9);

    my $range_start=$start->clone;
    $start->add(hours=>8);

    my $range_end=$start->clone;

    $self->add_one;
    ++$self->{total_days};

    return Data::Range::Compare::Stream::DateTime->new($range_start,$range_end);
  }

  sub add_one {
    my ($self)=@_;

    my $start_date=$self->{s_date};
    my $end_date=$self->{e_date};
    $start_date->add(days=>1);

    if($start_date->day_of_week==7) {
      $start_date->add(days=>1);
    } elsif($start_date->day_of_week==6) {
      $start_date->add(days=>2);
    }

    if(DateTime->compare($start_date,$end_date)==1) { 
      $self->{has_next}=0;
    } else {
      $self->{has_next}=1;
    }

  }

  sub parse_date {
    my ($self,$date)=@_;
    my $ref={};                 
    @{$ref}{qw(year month day )}=($date=~ /(\d+)/g);
    return $ref;
  }

  1;
}



{
  package Holidays;

  # package for generating the holiday list!
  use strict;
  use warnings;
  use DateTime;
  use base qw(Data::Range::Compare::Stream::Iterator::Base BusinessHours);

  sub new {
    my ($class,%args)=@_;
    my $self=$class->SUPER::new(holidays=>[],%args);
  }

  sub has_next {
    my ($self)=@_;
    my $holidays=$self->{holidays};
    return $#$holidays!=-1;
  }

  sub get_next {
    my ($self)=@_;
    my $string=shift @{$self->{holidays}};
    my $ref=$self->parse_date($string);

    my $date=new DateTime(%$ref);
    my $start=$date->clone;
    $date->add(hours=>23,minutes=>59,seconds=>59);
    my $end=$date->clone;
    return Data::Range::Compare::Stream::DateTime->new($start,$end);

  }

  1;
}

{
  package Data::Range::Compare::Stream::DateTime;
  
  use strict;
  use warnings;
  use DateTime;
  use lib qw(../lib);
  use base qw(Data::Range::Compare::Stream);
  use overload 
    '""'=>\&to_string,
    fallback=>1;
  
  #
  # Define the class internals will use when creating a new object instance(s)
  use constant NEW_FROM_CLASS=>'Data::Range::Compare::Stream::DateTime';
  
  use constant TIME_FORMAT=>'%Y-%m-%d %H:%M:%S';
  
  sub cmp_values ($$) {
    my ($self,$value_a,$value_b)=@_;
    return DateTime->compare($value_a,$value_b);
  }
  
  sub add_one ($) {
    my ($self,$value)=@_;
    return $value->clone->add(seconds=>1);
  }
  
  sub sub_one ($) {
    my ($self,$value)=@_;
    return $value->clone->subtract(seconds=>1);
  }
  
  sub range_start_to_string {
    my ($self)=@_;
    return $self->range_start->strftime($self->TIME_FORMAT);
  }
  
  sub range_end_to_string {
    my ($self)=@_;
    return $self->range_end->strftime($self->TIME_FORMAT);
  }

  sub duration_in_seconds {
    my ($self)=@_;
    1 + $self->range_end->epoch - $self->range_start->epoch;
  }

  sub to_string {
    my ($self)=@_;
    $self->range_start_to_string.' - '.$self->range_end_to_string;
  }

  1;
}
