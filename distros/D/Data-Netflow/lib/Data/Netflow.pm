package Data::Netflow;

use 5.006;
use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use Socket qw( inet_pton inet_ntop inet_ntoa AF_INET6 AF_INET);
use List::Util qw(any);

use Carp;
use Data::Dumper;

my %Ls = (
    1 => "C",
    2 => "n",
    4 => "N",
);

=head1 NAME

Data::Netflow - Module to process binary netflow data (v5 and v9)

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Module to create netflow binary data from text data

    use Data::Netflow;
    use IO::Socket;

    my $sock_udp = IO::Socket::INET->new(
        Proto    => 'udp',
        PeerPort => 9995,
        PeerAddr => '127.0.0.1',
    ) or die "Could not create UDP socket: $!\n";

    my $TemplateV9 = {
        'FlowSetId'      => 0,
        'TemplateId' => 300,
        'Fields'   => [
            { 'Length' => 4, 'Id' => 1  },    # octetDeltaCount
            { 'Length' => 4, 'Id' => 2  },    # packetDeltaCount
            { 'Length' => 1, 'Id' => 4  },    # protocolIdentifier
            { 'Length' => 1, 'Id' => 6  },    # tcp flags
            { 'Length' => 2, 'Id' => 7  },    # sourceTransportPort
            { 'Length' => 4, 'Id' => 8  },    # sourceIPv4Address
            { 'Length' => 2, 'Id' => 11 },    # destinationTransportPort
            { 'Length' => 4, 'Id' => 12 },    # destinationIPv4Address
            { 'Length' => 4, 'Id' => 21 },    # last switched
            { 'Length' => 4, 'Id' => 22 },    # first switched
    ],
}

    my $Header = {
                 Version => 9,
                 SysUptime => int ( uptime() *1000 ),
             };


    my @flow;
    my @tmp = qw( 5 8126 17 0 22 10.2.1.1 5365 10.2.1.254  ) ;
    my $uptime = int ( (uptime()- $back ) *1000 );
    push @tmp  , $uptime + 5;
    push @tmp  , $uptime;
    push @flow , \@tmp;

    my $encoded = Data::Netflow::encodeV9($Header, $TemplateV9 ,\@flow);
    $sock_udp->send( $encoded );



=head1 EXPORT

encodeV5
encodeV9

=head1 SUBROUTINES/METHODS


=head2 decode

decode netflow data

=cut

