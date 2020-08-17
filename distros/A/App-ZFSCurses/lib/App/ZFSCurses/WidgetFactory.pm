package App::ZFSCurses::WidgetFactory;

use 5.10.1;
use strict;
use warnings;

=head1 NAME

App::ZFSCurses::WidgetFactory - Create widgets.

=head1 METHODS

=head1 VERSION

Version 1.212.

=cut

our $VERSION = '1.212';

=head2 new

Create an instance of App::ZFSCurses::WidgetFactory.

=cut

sub new {
    my $class = shift;

    my %args = (
        container     => {},
        properties    => {},
        ro_properties => [
            'available',         'compressratio',
            'createtxg',         'creation',
            'clones',            'defer_destroy',
            'encryption_root',   'filesystem_count',
            'keystatus',         'guid',
            'logicalreferenced', 'logicalused',
            'mounted',           'objsetid',
            'origin',            'refcompressratio',
            'referenced',        'receive_resume_token',
            'snapshot_count',    'type',
            'used',              'usedbychildren',
            'usedbydataset',     'usedbyrefreservation',
            'usedbysnapshots',   'userrefs',
            'volsize',           'written',
            'utf8only'
        ]
    );

    my $this = bless \%args, $class;
    $this->fill_property_hash();

    return $this;
}

=head2 search_value

Search a value in an array. Return the value index if found. Return -1 if not
found.

=cut

sub search_value {
    my $self = shift;
    my ( $element, $array ) = @_;

    foreach ( 0 .. $#$array ) {
        if ( $array->[$_] eq $element ) {
            return $_;
        }
    }

    return -1;
}

=head2 widget_selector

Select the right widget to create. This method expects a property list as first
argument. It will then check for its type, create the widget accordingly and
return it.

=cut

sub widget_selector {
    my $self            = shift;
    my $property_values = shift;

    my $ref    = ref $property_values;
    my $widget = {};

    if ( $ref =~ /ARRAY/ ) {
        $widget->{type}   = 'Radiobuttonbox';
        $widget->{values} = {
            -height      => -1,
            -width       => -1,
            -y           => 3,
            -padleft     => 1,
            -padright    => 1,
            -padbottom   => 2,
            -fg          => 'blue',
            -bg          => 'black',
            -vscrollbar  => 1,
            -wraparound  => 1,
            -intellidraw => 1,
            -selected =>
              $self->search_value( $self->{current_value}, $property_values ),
            -values => $property_values
        };
    }
    elsif ( $ref =~ /SCALAR/ ) {
        $widget->{type}   = 'TextEntry';
        $widget->{values} = {
            -y        => 3,
            -ipadleft => 1,
            -sbborder => 1,
            -width    => 10
        };
    }
    else {
        $widget->{type} = '';
    }

    return $widget;
}

=head2 make_widget

Make a widget depending on the property type. This method expects a property
and, sometimes, the current value (selected in the UI). This method is called
from the UI module when a user selects a property and wants to change it.

=cut

sub make_widget {
    my $self = shift;
    my ( $property, $current_value ) = @_;

    $self->{current_value} = $current_value;
    my $property_values = $self->{properties}->{$property};
    my $widget          = $self->widget_selector($property_values);

    my $property_widget = $self->{container}
      ->add( 'property_widget', $widget->{type}, %{ $widget->{values} } );

    $property_widget->draw();
    return $property_widget;
}

=head2 set_container

Set the container that will contain the created widget.

=cut

sub set_container {
    my $self      = shift;
    my $container = shift;
    $self->{container} = $container;
}

=head2 fill_property_hash

Read the DATA handle and fill the property hash. __DATA__ contains a list of
key value pairs that represent a property and its possible values. Note: the
ALNUM value means the property is alphanumerical and a textfield has to be
created to be shown to the user. Otherwise, a radio button box is created with
the possible values. See the widget_selector function.

=cut

sub fill_property_hash {
    my $self = shift;

    while (<DATA>) {
        chomp;

        my ( $property, $values ) = split /%/;
        my @values = split /,/, $values;

        if ( $property =~ /compression/ ) {
            push @values, do {
                my $gzip = [];
                push @$gzip, "gzip-$_", for ( 1 .. 9 );
                @$gzip;
            };
        }

        if ( $values eq 'ALNUM' ) {
            $self->{properties}->{$property} = \$values;
        }
        else {
            $self->{properties}->{$property} = [ sort @values ];
        }
    }
}

=head2 properties

Return the properties hash.

=cut

sub properties {
    my $self = shift;
    return $self->{properties};
}

=head2 is_property_ro

Check whether a property is read only (cannot be changed).

=cut

sub is_property_ro {
    my $self     = shift;
    my $property = shift;
    my $array    = $self->{ro_properties};

    # 1 -> true. property is read only.
    # 0 -> false. property is not read only.
    my $is_ro = 1;

    foreach ( 0 .. $#$array ) {
        if ( $array->[$_] eq $property ) {
            $is_ro = 0;
            last;
        }
    }

    return $is_ro;
}

=head1 AUTHOR

Patrice Clement <monsieurp at cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Patrice Clement.

This is free software, licensed under the (three-clause) BSD License.

See the LICENSE file.

=cut

1;

__DATA__
aclinherit%discard,noallow,restricted,passthrough,passthrough-x
aclmode%discard,groupmask,passthrough,restricted
atime%on,off
canmount%on,off,noauto
checksum%on,off,fletcher2,fletcher4,sha256,noparity,sha512,skein
compression%on,off,lzjb,zle,lz4,gzip
copies%1,2,3
casesensitivity%sensitive,insensitive,mixed
dedup%on,off,verify,sha256,sha256verify,sha512,sha512verify,skein,skeinverify
devices%on,off
dnodesize%legacy,auto,1k,2k,4k,8k,16k
exec%on,off
jailed%off,on
logbias%latency,throughput
mlslabel%label,none
nbmand%on,off
normalization%none,formC,formD,formKC,formKD
primarycache%all,none,metadata
readonly%on,off
redundant_metadata%all,most
secondarycache%all,none,metadata
setuid%on,off
sharenfs%on,off,opts
sharesmb%on,off,opts
version%1,2,3,4,5,current
snapdir%hidden,visible
sync%standard,always,disabled
volmode%default,geom,dev,none
vscan%off,on
xattr%off,on
snapshot_limit%ALNUM
filesystem_limit%ALNUM
quota%ALNUM
recordsize%ALNUM
refquota%ALNUM
refreservation%ALNUM
reservation%ALNUM
mountpoint%ALNUM
volsize%ALNUM
