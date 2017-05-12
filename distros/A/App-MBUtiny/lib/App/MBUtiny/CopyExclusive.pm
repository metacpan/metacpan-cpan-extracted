package App::MBUtiny::CopyExclusive; # $Id: CopyExclusive.pm 12 2014-08-22 09:54:55Z abalama $
use strict;

=head1 NAME

App::MBUtiny::CopyExclusive - Exclusive copying directories

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use App::MBUtiny::CopyExclusive;
    
    xcopy( "/source/folder", "/destination/folder" )
        or die "Can't copy directory";

    # Copying without foo and bar/baz files/directories
    xcopy( "/source/folder", "/destination/folder", [qw( foo bar/baz )] )
        or die "Can't copy directory";

=head1 ABSTRACT

App::MBUtiny::CopyExclusive - Exclusive copying directories for App::MBUtiny

=head1 DESCRIPTION

Exclusive copying directories

=head1 FUNCTIONS

=over 8

=item B<xcopy>

    xcopy( $src_dir, $dst_dir, [ ... exclude rel. paths ... ] );

Copying all objects (files/directories) from $src_dir directory into $dst_dir 
directory without specified relative paths. The function returns status of work

=back

=head1 HISTORY

See C<CHANGES> file

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.com> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2014 D&D Corporation. All Rights Reserved

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

use vars qw/ $VERSION /;
$VERSION = '1.00';

use base qw/Exporter/;
our @EXPORT = qw/ xcopy /;

use Carp;
use File::Find;
use File::Copy;

use constant {
    DIRMODE => 0777,
};

our $DEBUG = 0;

sub xcopy {
    my $object = shift || ''; # from
    my $target = shift || ''; # to
    my $exclude = shift;      # exclude files
    
    carp("Source directory not exists: $object") && return 
        unless $object && (-e $object and -d $object);

    carp("Target directory not defined: $target") && return 
        unless $target;
    
    if ($exclude && ref($exclude) ne 'ARRAY') {
        carp("The third argument must be reference to array containing list of files for excluding");
        return;
    } else {
        $exclude = [] unless $exclude;
    }

    my $ob = File::Spec->canonpath($object);
    my $tg = File::Spec->canonpath($target);
    my (@exf, @exd);
    foreach (@$exclude) {
        my $tf = File::Spec->canonpath(File::Spec->catfile($ob, $_));
        my $td = File::Spec->canonpath(File::Spec->catdir($ob, $_));
        if (-e $td && -d $td) {
            push @exd, $td;
        } else {
            push @exf, $tf;
        }
    };
    
    if ($DEBUG) {
        printf("#F: %s\n", $_) for @exf;
        printf("#D: %s\n", $_) for @exd;
    }
    
    find({
        wanted => sub 
            {
                my $f = File::Spec->canonpath($_);
                my $p = File::Spec->abs2rel( $f, $ob );
                if ((-e $f and -f $f) && (grep {$_ eq $f} @exf)) {
                    print ">F [SKIP] $f\n" if $DEBUG;
                    return 1;
                } elsif (@exd && grep {_td($_,$f)} @exd) {
                    print ">D [SKIP] $f\n" if $DEBUG;
                    return 1;
                } else {
                    if (-d $f) {
                        my $end = File::Spec->catdir($tg, $p);
                        print ">D        $f -> $end\n" if $DEBUG;
                        unless (-e $end) {
                            mkdir($end,DIRMODE) or carp(sprintf("Can't create directoy \"%s\": ", $end, $!)) && return;
                            chmod scalar((stat($f))[2]), $end;
                        }
                    } else {
                        my $end = File::Spec->catfile($tg, $p);
                        print ">F        $f -> $end\n" if $DEBUG;
                        unless (-e $end) {
                            copy($f,$end) or carp(sprintf("Copy failed \"%s\" -> \"%s\": %s", $f, $end, $!)) && return;
                            chmod scalar((stat($f))[2]), $end;
                        }
                    }
                }
            }, 
        no_chdir => 1,
        }, $ob,
    );

    print "\n" if $DEBUG;
    return 1;
}

sub _td { # Test of base directory
    my $d = shift; # exclude directory
    my $o = shift; # test object

    my @t;
    my @sd;
    my $ret = 0;
    my ($volume,$dirs,$file) = File::Spec->splitpath( $o );
    return 0 unless $dirs;
    if (-f $o) {
        @sd = File::Spec->splitdir(File::Spec->catdir($volume, $dirs));
        #print join("#",@sd),"\n";
    } elsif (-d $o) {
        @sd = File::Spec->splitdir($o);
    } else {
        return 1; # undefined object - skipped!
    }
    for (@sd) {
        push @t, $_;
        if (File::Spec->catdir(@t) eq $d) {
            $ret = 1;
            last;
        }
    }
    return $ret;
}

1;
