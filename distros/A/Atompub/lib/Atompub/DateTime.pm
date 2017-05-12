package Atompub::DateTime;

use strict;
use warnings;

use Atompub;
use DateTime;
use DateTime::Format::W3CDTF;
use DateTime::TimeZone;
use HTTP::Date qw(str2time time2isoz time2str);
use Perl6::Export::Attrs;
use Time::Local;

use base qw(Class::Accessor::Fast Class::Data::Inheritable);

use overload (
    q{""}    => \&w3c,
    q{0+}    => \&epoch,
    fallback => 1,
);

my $tz;
sub tz {
    unless ($tz) {
        eval    { $tz = DateTime::TimeZone->new(name => 'local') };
        if ($@) { $tz = DateTime::TimeZone->new(name => 'UTC'  ) }
    }
    $tz;
}

__PACKAGE__->mk_classdata(fmt => DateTime::Format::W3CDTF->new);
__PACKAGE__->mk_accessors(qw(dt));

sub new {
    my($class, @args) = @_;
    my $self = bless {}, $class;
    $self->init(@args) or return;
    $self;
}

sub init {
    my($self, $arg) = @_;

    my $epoch = !$arg                         ? time
	      : UNIVERSAL::can($arg, 'epoch') ? $arg->epoch
	      : $arg =~ qr{^\d{1,13}$}        ? $arg
              : $arg =~ qr{^\d{14}$}          ? _parse_timestamp($arg)
	      :                                 str2time $arg;

    return unless defined $epoch;

    $self->dt(DateTime->from_epoch(
        epoch     => $epoch,
        time_zone => $self->tz,
        formatter => $self->fmt,
    ));

    $self;
}

sub datetime :Export { __PACKAGE__->new(@_) }

sub _parse_timestamp {
    my @a = $_[0] =~ /(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
    $a[1]--; # month
    timelocal reverse @a;
}

sub epoch { $_[0]->dt->epoch }

sub iso {
    my($self) = @_;
    $self->{iso} ||= sprintf '%s %s', $self->dt->ymd, $self->dt->hms;
}

sub isoz {
    my($self) = @_;
    $self->{isoz} ||= time2isoz $self->epoch;
}

sub w3c {
    my($self) = @_;
    $self->{w3c} ||= '' . $self->dt;
}

sub w3cz {
    my($self) = @_;
    unless ($self->{w3cz}) {
	my $w3cz = time2isoz $self->epoch;
	$w3cz =~ s/ /T/;
	$self->{w3cz} = $w3cz;
    }
    $self->{w3cz};
}

sub str {
    my($self) = @_;
    $self->{str} ||= time2str $self->epoch;
}

1;
__END__

=head1 NAME

Atompub::DateTime - A date and time object for the Atom Publishing Protocol


=head1 SYNOPSIS

    # assuming the local timezone is JST (+09:00)

    use Atompub::DateTime qw(datetime);

    $dt = datetime;                                  # current time
    $dt = datetime(DateTime->new);
    $dt = datetime(1167609600);                      # UTC epoch value
    $dt = datetime('20070101090000');
    $dt = datetime('2007-01-01 09:00:00');
    $dt = datetime('2007-01-01 00:00:00Z');
    $dt = datetime('2007-01-01T09:00:00+09:00');
    $dt = datetime('2007-01-01T00:00:00Z');
    $dt = datetime('Mon, 01 Jan 2007 00:00:00 GMT');

    $dt->epoch; # 1167609600 (UTC epoch value)
    $dt->iso;   # 2007-01-01 09:00:00 (in localtime)
    $dt->isoz;  # 2007-01-01 00:00:00Z
    $dt->w3c;   # 2007-01-01T09:00:00+09:00
    $dt->w3cz;  # 2007-01-01T00:00:00Z
    $dt->str;   # Mon, 01 Jan 2007 00:00:00 GMT

    my $dt2 = datetime($dt); # copy

    $dt == $dt2; # compare

    "$dt"; # $dt->w3c

    $dt->dt; # DateTime object

=head1 METHODS

=head2 Atompub::DateTime->new([ $str ])

Returns a datetime object representing the time $str.
If the function is called without an argument, it will use the current time.

=head2 datetime([ $str ])

An alias for Atompub::DateTime->new

=head2 $datetime->epoch

Returns UTC epoch value.

    1167609600

=head2 $datetime->iso

Returns a "YYYY-MM-DD hh:mm:ss"-formatted string representing time in the local time zone.

    2007-01-01 09:00:00

=head2 $datetime->isoz

Returns a "YYYY-MM-DD hh:mm:ssZ"-formatted string representing Universal Time.

    2007-01-01 00:00:00Z

=head2 $datetime->w3c

Returns a "YYYY-MM-DDThh:mm:ssTZ"-formatted string (W3C DateTime Format)
representing time in the local time zone.

    2007-01-01T09:00:00+09:00

=head2 $datetime->w3cz

Returns a "YYYY-MM-DDThh:mm:ssZ"-formatted string (W3C DateTime Format)
representing Universal Time.

    2007-01-01T00:00:00Z

=head2 $datetime->str

Returns a human readable representation.

    Mon, 01 Jan 2007 00:00:00 GMT

=head2 $datetime->dt

An accessor for the internal L<DateTime> object.

=head2 $datetime->tz

An accessor for the internal L<DateTime::TimeZone> object.

=head2 $datetime->fmt

An accessor for the internal L<DateTime::Format> object.


=head1 INTERNAL INTERFACES

=head2 $datetime->init

=head2 $datetime->_parse_timestamp


=head1 SEE ALSO

L<Atompub>


=head1 AUTHOR

Takeru INOUE, E<lt>takeru.inoue _ gmail.comE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
