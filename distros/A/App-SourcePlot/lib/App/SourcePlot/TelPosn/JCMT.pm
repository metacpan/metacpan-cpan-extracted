package App::SourcePlot::TelPosn::JCMT;

=head1 NAME

App::SourcePlot::TelPosn::JCMT - Class to obtain pointing position of JCMT

=cut

use strict;

our $VERSION = '1.32';

use Astro::PAL;

use App::SourcePlot::Source;

$ENV{'EPICS_CA_ADDR_LIST'} = '128.171.92.79';
$ENV{'EPICS_CA_AUTO_ADDR_LIST'} = 'NO';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return bless {
        name => 'TelescopePosition',
    }, $class;
}

sub get_position {
    my $self = shift;

    my $output = `/jac_sw/epics/R3.14.7/bin/linux-x86/caget -f3 mount:az:pid.EVAL mount:el:pid.EVAL`;

    my $az = undef;
    my $el = undef;
    foreach my $line (split /\n/, $output) {
        next unless $line =~ /([a-zA-Z:.]+)\s+([-0-9.]+)/;
        if ($1 eq 'mount:az:pid.EVAL') {
            $az = $2;
        }
        elsif ($1 eq 'mount:el:pid.EVAL') {
            $el = $2;
        }
    }

    return undef unless (defined $az) and (defined $el);

    return App::SourcePlot::Source->new(
        $self->{'name'},
        $az * Astro::PAL::DR2D,
        $el * Astro::PAL::DR2D,
        'AZ');
}

1;

__END__

=head1 COPYRIGHT

Copyright (C) 2024 East Asian Observatory
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc.,51 Franklin
Street, Fifth Floor, Boston, MA  02110-1301, USA

=cut