sub decode
{
    my ( $data, $byname ) = @_;
    my $version = unpack 'n', $data;
    my @flows;
    if ( $version == 5 )
    {
        my %data_id = (
            1  => 'SrcAddr',
            2  => 'DstAddr',
            3  => 'NextHop',
            4  => 'InputInt',
            5  => 'OutputInt',
            6  => 'Packets',
            7  => 'Octets',
            8  => 'StartTime',
            9  => 'EndTime',
            10 => 'SrcPort',
            11 => 'DstPort',
            12 => 'Padding',
            13 => 'TCP Flags',
            14 => 'Protocol',
            15 => 'IP ToS',
            16 => 'SrcAS',
            17 => 'DstAS',
            18 => 'SrcMask',
            19 => 'DstMask',
            20 => 'Padding',
        );
        my %headers_id = (
            1 => 'version',
            2 => 'count',
            3 => 'SysUptime',
            4 => 'unix_secs',
            5 => 'unix_nsecs',
            6 => 'flow_sequence',
            7 => 'engine_type',
            8 => 'engine_id',
            9 => 'sampling_interval'
        );
        my %headers_name = reverse %headers_id;
        my $header       = substr $data, 0, 24, '';
        my @headers      = unpack 'n2N4CCn', $header;
        $headers_name{$headers_id{$_ + 1}} = $headers[$_] foreach ( 0 .. 8 );
        for ( 1 .. $headers[1] )
        {
            my $flow_data = substr $data, 0, 48, '';
            my @flow = unpack 'NNNnnNNNNnnCCCCnnCCn', $flow_data;
            my %data_name;
            if ( $byname )
            {
                %data_name = reverse %data_id;
            }
            else
            {
                %data_name = %data_id;
            }
            foreach my $idx ( 0 .. 19 )
            {
                if ( $idx <= 2 )
                {
                    if ( $byname )
                    {
                        $data_name{$data_id{$idx + 1}} = inet_ntop( AF_INET, pack 'N', $flow[$idx] );
                    }
                    else
                    {
                        $data_name{$idx + 1} = inet_ntop( AF_INET, pack 'N', $flow[$idx] );
                    }
                }
                else
                {
                    if ( $byname ) {$data_name{$data_id{$idx + 1}} = $flow[$idx];}
                    else
                    {
                        $data_name{$idx + 1} = $flow[$idx];
                    }
                }
            }
            delete $data_name{Padding};
            push @flows, \%data_name;
        }
        return \%headers_name, \@flows;
    }
    elsif ( $version == 9 )
    {
        my %headers_id = (
            1 => 'version',
            2 => 'count',
            3 => 'SysUptime',
            4 => 'unix_secs',
            5 => 'flow_sequence',
            6 => 'engine_id',
        );
        my %headers_name = reverse %headers_id;
        my $header       = substr $data, 0, 20, '';
        my @headers      = unpack 'n2N4', $header;
        $headers_name{$headers_id{$_ + 1}} = $headers[$_] foreach ( 0 .. 5 );
        my %templates;
        my $flowser_id;
        my $field_count;
        my ( $flowset_id, $flowset_length ) = unpack 'n2', $data;

        if ( $flowset_id == 0 )
        {
            my $record = substr $data, 0, $flowset_length, '';
            substr $record, 0, 4, '';
## we are in template records
            my ( $flowser_id, $field_count ) = unpack 'n2', substr( $record, 0, 4, '' );
            my @tmp;
            for my $idx ( 1 .. $field_count )
            {
                my ( $id, $len ) = unpack 'n2', ( substr( $record, 0, 4, '' ) );
                push @tmp, "$id,$len";
            }
            $templates{$flowser_id} = \@tmp;
            ( $flowset_id, $flowset_length ) = unpack 'n2', ( substr( $data, 0, 4, '' ) );
        }

        if ( $flowset_id != 0 )
        {
## we are in data records
            for my $nbr ( 1 .. ( $headers_name{count} - 1 ) )
            {
                my %record;
                if ( exists $templates{$flowset_id} )
                {
                    foreach my $item ( @{$templates{$flowset_id}} )
                    {
                        my ( $i, $l ) = split ',', $item;
                        next if ( !defined $i || !defined $l );
                        if ( any {$_ == $i} qw(8 12 15 18) )
                        {
                            $record{$i} = inet_ntop( AF_INET, ( substr( $data, 0, $l, '' ) ) );
                        }
                        elsif ( any {$_ == $i} qw(27 28 62) )
                        {
                            $record{$i} = inet_ntop( AF_INET6, ( substr( $data, 0, $l, '' ) ) );
                        }
                        else
                        {
                            $record{$i} = unpack $Ls{$l}, ( substr( $data, 0, $l, '' ) );
                        }
                    }
                    push @flows, \%record;
                }
            }
        }
        return \%headers_name, \@flows;
    }
    else
    {
        croak "Version $version not supported";
    }

}

=head2 encodeV9

encode data for netflow version 9 with template

=cut

