package Basic::Test;

use strict;
use warnings FATAL => 'all';

sub days_between_dates {
    my ( $self, $c ) = @_;

    my $date1 = 'Sun Oct 18 15:14:48 2009';
    my $date2 = 'Sat Oct 31 15:14:48 2009';

    my $delta = $c->plugin('DateTime')->days_between_dates( $date1, $date2 );

    $self->_success($c) if ($delta == 13);
}

sub format_time {
    my ( $self, $c ) = @_;

    my $result = $c->plugin('DateTime')->format_time('110811606', '%a %b %d %T %Y');

    $self->_success($c) if ($result eq 'Fri Jul 06 06:00:06 1973');
}

sub _success {
    my ( $self, $c ) = @_;

    $c->request->content_type('text/html');

    print "success";
    exit;
}

1;
