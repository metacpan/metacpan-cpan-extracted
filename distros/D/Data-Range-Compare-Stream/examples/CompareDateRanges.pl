#!/usr/bin/perl
########################################################
#
#
# How to compare sets of date ranges for overlaps
#   

use strict;
use warnings;
use lib qw(../lib);

use Data::Range::Compare::Stream::Iterator::Array;
use Data::Range::Compare::Stream::Iterator::Compare::Asc;


my @link_a_down=(
  #YYYY-MM-DD-HH-mm-SS YYYY-MM-DD HH:mm:SS
  '2012-01-01 23:34:55 2012-01-02 23:39:16',
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
  '2012-01-28 04:34:25 2012-01-28 04:46:01',
);

my $cmp=new Data::Range::Compare::Stream::Iterator::Compare::Asc(factory_instance=>'Data::Range::Compare::Stream::DateTime');
my $link_count=0;
{
  foreach my $src (\(@link_a_down,@link_b_down,@link_c_down)) {
    ++$link_count;
    
    my $outages=Data::Range::Compare::Stream::Iterator::Array->new;
    
    foreach my $string (@$src) {
       $outages->add_range(parse_outage($string));
    }

    $outages->set_sorted(1);
    my $id=$cmp->add_consolidator($outages);

  }
}

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
my $total_downtime=0;
my @link_downtime;


while($cmp->has_next) {
  my $result=$cmp->get_next;
  next if $result->is_empty;

  my $links_down=$result->get_overlap_count;

  foreach my $id (@{$result->get_overlap_ids}) {
    $link_downtime[$id] +=$result->get_column_by_id($id)->duration_in_seconds;
  }

  print $result;

  if($links_down==$link_count) {
    print " Outage: ",format_downtime($result->get_common->duration_in_seconds),"\n";
    $total_downtime +=$result->get_common->duration_in_seconds;
  } else {
    
    my  $links_up=$link_count - $links_down;
    print " Redundant links online: $links_up/$link_count  Location is online\n";
  }
}
my @link_map=(qw(
  LINK_A
  LINK_B
  LINK_C
));

print "Total downtime: ",format_downtime($total_downtime),"\n";
for(my $id=0; $id < scalar(@link_map);++$id) {
  print "Downtime for $link_map[$id] ",format_downtime($link_downtime[$id]),"\n";
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
