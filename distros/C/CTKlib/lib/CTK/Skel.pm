package CTK::Skel; # $Id: Skel.pm 250 2019-05-09 12:09:57Z minus $
use strict;
use utf8;

=encoding utf8

=head1 NAME

CTK::Skel - Helper for building project's skeletons

=head1 VIRSION

Version 1.00

=head1 SYNOPSIS

    use CTK::Skel;

    my $skel = new CTK::Skel (
        -dir    => "/destination/directory/for/project",
    );

    my $skel = new CTK::Skel (
        -name   => "ProjectName",
        -root   => "/path/to/project/dir",
        -skels  => {
                foo => 'My::Foo::Module',
                # ...
            },
        -vars   => {
                VAR1 => "abc",
                VAR2 => "def",
                # ...
            },
        -debug  => 1,
    );

    my $status = $skel->build( "foo", "/path/to/project/dir", {
        VAR3 => 'my value',
        # ...
    });

=head1 DESCRIPTION

Helper for building project's skeletons

=head2 new

    my $skel = new CTK::Skel (
        -name   => "ProjectName",
        -root   => "/path/to/project/dir",
        -skels  => {
                foo => 'My::Foo::Module',
                # ...
            },
        -vars   => {
                VAR1 => "abc",
                VAR2 => "def",
                # ...
            },
        -debug  => 1,
    );

Returns skeletons helper's object

=head2 build

    my $status = $skel->build( "foo", "/path/to/project/dir", {
        VAR1 => 'foo',
        VAR2 => 'bar',
        # ...
    });

Building "foo" files and directories to "/path/to/project/dir" directory

    my $status = $skel->build( "foo", {
        VAR1 => 'foo',
        VAR2 => 'bar',
        # ...
    });

Building "foo" files and directories to default directory (see L</"new">)

=head2 dirs, pool

Base methods. For internal use only

=head2 skels

    my @available_skels = $skel->skels();

Returns list of registered skeletons

=head1 HISTORY

See C<Changes> file

=head1 SEE ALSO

L<CTK>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/$VERSION/;
$VERSION = '1.00';

use Carp;
use File::Spec;
use File::Temp qw();
use Class::C3::Adopt::NEXT; #use MRO::Compat;
use MIME::Base64 qw/decode_base64/;
use Term::ANSIColor qw/colored/;
use CTK::Util qw/ :BASE /;
use CTK::ConfGenUtil;
use CTK::TFVals qw/ :ALL /;

use Cwd qw/getcwd/;

use constant {
    PROJECT     => "Foo",
    EXEMODE     => 0755,
    DIRMODE     => 0777,
    ROOTDIR     => getcwd(),
    BOUNDARY    => qr/\-{5}BEGIN\s+FILE\-{5}(.*?)\-{5}END\s+FILE\-{5}/is,
    STDRPLC     => {
            PODSIG  => '=',
            DOLLAR  => '$',
            GMT     => sprintf("%s GMT", scalar(gmtime)),
            YEAR    => (gmtime)[5]+1900,
        },
};

our @ISA;

