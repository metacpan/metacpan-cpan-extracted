use strict;
use warnings;
use DateTime;
use lib qw(../lib lib .);
use Data::Range::Compare;

my @vpn_a=
  # outage start	 Outage End
(

 # start
 DateTime->new(qw(year 2010 month 01 day 02 hour 10 minute 01 second 59))  
 ,
 # end
 DateTime->new(qw(year 2010 month 01 day 02 hour 10 minute 05 second 47))
 ,
 # start
 DateTime->new(qw(year 2010 month 05 day 02 hour 07 minute 41 second 32))
 ,
 # end
 DateTime->new(qw(year 2010 month 05 day 02 hour 08 minute 00 second 16))
);

my @vpn_b=
  # outage start	  Outage End
(

  # start
  DateTime->new(qw(year 2010 month 05 day 02 hour 07 minute 41 second 32))
  ,
  # end
  DateTime->new(qw(year 2010 month 05 day 02 hour 07 minute 58 second 13))
  ,
  # start
  DateTime->new(qw(year 2010 month 01 day 02 hour 10 minute 03 second 59))
  ,
  # end
  DateTime->new(qw(year 2010 month 01 day 02 hour 10 minute 04 second 37))
);
my @vpn_c=
  # outage start	  Outage End
(
  DateTime->new(qw(year 2010 month 01 day 02 hour 10 minute 03 second 59))
  ,
  DateTime->new(qw(year 2010 month 01 day 02 hour 10 minute  04 second 37))

  ,
  DateTime->new(qw(year 2010 month 05 day 02 hour 07 minute 41 second 32))
  ,
  DateTime->new(qw(year 2010 month 05 day 02 hour 07 minute 58 second 13))

  ,
  DateTime->new(qw(year 2010 month 05 day 02 hour 07 minute 59 second 07))
  , 
  DateTime->new(qw(year 2010 month 05 day 02 hour 08 minute 00 second 16))

  ,
  DateTime->new(qw(year 2010 month 06 day 18 hour 10 minute 58 second 21))
  ,
  DateTime->new(qw(year 2010 month 06 day 18 hour 22 minute 06 second 55))
);
my %helper;

# create a simple function to handle comparing dates
sub cmp_values { DateTime->compare( $_[0],$_[1] ) }

# Now set cmp_values in %helper
$helper{cmp_values}=\&cmp_values;

# create a simple function to calculate the next second
sub add_one { $_[0]->clone->add(seconds=>1) }

# Now set add_one in %helper
$helper{add_one}=\&add_one;

# create a simple function to calculate the previous second
sub sub_one { $_[0]->clone->subtract(seconds=>1) }

# Now set sub_one in our %helper
$helper{sub_one}=\&sub_one;


# quick and dirty formatting tool
sub format_range ($) {
 my $s=$_[0];
 join ' - '
  ,$s->range_start->strftime('%F %T')
  ,$s->range_end->strftime('%F %T')
}

# Load our data into an array of arrays
my @parsed;
my @vpn_name=qw(vpn_a vpn_b vpn_c);
foreach my $outages (\@vpn_a,\@vpn_b,\@vpn_c) {
  my $id=shift @vpn_name;
  my $row=[];
  push @parsed,$row;
  print "\nVPN_ID $id\n";
  while(my ($dt_start,$dt_end)=splice(@$outages,0,2)) {
    my $range=Data::Range::Compare->new(\%helper,$dt_start,$dt_end);
    print format_range($range),"\n";
    push @$row,$range;
  }
}
# now compare our outages
my $sub=Data::Range::Compare->range_compare(\%helper,\@parsed);
while(my ($vpn_a,$vpn_b,$vpn_c)=$sub->()) {
  next unless 
    !$vpn_a->missing 
     && 
    !$vpn_b->missing 
     && 
    !$vpn_c->missing;
  my $common=Data::Range::Compare->get_common_range(
    \%helper
    ,[$vpn_a,$vpn_c,$vpn_b]
  );
  my $outage=$common->range_end->subtract_datetime($common->range_start);
  print "\nCommon outage range: "
    ,format_range($common)
    ,"\n"
    ,"Total Downtime: Months: $outage->{months}"
    ," Days: $outage->{days} Minutes: $outage->{minutes}"
    ," Seconds: $outage->{seconds}\n"
    ,'vpn_a '
    ,format_range($vpn_a)
    ,' '
    ,($vpn_a->missing ? 'up' : 'down')
    ,"\n"

    ,'vpn_b '
    ,format_range($vpn_b)
    ,' '
    ,($vpn_b->missing ? 'up' : 'down')
    ,"\n"

    ,'vpn_c '
    ,format_range($vpn_c)
    ,' '
    ,($vpn_c->missing ? 'up' : 'down')
    ,"\n";
}
