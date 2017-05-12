package Data::FormValidator::Constraints::DateTime;
use strict;
use DateTime;
use DateTime::Format::Strptime;
use Scalar::Util qw(blessed);
use Exporter;
use Carp qw(croak);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    to_datetime
    ymd_to_datetime
    before_today
    after_today
    ymd_before_today
    ymd_after_today
    before_datetime
    after_datetime
    between_datetimes
    to_mysql_datetime
    to_mysql_date
    to_mysql_timestamp
    to_pg_datetime
);

our %EXPORT_TAGS = (
    all     => \@EXPORT_OK,
    mysql   => [qw(to_mysql_datetime to_mysql_date to_mysql_timestamp)],
    pg      => [qw(to_pg_datetime)],
);
our $VERSION = '1.11';

=head1 NAME

Data::FormValidator::Constraints::DateTime - D::FV constraints for dates and times

=head1 DESCRIPTION

This package provides constraint routines for L<Data::FormValidator> for
dealing with dates and times. It provides an easy mechanism for validating
dates of any format (using strptime(3)) and transforming those dates (as long
as you 'untaint' the fields) into valid L<DateTime> objects, or into strings 
that would be properly formatted for various database engines.

=head1 ABSTRACT

  use Data::FormValidator;
  use Data::FormValidator::Constraints::DateTime qw(:all);
    
  # create our profile
  my $profile = {
      required                => [qw(my_date)],
      constraint_methods      => {
          my_date   => to_datetime('%D'), # in the format MM/DD/YYYY
      },
      untaint_all_constraints => 1,
  };

  # validate 'my_date'
  my $results = Data::FormValidator->check($my_input, $profile);

  if( $results->success ) {
    # if we got here then $results->valid('my_date')
    # is a valid DateTime object 
    my $datetime = $results->valid('my_date');
    .
    .
  }

=head1 STRPTIME FORMATS

Most of the validation routines provided by this module use
strptime(3) format strings to know what format your date string
is in before we can process it. You specify this format for each
date you want to validate using by passing it to constraint
generation routine (see the example above).

We use L<DateTime::Format::Strptime> for this transformation. 
If you need a list of these formats (if you haven't yet committed 
them to memory) you can see the strptime(3) man page (if you are 
on a *nix system) or you can see the L<DateTime::Format::Strptime> 
documentation.

There are however some routines that can live without the format
param. These include routines which try and validate according
to rules for a particular database (C<< to_mysql_* >> and 
C<< to_pg_* >>). If no format is provided, then we will attempt to
validate according to the rules for that datatype in that database
(using L<DateTime::Format::MySQL> and L<DateTime::Format::Pg>).
Here are some examples:

without a format param

 my $profile = {
   required                => [qw(my_date)],
   constraint_methods      => {
       my_date => to_mysql_datetime(),
   },
 };

with a format param

 my $profile = {
   required                => [qw(my_date)],
   constraint_methods      => {
       my_date => to_mysql_datetime('%m/%d/%Y'),
   },
 };

=head2 DateTime::Format Objects

Using strptime(3) format strings gives a lot of flexibility, but sometimes
not enough. Suppose you have a web form that allows the user to input a date
in the format '11/21/2006' or simply '11/21/06'. A simple format string is
not enough. To take full advantage of the DateTime project, any place that
you can pass in a strptime(3) format string, you can also pass in a
L<DateTime::Format> object. To solve the above problem you might have code
that looks like this:

  # your formatter code
  package MyProject::DateTime::FlexYear;
  use DateTime::Format::Strptime;

  use DateTime::Format::Builder (
    parsers => { 
      parse_datetime => [
        sub { eval { DateTime::Format::Strptime->new(pattern => '%m/%d/%Y')->parse_datetime($_[1]) } },
        sub { eval { DateTime::Format::Strptime->new(pattern => '%m/%d/%y')->parse_datetime($_[1]) } },
      ] 
    }
  );

  1;

  # in your web validation code
  my $profile = {
    required           => [qw(my_date)],
    constraint_methods => {
        my_date => to_mysql_datetime(MyProject::DateTime::FlexYear->new()),
    },
  };