sub encodeV9
{
    my ( $header, $template, $flowArrayRef ) = @_;
    my @flows = @$flowArrayRef;
    my $Id    = $template->{Fields};
    my $out;
###  start header ###
    $header->{SysUptime} //= int uptime() * 1000;
    $header->{TicksMS}   //= time;
    $header->{PackageNum} = ( ( $header->{PackageNum} // 0 ) + 1 ) % 0xFFFFFFFF;
    $header->{Count} = 1 + scalar @flows;
    $header->{SourceId} += 0;
    $out = pack "n2N4", @{$header}{qw{Version Count SysUptime TicksMS PackageNum SourceId}};
###  end header ###

###  start template ###
    $template->{FieldsCount} = scalar @$Id;
    $template->{Length} = 8 + ( $template->{FieldsCount} * 2 * 2 );
    my @template_data = ( $template->{FlowSetId}, $template->{Length}, $template->{TemplateId}, $template->{FieldsCount} );
    foreach my $f ( sort {$a->{Id} <=> $b->{Id}} @{$template->{Fields}} )
    {
        push @template_data, $f->{Id}, $f->{Length};
    }
    $out .= pack "n*", @template_data;
###  end template ###

    my $packedData;
    foreach my $flow ( @flows )
    {
        foreach my $fieldsIdx ( 0 .. $#$flow )
        {
            my $L = $Ls{$Id->[$fieldsIdx]{Length}};
            if ( $Id->[$fieldsIdx]{Id} == 8 || $Id->[$fieldsIdx]{Id} == 12 )
            {
                $packedData .= $flow->[$fieldsIdx] =~ /:/ ? inet_pton( AF_INET6, $flow->[$fieldsIdx] ) : inet_pton( AF_INET, $flow->[$fieldsIdx] );
            }
            else
            {
                $packedData .= pack $L, $flow->[$fieldsIdx];
            }
        }
    }
    $out .= pack "n2", $template->{TemplateId}, ( length( $packedData ) + 4 );
    $out .= $packedData;
    return $out;
}

=head2 encodeV5

encode data for netflow version 5

=cut

sub encodeV5
{
    my ( $header, $template, $flowArrayRef ) = @_;
    my @flows = @$flowArrayRef;
    my $Id    = $template->{Fields};
    $header->{SysUptime} //= int uptime() * 1000;
    ( $header->{UnixSecs}, $header->{UnixNsecs} ) = ( gettimeofday );
    $header->{FlowSeq}     //= 0;
    $header->{EngineType}  //= 0;
    $header->{EngineId}    //= 0;
    $header->{SamplingInt} //= 0;

    $header->{Count} = scalar @flows;
    my $out = pack "n2N4CCn", @{$header}{qw{Version Count SysUptime UnixSecs UnixNsecs FlowSeq EngineType EngineId SamplingInt}};

    my $packedData;
    foreach my $flow ( @flows )
    {
        foreach my $fieldsIdx ( 0 .. $#$flow )
        {
            my $L = $Ls{$Id->[$fieldsIdx]{Length}};
            if ( $Id->[$fieldsIdx]{Id} == 1 || $Id->[$fieldsIdx]{Id} == 2 || $Id->[$fieldsIdx]{Id} == 3 )
            {
                $packedData .= $flow->[$fieldsIdx] =~ /:/ ? inet_pton( AF_INET6, $flow->[$fieldsIdx] ) : inet_pton( AF_INET, $flow->[$fieldsIdx] );
            }
            else
            {
                $packedData .= pack $L, $flow->[$fieldsIdx];
            }
        }
    }
    $out .= $packedData;
    return $out;
}

sub uptime
{
    return (
        split /\s/,
        do {local ( @ARGV, $/ ) = '/proc/uptime'; <>}
    )[0];
}

=head1 AUTHOR

DULAUNOY Fabrice, C<< <fabrice at dulaunoy.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-netflow at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Netflow>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 TODO

decode V9 for multiple data set (and multiple template )
decode V9 return by id or by name (if flag) like for V5
A single encode (detect version by the header)
IPFIX (maybe)

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Netflow

For the netflow format:

Version 5:


Version 9:

https://www.ietf.org/rfc/rfc3954.txt

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Netflow>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Netflow>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Netflow>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Netflow/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 DULAUNOY Fabrice.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Data::Netflow
