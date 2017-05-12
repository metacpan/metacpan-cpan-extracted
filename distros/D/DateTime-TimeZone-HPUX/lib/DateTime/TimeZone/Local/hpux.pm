package DateTime::TimeZone::Local::hpux;

use strict;
use warnings;

# Debugging flags, used in the testsuite
BEGIN {
    defined &SKIP_ETC_TIMEZONE or *SKIP_ETC_TIMEZONE = sub () { 0 };
    defined &SKIP_JAVA or *SKIP_JAVA = sub () { 0 };
}



use base 'DateTime::TimeZone::Local';
use DateTime::TimeZone::HPUX;

sub Methods
{
    qw( _FromEnv _FromEtcTIMEZONE _FromJava )
}

# TODO Build the full timezone database from /usr/lib/tztab
sub _FromEnv
{
    return unless exists $ENV{TZ};
    DateTime::TimeZone::HPUX::_hpux_to_olson($ENV{TZ})
}

sub _FromEtcTIMEZONE
{
    return if SKIP_ETC_TIMEZONE;

    my $tz_file = '/etc/TIMEZONE';

    return unless -f $tz_file && -r _;

    local *TZ;
    open TZ, "<$tz_file"
        or die "Cannot read $tz_file: $!";

    my $name;
    while ( defined( $name = <TZ> ) )
    {
        if ( $name =~ /\A\s*TZ\s*=\s*(\S+)/ )
        {
            $name = $1;
            last;
        }
    }
    close TZ;

    DateTime::TimeZone::HPUX::_hpux_to_olson($name)
}

# Retrieve the default timezone using Java (java.util.TimeZone.getDefault())
sub _FromJava
{
    return if SKIP_JAVA;
    warn('Retrieving default timezone using Java (SLOOOOOW)... You should instead set $ENV{TZ}');
    my $tz_name = DateTime::TimeZone::HPUX::_olson_from_java();
    return unless defined $tz_name;

    # Build a DT::TZ object from the name returned by Java
    local $@;
    return eval { DateTime::TimeZone->new(name => $tz_name) };
}


1;
__END__

=head1 NAME

DateTime::TimeZone::Local::hpux - Local timezone detection for HP-UX

=head1 VERSION

$Id: hpux.pm,v 1.8 2009/10/15 13:17:25 omengue Exp $

=head1 SYNOPSIS

On an HP-UX system (C<$^O eq 'hpux'>):

    use DateTime::TimeZone;

    my $tz = DateTime::TimeZone(name => 'local');

=head1 DESCRIPTION

This module is automatically loaded by L<DateTime::TimeZone::Local> on HP-UX
systems, based on the C<$^O> value (the fix for bug RT#44724 must have been applied (fixed in DateTime::TimeZone 0.87)).

This is a workaround for bug RT#44721.

=head1 METHODS

As a subclass of DateTime::TimeZone::Local, the following methods are
overridden:

=head2 Methods()

See L<DateTime::TimeZone::Local/SUBCLASSING>.

=head1 SEE ALSO

=over 4

=item L<DateTime::TimeZone::HPUX/CAVEAT>.

=item C<man 4 tztab>

=item F</usr/lib/tztab>

=item L<http://rt.cpan.org/Public/Bug/Display.html?id=44721>

=item L<http://rt.cpan.org/Public/Bug/Display.html?id=44724>

=back

=head1 BUGS

See L<DateTime::TimeZone::HPUX/BUGS>.

=head1 AUTHOR

Olivier MenguE<eacute>, C<< <dolmen at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Olivier MenguE<eacute>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl 5.10.0 itself.

=cut