=head1 VALIDATION ROUTINES

Following is the list of validation routines that are provided
by this module.

=head2 to_datetime

The routine will validate the date aginst a strptime(3) format and
change the date string into a DateTime object. This routine B<must> 
have an accompanying L<strptime|DateTime::Format::Strptime> format param.

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub to_datetime {
    my $format = shift;
    # dereference stuff if we need to

    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );
        return match_to_datetime($dfv, $format);
    }
}

sub match_to_datetime {
    my ($dfv, $format) = @_;
    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $dfv ? $dfv->get_current_constraint_value : $dfv;
    # get the DateTime
    my $dt = _get_datetime_from_strp($value, $format);
    return $dt;
}

sub _get_datetime_from_strp {
    my ($value, $format) = @_;
    $format = $$format if( ref $format eq 'SCALAR' );
    my $formatter;
    # if we have a simple scalar for the format
    if( ! ref $format ) {
        # create the formatter
        $formatter = DateTime::Format::Strptime->new(
            pattern => $format
        );
    # else we assume it's a DateTime::Format based object
    } else {
        $formatter = $format;
    }

    # create the DateTime object
    my $dt;
    eval { $dt = $formatter->parse_datetime($value); };
    # set the formatter (if we can) so that the object
    # stringifies to the same format as we parsed
    $dt->set_formatter($formatter)
        if( $dt && $formatter->can('format_datetime') );
    return $dt;
}

=head2 ymd_to_datetime

This routine is used to take multiple inputs (one each for the
year, month, and day) and combine them into a L<DateTime> object,
validate the resulting date, and give you the resulting DateTime
object in your C<< valid() >> results. It must recieve as C<< params >>
the year, month, and day inputs in that order. You may also specify
additional C<< params >> that will be interpretted as 'hour', 'minute'
and 'second' values to use. If none are provided, then the time '00:00:00'
will be used.

 my $profile = {
   required                => [qw(my_year)],
   constraint_methods      => {
      my_year => ymd_to_datetime(qw(my_year my_month my_day my_hour my_min my_sec)),
   },
 };

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub ymd_to_datetime {
    my ($year, $month, $day, $hour, $min, $sec) = @_;
    
    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );
        my $data = $dfv->get_input_data(as_hashref => 1);
        return match_ymd_to_datetime(
            $dfv, 
            _get_value($year,  $data),
            _get_value($month, $data),
            _get_value($day,   $data),
            _get_value($hour,  $data),
            _get_value($min,   $data),
            _get_value($sec,   $data),
        );
    };
}

sub _get_value {
    my ($value, $data) = @_;
    if( $value && exists $data->{$value} ) {
        return $data->{$value};
    } else {
        return $value;
    }
}

sub match_ymd_to_datetime {
    my ($dfv, $year, $month, $day, $hour, $min, $sec);

    # if we were called as a 'constraint_method'
    if( ref $_[0] ) {
        ($dfv, $year, $month, $day, $hour, $min, $sec) = @_;
    # else we were called as a 'constraint'
    } else {
        ($year, $month, $day, $hour, $min, $sec) = @_;
    }
        
    # make sure year, month and day are positive numbers
    if( 
        defined $year && $year ne "" 
        && defined $month && $month ne "" 
        && defined $day && $day ne "" 
    ) {
        # set the defaults for time if we don't have any
        $hour ||= 0;
        $min  ||= 0;
        $sec  ||= 0;
    
        my $dt;
        eval {
            $dt = DateTime->new(
                year    => $year,
                month   => $month,
                day     => $day,
                hour    => $hour,
                minute  => $min,
                second  => $sec,
            );
        };
        
        return $dt;
    } else {
        return;
    }
}

=head2 before_today

This routine will validate the date and make sure it less than or
equal to today (using C<< DateTime->today >>). It takes one param
which is the <strptime|DateTime::Format::Strptime> format string for the date.

