use strict;
use warnings;
use v5.10.0;
package Convert::EDS::XDD;
no warnings 'uninitialized';

# ABSTRACT: Converts CANopen EDS format to Ethernet POWERLINK XDD
our $VERSION = '0.009'; # VERSION

use Carp;
use Config::Tiny;
use DateTime;
use XML::Writer;
use List::MoreUtils qw(natatime);

use Exporter 'import';
our @EXPORT_OK = qw(eds2xdd eds2xdd_string);  # symbols to export on request

=pod

=encoding utf8

=head1 NAME

Convert::EDS::XDD - Convert CANopen EDS to POWERLINK XDD

=head1 SYNOPSIS

  $ cpan Convert::EDS::XDD # install from CPAN
  $ eds2xdd profile.eds > profile.xdd # Convert with the eds2xdd script

=head1 DESCRIPTION

EDS is an L<ini|Config::Tiny> based format specified by the CiA e.V. in order to describe CANopen devices. The Ethernet POWERLINK Standardization Group specifies an EDS-based L<XML|XML::Writer> format for EPL devices.

This module takes in an EDS file or a string with its content and returns a XDD string. An L<eds2xdd> wrapper script is also installed into the C<PATH>.

C<eds2xdd> is also available as a self-contained (fatpacked) script L<at the Github releases page|https://github.com/epl-viz/Convert-EDS-XDD/releases/latest>.

=head1 LIMITATIONS