sub new {
    my $class = shift;
    my ($project_name, $project_dir, $modules, $newrplc, $debug) = read_attributes([
        ['PROJECTNAME','PROJECT','NAME'],
        ['PROJECTDIR','DIR','PROJECTROOT','ROOT'],
        ['SKELS','LIST','MODULES'],
        ['REPLACE','RPLC','VARS'],
        ['DEBUG'],
    ],@_) if defined $_[0];
    $newrplc ||= {};
    my %rplc = %{(STDRPLC)};
    $rplc{"PROJECT"} = $project_name || PROJECT;
    if (ref($newrplc) eq 'HASH') {
        foreach my $k (keys %$newrplc) {
            $rplc{$k} = $newrplc->{$k};
        }
    }

    my $self = bless {
            project => $rplc{"PROJECT"},
            boundary=> BOUNDARY,
            rplc    => { %rplc },
            root    => $project_dir || ROOTDIR,
            subdirs => {},
            pools   => {},
            skels   => [], # Names of loaded modules
            debug   => $debug ? 1 : 0,
        }, $class;

    # Register skels
    if ($modules && ref($modules) eq 'HASH') {
        my @skels;
        foreach my $skel (keys %$modules) {
            if ($self->_load($modules->{$skel})) {
                push @skels, $skel;
            } else {
                carp(sprintf("Can't initialize %s skeleton", $skel));
                last;
            }
        }
        $self->{skels} = [@skels];
    }

    return $self;
}
sub skels {
    my $self = shift;
    my $skels = $self->{skels};
    return @$skels;
}
sub build {
    my $self = shift;
    my $name = shift;
    my $dir = shift if $_[1];
    my $rplc = shift || {};
    my $root = $dir || $self->{root};

    # Get skels list
    my @skels = $self->skels;
    unless ($name && grep {$_ eq $name} @skels) {
        carp("Incorrect scope name. Allowed: ".join(", ",@skels));
        return 0;
    }
    $rplc = {} unless ref($rplc) eq 'HASH';

    # Directories normalize
    $self->dirs() if $self->can('dirs');

    # Pools normalize
    $self->pool() if $self->can('pool');

    # To next build() in modules
    my $ret = $self->maybe::next::method();
    return 0 unless $ret;

    #
    # Building
    #
    my $_rplc = $self->{rplc};
    for (keys %$_rplc) { $rplc->{$_} = $_rplc->{$_} }

    # Post-processing: directories
    my $subdirs = $self->{subdirs} || {};
    my $vd = $subdirs->{$name};
    foreach my $d (@$vd) {
        my @ds = split(/\//,_ff($d->{path}, $rplc));
        my $path = $root ? File::Spec->catdir($root, @ds) : File::Spec->catdir(@ds);
        my $mode = defined $d->{mode} ? $d->{mode} : DIRMODE;
        if (preparedir($path, $mode)) {
            $self->_debug(_yep("%s", $path));
        } else {
            $self->_debug(_nope("Can't create directory \"%s\" [%o]", $path, $mode));
        }
    }

    # Post-processing: files
    my $pools = $self->{pools} || {};
    my $vp = $pools->{$name};
    foreach my $p (@$vp) {
        next if $p->{type} && !isostype($p->{type}); # Type check
        my $b64 = ($p->{encode} && $p->{encode} eq 'base64') ? 1 : 0;
        my $fname = $p->{name} || 'noname';
        unless ($p->{file}) {
            $self->_debug(_skip("Skip %s file: path not defined!", $fname));
            next;
        }
        my @ds = split(/\//,_ff($p->{file}, $rplc));
        my $file = File::Spec->catfile($root, @ds);
        if (-e $file) {
            $self->_debug(_skip("%s", $file));
            next;
        }
        my $mode = $p->{mode};
        my $st = 0;
        if ($b64) { $st = bsave($file, decode_base64( $p->{data} )) }
        else      { $st = bsave($file, CTK::Util::lf_normalize(_ff($p->{data}, $rplc)), 1) }
        if ($st && -e $file) {
            chmod($mode, $file) if defined($mode);
            $self->_debug(_yep("%s", $file));
        } else {
            $self->_debug(_nope("Can't create file \"%s\" [%o]", $file, $mode // 0));
            return 0;
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
            carp "Directory incorrect. Array or hash expected!" if $dirs->{$kd};
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
            my $enc = ($r =~ /^\s*encode\s*\:\s*(.+?)\s*$/mi) ? $1 : '';
            my $data = ($r =~ /\s*\r?\n\s*\r?\n(.+)/s) ? $1 : '';

            $mode = undef unless $mode =~ /^[0-9]{1,3}$/;
            $r = {
                    name => $name,
                    file => $file,
                    data => lf_normalize($data), # CRLF correct
                    mode => defined($mode) ? oct($mode) : undef,
                    type => $type,
                    encode => $enc,
                };
        }
        $pools->{$kd} = [@pool];
    }
    return 1;
}

# Methods
sub _load {
    my $self = shift;
    my $module = shift;
    my $file = sprintf("%s.pm", join('/', split('::', $module)));
    utf8::encode($file); # from base.pm
    return 1 if exists $INC{$file};
    eval { require $file; };
    if ($@) {
        carp(sprintf("Can't load file: %s", $@));
        return 0;
    }
    push @ISA, $module;
    return 1;
}
sub _debug {
    my $self = shift;
    return unless $self->{debug};
    print @_, "\n";
}

# Functions
sub _yep {
    return(colored(['green on_black'], '[  OK  ]'), ' ', sprintf(shift, @_));
}
sub _nope {
    return(colored(['red on_black'], '[ FAIL ]'), ' ', sprintf(shift, @_));
}
sub _skip {
    return(colored(['yellow on_black'], '[ SKIP ]'), ' ', sprintf(shift, @_));
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