If it validates and you tell D::FV to untaint this parameter it will be
converted into a DateTime object.

 # make sure they weren't born in the future
 my $profile = {
   required                => [qw(birth_date)],
   constraint_methods      => {
      birth_date => before_today('%m/%d/%Y'),
   },
 };

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub before_today {
    my $format = shift;

    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );
        return match_before_today($dfv, $format);
    };
}

sub match_before_today {
    my ($dfv, $format) = @_;
    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $dfv ? $dfv->get_current_constraint_value : $dfv;
    # get the DateTime
    my $dt = _get_datetime_from_strp($value, $format);
    my $dt_target = DateTime->today();
    # if we have valid DateTime objects and they have the correct
    # temporaral relationship
    if( $dt && $dt_target && $dt <= $dt_target ) {
        return $dt;
    } else {
        return;
    }
}

=head2 after_today

This routine will validate the date and make sure it is greater
than or equal to today (using C<< DateTime->today() >>). It takes
only one param, which is the L<strptime|DateTime::Format::Strptime> format for the date being
validated.

If it validates and you tell D::FV to untaint this parameter it will be
converted into a DateTime object.

 # make sure the project isn't already due
 my $profile = {
   required                => [qw(death_date)],
   constraint_methods      => {
      death_date => after_today('%m/%d/%Y'),
   },
   untaint_all_constraints => 1,
 };

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub after_today {
    my $format = shift;

    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );
        return match_after_today($dfv, $format);
    };
}

sub match_after_today {
    my ($dfv, $format) = @_;
    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $dfv ? $dfv->get_current_constraint_value : $dfv;
    # get the DateTime
    my $dt = _get_datetime_from_strp($value, $format);
    my $dt_target = DateTime->today();
    # if we have valid DateTime objects and they have the correct
    # temporaral relationship
    if( $dt && $dt_target && $dt >= $dt_target ) {
        return $dt;
    } else {
        return;
    }
}


=head2 ymd_before_today

This routine will validate the date and make sure it less than or
equal to today (using C<< DateTime->today >>). It works just like
L<ymd_to_datetime> in the parameters it takes.

If it validates and you tell D::FV to untaint this parameter it will be
converted into a DateTime object.

 # make sure they weren't born in the future
 my $profile = {
   required                => [qw(birth_date)],
   constraint_methods      => {
      birth_date => ymd_before_today(qw(dob_year dob_month dob_day)),
   },
   untaint_all_constraints => 1,
 };

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub ymd_before_today {
    my ($year, $month, $day, $hour, $min, $sec) = @_;
    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );

        my $data = $dfv->get_input_data(as_hashref => 1);
        return match_ymd_before_today(
            $dfv, 
            _get_value($year,  $data),
            _get_value($month, $data),
            _get_value($day,   $data),
            _get_value($hour,  $data),
            _get_value($min,   $data),
            _get_value($sec,   $data),
        );
    };
}

sub match_ymd_before_today {
    my $dt = match_ymd_to_datetime(@_);
    if( $dt && ( $dt <= DateTime->today ) ) {
      return $dt;
    }
    return; # if we get here then it's false
}

=head2 ymd_after_today

This routine will validate the date and make sure it greater than or
equal to today (using C<< DateTime->today >>). It works just like
L<ymd_to_datetime> in the parameters it takes.

If it validates and you tell D::FV to untaint this parameter it will be
converted into a DateTime object.

 # make sure the project isn't already due
 my $profile = {
   required                => [qw(due_date)],
   constraint_methods      => {
      birth_date => ymd_after_today(qw(dob_year dob_month dob_day)),
   },
   untaint_all_constraints => 1,
 };

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub ymd_after_today {
    my ($year, $month, $day, $hour, $min, $sec) = @_;
    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );

        my $data = $dfv->get_input_data(as_hashref => 1);
        return match_ymd_after_today(
            $dfv, 
            _get_value($year,  $data),
            _get_value($month, $data),
            _get_value($day,   $data),
            _get_value($hour,  $data),
            _get_value($min,   $data),
            _get_value($sec,   $data),
        );
    };
}

