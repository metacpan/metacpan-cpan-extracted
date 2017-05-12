package App::MonM::RRDtool; # $Id: RRDtool.pm 65 2016-10-05 14:53:02Z abalama $
use strict;

=head1 NAME

App::MonM::RRDtool - App::MonM RRDtool interface

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

    use App::MonM::RRDtool;

=head1 DESCRIPTION

App::MonM RRDtool interface

See C<README> file

=head1 METHODS

=over 8

=item B<new>

    my $rrdtool = new App::MonM::RRDtool;

=item B<is_loaded>

    $rrdtool->is_loaded or die "Module RRDs not loaded";

Method checks the state of loaded RRDs module

=item B<status>

    my $status = $rrdtool->status( NEW_CODE_STATUS );

Returns status code and setup if argument (NEW_CODE_STATUS) exists

=item B<error>

    my $error = $rrdtool->error( NEW_ERROR_MESSAGE );

Returns error message and setup if argument (NEW_ERROR_MESSAGE) exists

=item B<create>

    $rrdtool->create(
            file    => <FILE>,
            type    => <TYPE>, 
        );

Create empty RRD file by filename and type

=item B<update>

    $rrdtool->update( $XML_DOCUMENT_OR_XML_STRUCTURE );

Update data in database files. As the data is a XML document created following command:

    monm alertgrid export

=item B<graph>

Create RRD graphs by keys

    $rrdtool->graph( ARG1, ARG2, ..., ARGn );

=back

=head1 SEE ALSO

L<App::MonM>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is distributed under the GNU GPL v3.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/$VERSION/;
$VERSION = '1.01';

my $RRDs_loaded = 0;

use constant {
    NAMESEP     => '::',
    PREFIX      => 'monm',
    EXT         => 'rrd',
    XMLDEFAULT  => '<?xml version="1.0" encoding="utf-8"?>'."\n".'<response />',
    GTYPES      => [qw/ mini quarter daily weekly monthly yearly /],
    MASK        => '[TYPE].[KEY].[GTYPE].[EXT]',
};

use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use CTK::Util;
use XML::Simple;
use Try::Tiny;
use Time::Local qw/timelocal/;

sub _init { # Loading module RRDs if it need
    return 1 if $RRDs_loaded;
    try {
        require RRDs;
        my $RRDsV = RRDs->VERSION;
        die "VERSION need 1.3008 or more" if $RRDsV < 1.3008;
        $RRDs_loaded = 1;
    } catch {
        carp($_) if $_ =~ /VERSION/;
    };
    # preparing dir
    preparedir(_get_dbpath());
    
    return 0 unless $RRDs_loaded;
    return 1;
}
sub is_loaded { $RRDs_loaded ? 1 : 0 } # Loading check

