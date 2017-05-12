package Class::Date::Const;
use strict;

use vars qw(@EXPORT @ISA @ERROR_MESSAGES %EXPORT_TAGS);
use Exporter;

our $VERSION = '1.1.15';

my %FIELDS = (
    # Class::Date fields
    c_year      =>  0,
    c_mon       =>  1,
    c_day       =>  2,
    c_hour      =>  3,
    c_min       =>  4,
    c_sec       =>  5,
    c_wday      =>  6,
    c_yday      =>  7,
    c_isdst     =>  8,
    c_epoch     =>  9,
    c_tz        => 10,
    c_error     => 11,
    c_errmsg    => 12,
    # Class::Date::Rel fields
    cs_mon      => 0,
    cs_sec      => 1,
    # Class::Date::Invalid fields
    ci_error    => 0,
    ci_errmsg   => 1,
);

eval " sub $_ () { ".$FIELDS{$_}."}" foreach keys %FIELDS;
@ISA = qw(Exporter);

my @ERRORS = ( 
    E_OK         => '',
    E_INVALID    => 'Invalid date or time',
    E_RANGE      => 'Range check on date or time failed',
    E_UNPARSABLE => 'Unparsable date or time: %s',
    E_UNDEFINED  => 'Undefined date object',
);

my @ERR;
# predeclaring error constants
my $c = 0;
while (@ERRORS) {
    my $errorcode = shift @ERRORS;
    my $errorname = shift @ERRORS;
    eval "sub $errorcode () { $c }";
    $ERROR_MESSAGES[$c] = $errorname;
    push @{$EXPORT_TAGS{errors}}, $errorcode;
    $c++;
}

@EXPORT = (keys %FIELDS, qw(@ERROR_MESSAGES), @{$EXPORT_TAGS{errors}});

1;
