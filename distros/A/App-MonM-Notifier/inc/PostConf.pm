package PostConf; # $Id: SkelModule.pm 200 2017-05-01 08:51:48Z minus $
use strict;

=head1 NAME

PostConf - Configuration your modules on phase Postamble.

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

    perl -Iinc -MPostConf -e configure -- PROJECTNAME

    perl -Iinc -MPostConf -e install -- PROJECTNAME

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY!>

Configuration your modules on phase Postamble.

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) http://www.serzik.com <minus@mail333.com>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

use base qw/Exporter/;
our @EXPORT = qw/configure install/;

use vars qw/$VERSION/;
$VERSION = '1.01';

use CTK qw/ say /;
use CTK::Util qw/ :BASE /;
use File::Copy qw/copy cp/;
use File::Find;
use Cwd;
my $basedir = getcwd();

sub configure {
    my $projectname = @ARGV ? shift @ARGV : '';
    croak "Project name is missing!" unless $projectname;

    my $c = new CTK( prefix=> lc($projectname), syspaths => 1 );
    my $confdir = $c->confdir();
    my $cfgfile = $c->cfgfile();
    my $datadir = $c->datadir();

    preparedir({
       confdir => $confdir,
       datadir => $datadir,
    });

    if ($cfgfile && !-e $cfgfile) {
        printf "Copying file %s --> %s... ", catfile('blib','conf',lc($projectname).'.conf'), $cfgfile;
        copy(catfile('blib','conf',lc($projectname).'.conf'), $cfgfile);
        print "Done.\n";
    }
    copy($cfgfile, $cfgfile.".default") if !-e $cfgfile.".default";

    # blib/conf -> /etc/PROJECTNAME/conf
    my $wdir = catdir('blib','conf','conf');
    chdir($wdir) or do {warn "Can't change directory: $!"; return};
    find({ wanted => sub {
        return if /^\.exists$/;
        if (-f $_) {
            my $src = catfile($wdir,$File::Find::dir, $_);
            my $dst = catfile($confdir, $File::Find::dir, $_);
            printf "Copying file %s --> %s... ", $src, $dst;
            if (-e $dst) {
                print "Skipped. File already exists\n";
                return;
            }
            cp($_, $dst) or warn "Can't create $dst: $!";
            print "Done.\n";
        } elsif (-d $_) {
            return if /^\.+$/;
            my $dst = catdir($confdir, $File::Find::dir, $_);
            my $perm = 0755 & 07777;
            print sprintf("Creating directory %s [%03o]... ", $dst, $perm);
            if (-e $dst) {
                print "Skipped. Directory already exists\n";
                return;
            }
            mkdir $dst or warn "Can't create $dst: $!";;
            eval { chmod $perm, $dst; };
            print "Done.\n";
        } else {
            say "Skipped: $_";
        }
    }}, ".");
    chdir($basedir) or warn "Can't change directory: $!";

    return 1;
}
sub install {
    my $projectname = @ARGV ? shift @ARGV : '';
    croak "Project name is missing!" unless $projectname;

    # blib/misc
    # Misc (for *nix only)
    if (isostype('Unix')) {
        say sprintf("Embedding %s...", $projectname);
        my $rootdir = rootdir();
        my $wdir = catdir('blib','misc');
        chdir($wdir) or do {warn "Can't change directory: $!"; return};
        find({ wanted => sub {
            return if /^\.exists$/;
            if (-f $_) {
                my $dir = catdir($rootdir, $File::Find::dir);
                my $src = catfile($wdir,$File::Find::dir, $_);
                my $dst = catfile($dir, $_);
                printf "Copying file %s --> %s... ", $src, $dst;
                unless (-e $dir) {
                    print "Skipped. Directory $dir not found\n";
                    return;
                }
                if (-e $dst) {
                    print "Skipped. File already exists\n";
                    return;
                }
                cp($_, $dst) or warn "Can't copy $dst: $!";
                print "Done.\n";
            } elsif (-d $_) {
                return if /^\.+$/;
                my $dst = catdir($rootdir, $File::Find::dir, $_);
                my $perm = 0755 & 07777;
                print sprintf("Creating directory %s [%03o]... ", $dst, $perm);
                if (-e $dst) {
                    print "Skipped. Directory already exists\n";
                    return;
                }
                mkdir $dst or warn "Can't create $dst: $!";
                eval { chmod $perm, $dst; };
                print "Done.\n";
            } else {
                say "Skipped: $_";
            }
        }}, ".");
        chdir($basedir) or warn "Can't change directory: $!";
    }

    return 1;
}

1;
__END__