sub new {
    my $class = shift;
    my $devel = shift || 0;
    #my $cfg = shift;
    #croak "rrdcfg not defined" unless is_hash($cfg);
    _init unless $RRDs_loaded;
    my $maker = $ENV{MAKE} || syscfg("make");
    unless ($RRDs_loaded || $maker || $devel) {
        croak "The make utility not installed. Please install MinGW project package first";
    }
    
    my %props = (
            load_status => $RRDs_loaded,
            devel       => $devel ? 1 : 0,
            #rrdcfg      => $cfg,
            status      => $RRDs_loaded || $devel || $maker ? 1 : 0,
            error       => $RRDs_loaded ? '' : "Module RRDs 1.3008 is not loaded. Please install RRDtool",
            maker       => $maker,
        );
    
    my $self = bless {%props}, $class;
    return $self;
}
sub status {
    my $self = shift;
    my $stt = shift;
    $self->{status} = $stt if defined($stt) && is_int($stt);
    return $self->{status};
}
sub error {
    my $self = shift;
    my $err = shift;
    $self->{error} = $err if defined $err;
    return $self->{error};
}
sub create {
    my $self = shift;
    my %in = @_;
    croak "The \"file\" argument missing" unless exists($in{file}) && defined($in{file});
    croak "The \"type\" argument missing" unless exists($in{type}) && defined($in{type});
    
    my $file = $in{file};
    my $type = $in{type};
    
    if (-e $file) {
        $self->error(sprintf("File already exists \"%s\"", $file));
        return $self->status(0);
    }

    # See http://oss.oetiker.ch/rrdtool/tut/rrdtutorial.en.html
    my ($msg, $err);
    if (0) {
        # Skipped
    } elsif ($type eq "traffic") {
        if ($self->is_loaded) {
            RRDs::create ($file, "--step",300,
                "DS:input:COUNTER:600:U:U",
                "DS:output:COUNTER:600:U:U",
                "RRA:AVERAGE:0.5:1:600",
                "RRA:AVERAGE:0.5:6:700",
                "RRA:AVERAGE:0.5:24:775",
                "RRA:AVERAGE:0.5:288:797",
                "RRA:MIN:0.5:1:600",
                "RRA:MIN:0.5:6:700",
                "RRA:MIN:0.5:24:775",
                "RRA:MIN:0.5:288:797",
                "RRA:MAX:0.5:1:600",
                "RRA:MAX:0.5:6:700",
                "RRA:MAX:0.5:24:775",
                "RRA:MAX:0.5:288:797",
            );
            my $rrderror = RRDs::error();
            $err = $rrderror ? sprintf("%s: Unable to create \"%s\": %s\n",$0,$file,$rrderror) : '';
        } else {
            my $cmd = [$self->{maker},
                    "-f", catfile(sharedir(), 'monm', 'Makefile.net'),
                    "create",
                    sprintf("FILE=%s", $file),
                ];
            $self->_debug(join " ", @$cmd);
            $msg = exe($cmd, undef, \$err);
        }
    } elsif ($type eq "resources") {
        if ($self->is_loaded) {
            RRDs::create ($file, "--step",300,
                "DS:cpu:GAUGE:600:0:100",
                "DS:hdd:GAUGE:600:0:100",
                "DS:mem:GAUGE:600:0:100",
                "DS:swp:GAUGE:600:0:100",
                "RRA:AVERAGE:0.5:1:600",
                "RRA:AVERAGE:0.5:6:700",
                "RRA:AVERAGE:0.5:24:775",
                "RRA:AVERAGE:0.5:288:797",
                "RRA:MIN:0.5:1:600",
                "RRA:MIN:0.5:6:700",
                "RRA:MIN:0.5:24:775",
                "RRA:MIN:0.5:288:797",
                "RRA:MAX:0.5:1:600",
                "RRA:MAX:0.5:6:700",
                "RRA:MAX:0.5:24:775",
                "RRA:MAX:0.5:288:797",
            );
            my $rrderror = RRDs::error();
            $err = $rrderror ? sprintf("%s: Unable to create \"%s\": %s\n",$0,$file,$rrderror) : '';
        } else {
            my $cmd = [$self->{maker},
                    "-f", catfile(sharedir(), 'monm', 'Makefile.res'),
                    "create",
                    sprintf("FILE=%s", $file),
                ];
            $self->_debug(join " ", @$cmd);
            $msg = exe($cmd, undef, \$err);
        }
    } elsif ($type eq "single") {
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.sng'),
                "create",
                sprintf("FILE=%s", $file),
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
    } elsif ($type eq "double") {
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.dbl'),
                "create",
                sprintf("FILE=%s", $file),
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
    } elsif ($type eq "triple") {
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.trp'),
                "create",
                sprintf("FILE=%s", $file),
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
    } elsif ($type eq "quadruple") {
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.qdr'),
                "create",
                sprintf("FILE=%s", $file),
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
    
    } else {
        $err = "Unsupported type";
    }

    $self->_debug($msg);    
    if ($err) {
        $self->_debug($err);
        $self->error($err);
        $self->status(0);
    }
    
    return $self->status;
}
sub update {
    # perl -Ilib bin\monm alertgrid export -F xml | perl -Ilib bin\monm -vdt rrd update --stdin
    my $self = shift;
    my %in = @_;

    croak "The \"file\" argument missing" unless exists($in{file}) && defined($in{file});
    croak "The \"type\" argument missing" unless exists($in{type}) && defined($in{type});
    
    my $file = $in{file};
    my $type = $in{type};
    my $sources = $in{sources};
    my $xml  = $in{xml} || XMLDEFAULT;
    
    # Проверка на вшивость источников
    unless (is_hash($sources) && keys %$sources) {
        $self->error("Sources missing");
        return $self->status(0);
    }
    
    # Чтение данных XML из структуры или документа
    my $data;
    my $stt = 0;
    try {
        if ($xml && ref($xml) eq 'HASH') {
            $data = $xml;
            $stt = 1;
        } else {
            $data = XMLin($xml, ForceArray => 0, KeyAttr => ['id']);
            $stt = 1;
        }
    } catch {
        $self->error("Can't load XML from input data: $_");
    };
    return $self->status(0) unless $stt;
    unless (is_hash($data) && keys %$data) {
        $self->error("Data missing");
        return $self->status(0);
    }
    #print Data::Dumper::Dumper($data);

    # Преобразуем в структуру для быстрого поиска (хэш времени и значения )
    my $counts = hash($data, 'counts/count');
    my %struct;
    foreach (keys %$counts) {
        next unless value($counts, $_, 'status') eq 'OK';
        my $i_ip = value($counts, $_, 'ip') || '127.0.0.1';
        my $i_alertgrid_name = value($counts, $_, 'alertgrid_name');
        my $i_count_name = value($counts, $_, 'count_name');
        $struct{sprintf("%s::%s::%s", $i_ip, $i_alertgrid_name, $i_count_name)} = {
                pubdate => value($counts, $_, 'pubdate'),
                value   => value($counts, $_, 'value'),
            };
    }

    # See http://oss.oetiker.ch/rrdtool/tut/rrdtutorial.en.html
    my ($msg, $err);
    if (0) {
        # Skipped
    } elsif ($type eq "traffic") {
        my $src_pubdate = value($struct{(value($sources, 'srcinput') || 'In')}, 'pubdate');
        my $src_input   = value($struct{(value($sources, 'srcinput') || 'In')}, 'value');
        my $src_output  = value($struct{(value($sources, 'srcoutput') || 'Out')}, 'value');

        if ($self->is_loaded) {
            RRDs::update ($file, "--template", "input:output", sprintf("%s:%s:%s",
                    $src_pubdate || 'N',
                    $src_input || 0,
                    $src_output || 0,
                ));
            
            my $rrderror = RRDs::error();
            $err = $rrderror ? sprintf("%s: Unable to update \"%s\": %s\n",$0,$file,$rrderror) : '';
        } else {
            my $cmd = [$self->{maker},
                    "-f", catfile(sharedir(), 'monm', 'Makefile.net'),
                    "update",
                    sprintf("FILE=%s", $file),
                    sprintf("PUBDATE=%s", $src_pubdate || 'N'),
                    sprintf("INPUT=%s", $src_input || 0),
                    sprintf("OUTPUT=%s", $src_output || 0),
                ];
            $self->_debug(join " ", @$cmd);
            $msg = exe($cmd, undef, \$err);
        }
        
    } elsif ($type eq "resources") {
    
        my $src_pubdate = value($struct{(value($sources, 'srccpu') || 'cpu::UsedPercent')}, 'pubdate');
        my $src_cpu = value($struct{(value($sources, 'srccpu') || 'cpu::UsedPercent')}, 'value');
        my $src_hdd = value($struct{(value($sources, 'srchdd') || 'hdd::UsedPercent')}, 'value');
        my $src_mem = value($struct{(value($sources, 'srcmem') || 'mem::UsedPercent')}, 'value');
        my $src_swp = value($struct{(value($sources, 'srcswp') || 'swp::UsedPercent')}, 'value');
        
        if ($self->is_loaded) {
            RRDs::update ($file, "--template", "cpu:hdd:mem:swp", sprintf("%s:%s:%s:%s:%s",
                    $src_pubdate || 'N',
                    $src_cpu || 0,
                    $src_hdd || 0,
                    $src_mem || 0,
                    $src_swp || 0,
                ));
        
            my $rrderror = RRDs::error();
            $err = $rrderror ? sprintf("%s: Unable to update \"%s\": %s\n",$0,$file,$rrderror) : '';
        } else {
            my $cmd = [$self->{maker},
                    "-f", catfile(sharedir(), 'monm', 'Makefile.res'),
                    "update",
                    sprintf("FILE=%s", $file),
                    sprintf("PUBDATE=%s", $src_pubdate || 'N'),
                    sprintf("CPU=%s", $src_cpu || 0),
                    sprintf("HDD=%s", $src_hdd || 0),
                    sprintf("MEM=%s", $src_mem || 0),
                    sprintf("SWP=%s", $src_swp || 0),
                ];
            $self->_debug(join " ", @$cmd);
            $msg = exe($cmd, undef, \$err);
        }

    } elsif ($type eq "single") {
        my $src_pubdate = value($struct{(value($sources, 'srcusr1') || 'USR1')}, 'pubdate');
        my $src_usr1    = value($struct{(value($sources, 'srcusr1') || 'USR1')}, 'value');
        #print STDERR "USR1: $src_usr1";
        #print STDERR "PUB: $src_pubdate";
        
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.sng'),
                "update",
                sprintf("FILE=%s", $file),
                sprintf("PUBDATE=%s", $src_pubdate || 'N'),
                sprintf("USR1=%s", $src_usr1 || 0),
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
    } elsif ($type eq "double") {
        my $src_pubdate = value($struct{(value($sources, 'srcusr1') || 'USR1')}, 'pubdate');
        my $src_usr1    = value($struct{(value($sources, 'srcusr1') || 'USR1')}, 'value');
        my $src_usr2    = value($struct{(value($sources, 'srcusr2') || 'USR2')}, 'value');
        
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.dbl'),
                "update",
                sprintf("FILE=%s", $file),
                sprintf("PUBDATE=%s", $src_pubdate || 'N'),
                sprintf("USR1=%s", $src_usr1 || 0),
                sprintf("USR2=%s", $src_usr2 || 0),
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
    } elsif ($type eq "triple") {
        my $src_pubdate = value($struct{(value($sources, 'srcusr1') || 'USR1')}, 'pubdate');
        my $src_usr1    = value($struct{(value($sources, 'srcusr1') || 'USR1')}, 'value');
        my $src_usr2    = value($struct{(value($sources, 'srcusr2') || 'USR2')}, 'value');
        my $src_usr3    = value($struct{(value($sources, 'srcusr3') || 'USR3')}, 'value');
        
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.trp'),
                "update",
                sprintf("FILE=%s", $file),
                sprintf("PUBDATE=%s", $src_pubdate || 'N'),
                sprintf("USR1=%s", $src_usr1 || 0),
                sprintf("USR2=%s", $src_usr2 || 0),
                sprintf("USR3=%s", $src_usr3 || 0),
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
    } elsif ($type eq "quadruple") {
        my $src_pubdate = value($struct{(value($sources, 'srcusr1') || 'USR1')}, 'pubdate');
        my $src_usr1    = value($struct{(value($sources, 'srcusr1') || 'USR1')}, 'value');
        my $src_usr2    = value($struct{(value($sources, 'srcusr2') || 'USR2')}, 'value');
        my $src_usr3    = value($struct{(value($sources, 'srcusr3') || 'USR3')}, 'value');
        my $src_usr4    = value($struct{(value($sources, 'srcusr4') || 'USR4')}, 'value');
        
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.qdr'),
                "update",
                sprintf("FILE=%s", $file),
                sprintf("PUBDATE=%s", $src_pubdate || 'N'),
                sprintf("USR1=%s", $src_usr1 || 0),
                sprintf("USR2=%s", $src_usr2 || 0),
                sprintf("USR3=%s", $src_usr3 || 0),
                sprintf("USR4=%s", $src_usr4 || 0),
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);

    } else {
        $err = "Unsupported type";
    }
    
    $self->_debug($msg);    
    if ($err) {
        $self->_debug($err);
        $self->error($err);
        $self->status(0);
    }
    
    return $self->status;
}
sub graph {
    my $self = shift;
    my %in = @_;

    croak "The \"name\" argument missing" unless exists($in{name}) && defined($in{name});
    croak "The \"file\" argument missing" unless exists($in{file}) && defined($in{file});
    croak "The \"type\" argument missing" unless exists($in{type}) && defined($in{type});
    
    my $name = $in{name};
    my $file = $in{file};
    my $type = $in{type};
    my $odir = $in{dir} || _get_dbpath();
    my $mask = $in{mask} || MASK;
    my $image;
    my $fle = $file; $fle =~ s/\:/\\\:/g; # Корректировка
    
    my @graph_a = (
        "graph",
        sprintf("FILE=%s", $fle),
        sprintf("NAME=%s", $name),
        #sprintf("PUBDATE=\"%s\"", dtf("%w, %DD %MON %YYYY %hh\\:%mm\\:%ss %Z",time())),
        sprintf("PUBDATE=%s", dtf("%w, %DD %MON %YYYY %hh\\:%mm\\:%ss",time())),
        sprintf("MINI=%s", catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "mini" }))),
        sprintf("QUARTER=%s", catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "quarter" }))),
        sprintf("DAILY=%s", catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "daily" }))),
        sprintf("WEEKLY=%s", catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "weekly" }))),
        sprintf("MONTHLY=%s", catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "monthly" }))),
        sprintf("YEARLY=%s", catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "yearly" }))),
        sprintf("BRD_D=%s", _vborder("daily")),
        sprintf("BRD_W=%s", _vborder("weekly")),
        sprintf("BRD_M=%s", _vborder("monthly")),
        sprintf("BRD_Y=%s", _vborder("yearly")),
    );
    
    # See http://oss.oetiker.ch/rrdtool/tut/rrdtutorial.en.html
    my ($msg, $err);
    if (0) {
        # Skipped
    } elsif ($type eq "traffic") {
        my @maindata = (
            sprintf("DEF:inoctets=%s:input:AVERAGE",$file),
            sprintf("DEF:outoctets=%s:output:AVERAGE",$file),
            "CDEF:in=inoctets,8,*",
            "CDEF:out=outoctets,8,*",
            "VDEF:in_cur=in,LAST",
            "VDEF:in_avg=in,AVERAGE",
            "VDEF:in_min=in,MINIMUM",
            "VDEF:in_max=in,MAXIMUM",
            "VDEF:out_cur=out,LAST",
            "VDEF:out_avg=out,AVERAGE",
            "VDEF:out_min=out,MINIMUM",
            "VDEF:out_max=out,MAXIMUM",
            "COMMENT:\\s",
            "COMMENT:----------------------------------------------------------------------------------------------------\\s",
            "COMMENT:\\s",
            "COMMENT:\\t\\t\\t      Current\\t\\t Average\\t    Minimum\\t\\tMaximum\\s",
            "COMMENT:\\s",
            "COMMENT:----------------------------------------------------------------------------------------------------\\s",
            "COMMENT:\\s",
            "COMMENT: ",
            "AREA:in#00FF00:In traffic ",
            "GPRINT:in_cur:\\t%8.0lf%s",
            "GPRINT:in_avg:\\t%8.0lf%s",
            "GPRINT:in_min:\\t%8.0lf%s",
            "GPRINT:in_max:\\t%8.0lf%s\\l",
            "COMMENT: ",
            "LINE1:out#0000FF:Out traffic",
            "GPRINT:out_cur:\\t%8.0lf%s",
            "GPRINT:out_avg:\\t%8.0lf%s",
            "GPRINT:out_min:\\t%8.0lf%s",
            "GPRINT:out_max:\\t%8.0lf%s\\l",
            "COMMENT:\\s",
            "COMMENT:----------------------------------------------------------------------------------------------------\\l",
            sprintf("COMMENT:Generated\\: %s\\r",dtf("%w, %DD %MON %YYYY %hh\\:%mm\\:%ss %Z",time())),
        );

        if ($self->is_loaded) {
            # Формируем имя файла по маске для MINI
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "mini" }));
            RRDs::graph( $image, "--imgformat","PNG", "--slope-mode", "--rigid",
                "--title", sprintf("%s 3h", $name),
                "-v", "bps",
                "--base", "1000",
                "--start", "-3h", "--end", "now",
                "--width", 150, "--height", 50,
                "--x-grid", "MINUTE:10:HOUR:1:HOUR:1:0:%H\:%M",
                "--color", "ARROW#EE0000",
                sprintf("DEF:inoctets=%s:input:AVERAGE",$file),
                sprintf("DEF:outoctets=%s:output:AVERAGE",$file),
                "CDEF:in=inoctets,8,*",
                "CDEF:out=outoctets,8,*",
                "VDEF:in_cur=in,LAST",
                "VDEF:out_cur=out,LAST",
                "AREA:in#00FF00:In",
                "GPRINT:in_cur:%3.0lf%s",
                "LINE1:out#0000FF:Out",
                "GPRINT:out_cur:%3.0lf%s",
            );
            
            # Формируем имя файла по маске для QUARTER
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "quarter" }));
            RRDs::graph( $image, "--imgformat","PNG",
                "--title", sprintf("%s 6 hours (5 Minute Average)", $name),
                "-v", "Bits per Second",
                "--base", "1000",
                "--start", "-6h", "--end", "now",
                "--width", 640, "--height", 260,
                "--x-grid", "MINUTE:20:HOUR:1:HOUR:1:0:%a %H\:%M",
                "--color", "ARROW#EE0000",
                @maindata
            );        

            # Формируем имя файла по маске для DAILY
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "daily" }));
            RRDs::graph( $image, "--imgformat","PNG",
                "--title", sprintf("%s daily (5 Minute Average)", $name),
                "-v", "Bits per Second",
                "--base", "1000",
                "--start", "-27h", "--end", "now",
                "--width", 640, "--height", 260,
                "--x-grid", "MINUTE:20:HOUR:1:HOUR:3:0:%a %H:%M",
                "--color", "ARROW#EE0000",
                @maindata,
                sprintf("VRULE:%s#EE0000", _timeborder()),
            );
            
            # Формируем имя файла по маске для WEEKLY
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "weekly" }));
            RRDs::graph( $image, "--imgformat","PNG",
                "--title", sprintf("%s weekly (30 Minute Average)", $name),
                "-v", "Bits per Second",
                "--base", "1000",
                "--start", "-8d", "--end", "now",
                "--width", 640, "--height", 260,
                "--x-grid", "HOUR:6:DAY:1:DAY:1:86400:%a %d/%m",
                "--color", "ARROW#EE0000",
                @maindata,
                sprintf("VRULE:%s#EE0000", _vborder("weekly")),
            );

            # Формируем имя файла по маске для MONTHLY
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "monthly" }));
            RRDs::graph( $image, "--imgformat","PNG",
                "--title", sprintf("%s monthly (2 Hour Average)", $name),
                "-v", "Bits per Second",
                "--base", "1000",
                "--start", "-1mon1d", "--end", "now",
                "--width", 640, "--height", 260,
                "--x-grid", "DAY:3:DAY:1:DAY:3:0:%d/%m",
                "--color", "ARROW#EE0000",
                @maindata,
                sprintf("VRULE:%s#EE0000", _vborder("monthly")),
            );
            
            # Формируем имя файла по маске для YEARLY
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "yearly" }));
            RRDs::graph( $image, "--imgformat","PNG",
                "--title", sprintf("%s yearly (1 Day Average)", $name),
                "-v", "Bits per Second",
                "--base", "1000",
                "--start", "-13mon", "--end", "now",
                "--width", 640, "--height", 260,
                "--x-grid", "MONTH:3:MONTH:1:MONTH:1:2592000:%b",
                "--color", "ARROW#EE0000",
                @maindata,
                sprintf("VRULE:%s#EE0000", _vborder("yearly")),
            );

            my $rrderror = RRDs::error();
            $err = $rrderror ? sprintf("%s: Unable to create image \"%s\": %s\n",$0,$file,$rrderror) : '';
        } else {
            my $cmd = [$self->{maker},
                    "-f", catfile(sharedir(), 'monm', 'Makefile.net'),
                    @graph_a
                ];
            $self->_debug(join " ", @$cmd);
            $msg = exe($cmd, undef, \$err);
            #print "$err\n" if $err;
        }
    } elsif ($type eq "resources") {
        my @maindata = (
            sprintf("DEF:mem=%s:mem:AVERAGE",$file),
            sprintf("DEF:swp=%s:swp:AVERAGE",$file),
            sprintf("DEF:cpu=%s:cpu:AVERAGE",$file),
            sprintf("DEF:hdd=%s:hdd:AVERAGE",$file),
            
            "VDEF:mem_cur=mem,LAST",
            "VDEF:mem_avg=mem,AVERAGE",
            "VDEF:mem_min=mem,MINIMUM",
            "VDEF:mem_max=mem,MAXIMUM",
            
            "VDEF:swp_cur=swp,LAST",
            "VDEF:swp_avg=swp,AVERAGE",
            "VDEF:swp_min=swp,MINIMUM",
            "VDEF:swp_max=swp,MAXIMUM",
            
            "VDEF:cpu_cur=cpu,LAST",
            "VDEF:cpu_avg=cpu,AVERAGE",
            "VDEF:cpu_min=cpu,MINIMUM",
            "VDEF:cpu_max=cpu,MAXIMUM",
            
            "VDEF:hdd_cur=hdd,LAST",
            "VDEF:hdd_avg=hdd,AVERAGE",
            "VDEF:hdd_min=hdd,MINIMUM",
            "VDEF:hdd_max=hdd,MAXIMUM",
            
            "COMMENT:\\s",
            "COMMENT:----------------------------------------------------------------------------------------------------\\s",
            "COMMENT:\\s",
            "COMMENT:\\t\\t\\t\\tCurrent\\t\\t  Average\\t    Minimum\\t      Maximum\\s",
            "COMMENT:\\s",
            "COMMENT:----------------------------------------------------------------------------------------------------\\s",
            "COMMENT:\\s",
            "COMMENT: ",
            
            "LINE2:mem#00FF00:Memory usage\\t",
            "GPRINT:mem_cur:\\t%7.0lf%s",
            "GPRINT:mem_avg:\\t%7.0lf%s",
            "GPRINT:mem_min:\\t%7.0lf%s",
            "GPRINT:mem_max:\\t%7.0lf%s\\l",
            "COMMENT: ",
            
            "LINE2:swp#FFFF00:Swap usage  \\t",
            "GPRINT:swp_cur:\\t%7.0lf%s",
            "GPRINT:swp_avg:\\t%7.0lf%s",
            "GPRINT:swp_min:\\t%7.0lf%s",
            "GPRINT:swp_max:\\t%7.0lf%s\\l",
            "COMMENT: ",
            
            "LINE2:cpu#FF0000:CPU usage   \\t",
            "GPRINT:cpu_cur:\\t%7.0lf%s",
            "GPRINT:cpu_avg:\\t%7.0lf%s",
            "GPRINT:cpu_min:\\t%7.0lf%s",
            "GPRINT:cpu_max:\\t%7.0lf%s\\l",
            "COMMENT: ",
            
            "LINE2:hdd#0000FF:Disk usage  \\t",
            "GPRINT:hdd_cur:\\t%7.0lf%s",
            "GPRINT:hdd_avg:\\t%7.0lf%s",
            "GPRINT:hdd_min:\\t%7.0lf%s",
            "GPRINT:hdd_max:\\t%7.0lf%s\\l",
            
            "COMMENT:\\s",
            "COMMENT:----------------------------------------------------------------------------------------------------\\l",
            sprintf("COMMENT:Generated\\: %s\\r",dtf("%w, %DD %MON %YYYY %hh\\:%mm\\:%ss %Z",time())),
        );    
        
        if ($self->is_loaded) {
            # Формируем имя файла по маске для MINI
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "mini" }));
            RRDs::graph( $image, "--imgformat","PNG", "--slope-mode", "--rigid",
                "--title", sprintf("%s 3h", $name),
                "-v", "Load, %",
                "--base", "1000",
                "--start", "-3h", "--end", "now",
                "--width", 150, "--height", 50,
                "--x-grid", "MINUTE:10:HOUR:1:HOUR:1:0:%H\:%M",
                "--color", "ARROW#EE0000",
                sprintf("DEF:mem=%s:mem:AVERAGE",$file),
                sprintf("DEF:swp=%s:swp:AVERAGE",$file),
                sprintf("DEF:cpu=%s:cpu:AVERAGE",$file),
                sprintf("DEF:hdd=%s:hdd:AVERAGE",$file),
                "LINE1:mem#00FF00:MEM",
                "LINE1:swp#FFFF00:SWP",
                "LINE1:cpu#FF0000:CPU",
                "LINE1:hdd#0000FF:HDD",
            );
            
            # Формируем имя файла по маске для QUARTER
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "quarter" }));
            RRDs::graph( $image, "--imgformat","PNG",
                "--title", sprintf("%s 6 hours (5 Minute Average)", $name),
                "-v", "Load, %",
                "--base", "1000",
                "--start", "-6h", "--end", "now",
                "--width", 640, "--height", 260,
                "--x-grid", "MINUTE:20:HOUR:1:HOUR:1:0:%a %H\:%M",
                "--color", "ARROW#EE0000",
                @maindata
            );        

            # Формируем имя файла по маске для DAILY
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "daily" }));
            RRDs::graph( $image, "--imgformat","PNG",
                "--title", sprintf("%s daily (5 Minute Average)", $name),
                "-v", "Load, %",
                "--base", "1000",
                "--start", "-27h", "--end", "now",
                "--width", 640, "--height", 260,
                "--x-grid", "MINUTE:20:HOUR:1:HOUR:3:0:%a %H:%M",
                "--color", "ARROW#EE0000",
                @maindata,
                sprintf("VRULE:%s#EE0000", _timeborder()),
            );
            
            # Формируем имя файла по маске для WEEKLY
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "weekly" }));
            RRDs::graph( $image, "--imgformat","PNG",
                "--title", sprintf("%s weekly (30 Minute Average)", $name),
                "-v", "Load, %",
                "--base", "1000",
                "--start", "-8d", "--end", "now",
                "--width", 640, "--height", 260,
                "--x-grid", "HOUR:6:DAY:1:DAY:1:86400:%a %d/%m",
                "--color", "ARROW#EE0000",
                @maindata,
                sprintf("VRULE:%s#EE0000", _vborder("weekly")),
            );

            # Формируем имя файла по маске для MONTHLY
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "monthly" }));
            RRDs::graph( $image, "--imgformat","PNG",
                "--title", sprintf("%s monthly (2 Hour Average)", $name),
                "-v", "Load, %",
                "--base", "1000",
                "--start", "-1mon1d", "--end", "now",
                "--width", 640, "--height", 260,
                "--x-grid", "DAY:3:DAY:1:DAY:3:0:%d/%m",
                "--color", "ARROW#EE0000",
                @maindata,
                sprintf("VRULE:%s#EE0000", _vborder("monthly")),
            );
            
            # Формируем имя файла по маске для YEARLY
            $image = catfile($odir, dformat($mask, { EXT => "png", TYPE => $type, KEY => $name, GTYPE => "yearly" }));
            RRDs::graph( $image, "--imgformat","PNG",
                "--title", sprintf("%s yearly (1 Day Average)", $name),
                "-v", "Load, %",
                "--base", "1000",
                "--start", "-13mon", "--end", "now",
                "--width", 640, "--height", 260,
                "--x-grid", "MONTH:3:MONTH:1:MONTH:1:2592000:%b",
                "--color", "ARROW#EE0000",
                @maindata,
                sprintf("VRULE:%s#EE0000", _vborder("yearly")),
            );
            
            my $rrderror = RRDs::error();
            $err = $rrderror ? sprintf("%s: Unable to create image \"%s\": %s\n",$0,$file,$rrderror) : '';
        } else {
            my $cmd = [$self->{maker},
                    "-f", catfile(sharedir(), 'monm', 'Makefile.res'),
                    @graph_a
                ];
            $self->_debug(join " ", @$cmd);
            $msg = exe($cmd, undef, \$err);
            #print "$err\n" if $err;
        }
    } elsif ($type eq "single") {
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.sng'),
                @graph_a,
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
        #print "$err\n" if $err;
    } elsif ($type eq "double") {
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.dbl'),
                @graph_a,
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
    } elsif ($type eq "triple") {
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.trp'),
                @graph_a,
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
    } elsif ($type eq "quadruple") {
        my $cmd = [$self->{maker},
                "-f", catfile(sharedir(), 'monm', 'Makefile.qdr'),
                @graph_a,
            ];
        $self->_debug(join " ", @$cmd);
        $msg = exe($cmd, undef, \$err);
    } else {
        $err = "Unsupported type";
    }

    $self->_debug($msg);
    if ($err) {
        $self->_debug($err);
        $self->error($err);
        $self->status(0);
    } else {
        $self->status(1);
    }
    
    return $self->status;
}
sub _debug {
    my $self = shift;
    my $s = shift;
    printf "\n-----BEGIN DEVEL DATA-----\n%s\n-----END DEVEL DATA-----\n", $s 
        if $self->{devel} && defined $s;
    return 1;
}
sub _get_dbpath { 
    my $dir = shift;
    return $dir if $dir && (-e $dir) && ( (-d $dir) || (-l $dir) );
    return catdir(tmpdir(), PREFIX) 
}
sub _timeborder {
    my $off = shift || 0;
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time() + $off);
    return timelocal(0,0,0,$mday,$mon,$year);
}
sub _vborder {
    my $g = shift || '';
    my $offday;
    if ($g =~ /yearly/i) {
        $offday = (localtime(time()))[7] || 0;
        return _timeborder(-1 * 60 * 60 * 24 * $offday);
    } elsif ($g =~ /monthly/i) {
        $offday = (localtime(time()))[3] || 0;
        return _timeborder(-1 * 60 * 60 * 24 * $offday);
    } elsif ($g =~ /weekly/i) {
        $offday = (localtime(time()))[6] || 0; 
        $offday = 7 if $offday == 0;
        return _timeborder(-1 * 60 * 60 * 24 * ($offday-1));
    } 
    
    # daily
    return _timeborder()

}
1;
