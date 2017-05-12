package App::JobLog::Time;
$App::JobLog::Time::VERSION = '1.042';
# ABSTRACT: consolidates basic time functions into one location


use Exporter 'import';
our @EXPORT_OK = qw(
  now
  today
  tz
);

use Modern::Perl;
use DateTime;
use DateTime::TimeZone;
use App::JobLog::Config qw(_tz);

# cached values
our ( $today, $now );


sub now {
    $now //= DateTime->now( time_zone => tz() );
    return $now->clone;
}


sub today {
    $today //= now()->truncate( to => 'day' );
    return $today->clone;
}


sub tz {
    _tz;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::JobLog::Time - consolidates basic time functions into one location

=head1 VERSION

version 1.042

=head1 DESCRIPTION

C<App::JobLog::Time> puts the cachable time functions into a common module
to improve efficiency and facilitate testing.

=head1 METHODS

=head2 now

The present moment with the time zone set to C<$App::JobLog::Time::tz>. This
may be overridden with C<$App::JobLog::Time::now>.

=head2 today

Unless C<$App::JobLog::Time::today> has been set, whatever is given by C<now>
truncated to the day.

=head2 tz

Returns time zone, which will be the local time zone unless C<$App::JobLog::Time::tz>
has been set.

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
