package App::ZFSCurses::WidgetFactory;

use 5.10.1;

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
            'version',           'volsize',
            'written'
        ]
    );

    my $this = bless \%args, $class;
    $this->fill_property_hash();

    return $this;
}

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

sub set_container {
    my $self      = shift;
    my $container = shift;
    $self->{container} = $container;
}

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

        if ( $values eq 'TEXT' ) {
            $self->{properties}->{$property} = \$values;
        }
        else {
            $self->{properties}->{$property} = \@values;
        }
    }
}

sub properties {
    my $self = shift;
    return $self->{properties};
}

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
mountpoint%path,none,legacy
nbmand%on,off
normalization%none,formC,formD,formKC,formKD
primarycache%all,none,metadata
readonly%on,off
redundant_metadata%all,most
secondarycache%all,none,metadata
setuid%on,off
sharenfs%on,off,opts
sharesmb%on,off,opts
snapdir%hidden,visible
sync%standard,always,disabled
utf8only%on,off
volmode%default,geom,dev,none
vscan%off,on
xattr%off,on
snapshot_limit%TEXT
filesystem_limit%TEXT
quota%TEXT
recordsize%TEXT
refquota%TEXT
refreservation%TEXT
reservation%TEXT
volsize%TEXT
