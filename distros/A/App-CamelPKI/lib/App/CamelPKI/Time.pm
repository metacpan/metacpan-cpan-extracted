#!perl -w

package App::CamelPKI::Time;
use strict;
use warnings;

=head1 NAME

B<App::CamelPKI::Time> - Modelise Camel-PKI horatading, up to the second.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  use App::CamelPKI::Time;

  print App::CamelPKI::Time->now();

  my $time = App::CamelPKI::Time->parse("20070412101200Z");
  my $later = $time->advance_days(42);

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

Objects in the I<App::CamelPKI::Time> class represent an universal
timestamp precise to the second. Time zones are B<not> dealt with in
this class, and should be handled as an external, view-side attribute
instead.

I<App::CamelPKI::Time> objects are immutable and stringifiable: when they
are used as strings (for example with C<print>, as shown in the
L</SYNOPSIS>), they automagically convert themselves into the "Zulu"
notation (yyymmddhhmmssZ).

=head1 CAPABILITY DISCIPLINE

I<App::CamelPKI::Time> objects are pure data; they do not carry privileges.

=cut

use App::CamelPKI::Error;
use DateTime;
use DateTime::Duration;

=head1 CONSTRUCTORS

=head2 parse($time)

=head2 parse($time, -format => $format)

Parses $time, a string, returns an instance of I<App::CamelPKI::Time>. The
default format (and the only one supported for now) is "Zulu".

If no format is specified (and B<only> in this case), $time may be from
one of the following special values:

=over

=item B<"now">

The return value is then L</now>;

=item B<An object of class App::CamelPKI::Time>

A deep copy of this object is returned.

=back

=cut

sub parse {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        if (@_ % 2);
    my ($class, $time, %opts) = @_;

    if (! exists $opts{-format}) {
        return bless { %$time }, $class if eval { $time->isa($class) };
        return $class->now if ($time eq "now");
        $opts{-format} = "Zulu";
    }

    throw App::CamelPKI::Error::Internal
        ("UNIMPLEMENTED",
         -details => "unsupported format $opts{-format}")
        unless ($opts{-format} eq "Zulu");

    throw App::CamelPKI::Error::Internal("INCORRECT_ARGS",
                                    -details => "cannot parse time")
        unless my ($Y, $M, $D, $h, $m, $s) =
            ($time =~ m/^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})Z$/);
    return bless
    { dt => DateTime->new(year => $Y, month  => $M, day    => $D,
                          hour => $h, minute => $m, second => $s),
    }, $class;
}

=head2 now()

Returns the current system time.

=cut

sub now {
    my ($class) = @_;
    return bless { dt => DateTime->now() }, $class;
}

=head1 METHODS

=head2 zulu()

Returns the time in "Zulu" format. This method is also used as the
stringgification operator overload.

=cut

use overload
    '""' => \&zulu,
    # Reenacting regular behavior for pointer comparison:
    '==' => sub { overload::StrVal(shift) eq
        overload::StrVal(shift) },
    'fallback' => 1;

sub zulu {
    my ($self) = @_;
    my $dt = $self->{dt};
    return join("", $dt->year,
                (map { sprintf("%02d", $_) }
                 ($dt->month, $dt->day, $dt->hour, $dt->min, $dt->sec)),
                "Z");
}

=head2 advance_days($days)

Returns a copy of this I<App::CamelPKI::Time> object advanced by the
specified number of days (which may be negative).

=cut

sub advance_days {
    my ($self, $days) = @_;
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        if (! defined $days);
    my $dt = $self->{dt}->clone;
    my $duration = DateTime::Duration->new(days => abs($days));
    $days >= 0 ? $dt->add_duration($duration) :
        $dt->subtract_duration($duration);
    return bless { dt => $dt }, ref($self);
}

=head2 advance_years($years)

Returns a copy of this I<App::CamelPKI::Time> object advanced by the
specified number of years, which may be negative.

=cut

sub advance_years {
    my ($self, $days) = @_;
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        if (! defined $days);
    my $dt = $self->{dt}->clone;
    my $duration = DateTime::Duration->new(years => abs($days));
    $days >= 0 ? $dt->add_duration($duration) :
        $dt->subtract_duration($duration);
    return bless { dt => $dt }, ref($self);
}

=head2 make_your()

Nothing, actually.

=cut

sub make_your {
    die "ALL YOUR CODEBASE ARE BELONG TO US";
}

require My::Tests::Below unless caller;
1;

__END__

=begin internals

=head1 TESTS

=cut

use Test::More qw(no_plan);
use Test::Group;

test "now() and stringification" => sub {
    like(App::CamelPKI::Time->now(), qr/^\d{14}Z$/);
};

test "->parse" => sub {
    like(App::CamelPKI::Time->parse("now"), qr/^\d{14}Z$/);
};

test "overload and compare" => sub {
    my $time = App::CamelPKI::Time->now();
    sleep(2);
    cmp_ok($time, "lt", App::CamelPKI::Time->now());
};

test "->parse(\$object) does a copy" => sub {
    my $time = App::CamelPKI::Time->now();
    my $time2 = App::CamelPKI::Time->parse($time);
    is($time->zulu, $time2->zulu, "same hour...");
    ok(! ($time == $time2), "... but different address");
    cmp_ok($time, "eq", $time2, "string comparison works");
};

test "synopsis" => sub {
    my $code = My::Tests::Below->pod_code_snippet("synopsis");
    $code =~ s/print//g;
    $code =~ s/my //g;
    my ($time, $later);
    eval $code; die $@ if $@;

    is("$later", "20070524101200Z");
};

test "->advance_days and ->advance_years" => sub {
    my $date = App::CamelPKI::Time->now;
    ok( ($date->advance_days(365)->zulu eq $date->advance_years(1)->zulu)
       or
        ($date->advance_days(366)->zulu eq $date->advance_years(1)->zulu) );
};

=end internals

=cut