sub match_ymd_after_today {
    my $dt = match_ymd_to_datetime(@_);
    if( $dt && ( $dt >= DateTime->today ) ) {
      return $dt;
    }
    return; # if we get here then it's false
}

=head2 before_datetime

This routine will validate the date and make sure it occurs before
the specified date. It takes two params: 

=over

=item * first, the L<strptime|DateTime::Format::Strptime> format 

(for both the date we are validating and also the date we want to 
compare against) 

=item * second, the date we are comparing against. 

This date we are comparing against can either be a specified date (using 
a scalar ref), or a named parameter from your form (using a scalar name).

=back

If it validates and you tell D::FV to untaint this parameter it will be
converted into a DateTime object.

 # make sure they were born before 1979
 my $profile = {
   required                => [qw(birth_date)],
   constraint_methods      => {
      birth_date => before_datetime('%m/%d/%Y', '01/01/1979'),
   },
   untaint_all_constraints => 1,
 };

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub before_datetime {
    my ($format, $date) = @_;
    # dereference stuff if we need to
    $date = $$date if( ref $date eq 'SCALAR' );

    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );

        # are we using a real date or the name of a parameter
        my $data = $dfv->get_input_data(as_hashref => 1);
        $date = $data->{$date} if( $data->{$date} );
        return match_before_datetime($dfv, $format, $date);
    };
}

sub match_before_datetime {
    my ($dfv, $format, $target_date) = @_;
    $target_date = $$target_date if( ref $target_date eq 'SCALAR' );
    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $dfv ? $dfv->get_current_constraint_value : $dfv;
    # get the DateTime
    my $dt = _get_datetime_from_strp($value, $format);
    my $dt_target = _get_datetime_from_strp($target_date, $format);
    # if we have valid DateTime objects and they have the correct
    # temporaral relationship
    if( $dt && $dt_target && $dt < $dt_target ) {
        return $dt;
    } else {
        return;
    }
}

=head2 after_datetime

This routine will validate the date and make sure it occurs after
the specified date. It takes two params: 

=over

=item * first, the L<strptime|DateTime::Format::Strptime> format 

(for both the date we are validating and also the date we want to 
compare against)

=item * second, the date we are comparing against. 

This date we are comparing against can either be a specified date (using a 
scalar ref), or a named parameter from your form (using a scalar name).

=back

 # make sure they died after they were born
 my $profile = {
   required                => [qw(birth_date death_date)],
   constraint_methods      => {
      death_date => after_datetime('%m/%d/%Y', 'birth_date'),
   },
   untaint_all_constraints => 1,
 };

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub after_datetime {
    my ($format, $date) = @_;
    # dereference stuff if we need to
    $date = $$date if( ref $date eq 'SCALAR' );

    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );

        # are we using a real date or the name of a parameter
        my $data = $dfv->get_input_data(as_hashref => 1);
        $date = _get_value($date, $data);
        return match_after_datetime($dfv, $format, $date);
    };
}

sub match_after_datetime {
    my ($dfv, $format, $target_date) = @_;
    $target_date = $$target_date if( ref $target_date eq 'SCALAR' );
    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $dfv ? $dfv->get_current_constraint_value : $dfv;
    # get the DateTime
    my $dt = _get_datetime_from_strp($value, $format);
    my $dt_target = _get_datetime_from_strp($target_date, $format);
    # if we have valid DateTime objects and they have the correct
    # temporaral relationship
    if( $dt && $dt_target && $dt > $dt_target ) {
        return $dt;
    } else {
        return;
    }
}

=head2 between_datetimes

This routine will validate the date and make sure it occurs after
the first specified date and before the second specified date. It 
takes three params: 

=over

=item * first, the L<strptime|DateTime::Format::Strptime> format 

(for both the date we are validating and also the dates we want to 
compare against)

=item * second, the first date we are comparing against. 

=item * third, the second date we are comparing against. 

This date (and the second) we are comparing against can either be a specified date 
(using a scalar ref), or a named parameter from your form (using a scalar name).

