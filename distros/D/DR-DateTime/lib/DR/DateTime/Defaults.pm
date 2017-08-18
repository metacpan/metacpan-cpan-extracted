use utf8;
use strict;
use warnings;

package DR::DateTime::Defaults;
use POSIX ();

our $TZ     = POSIX::strftime '%z', localtime;

our $TZFORCE;

1;

__END__

=head1 NAME

DR::DateTime::Defaults - Default variables for L<DR::DateTime>.

=head1 SYNOPSIS

    use DR::DateTime::Defaults;


    $http_server->hook(before_dispatch => sub {
        $DR::DateTime::Defaults::TZFORCE = '+0300';
    });

=head1 DESCRIPTION

The module contains variables that uses in L<DR::DateTime> as defaults.

=head2 $TZ

Default value is C<+DDDD> (Your local timezone).

=head2 $TZFORCE

If the variable is defined, all constructors of L<DR::DateTime> will
force timezone to the value.

You can use the feature for example for http-server.

=cut
