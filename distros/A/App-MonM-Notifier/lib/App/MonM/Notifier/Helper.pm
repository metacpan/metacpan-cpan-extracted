package App::MonM::Notifier::Helper; # $Id: Helper.pm 6 2017-10-17 16:42:06Z abalama $
use strict;

=head1 NAME

App::MonM::Notifier::Helper - Helper for building configuration and misc files

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

    use App::MonM::Notifier::Helper;

    my $h = new App::MonM::Notifier::Helper (
        -conf   => "/destination/directory/for/conf",
        -misc   => "/destination/directory/for/misc",
    );

    my $status = $h->build();


=head1 DESCRIPTION

Helper for building configuration and misc files

=head2 new

    my $h = new App::MonM::Notifier::Helper (
        -conf   => "/destination/directory/for/conf",
        -misc   => "/destination/directory/for/misc",
    );

Returns helper's object

=head2 build

    my $status = $h->build(
            PARAM1 => 'foo',
            PARAM2 => 'bar',
            # . . .
        );

Building files

=head2 backward_build

    my $status = $self->backward_build();

Second pass of building. For internal use only

=head2 dirs, pool

Base methods. For internal use only

=head1 HISTORY

See C<CHANGES> file

=head1 SEE ALSO

L<App::MonM>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

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

use CTKx;
use CTK qw/:BASE/;
use CTK::Util qw/ :BASE /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;
use Class::C3::Adopt::NEXT; #use MRO::Compat;

use base qw/
        App::MonM::Notifier::Helper::Config
        App::MonM::Notifier::Helper::Misc
    /;

use constant {
    PROJECT     => "monotifier",
    EXEMODE     => 0755,
    DIRMODE     => 0777,
    BOUNDARY    => qr/\-{5}BEGIN\s+FILE\-{5}(.*?)\-{5}END\s+FILE\-{5}/is,
    STDRPLC     => {
            PODSIG  => '=',
            DOLLAR  => '$',
            GMT     => sprintf("%s GMT", scalar(gmtime)),
            YEAR    => (gmtime)[5]+1900,
        },
};

use vars qw/$VERSION/;
$VERSION = '1.00';

sub new {
    my $class = shift;
    my ($conf_dir, $misc_dir) = read_attributes([
        ['CONFDIR','CONFIGDIR','CONF', 'CONFIG'],
        ['MISCDIR','MISC'],
    ],@_) if defined $_[0];

    my %rplc = %{(STDRPLC)};
    $rplc{PROJECT} = PROJECT;

    return bless {
            project => PROJECT,
            boundary=> BOUNDARY,
            pool    => [],
            rplc    => { %rplc },
            dirs    => {
                    conf => $conf_dir,
                    misc => $misc_dir,
                },
            subdirs => {},
            pools   => {},
        }, $class;
}
sub build {
    my $self = shift;
    my %data = @_;
    my $rplc = $self->{rplc};
    foreach (keys %data) {
        $rplc->{$_} = $data{$_};
    }

    # Directories re-definition
    $self->dirs() if $self->can('dirs');

    # Pool definition
    $self->pool() if $self->can('pool');

    # To next controller
    my $ret = $self->maybe::next::method();
    return 0 unless $ret;

    # Backward
    my $bret = $self->backward_build();
    return $bret || 0;
}
sub backward_build {
    my $self = shift;
    my $c = CTKx->instance->c();
    my $rplc = $self->{rplc};

    # Post-processing: directories
    my $dirs = $self->{dirs};
    my $subdirs = $self->{subdirs} || {};
    foreach my $kd (keys %$subdirs) {
        my $vd = $subdirs->{$kd};
        foreach my $d (@$vd) {
            my @ds = split(/\//,_ff($d->{path},$rplc));
            my $root = uv2null(value($dirs, $kd));
            my $path = $root ? catdir($root, @ds) : catdir(@ds);
            my $mode = defined $d->{mode} ? $d->{mode} : DIRMODE;
            if (-e $path) {
                debug(sprintf("Skipped. Directory \"%s\" already exists", $path));
                next;
            }
            debug(sprintf("Created directory \"%s\" [%o]", $path, $mode));
            preparedir($path,$mode);
        }
    }

    # Post-processing: files
    my $pools = $self->{pools};
    foreach my $kp (keys %$pools) {
        #print ">>>> ", $kp, "\n";
        my $vp = $pools->{$kp};
        foreach my $p (@$vp) {
            next if $p->{type} && !isostype($p->{type});
            my $root = uv2null(value($dirs, $kp));
            my $name = $p->{name} || 'noname';
            unless ($p->{file}) {
                carp("Skipping file $name");
                next;
            }
            my @ds = split(/\//,_ff($p->{file},$rplc));
            my $file = catfile($root, @ds);
            if (-e $file) {
                debug(sprintf("Skipped. File \"%s\" already exists", $file));
                next;
            }
            my $mode = $p->{mode};
            my $data = _ff($p->{data},$rplc);

            debug(sprintf("Created file \"%s\" [%o]", $file, $mode // 0));
            bsave($file,$data);
            chmod($mode,$file) if defined($mode);
        }
    }

    return 1;
}
sub dirs {
    my $self = shift;
    $self->maybe::next::method();
    my $dirs = $self->{subdirs} || {};
    foreach my $kd (keys %$dirs) {
        if (ref($dirs->{$kd}) eq 'HASH') {
            $dirs->{$kd} = [$dirs->{$kd}];
        } elsif (ref($dirs->{$kd}) eq 'ARRAY') {
            # OK;
        } else {
            carp "Directories missing" if $dirs->{$kd};
        }
    }
    return 1;
}
sub pool {
    my $self = shift;
    $self->maybe::next::method();
    my $boundary = $self->{boundary};
    my $pools = $self->{pools} || {};
    foreach my $kd (keys %$pools) {
        my $buff = $pools->{$kd};
        my @pool;
        $buff =~ s/$boundary/_bcut($1,\@pool)/ge;
        foreach my $r (@pool) {
            my $name = ($r =~ /^\s*name\s*\:\s*(.+?)\s*$/mi) ? $1 : '';
            my $file = ($r =~ /^\s*file\s*\:\s*(.+?)\s*$/mi) ? $1 : '';
            my $mode = ($r =~ /^\s*mode\s*\:\s*(.+?)\s*$/mi) ? $1 : '';
            my $type = ($r =~ /^\s*type\s*\:\s*(.+?)\s*$/mi) ? $1 : '';
            my $data = ($r =~ /\s*\r?\n\s*\r?\n(.+)/s) ? $1 : '';

            $mode = undef unless $mode =~ /^[0-9]{1,3}$/;
            $r = {
                    name => $name,
                    file => $file,
                    data => lf_normalize($data), # CRLF correct
                    mode => defined $mode ? oct($mode) : undef,
                    type => $type,
                };
        }
        $pools->{$kd} = [@pool];
    }
    return 1;
}

sub _bcut {
    my $s = shift;
    my $a = shift;
    push @$a, $s;
    return '';
}
sub _ff {
    my $d = shift || '';
    my $h = shift || {};
    $d =~ s/\%(\w+?)\%/(defined $h->{$1} ? $h->{$1} : '%'.$1.'%')/eg;
    return $d
}

1;