=back

 # make sure they died after they were born
 my $profile = {
   required                => [qw(birth_date death_date marriage_date)],
   constraint_methods      => {
      marriage_date => between_datetimes('%m/%d/%Y', 'birth_date', 'death_date'),
   },
   untaint_all_constraints => 1,
 };

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub between_datetimes {
    my ($format, $target1, $target2) = @_;
    # dereference stuff if we need to
    $target1 = $$target1 if( ref $target1 eq 'SCALAR' );
    $target2 = $$target2 if( ref $target2 eq 'SCALAR' );

    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );

        # are we using a real date or the name of a parameter
        my $data = $dfv->get_input_data(as_hashref => 1);
        $target1 = _get_value($target1, $data);
        $target2 = _get_value($target2, $data);
        return match_between_datetimes($dfv, $format, $target1, $target2);
    }
}

sub match_between_datetimes {
    my ($dfv, $format, $target1, $target2) = @_;
    $target1 = $$target1 if( ref $target1 eq 'SCALAR' );
    $target2 = $$target2 if( ref $target2 eq 'SCALAR' );

    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $dfv ? $dfv->get_current_constraint_value : $dfv;
    # get the DateTime
    my $dt = _get_datetime_from_strp($value, $format);
    my $dt_target1 = _get_datetime_from_strp($target1, $format);
    my $dt_target2 = _get_datetime_from_strp($target2, $format);
    # if we have valid DateTime objects and they have the correct
    # temporaral relationship
    if( 
        $dt 
        && $dt_target1 
        && $dt_target2 
        && $dt > $dt_target1 
        && $dt < $dt_target2 
    ) {
        return $dt;
    } else {
        return;
    }
}

=head1 DATABASE RELATED VALIDATION ROUTINES

=head2 to_mysql_datetime

The routine will change the date string into a DATETIME datatype
suitable for MySQL. If you don't provide a format parameter then
this routine will just validate the data as a valid MySQL DATETIME
datatype (using L<DateTime::Format::MySQL>).

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub to_mysql_datetime {
    my $format = shift;

    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );
        return match_to_mysql_datetime($dfv, $format);
    }
}

sub match_to_mysql_datetime {
    my ($dfv, $format) = @_;
    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $dfv ? $dfv->get_current_constraint_value : $dfv;

    # make sure they have DateTime::Format::MySQL
    eval { require DateTime::Format::MySQL; };
    die "DateTime::Format::MySQL is required to use this routine"
        if( $@ );
    my $dt;

    # if they gave us a format (through params as a scalar ref)
    # then translate the value
    if( $format ) {
        $dt = _get_datetime_from_strp($value, $format);
    # else there is no format, so just use parse_datetime
    } else {
        eval { $dt = DateTime::Format::MySQL->parse_datetime($value) };
    }
    if( $dt ) {
        return DateTime::Format::MySQL->format_datetime($dt); 
    } else {
        return undef;
    }
}

=head2 to_mysql_date

The routine will change the date string into a DATE datatype
suitable for MySQL. If you don't provide a format param then
this routine will validate the data as a valid DATE datatype
in MySQL (using L<DateTime::Format::MySQL>).

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub to_mysql_date {
    my $format = shift;

    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );
        return match_to_mysql_date($dfv, $format);
    };
}

sub match_to_mysql_date {
    my ($dfv, $format) = @_;
    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $dfv ? $dfv->get_current_constraint_value : $dfv;

    # make sure they have DateTime::Format::MySQL
    eval { require DateTime::Format::MySQL; };
    die "DateTime::Format::MySQL is required to use this routine"
        if( $@ );
    my $dt;

    # if they gave us a format (through params as a scalar ref)
    # then translate the value
    if( $format ) {
        $dt = _get_datetime_from_strp($value, $format);
    # else there is no format, so just use parse_datetime
    } else {
        eval { $dt = DateTime::Format::MySQL->parse_date($value) };
    }
    if( $dt ) {
        return DateTime::Format::MySQL->format_date($dt);
    } else {
        return undef;
    }
}

=head2 to_mysql_timestamp

