package App::Sys::Info;
$App::Sys::Info::VERSION = '0.25';
use strict;
use warnings;

use constant CP_UTF8      => 65_001;
use constant LAST_ELEMENT =>     -1;

use Carp                 qw( croak    );
use Format::Human::Bytes;
use POSIX                qw( locale_h );
use Text::Table          qw();
use Time::Elapsed        qw( elapsed  );
use Sys::Info            qw();
use Sys::Info::Constants qw( NEW_PERL OSID );

my($NEED_CHCP, $OLDCP);

BEGIN {
    no strict qw( refs );
    foreach my $id ( qw( info os cpu fhb meta NA ) ) {
        *{ $id } = sub () { return shift->{$id} };
    }
}

END {
    _chcp( $OLDCP ) if $NEED_CHCP && $OLDCP;
}

sub _chcp {
    my $enc = shift || croak 'No encoding specified';
    system chcp => $enc, '2>nul', '1>nul';
    return;
}

sub new {
    my $class  = shift;
    my $i      = Sys::Info->new;
    my $loc    = do {
        my $rv;
        eval {
            $rv = setlocale( LC_CTYPE );
            1;
        } or do {
            my $error = $@ || 'Unknown error';
            warn "Unable to collect the locale information: $error";
            $rv = '';
        };
        $rv;
    };
    my $self   = {
        LOCALE => $loc,
        NA     => 'N/A',
        info   => $i,
        os     => $i->os,
        cpu    => $i->device('CPU'),
        fhb    => Format::Human::Bytes->new,
    };
    $self->{meta} = { $self->{os}->meta };
    bless $self, $class;
    return $self;
}

sub run {
    my $self   = __PACKAGE__->new;
    $NEED_CHCP = $self->os->is_winnt && $ENV{PROMPT};
    my @probe  = $self->probe;

    $self->_init_encoding;

    my $tb = Text::Table->new( q{}, q{} );
    $tb->load( @probe );

    print "\n", $tb or croak "Unable to orint to STDOUT: $!";
    return;
}

sub probe {
    my $self = shift;
    my @rv   = eval { $self->_probe(); };
    croak "Error fetching information: $@" if $@;
    return @rv;
}

sub _init_encoding {
    my $self = shift;
    if ( $NEED_CHCP ) {
        ## no critic (InputOutput::ProhibitBacktickOperators)
        chomp($OLDCP = (split /:\s?/xms, qx(chcp))[LAST_ELEMENT]);
        # try to change the command line encoding to unicode
        _chcp( CP_UTF8 ) if $OLDCP;
        if ( NEW_PERL ) {
            my $eok = eval q{ binmode STDOUT, ':utf8'; 1; };
        }
    }
    return;
}

