package Date::Calc::Endpoints;
use base qw(Class::Accessor);
use strict;
use vars qw($VERSION);

use Date::Calc qw(
                  Today
                  Add_Delta_YMD
                  check_date
                  Day_of_Week
                  Monday_of_Week
                  Week_of_Year
                  );

__PACKAGE__->mk_accessors(qw(
                              type intervals direction span sliding_window
                              start_dow start_dow_name start_dom start_moy
                              today_date error print_format
                            ));

$VERSION = 1.03;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %args = @_;
    $self->_set_default_parameters();
    $self->_set_passed_parameters(\%args);
    return $self;
}

sub get_dates {
    my $self = shift;
    $self->clear_error;
    my %args = @_;
    if (scalar keys %args) {
        $self->_set_passed_parameters(\%args);
    }
    if (!$self->type) {
        $self->set_error("Cannot get dates - no range type specified");
        return ();
    }
    my @start = $self->_get_start_date;
    unless (scalar @start) {
        return ();
    }
    my @end = $self->_get_end_date(@start);
    unless (scalar @end) {
        return ();
    }
    my @last = $self->_get_last_date(@end);
    unless (scalar @last) {
        return ();
    }

    my $start_date = $self->_array_to_date(@start);
    my $end_date = $self->_array_to_date(@end);
    my $last_date = $self->_array_to_date(@last);
    return ($start_date,$end_date,$last_date);
}

sub set_type {
    my ($self, $type) = @_;
    return 0 unless defined $type;
    $type = uc($type);
    my %valid_types = ('DAY' => 1 , 'WEEK' => 1 , 'MONTH' => 1 , 'QUARTER' => 1 , 'YEAR' => 1);
    unless ($valid_types{$type}) {
        $self->set_error("Invalid type $type");
        $self->type('');
        return 0;
    }
    $self->type($type);
    return 1;
}

sub get_type {
    my $self = shift;
    return $self->type;
}

sub set_intervals {
    my ($self, $intervals) = @_;
    return 0 unless defined $intervals;
    if ($intervals =~ /^(?:-)?\d+$/) {
        $self->intervals($intervals);
        return 1;
    }
    else {
        $self->set_error("Invalid intervals, \"$intervals\"");
        return 0;
    }
}

sub get_intervals {
    my $self = shift;
    return $self->intervals;
}

sub set_span {
    my ($self, $span) = @_;
    return 0 unless defined $span;
    if ($span =~ /^\d+$/ and $span > 0) {
        $self->span($span);
        return 1;
    }
    else {
        $self->set_error("Invalid span, \"$span\"");
        return 0;
    }
}

sub get_span {
    my $self = shift;
    return $self->span;
}

sub set_start_day_of_week {
    my ($self, $start_dow) = @_;
    return 0 unless defined $start_dow;
    $start_dow = uc($start_dow);
    my %valid_dow = (
                       'MONDAY'    => 1,
                       'TUESDAY'   => 2,
                       'WEDNESDAY' => 3,
                       'THURSDAY'  => 4,
                       'FRIDAY'    => 5,
                       'SATURDAY'  => 6,
                       'SUNDAY'    => 7,
                    );
    if (exists $valid_dow{$start_dow}) {
        $self->start_dow($valid_dow{$start_dow});
        $self->_set_start_dow_name($start_dow);
        return 1;
    }
    else {
        $self->set_error("Invalid start day of week, \"$start_dow\"");
        return 0;
    }
}

sub get_start_day_of_week {
    my $self = shift;
    return $self->start_dow;
}

sub set_start_day_of_month {
    my ($self, $start_dom) = @_;
    return 0 unless defined $start_dom;
    if ($start_dom =~ /^\d+$/ and $start_dom >= 1 and $start_dom <= 28) {
        $self->start_dom($start_dom);
    } else {
        $self->set_error("Invalid start day of month, \"$start_dom\"");
        return 0;
    }
    return 1;
}

sub get_start_day_of_month {
    my $self = shift;
    return $self->start_dom;
}