May not handle all details of the EDS. Pull requests and reports (L<issues on Github|https://github.com/epl-viz/Convert-EDS-XDD/issues>) are welcome.

=cut

sub _hex_or_dec {
    my $num = shift;
    return $num =~ /^0x/ ? hex($num) : $num;
}
sub _hashref_filterout {
    my $hash = shift;
    delete @$hash{ grep { not defined $hash->{$_} } keys %$hash };

}
sub _array_filterout {
    my $it = natatime 2, @_;
    my @out;
    while (my @vals = $it->()) {
        push @out, @vals if defined $vals[1];
    }
    return @out;
}


my @PDOmapping_str_of = qw( no yes );
sub _extract {
    my $obj = shift;
    _array_filterout (
        name          => $obj->{ParameterName},
        objectType    => _hex_or_dec($obj->{ObjectType}),
        dataType      => sprintf("%04X", _hex_or_dec($obj->{DataType})),
        accessType    => $obj->{AccessType},
        PDOmapping    => $PDOmapping_str_of[$obj->{PDOMapping}],
        lowLimit      => _hex_or_dec($obj->{LowLimit}),
        highLimit     => _hex_or_dec($obj->{HighLimit}),
        defaultValue  => $obj->{DefaultValue},
        actualValue   => $obj->{ActualValue},
    );
}


=head1 METHODS AND ARGUMENTS

=over 4

=item eds2xdd($filename, [$encoding])

Here, the C<[]> indicate an optional parameter.

Returns the EDS' content as XML string on success or undef on error in file contents.

Function croaks if opening file fails.

C<$encoding> may be used to indicate the encoding of the file, e.g. C<'utf8'> or
C<'encoding(iso-8859-1)'>.

Do not add a prefix to C<$encoding>, such as C<< '<' >> or C<< '<:' >>.

=cut

sub eds2xdd {
    my($file, $encoding) = @_;
    croak 'No file name provided' if !defined $file || $file eq '';

    # Slurp in the file.
    $encoding = $encoding ? "<:$encoding" : '<';
    local $/;

    open(my $eds, $encoding, $file) or croak "Failed to open file '$file' for reading: $!";
    my $contents = <$eds>;
    close($eds);

    croak "Reading from '$file' returned undef" unless defined $contents;
    eds2xdd_string($contents) or return;
};

my $template = do {
    local $/;
    <DATA>
};


=item eds2xdd_string($string)

Returns the EDS string as XML string

=cut

sub eds2xdd_string {
    my $str = shift;
    $str =~ s/#.*//gm;
    my $eds = Config::Tiny->read_string($str);

    my ($basename, $extension) = $eds->{FileInfo}->{FileName} =~ /^(.*)(\.[^.]*)/;
    $basename = undef;

    my $comments = do {
        if($eds->{Comments}) {
            my $comments = "<!--\n" . ('*' x76) . "\n";
            for my $i (1..$eds->{Comments}->{Lines}) {
                $comments .= $eds->{Comments}->{"Line$i"} . "\n";
            }
            $comments .= ('*' x 76) . "\n-->";
        }
        delete $eds->{Comments};
    };

    my %placeholder = _mktemplate(
        fileCreator          => $eds->{FileInfo}->{CreatedBy},
        fileModifiedBy       => $eds->{FileInfo}->{ModifiedBy},
        ProfileName          => $eds->{FileInfo}->{Description},
        fileCreationTime     => $eds->{FileInfo}->{CreationTime},
        fileCreationDate     => $eds->{FileInfo}->{CreationDate},
        fileModificationTime => $eds->{FileInfo}->{ModificationTime},
        fileModificationDate => $eds->{FileInfo}->{ModificationDate},
        basename             => $basename,
        extension            => $extension,
        version              => sprintf('%02u.%02u', $eds->{FileInfo}->{FileVersion},
            $eds->{FileInfo}->{FileRevision}),

        vendorID        => $eds->{DeviceInfo}->{VendorNumber},
        vendorName      => $eds->{DeviceInfo}->{VendorName},
        productName     => "$eds->{DeviceInfo}->{ProductName} ".
        $eds->{DeviceInfo}->{ProductNumber},
        product_version => $eds->{DeviceInfo}->{RevisionNumber},
        comments => $comments,

        @_
    );
    delete $eds->{FileInfo};
    delete $eds->{DeviceInfo};

    my $writer = XML::Writer->new(OUTPUT => 'self', DATA_MODE => 1, DATA_INDENT => 2);
    $writer->startTag("ObjectList");

    my ($in_sublist, $in_6000, $in_2000, $in_1000) = (0) x 4;
    my @sections = (sort keys %{$eds});
    foreach my $section_index (0 .. @sections - 1) {
        my $section = $sections[$section_index];
        unless ($section =~ /([[:xdigit:]]{4})(?:sub([[:xdigit:]]))|([[:xdigit:]]{4})/) {
            carp "Ignoring unknown section $section\n";
            next;
        }
        my ($index, $subindex) = ($1 // $3, $2);

        my $obj = $eds->{$section};

        my @object = _extract($obj);
        if (not defined $subindex) {
            $writer->endTag("Object") if $in_sublist;
            if (!$in_6000 && hex($index) >= 0x6000) {
                $writer->comment('Standardised Device Profile Area (0x6000 - 0x9FFF): may be used according to a CiA device profile.'
                    .'The profile to be used is given by NMT_DeviceType_U32');
                $in_6000 = 1;
            } elsif (!$in_2000 && hex($index) >= 0x2000) {
                $writer->comment('Manufacturer Specific Profile Area (0x2000 - 0x5FFF): may freely be used by the device manufacturer');
                $in_2000 = 1;
            } elsif (!$in_1000 && hex($index) >= 0x1000) {
                $writer->comment('Communication Profile Area (0x1000 - 0x1FFF): defined by EPSG 301');
                $in_1000 = 1;
            }

            $in_sublist = 0;

            unshift @object, index => sprintf('%04X', hex($index));
            if ($sections[$section_index+1] =~ /^${index}sub/) {
                $writer->startTag("Object", @object);
                $in_sublist = 1;
            } else {
                $writer->emptyTag("Object", @object);
            }
        } else {
            unshift @object, subIndex => sprintf('%02X', hex($subindex));
            $writer->emptyTag("SubObject", @object);
        }
    }

    $writer->endTag("Object") if $in_sublist;
    $writer->endTag("ObjectList");

    my $ObjectList = $writer->end();
    my $xdd = $template;
    if ($xdd =~ s/^([ \t]+?)\$ObjectList/\$ObjectList/m) {
        my $ObjectList_indent = $1;
        $ObjectList =~ s/^/$ObjectList_indent/mg;
    }
    $xdd =~ s/(\$\w+(?:\{\w+\})?)/$1/gee;
    return $xdd;
}

sub _mktemplate {
    my $dt = DateTime->now();
    @_ = _array_filterout(@_);
    my %placeholder = (
        basename => 'unknown',
        extension => '',
        date => $dt->ymd,
        time => $dt->hms,
        version => '01.00',
        product_version => '1.00',

        #@_
    );
    %placeholder = (
        fileName => "$placeholder{basename}.xdd",
        comment => "Generated from $placeholder{basename}$placeholder{extension} by " . __PACKAGE__,
        ProfileName => "POWERLINK $placeholder{basename}",

        fileCreator => __PACKAGE__,
        fileCreationDate => $placeholder{date},
        fileCreationTime => $placeholder{time},

        fileModifiedBy => __PACKAGE__,
        fileModificationDate => $placeholder{date},
        fileModificationTime => $placeholder{time},

        vendorName => 'Unknown vendor',
        vendorID => '0x00000000',
        productName => $placeholder{basename},
        versionHW => $placeholder{product_version},
        versionFW => $placeholder{product_version},
        versionSW => $placeholder{product_version},

        transferRate => '100 MBit/s',

        @_
    );
    _hashref_filterout(\%placeholder);
    %placeholder
}


1;

=back

=head1 GIT REPOSITORY

L<http://github.com/epl-viz/Convert-EDS-XDD>

=head1 SEE ALSO

L<EPL-Viz - Visualization for Ethernet POWERLINK|http://github.com/epl-viz>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017-2018 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<!-- $placeholder{comment} -->
$placeholder{comments}
<ISO15745ProfileContainer xmlns="http://www.ethernet-powerlink.org" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.ethernet-powerlink.org Powerlink_Main.xsd">
  <ISO15745Profile>
    <ProfileHeader>
      <ProfileIdentification>Powerlink_Device_Profile</ProfileIdentification>
      <ProfileRevision>1</ProfileRevision>
      <ProfileName>$placeholder{ProfileName} device profile</ProfileName>
      <ProfileSource/>
      <ProfileClassID>Device</ProfileClassID>
      <ISO15745Reference>
        <ISO15745Part>4</ISO15745Part>
        <ISO15745Edition>1</ISO15745Edition>
        <ProfileTechnology>Powerlink</ProfileTechnology>
      </ISO15745Reference>
    </ProfileHeader>
    <ProfileBody xsi:type="ProfileBody_Device_Powerlink" fileName="$placeholder{fileName}" fileCreator="$placeholder{fileCreator}" fileCreationDate="$placeholder{fileCreationDate}" fileCreationTime="$placeholder{fileCreationTime}" fileModificationDate="$placeholder{fileModificationDate}" fileModificationTime="$placeholder{fileModificationTime}" fileModifiedBy="$placeholder{fileModifiedBy}" fileVersion="$placeholder{version}" supportedLanguages="en">
      <DeviceIdentity>
        <vendorName>$placeholder{vendorName}</vendorName>
        <vendorID>$placeholder{vendorID}</vendorID>
        <productName>$placeholder{productName}</productName>
        <version versionType="HW">$placeholder{versionHW}</version>
        <version versionType="SW">$placeholder{versionSW}</version>
        <version versionType="FW">$placeholder{versionFW}</version>
      </DeviceIdentity>
      <DeviceFunction>
        <capabilities>
          <characteristicsList>
            <characteristic>
              <characteristicName>
                <label lang="en">Transfer rate</label>
              </characteristicName>
              <characteristicContent>
                <label lang="en">$placeholder{transferRate}</label>
              </characteristicContent>
            </characteristic>
          </characteristicsList>
        </capabilities>
      </DeviceFunction>
    </ProfileBody>
  </ISO15745Profile>
  <ISO15745Profile>
    <ProfileHeader>
      <ProfileIdentification>Powerlink_Communication_Profile</ProfileIdentification>
      <ProfileRevision>1</ProfileRevision>
      <ProfileName></ProfileName>
      <ProfileSource/>
      <ProfileClassID>CommunicationNetwork</ProfileClassID>
      <ISO15745Reference>
        <ISO15745Part>4</ISO15745Part>
        <ISO15745Edition>1</ISO15745Edition>
        <ProfileTechnology>Powerlink</ProfileTechnology>
      </ISO15745Reference>
    </ProfileHeader>
    <ProfileBody xsi:type="ProfileBody_CommunicationNetwork_Powerlink" fileName="$placeholder{fileName}"
     fileCreator="$placeholder{fileCreator}" fileCreationDate="$placeholder{fileCreationDate}" fileCreationTime="$placeholder{fileCreationTime}" fileModificationDate="$placeholder{fileModificationDate}" fileModificationTime="$placeholder{fileModificationTime}" fileModifiedBy="$placeholder{fileModifiedBy}" fileVersion="$placeholder{version}" supportedLanguages="en">
      <ApplicationLayers>
        <identity>
          <vendorID>$placeholder{vendorID}</vendorID>
        </identity>
        <DataTypeList>
          <defType dataType="0001"> <Boolean/> </defType>
          <defType dataType="0002"> <Integer8/> </defType>
          <defType dataType="0003"> <Integer16/> </defType>
          <defType dataType="0004"> <Integer32/> </defType>
          <defType dataType="0005"> <Unsigned8/> </defType>
          <defType dataType="0006"> <Unsigned16/> </defType>
          <defType dataType="0007"> <Unsigned32/> </defType>
          <defType dataType="0008"> <Real32/> </defType>
          <defType dataType="0009"> <Visible_String/> </defType>
          <defType dataType="0010"> <Integer24/> </defType>
          <defType dataType="0011"> <Real64/> </defType>
          <defType dataType="0012"> <Integer40/> </defType>
          <defType dataType="0013"> <Integer48/> </defType>
          <defType dataType="0014"> <Integer56/> </defType>
          <defType dataType="0015"> <Integer64/> </defType>
          <defType dataType="000A"> <Octet_String/> </defType>
          <defType dataType="000B"> <Unicode_String/> </defType>
          <defType dataType="000C"> <Time_of_Day/> </defType>
          <defType dataType="000D"> <Time_Diff/> </defType>
          <defType dataType="000F"> <Domain/> </defType>
          <defType dataType="0016"> <Unsigned24/> </defType>
          <defType dataType="0018"> <Unsigned40/> </defType>
          <defType dataType="0019"> <Unsigned48/> </defType>
          <defType dataType="001A"> <Unsigned56/> </defType>
          <defType dataType="001B"> <Unsigned64/> </defType>
          <defType dataType="0401"> <MAC_ADDRESS/> </defType>
          <defType dataType="0402"> <IP_ADDRESS/> </defType>
          <defType dataType="0403"> <NETTIME/> </defType>
        </DataTypeList>

        $ObjectList
      </ApplicationLayers>
      <TransportLayers/>
      <NetworkManagement>
        <GeneralFeatures DLLFeatureMN="false" NMTBootTimeNotActive="9000000" NMTCycleTimeMin="400" NMTCycleTimeMax="4294967295" NMTErrorEntries="2" NWLIPSupport="false" PHYExtEPLPorts="2" PHYHubIntegrated="true" SDOServer="true" SDOMaxConnections="2" SDOMaxParallelConnections="2" SDOCmdWriteAllByIndex="false" SDOCmdReadAllByIndex="false" SDOCmdWriteByName="false" SDOCmdReadByName="false" SDOCmdWriteMultParam="false" NMTFlushArpEntry="false" NMTNetHostNameSet="false" PDORPDOChannels="3" PDORPDOChannelObjects="25" PDOSelfReceipt="false" PDOTPDOChannelObjects="25"/>
        <CNFeatures DLLCNFeatureMultiplex="true" DLLCNPResChaining="true" NMTCNSoC2PReq="0"/>
        <Diagnostic/>
      </NetworkManagement>
    </ProfileBody>
  </ISO15745Profile>
</ISO15745ProfileContainer>