sub _probe {
    my $self   = shift;
    my $meta   = $self->meta;
    my $NA     = $self->NA;
    my $i      = $self->info;
    my $os     = $self->os;
    my $pt     = $os->product_type;
    my $proc   = $self->_processors;
    my $tz     = $os->tz;
    my $driver = 'Sys::Info::Driver::' . OSID;
    my @rv;

    push @rv,
        [ 'Sys::Info Version' => Sys::Info->VERSION ],
        [  sprintf( '%s Driver Version', OSID ) => $driver->VERSION ],
        [ 'Perl Version'      => $i->perl_long      ],
        [ 'Host Name'         => $os->host_name     ],
        [ 'OS Name'           => $self->_os_name    ],
        [ 'OS Version'        => $self->_os_version ],
    ;

    my $manu = $meta->{manufacturer};
    my $bt   = $meta->{build_type};

    push @rv, [ 'OS Manufacturer'  => $manu ] if $manu;
    push @rv, [ 'OS Configuration' => $pt   ] if $pt;
    push @rv, [ 'OS Build Type'    => $bt   ] if $bt;

    $self->_bitness(      \@rv );
    $self->_current_user( \@rv );
    $self->_registered(   \@rv, $meta );

    my $pid  = $meta->{product_id};
    my $tick = $os->tick_count;
    my $st   = $meta->{system_type};

    push @rv, [ 'Product ID'     => $pid           ] if $pid;

    $self->_install_date( \@rv );

    push @rv, [ 'System Up Time' => elapsed($tick) ] if $tick;

    $self->_manufacturer( \@rv, $meta );

    push @rv, [ 'System Type'    => $st            ] if $st;
    push @rv, [ 'Processor(s)'   => $proc          ] if $proc;

    $self->_proc_meta(    \@rv );
    $self->_bios_version( \@rv );
    $self->_directories(  \@rv, $meta );

    my $loc = $self->{LOCALE};

    push @rv, [ 'System Locale' => $loc ] if $loc;
    push @rv, [ 'Input Locale'  => $loc ] if $loc;
    push @rv, [ 'Time Zone'     => $tz  ] if $tz;

    $self->_memory( \@rv, $meta );
    $self->_vm(     \@rv );

    my $domain = $os->domain_name;
    my $logon  = $os->logon_server;
    my $ip     = $os->ip;
    my $page   = $meta->{page_file_path};

    push @rv, [ 'Page File Location(s)' => $page    ] if $page;
    push @rv, [ 'Domain'                => $domain  ] if $domain;
    push @rv, [ 'Logon Server'          => $logon   ] if $logon;
    push @rv, [ 'IP Address'            => $ip      ] if $ip;

    $self->_cdkey( \@rv );

    return @rv;
}

sub _registered {
    my($self, $rv, $meta) = @_;
    return if ! $self->os->is_windows;
    my $owner = $meta->{owner};
    my $org   = $meta->{organization};
    push @{ $rv }, [ 'Registered Owner'        => $owner ] if $owner;
    push @{ $rv }, [ 'Registered Organization' => $org   ] if $org;
    return;
}

sub _directories {
    my($self, $rv, $meta) = @_;
    my $win  = $meta->{windows_dir};
    my $sys  = $meta->{system_dir};
    my $boot = $meta->{boot_device};
    push @{ $rv }, [ 'Windows Directory' => $win  ] if $win;
    push @{ $rv }, [ 'System Directory'  => $sys  ] if $sys;
    push @{ $rv }, [ 'Boot Device'       => $boot ] if $boot;
    return;
}

sub _manufacturer {
    my($self, $rv, $meta) = @_;
    return if ! $self->os->is_windows;
    my $manu  = $meta->{system_manufacturer};
    my $model = $meta->{system_model};
    push @{ $rv }, [ 'System Manufacturer' => $manu  ] if $manu;
    push @{ $rv }, [ 'System Model'        => $model ] if $model;
    return;
}

sub _cdkey {
    my($self, $rv) = @_;
    my $os = $self->os;
    return if ! $os->is_windows;

    my $cdkey = $os->cdkey;
    my $okey  = $self->_office_cdkey;
    push @{ $rv }, [ 'Windows CD Key'          => $cdkey ] if $cdkey;
    push @{ $rv }, [ 'Microsoft Office CD Key' => $okey  ] if $okey;
    return;
}

sub _current_user {
    my($self, $rv_ref) = @_;
    my $os   = $self->os;
    my $user = $os->login_name || return;
    my $real = $os->login_name( real => 1 );

    return if ! $user || ! $real;

    my $display = $real && ($real ne $user) ? qq{$real ($user)} : $user;
    $display .= $os->is_root ? q{ is an administrator} : q{};
    push @{ $rv_ref }, [ 'Current User', $display ];

    return;
}