The routine will change the date string into a TIMESTAMP datatype
suitable for MySQL. If you don't provide a format then the data
will be validated as a MySQL TIMESTAMP datatype.

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub to_mysql_timestamp {
    my $format = shift;

    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );
        match_to_mysql_timestamp($dfv, $format);
    };
}

sub match_to_mysql_timestamp {
    my ($dfv, $format) = @_;
    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $dfv ? $dfv->get_current_constraint_value : $dfv;
    my $dt;

    # if they gave us a format (through params as a scalar ref)
    # then translate the value
    if( $format ) {
        $dt = _get_datetime_from_strp($value, $format);
    # else there is no format, so parse into a timestamp
    } else {
        # if it matches a timestamp format YYYYMMDDHHMMSS
        # but we're actually a little looser than that... we take
        # YYYY-MM-DD HH:MM:SS with any other potential separators
        if( $value =~ /(\d{4})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})\D*(\d{2})/ ) {
            eval { 
                $dt = DateTime->new(
                    year    => $1,
                    month   => $2,
                    day     => $3,
                    hour    => $4,
                    minute  => $5,
                    second  => $6,
                );
            };
        }
    }
    if( $dt ) {
        return $dt->ymd('') . $dt->hms('');
    } else {
        return undef;
    }
}

=head2 to_pg_datetime

The routine will change the date string into a DATETIME datatype
suitable for PostgreSQL. If you don't provide a format then the
data will validated as a DATETIME datatype in PostgresSQL (using
L<DateTime::Format::Pg>).

If the value is untainted (using C<untaint_all_constraints> or
C<untaint_constraint_fields>, it will change the date string into a DateTime
object.

=cut

sub to_pg_datetime {
    my $format = shift;

    return sub {
        my $dfv = shift;
        croak("Must be called using 'constraint_methods'!")
            unless( blessed $dfv && $dfv->isa('Data::FormValidator::Results') );
        match_to_pg_datetime($dfv, $format);
    };
}

sub match_to_pg_datetime {
    my ($dfv, $format) = @_;
    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constaint'
    my $value = ref $dfv ? $dfv->get_current_constraint_value : $dfv;

    # make sure they have DateTime::Format::MySQL
    eval { require DateTime::Format::Pg; };
    die "DateTime::Format::Pg is required to use this routine"
        if( $@ );
    my $dt;

    # if they gave us a format (through params as a scalar ref)
    # then translate the value
    if( $format ) {
        $dt = _get_datetime_from_strp($value, $format);
    # else there is no format, so just use parse_datetime
    } else {
        eval { $dt = DateTime::Format::Pg->parse_datetime($value) };
    }
    if( $dt ) {
        return DateTime::Format::Pg->format_datetime($dt);
    } else {
        return undef;
    }
}


=head1 AUTHOR

Michael Peters <mpeters@plusthree.com>

Thanks to Plus Three, LP (http://www.plusthree.com) for sponsoring my work on this module

=head1 CONTRIBUTORS

=over 

=item Mark Stosberg <mark@summersault.com>

=item Charles Frank <cfrank@plusthree.com>

=item Aaron Ross <aaronelliotross@gmail.com>

=back

=head1 SUPPORT

This module is a part of the larger L<Data::FormValidator> project. If you have
questions, comments, bug reports or feature requests, please join the 
L<Data::FormValidator>'s mailing list.

=head1 CAVEAT

When passing parameters to typical L<Data::FormValidator> constraints you pass
plain scalars to refer to query params and scalar-refs to refer to literals. We get
around that in this module by assuming everything could be refering to a query param,
and if one is not found, then it's a literal. This works well unless you have query
params with names like C<'01/02/2005'> or C<'%m/%d/%Y'>. 

And if you do, shame on you for having such horrible names.

=head1 SEE ALSO

L<Data::FormValidator>, L<DateTime>. L<DateTime::Format::Strptime>,
L<DateTime::Format::MySQL>, L<DateTime::Format::Pg>

=head1 COPYRIGHT & LICENSE

Copyright Michael Peters 2010, all rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