sub set_start_month_of_year {
    my ($self, $start_moy) = @_;
    return 0 unless defined $start_moy;
    if ($start_moy =~ /^\d+$/ and $start_moy >= 1 and $start_moy <= 12) {
        $self->start_moy($start_moy);
    } else {
        $self->set_error("Invalid start month of year, \"$start_moy\"");
        return 0;
    }
    return 1;
}

sub get_start_month_of_year {
    my $self = shift;
    return $self->start_moy;
}

sub set_today_date {
    my ($self, @today) = @_;
    if (scalar @today) {
        my @verified_date = $self->_date_to_array(@today);
        if (@verified_date) {
            $self->today_date(@verified_date);
            return 1;
        }
        my $temp = join(":",@today);
        $self->set_error("Today override failed validation, \"$temp\"");
        return 0;
    }
    else {
        $self->today_date(Today);
        return 1;
    }
}

sub get_today_date {
    my $self = shift;
    return @{$self->today_date};
}

sub set_sliding_window {
    my ($self, $sliding_window) = @_;
    return 0 unless defined $sliding_window;
    if ($sliding_window == 0 or $sliding_window == 1) {
        $self->sliding_window($sliding_window);
        return 1;
    }
    else {
        $self->set_error("Invalid sliding window, \"$sliding_window\"");
        return 0;
    }
}

sub get_sliding_window {
    my $self = shift;
    return $self->sliding_window;
}

sub set_direction {
    my ($self,$direction) = @_;
    return 0 unless defined $direction;
    if ($direction =~ /^[\+-]$/) {
        $self->direction($direction);
        return 1;
    }
    $self->set_error("Invalid direction argument, \"$direction\"");
    return 0;
}

sub get_direction {
    my $self = shift;
    return $self->direction;
}

sub set_error {
    my ($self, $msg) = @_;
    my @existing = @{$self->error};
    push @existing, $msg;
    $self->error(\@existing);
}

sub get_error {
    my $self = shift;
    return $self->error;
}

sub clear_error {
    my $self = shift;
    $self->error([]);
}

################################################################################
sub _set_default_parameters {
    my $self = shift;
    $self->set_intervals(1);
    $self->set_span(1);
    $self->set_start_day_of_week('MONDAY');
    $self->set_start_day_of_month(1);
    $self->set_start_month_of_year(1);
    $self->_set_print_format('%04d-%02d-%02d');
    $self->set_today_date();
    $self->set_sliding_window(0);
    $self->set_direction('-');
    $self->clear_error();
}

sub _set_passed_parameters {
    my $self = shift;
    my $hash = shift;
    $self->set_type($hash->{type})             if exists $hash->{type};
    $self->set_intervals($hash->{intervals})   if exists $hash->{intervals};
    $self->set_span($hash->{span})             if exists $hash->{span};
    $self->set_today_date($hash->{today_date}) if exists $hash->{today_date};
    $self->set_direction($hash->{direction})   if exists $hash->{direction};
    $self->set_start_day_of_week($hash->{start_day_of_week})
        if exists $hash->{start_day_of_week};
    $self->set_sliding_window($hash->{sliding_window})
        if exists $hash->{sliding_window};
    $self->set_start_day_of_month($hash->{start_day_of_month})
       if exists $hash->{start_day_of_month};
    $self->set_start_month_of_year($hash->{start_month_of_year})
         if exists $hash->{start_month_of_year};
}

sub _get_start_date {
    my $self = shift;
    my $direction = $self->get_direction;
    my @start = $self->_start_reference;
    my $span = $self->get_span;
    my $intervals = $self->get_intervals;
    my @delta = $self->_delta_per_period;
    if ($direction eq '-') {
        @delta = _negate(@delta);
    }
    my $map_factor;
    if ($self->get_sliding_window) {
        $map_factor = ($direction eq '+') ? $intervals
                    :                      ($span + $intervals - 1)
                    ;
    } else {
        $map_factor = $span * $intervals;
    }
    @delta = map { $_ * $map_factor } @delta;
    @start = $self->_add_delta_ymd(@start, @delta);
    return @start;
}

sub _get_end_date {
    my $self = shift;
    my @start = @_;
    my @delta = $self->_delta_ymd;
    my @end = $self->_add_delta_ymd(@start,@delta);
    return @end;
}