sub _proc_meta {
    my $self = shift;
    my $data = shift;
    my @cpu  = $self->cpu->identify;
    my $prop = $cpu[0] || {};
    my $load = $self->cpu->load;
    my $L1   = $prop->{L1_cache}{max_cache_size};
    my $L2   = $prop->{L2_cache}{max_cache_size};
    my $sock = $prop->{socket_designation};
    my $id   = $prop->{processor_id};
    my @rv;

    my $check_lc = sub {
        my $ref = shift || return;
        return if ! ${ $ref };
        ${ $ref } .= q{ KB} if ${ $ref } !~ m{\sKB\z}xms;
        return;
    };

    $check_lc->( \$L1 );
    $check_lc->( \$L2 );

    push @rv, qq{Load    : $load}  if $load;
    push @rv, qq{L1 Cache: $L1}    if $L1;
    push @rv, qq{L2 Cache: $L2}    if $L2;
    push @rv, qq{Package : $sock}  if $sock;
    push @rv, qq{ID      : $id}    if $id;

    my $buf = q{ } x 2**2;
    push @{$data}, [ q{ }, $buf . $_ ] for @rv;
    return;
}

sub _processors {
    my $self = shift;
    my $cpu  = $self->cpu;
    my $name = scalar $cpu->identify;
    my $rv   = sprintf '%s ~%sMHz', $name, $cpu->speed;
    $rv =~ s{\s+}{ }xmsg;
    return $rv;
}

sub _memory {
    my($self, $rv, $meta) = @_;
    push @{ $rv },
        map {
            [ $_->[0], $self->_mb( $_->[1] ) ]
        }
        [ 'Total Physical Memory'     => $meta->{physical_memory_total}     ],
        [ 'Available Physical Memory' => $meta->{physical_memory_available} ],
        [ 'Virtual Memory: Max Size'  => $meta->{page_file_total}           ],
        [ 'Virtual Memory: Available' => $meta->{page_file_available}       ],
    ;
    return;
}

sub _vm {
    my($self, $rv_ref) = @_;
    my $tot = $self->meta->{page_file_total}     || return;
    my $av  = $self->meta->{page_file_available} || return;
    push @{ $rv_ref },
        [ 'Virtual Memory: In Use' => $self->_mb( $tot - $av ) ]
    ;
    return;
}

sub _mb {
    my $self = shift;
    my $kb   = shift || return $self->NA;
    return $self->fhb->base2( $kb, 2 );
}

sub _os_name {
    my $self = shift;
    return $self->os->name( long => 1, edition => 1 );
}

sub _os_version {
    my $self = shift;
    my $os   = $self->os;
    return $os->version . q{.} . $os->build;
}

sub _office_cdkey {
    my $self   = shift;
    my @office = $self->os->cdkey( office => 1 );
    return @office ? $office[0] : undef;
}

sub _bitness {
    my($self, $rv_ref) = @_;
    my $cpu = $self->cpu->bitness || q{??};
    my $os  = $self->os->bitness  || q{??};
    push @{ $rv_ref }, [ 'Running on' => qq{${cpu}bit CPU & ${os}bit OS} ];
    return;
}

sub _install_date {
    my($self, $rv_ref) = @_;
    my $date = $self->meta->{install_date} || return;
    push @{ $rv_ref }, [ 'Original Install Date' => scalar localtime $date ];
    return;
}

sub _bios_version {
    my($self, $rv_ref) = @_;
    local $@;
    my $bv = eval { $self->info->device('bios')->version; };
    return if $@ || ! $bv;
    push @{ $rv_ref }, [ 'BIOS Version' => $bv ];
    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Sys::Info

=head1 VERSION

version 0.25

=head1 SYNOPSIS

Run C<psysinfo> from the command line.

=head1 DESCRIPTION

The output is similar to I<systeminfo> windows command.

=head1 NAME

App::Sys::Info - Application of Sys::Info to gather information from the system

=head1 METHODS

=head2 cpu

=head2 fhb

=head2 info

=head2 meta

=head2 new

=head2 NA

=head2 nf

=head2 os

=head2 probe

=head2 run

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
