package Calendar::Any;
{
  $Calendar::Any::VERSION = '0.5';
}
use Carp;
use overload
    '<=>' => sub { $_[0]->absolute_date <=> (ref $_[1] ? $_[1]->absolute_date : $_[1]) },
    '+' => \&add,
    '-' => \&substract,
    '""' => \&date_string,
    '0+' => \&absolute_date;

sub new {
    my $_class = shift;
    my $class = ref $_class || $_class;
    my $self = {};
    bless $self, $class;
    if ( @_ ) {
        $self->{absolute} = shift;
    }
    return $self;
}

sub new_from_Astro {
    my ($self, $days) = @_;
    return $self->new($days - 1721424.5);
}

sub absolute_date {
    return shift->{absolute};
}

sub astro_date {
    return shift->absolute_date + 1721424.5;
}

sub today {
    my $self = shift;
    my @time = localtime;
    my $date = $self->new_from_Gregorian($time[4]+1, $time[3], $time[5]+1900);
    return $self->new($date->absolute_date);
}

#{{{  Format functions
our @weekday_name = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
our @month_name = qw(January February March April May June July August September October November December);
our $default_format = "%A";

sub year {
    return shift->{year};
}

sub month {
    return shift->{month};
}

sub day {
    return shift->{day};
}

sub weekday {
    return shift->{absolute} % 7;
}

sub weekday_name {
    return $weekday_name[shift->weekday];
}

sub month_name {
    return $month_name[shift->month-1];
}

sub date_string {
    my $self = shift;
    no strict;
    my $fmt = shift || ${(ref $self||$self)."::default_format"} || $default_format;
    $fmt =~ s/
              %(O?[%a-zA-Z])
             /
             ($self->can("format_$1") || sub { $1 })->($self);
             /sgeox;
    return $fmt;
}

sub format_d { sprintf("%02d", shift->day) }
sub format_m { sprintf("%02d", shift->month) }
sub format_A { shift->absolute_date }
sub format_w { shift->weekday }
sub format_W { shift->weekday_name }
sub format_M { shift->month_name }
sub format_Y { shift->year }
sub format_D {
    my $self = shift;
    return join("/", map { sprintf "%02d", $_ } $self->month, $self->day, $self->year);
}
sub format_F {
    my $self = shift;
    return join("-", map { sprintf "%02d", $_ } $self->year, $self->month, $self->day);
}
#}}}

#{{{  Overload Operators
sub substract {
    my ($self, $operand) = @_;
    if ( ref $operand ) {
        return $self->absolute_date - $operand->absolute_date;
    } else {
        return $self->new($self->absolute_date-$operand);
    }
}

sub add {
    my ($self, $operand) = @_;
    confess "operand must be numeric!\n" if ref $operand;
    $self->new($self->absolute_date + $operand);
}
#}}}

sub AUTOLOAD {
    no strict 'refs';
    our ($AUTOLOAD);
    (my $subname = $AUTOLOAD) =~ s/.*:://;
    if ( $AUTOLOAD =~ /::new_from_(\w+)/ ) {
        my $module = "Calendar::Any::" . $1;
        eval("require $module");
        if ( $@ ) {
            die "Can't load module $module: $@!\n"
        }
        my $sub = *{$subname} = sub {
            my $self = shift;
            return $module->new(@_);
        };
        goto &$sub;
    } elsif ( $AUTOLOAD =~ /::to_(\w+)/ ) {
        my $module = "Calendar::Any::" . $1;
        eval("require $module");
        if ( $@ ) {
            die "Can't load module $module: $@!\n"
        }
        my $sub = *{$subname} = sub {
            $_[0] = $module->new($_[0]->absolute_date);
            return $_[0];
        };
        goto &$sub;
    } elsif ( $AUTOLOAD =~ /DESTROY/) {
    } else {
        die "Unknown function $AUTOLOAD\n";
    }
}

1;

__END__

=head1 NAME

Calendar::Any - Perl extension for calendar convertion

=head1 VERSION

version 0.5

=head1 SYNOPSIS

   use Calendar::Any;
   my $date = Calendar::Any->new_from_Gregorian(12, 16, 2006);
   print $date->date_string("Gregorian date: %M %W %d %Y"), "\n";

   my $newdate = $date + 7;
   print $newdate->date_string("Gregorian date of next week: %D"), "\n";
   
   $newdate = $date-7;
   print $newdate->date_string("Absolute date of last week: %A\n");
   
   my $diff = $date-$newdate;
   printf "There is %d days between %s and %s\n",
       $diff, $date->date_string("%D"), $newdate->date_string("%D");
   
   $date->to_Julian;
   print $date->date_string("Julian date: %M %W %d %Y"), "\n";

