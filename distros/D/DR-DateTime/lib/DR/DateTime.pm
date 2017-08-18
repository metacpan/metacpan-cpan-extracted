package DR::DateTime;
use DR::DateTime::Defaults;

use 5.010001;
use strict;
use warnings;
our $VERSION = '0.01';
use Carp;

use Data::Dumper ();
use POSIX ();
use Time::Local ();
use Time::Zone ();
use feature 'state';

sub new {
    my ($self, $stamp, $tz) = @_;
    $stamp //= time;

    if (defined $tz) {
        $tz =~ /^([+-])?(\d{2})(\d{2})?$/;
        croak "Wrong timezone format" unless defined $2;

        $tz = join '',
                $1 // '+',
                $2,
                $3 // '00';
    }

    $tz = $DR::DateTime::Defaults::TZFORCE
        if defined $DR::DateTime::Defaults::TZFORCE;

    bless [ $stamp, $tz // () ] => ref($self) || $self;
}

sub parse {
    my ($class, $str, $default_tz, $nocheck) = @_;
    return undef unless defined $str;
    my ($y, $m, $d, $H, $M, $S, $ns, $z);

    for ($str) {
        if (/^(\d{4})-(\d{2})-(\d{2})(?:\s+|T)(\d{2}):(\d{2}):(\d{2})(\.\d+)?\s*(\S+)?$/) {
            ($y, $m, $d, $H, $M, $S, $ns, $z) =
                ($1, $2, $3, $4, $5, $6, $7, $8);
            goto PARSED;
        }
        
        if (/^(\d{4})-(\d{2})-(\d{2})(?:\s+|T)(\d{2}):(\d{2})$/) {
            ($y, $m, $d, $H, $M, $S, $ns, $z) =
                ($1, $2, $3, $4, $5, 0, 0, undef);
            goto PARSED;
        }
        
        if (/^(\d{4})-(\d{2})-(\d{2})$/) {
            ($y, $m, $d, $H, $M, $S, $ns, $z) =
                ($1, $2, $3, 0, 0, 0, 0, undef);
            goto PARSED;
        }

        if (/^(\d{1,2})\.(\d{1,2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})(\.\d+)\s*(\S+)?$/) {
            ($y, $m, $d, $H, $M, $S, $ns, $z) =
                ($3, $2, $1, $4, $5, $6, $7, $8);
            goto PARSED;
        }

        return undef;
    }


    PARSED:

        $z //= $default_tz // '+0000';
        for ($z) {
            if (/^[+-]\d{1,4}$/) {
                s/^([+-])(\d|\d{3})$/${1}0$2/;
                s/^([+-])(\d{2})$/${1}${2}00/;
            } else {
                croak "Wrong time zone format: '$z'";
            }
        }
        for ($m) {
            s/^0//;
            $_--;
        }
        for ($d, $H, $M, $S) {
            s/^0//;
        }
        $y -= 1900;

        $ns //= 0;
        my $stamp = eval {
            local $SIG{__DIE__} = sub {}; # Ick!
            return Time::Local::timegm_nocheck($S,$M,$H,$d,$m,$y) if $nocheck;
            Time::Local::timegm($S,$M,$H,$d,$m,$y);
        };
        $stamp += $ns;

        my $offset = Time::Zone::tz_offset($z, $stamp);
        $class->new($stamp - $offset, $z);
}

sub fepoch  { shift->[0] }
sub epoch   { POSIX::floor(shift->[0]) }
sub tz      { shift->[1] // $DR::DateTime::Defaults::TZ }

sub strftime :method {
    my ($self, $format) = @_;
    croak 'Invalid format' unless $format;
    my $offset = Time::Zone::tz_offset($self->tz, $self->epoch);
    my $stamp = $self->epoch + $offset;
    my $fstamp = $self->fepoch + $offset;

    state $patterns;
    unless ($patterns) {
        $patterns = {
            '%'     => sub { '%' },
            'z'     => sub { shift->tz },
            'Z'     => sub { shift->tz },
            'N'     => sub {
                int(1_000_000_000 * abs($_[2] - $_[1])) }

        };
        for my $sp (split //, 'aAbBcCdDeEFgGhHIjklmMnOpPrRsStTuUVwWxXyY') {
            $patterns->{$sp} = sub { POSIX::strftime "%$sp", gmtime $_[1] }
        }
    }

    $format =~ s{%([a-zA-Z%])}
        { $patterns->{$1} ? $patterns->{$1}->($self, $stamp, $fstamp) : "%$1" }sgex;

    $format;
}


sub year { shift->strftime('%Y') }

sub month {
    for my $m (shift->strftime('%m')) {
        $m =~ s/^0//;
        return $m;
    }
}

sub day {
    for my $d (shift->strftime('%d')) {
        $d =~ s/^0//;
        return $d;
    }
}

sub day_of_week { shift->strftime('%u') }

sub quarter { POSIX::ceil(shift->month / 3) }

sub hour {
    for my $h (shift->strftime('%H')) {
        $h =~ s/^0//;
        return $h;
    }
}

sub minute {
    for my $m (shift->strftime('%M')) {
        $m =~ s/^0//;
        return $m;
    }
}
sub second {
    for my $s (shift->strftime('%S')) {
        $s =~ s/^0//;
        return $s;
    }
}

sub nanosecond { shift->strftime('%N') }

sub hms {
    my ($self, $sep) = @_;
    $sep //= ':';
    for ($sep) {
        s/%/%%/g;
    }
    $self->strftime("%H$sep%M$sep%S");
}

sub datetime {
    my ($self) = @_;
    return join 'T', $self->ymd, $self->hms;
}

sub ymd {
    my ($self, $sep) = @_;
    $sep //= ':';
    for ($sep) {
        s/%/%%/g;
    }
    $self->strftime("%Y$sep%m$sep%d");
}

sub time_zone { goto \&tz   }
sub hires_epoch { goto \&fepoch }
sub _fix_date_after_arith_month {
    my ($self, $new) = @_;
    return $new->fepoch if $self->day == $new->day;
    if ($new->day < $self->day) {
        $new->[0] -= 86400;
    }
    $new->fepoch;
}
sub add {
    my ($self, %set) = @_;
    
    for my $n (delete $set{nanosecond}) {
        last unless defined $n;
        $self->[0] += $n / 1_000_000_000;
    }

    for my $s (delete $set{second}) {
        last unless defined $s;
        $self->[0] += $s;
    }

    for my $m (delete $set{minute}) {
        last unless defined $m;
        $self->[0] += $m * 60;
    }
    
    for my $h (delete $set{hour}) {
        last unless defined $h;
        $self->[0] += $h * 3600;
    }

    for my $d (delete $set{day}) {
        last unless defined $d;
        $self->[0] += $d * 86400;
    }

    for my $m (delete $set{month}) {
        last unless defined $m;
        my $nm = $self->month + $m;

        $set{year} //= 0;
        while ($nm > 12) {
            $nm -= 12;
            $set{year}++;
        }

        while ($nm < 1) {
            $nm += 12;
            $set{year}--;
        }
        my $str = $self->strftime('%F %T.%N %z');
        $str =~ s/(\d{4})-\d{2}-/sprintf "%s-%02d-", $1, $nm/e;
        $self->[0] =
            $self->_fix_date_after_arith_month($self->parse($str, undef, 1));
    }

    for my $y (delete $set{year}) {
        last unless defined $y;
        $y += $self->year;
        my $str = $self->strftime('%F %T.%N %z');
        $str =~ s/^\d{4}/$y/;
        $self->[0] =
            $self->_fix_date_after_arith_month($self->parse($str, undef, 1));
    }
    $self;
}

sub subtract {
    my ($self, %set) = @_;

    my %sub;
    while (my ($k, $v) = each %set) {
        $sub{$k} = -$v;
    }
    $self->add(%sub);
}

sub truncate {
    my ($self, %opts) = @_;

    my $to = $opts{to} // 'second';

    if ($to eq 'second') {
        $self->[0] = $self->epoch;
        return $self;
    }

    my $str;
    if ($to eq 'minute') {
        $str = $self->strftime('%F %H:%M:00%z');
        goto PARSE;
    }

    if ($to eq 'hour') {
        $str = $self->strftime('%F %H:00:00%z');
        goto PARSE;
    }
    
    if ($to eq 'day') {
        $str = $self->strftime('%F 00:00:00%z');
        goto PARSE;
    }

    if ($to eq 'month') {
        $str = $self->strftime('%Y-%m-01 00:00:00%z');
        goto PARSE;
    }
    
    if ($to eq 'year') {
        $str = $self->strftime('%Y-01-01 00:00:00%z');
        goto PARSE;
    }

    croak "Can not truncate the datetime to '$to'";

    PARSE:
        $self->[0] = $self->parse($str)->epoch;
        $self;
}

sub clone {
    my ($self) = @_;
    bless [ @$self ] => ref($self) || $self;
}

1;

__END__

=head1 NAME

DR::DateTime - Easy DateTime implementator.

=head1 SYNOPSIS

  use DR::DateTime;
  my $t = new DR::DateTime time;
  my $t = new DR::DateTime time, '+0300';

  my $t = parse DR::DateTime '2017-08-18 12:33:19.1234+0300';

  $t->year;
  $t->month;
  $t->day;
  $t->day_of_week;
  $t->hour;
  $t->minute;
  $t->second;
  $t->nanosecond;

  $t->add(second => 15, hour => 24, month => 17);
  $t->subtract(year => 7);

=head1 DESCRIPTION

The module provide the same (reduced) API as L<DateTime>.

L<DateTime> is a very usable and good module, but Dump of its objects gets two
or three screens, so If You use more than one object L<DateTime> You have too
many troubles to debug Your code.

=head2 METHODS

=head3 new([$timestamp[,$timezone]])

Create L<DR::DateTime> instance. If C<$timezone> is not defined,
the module will use C<$DR::DateTime::Defaults::TZ> value.

C<$timezone> is used only for L</strftime> method.

=head3 parse($str[, $default_timezone])

Default value for C<$default_timezone> is C<'+0000'> (C<UTC>).

Parse string and creates and object (or return C<undef>).

The module can parse only standard time format like (may be partly incompleted)
C<%F %T.%N %z> (see man strftime).


=head3 strftime($format)

Method that works like L<POSIX/strftime>. The method has one additional
placeholder - C<%N> - nanosecond.


=head3 nanosecond, second, etc

Methods that return part of contained date. Allow:

=over

=item nanosecond

=item second

=item minute

=item hour

=item day

=item day_of_week (C<< $t->strftime('%u') >>)

=item month

=item year

=back


=head3 truncate(to => ...)

This method allows You to reset some of the local time components in the
object to their "zero" values. The "to" parameter is used to specify which
values to truncate, and it may be one of C<year>, C<month>, C<day>,
C<hour>, C<minute>, or C<second>.


=head3 add(...), substract(...)

These methods allow You add or substract values to object.

    $t
        -> add(
            year        => 1,
            month       => 2,
            day         => 4,
            hour        => 17,
            minute      => 18,
            second      => 19,
            nanosecond  => 50001
        )
        -> subtract(
            year        => 3,
            month       => 4,
            day         => 5,
            hour        => 22,
            minute      => 23,
            second      => 24,
            nanosecond  => 7829
        );
        

=head3 time_zone or tz

Return timezone that is used for L<strftime> method.

Now L<DR::DateTime> uses only one time zone format: C<qr/^[+-]\d{2,4}$/>.
Named time zones are not supported yet.

=head3 epoch

Retrun timestamp value.

=head3 hires_epoch or fepoch

Return timestamp that includes nanoseconds as float value.

=head3 clone

Clone the value.

=head1 SEE ALSO

=over

=item man strftime

=item L<POSIX/strftime>

=back

=head1 AUTHOR

Dmitry E. Oboukhov, E<lt>unera@debian.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Dmitry E. Oboukhov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
