use utf8;
use strict;
use warnings;

package DR::DateTime::MouseType;

use DR::DateTime;
use Mouse::Util::TypeConstraints;
use Carp;

subtype DRDateTime      => as 'DR::DateTime';
subtype MaybeDRDateTime => as 'Maybe[DR::DateTime]';

coerce DRDateTime =>
    from    'Num',
    via     { DR::DateTime->new($_) },

    from    'Str',
    via     {
        my $r = DR::DateTime->parse($_);
        die "Can't parse datetime: '$_'" unless $r;
        $r;
    }
;

coerce MaybeDRDateTime =>
    from    'Num',
    via     { DR::DateTime->new($_) },

    from    'Str',
    via     {
        my $r = DR::DateTime->parse($_);
        die "Can't parse datetime: '$_'" unless $r;
        $r;
    };

1;

=head1 NAME

DR::DateTime::MouseType - Mouse type definer

=head1 SYNOPSIS

    use DR::DateTime::MouseType;

    package Bla;
    use Mouse;

    has dt  => is => 'ro', isa => 'DRDateTime', coerce => 1;
    has mdt => is => 'ro', isa => 'MaybeDRDateTime', coerce => 1;

    package main;

    my $i = new Bla dt => time, mdt => undef;
    my $j = new Bla dt => '2017-01-00';

=cut