sub _get_last_date {
    my $self = shift;
    my @end = @_;
    @end = $self->_add_delta_ymd(@end,(0,0,-1));
    return @end;
}

sub _start_reference {
    my $self = shift;
    my @start = $self->get_today_date;
    my $type = $self->get_type;
    if ($type eq 'YEAR') {
        my $start_moy = $self->get_start_month_of_year;
        if ($start_moy > $start[1]) {
            @start = $self->_add_delta_ymd(@start,(-1,0,0));
        }
        $start[1] = $start_moy;
        $start[2] = 1;
    } elsif ($type eq 'QUARTER') {
        $start[1] -= ( ( $start[1] - 1 ) % 3 );
        $start[2] = 1;
    } elsif ($type eq 'MONTH') {
        my $start_dom = $self->get_start_day_of_month;
        if ($start_dom > $start[2]) {
            @start = $self->_add_delta_ymd(@start,(0,-1,0));
        }
        $start[2] = $start_dom;
    } elsif ($type eq 'WEEK') {
        ## Calculate the "Monday" of the current week, and add the number of days to get to
        ## desired start date.  If that start day-of-week is "after" the "current" day-of-week,
        ## that start date will be in the future.  Will need to subtract a week.
        my $start_dow = $self->get_start_day_of_week;
        my $today_dow = Day_of_Week(@start);
        @start = $self->_add_delta_ymd(Monday_of_Week(Week_of_Year(@start)),(0,0,$start_dow - 1));
        ## NEED MORE HERE _ this is just "monday" at this point
        if ($today_dow < $start_dow) {
            @start = $self->_add_delta_ymd(@start,(0,0,-7));
        }
    } elsif ($type eq 'DAY') {
        ## No change
    }
    return @start;
}

sub _set_start_dow_name {
    my ($self,$start_dow_name) = @_;
    $self->start_dow_name($start_dow_name);
}

sub _get_start_dow_name {
    my $self = shift;
    return $self->start_dow_name;
}

sub _set_print_format {
    my ($self, $format) = @_;
    ## valid: %s, %d, '/', '-', ' ', ':'
    my $validate = $format;
    $validate =~ s/[\/\- :]//g;
    $validate =~ s/%[0-9]*d//g;
    if ($validate) {
        $self->set_error("Suspect output format: \"$format\"");
        return 0;
    }
    $self->print_format($format);
    return 1;
}

sub _get_print_format {
    my $self = shift;
    return $self->print_format;
}

sub _delta_ymd {
    my $self = shift;
    my $span = $self->get_span;
    my @single_delta = $self->_delta_per_period;
   my @total_delta = map { $span * $_ } @single_delta;
   return @total_delta;
}

sub _delta_per_period {
    my $self = shift;
    my $type = $self->get_type;
    return $type eq 'YEAR'    ? (1,0,0)
         : $type eq 'QUARTER' ? (0,3,0)
         : $type eq 'MONTH'   ? (0,1,0)
         : $type eq 'WEEK'    ? (0,0,7)
         :                      (0,0,1)
}

sub _negate {
    my @negatives = map { -1 * $_ } @_;
    return @negatives;
}

sub _date_to_array {
    my ($self,@date) = @_;
    if (scalar(@date) == 1 and $date[0] =~ /^(\d+)-(\d+)-(\d+)$/) {
        @date = ($1,$2,$3);
    }
    if ((scalar(@date) == 3) and
        ($date[0] =~ /^\d+$/) and
        ($date[1] =~ /^\d+$/) and
        ($date[2] =~ /^\d+$/) and
        (check_date(@date))) {
        return (@date);
    }
    else {
        $self->set_error("Invalid \"today\": " . join("-",@date));
    }
    return ();
}

sub _array_to_date {
    my ($self, @date) = @_;
    my $format = $self->_get_print_format();
    return sprintf $format, @date;
}

sub _add_delta_ymd {
    my ($self,@date_info) = @_;
    my @new_date = ();
    eval {
        @new_date = Add_Delta_YMD(@date_info);
    };
    if ($@) {
        my $errstring = sprintf "Cannot calculate date diff: (%d,%d,%d) + (%d,%d,%d)", @date_info;
        $self->set_error($errstring);
    }
    return @new_date;
}

1;

__END__
