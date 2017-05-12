=head1 NAME

Apache2::Controller::Test::Funk

=head1 SYNOPSIS

Useful functions for use in Apache::Test tests for Apache2::Controller.

=cut

package Apache2::Controller::Test::Funk;

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';
use URI::Escape;
use Carp qw(croak);

use base 'Exporter';

our @EXPORT = qw(
    diag
    od
    qs
);

=head2 diag

Like the diag() from Test::More, except importing Test::More screws up
all the Apache::Test stuff.

=cut

sub diag {
    my @args = @_;
    defined && do { s{^}{# }mxsg; print "$_\n" } for @args;
}

=head2 od

diag the argument string through `od -a` using L<IPC::Open3>.

This is only useful for internal debugging when I can't figure
something out, then I enable it temporarily in the test, because
I don't know if od is installed on some system, and it wouldn't
be on Win32 systems, etc.

=cut

sub od {
    use IPC::Open3;
    my ($string) = @_;
    my ($wtr, $rdr, $err, $od_out);
    my $pid = open3($wtr, $rdr, $err, 'od -a');
    print $wtr $string;
    close $wtr;
    {
        local $/ = 1;
        $od_out = <$rdr> || <$err>;
    }
    close $rdr;
    close $err if $err;
    diag($od_out);
}

=head2 qs

 my $query_string = qs( 
    foo => [ 'bar', 'biz&baz' ], 
    boz => 'noz',
    beez => 'kneez',
    beez => 'jeez',
 );

 # $query_string == "foo=bar&foo=biz%26baz&boz=noz&beez=kneez&beez=jeez"

Formulate a query string from the given params.

=cut

sub qs {
    my $qs = q{};
    while (defined $_[0] && defined $_[1]) {
        my $var = shift;
        my $val = shift;
        $qs .= '&' if $qs;
        if (ref $val) {
            croak "wrong ref type, only array allowed\n" if ref $val ne 'ARRAY';
            $qs .= join('&', map "$var=".uri_escape($_), @{$val});
        }
        else {
            $qs .= "$var=".uri_escape($val);
        }
    }
    return $qs;
}

1;