=head1 DESCRIPTION

Calendar::Any is a class for calendar convertion or calculation. The
algorithm is from emacs calendar library. Most functions of this class
is simply rewrite from elisp to perl. 

=head2 Constructor

=over 4

=item new

All class of Calendar should accept absolute date to construct the
object. Other type of argument may also be acceptable. For example:

    use Calendar::Any::Gregorian;
    Calendar::Any::Gregorian->new(732662);
    Calendar::Any::Gregorian->new(12, 17, 2006);
    Calendar::Any::Gregorian->new(-year=>2006, -month=>12, -day=>17);

=item new_from_{Module}

Calendar::Any has AUTOLOAD function that can automatic call new function
from package. So the following construct are also valid:

    use Calendar::Any;
    Calendar::Any->new_from_Gregorian(732662);
    Calendar::Any->new_from_Gregorian(12, 17, 2006);
    Calendar::Any->new_from_Gregorian(-year=>2006, -month=>12, -day=>17);

=back

=head2 Convertion

Calendar::Any object can convert from each other. The function is name
`to_{Module}'. For example:

    $date = Calendar::Any->new_from_Gregorian(12, 17, 2006);
    $date->to_Julian;

Now $date is a Julian calendar date. If you want maintain $date not
change, use Calendar::Any->new_from_Julian($date->absolute_date) instead.

=head2 Operator

Calendar overload several operator. 

=over 4

=item +

A Calendar object can add a number of days. For example:

    $newdate = $date + 1;

The $newdate is next day of $date. You CANNOT add a date to another
date.

=item -

If a date substract from a number of days, that means the date before
the number of days. For example:

    $newdate = $date - 1;

The $newdate is the last day of $date.

When a date substract from another date, returns the days between the
two date. For example:

    $newdate = $date + 7;
    $days = $newdate - $date;        # $days is 7

=item <=>

Two date can compare from each other. For example:

    if ( $date2 > $date1 ) {
        print "$date2 is after $date1.\n";
    } else {
        print "$date2 is before $date1.\n";
    }    

=item ""

That means you can simply print the date without explicitly call a
method. For detail, read "Format date" section.

=back

=head2 Format date

Every calendar class has a format template: $default_format. You can
set the template. For example:

   Calendar::Any::Gregorian::$default_format = "%F";
   print Calendar::Any::Gregorian::today();  # 2012-05-18

The format function is `date_string'. The format
specifications as following:

   %%       PERCENT
   %A       Absoute date
   %d       numeric day of the month, with leading zeros (eg 01..31)
   %F       YYYY-MM-DD
   %D       MM/DD/YYYY
   %m       month number, with leading zeros (eg 01..31)
   %M       month name
   %W       day of the week
   %Y       year

For chinese calendar, the following specifications are available:

   %S       sexagesimal name, eg. "丙戌"
   %D       day name, eg. "初二"
   %Z       zodiac name, eg. "狗"
   %M       month name in chinese, eg. "十一月"
   %W       week day name in chinese, eg. "星期一"

Meanwhile, %Y, %m and %d now stand for Gregorian year, month and day.

=head2 Other method

=over 4

=item  absoute_date

The number of days elapsed between the Gregorian date 12/31/1 BC.
The Gregorian date Sunday, December 31, 1 BC is imaginary.

=item  astro_date

Astronomers use a simple counting of days elapsed since noon, Monday,
January 1, 4713 B.C. on the Julian calendar.  The number of days elapsed
is called the "Julian day number" or the "Astronomical day number".

=item  new_from_Astro

There is no package Calendar::Any::Astro. use new_from_Astro and astro_date
to convert between other type of calendar and astro calendar.

=item  today

Get the current date of local time. 

=item  weekday

The weekday number. 0 for sunday and 1 for monday.

=item  weekday_name

The full name of the weekday.

=item  month

The number of month, range from 1 to 12.

=item  month_name

The full name of month.

=item  day

The number of day in the month. The first day in the month is 1.

=item  year

The year number.

=back

=head1 AUTHOR

Ye Wenbin <wenbinye@gmail.com>

=head1 SEE ALSO

L<Calendar::Any::Gregorian>, L<Calendar::Any::Julian>, L<Calendar::Any::Chinese>

=head1 COPYRIGHT

Copyright (c) 2012 by Ye Wenbin

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
