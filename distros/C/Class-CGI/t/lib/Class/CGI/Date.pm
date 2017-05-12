package Class::CGI::Date;

use strict;
use warnings;

use Example::Date;

sub new {
    my ( $self, $cgi, $param ) = @_;

    my $prefix;
    if ( 'date' eq $param ) {
        $prefix = '';
    }
    else {
        ( $prefix = $param ) =~ s/date$//;
    }
    my ( $day, $month, $year ) =
      grep {defined}
      map  { $cgi->param("$prefix$_") } qw/day month year/;
    return Example::Date->new(
        day   => $day,
        month => $month,
        year  => $year,
    );
}

1;
