#!/usr/bin/perl
use strict;
use warnings;
use File::Spec;
use File::Path qw(make_path);
use File::Copy qw(move);

sub migrate_5_21_0 {
    my %args = @_;
    my $target_dir = $args{target_dir} or die "Missing target_dir\n";

    my $scheme_dir = File::Spec->catdir($target_dir, 'scheme');
    my $schema_dir = File::Spec->catdir($target_dir, 'schema');

    if (-d $scheme_dir) {
        if (!-d $schema_dir) {
            if (rename($scheme_dir, $schema_dir)) {
                print "  [v5.21.0] Renamed '$scheme_dir' -> '$schema_dir'\n";
                return { ok => 1, action => 'renamed', from => $scheme_dir, to => $schema_dir };
            }
            else {
                make_path($schema_dir);
                opendir(my $dh, $scheme_dir) or die "Cannot open $scheme_dir: $!";
                my $moved = 0;
                while (my $f = readdir($dh)) {
                    next if $f eq '.' || $f eq '..';
                    move(File::Spec->catfile($scheme_dir, $f), File::Spec->catfile($schema_dir, $f));
                    $moved++;
                }
                closedir($dh);
                rmdir($scheme_dir);
                print "  [v5.21.0] Moved $moved files from '$scheme_dir' -> '$schema_dir'\n";
                return { ok => 1, action => 'moved', count => $moved };
            }
        }
        else {
            opendir(my $dh, $scheme_dir) or die "Cannot open $scheme_dir: $!";
            my $moved = 0;
            while (my $f = readdir($dh)) {
                next if $f eq '.' || $f eq '..';
                my $src = File::Spec->catfile($scheme_dir, $f);
                my $dst = File::Spec->catfile($schema_dir, $f);
                if (!-e $dst) {
                    move($src, $dst);
                    $moved++;
                }
            }
            closedir($dh);
            rmdir($scheme_dir);
            print "  [v5.21.0] Merged $moved files from '$scheme_dir' into '$schema_dir'\n";
            return { ok => 1, action => 'merged', count => $moved };
        }
    }
    else {
        make_path($schema_dir) unless -d $schema_dir;
        print "  [v5.21.0] Verified schema directory '$schema_dir'\n";
        return { ok => 1, action => 'verified' };
    }
}

if (!caller) {
    use Getopt::Long;
    my $dbase_dir = '';
    GetOptions('dbase_dir=s' => \$dbase_dir);
    $dbase_dir ||= $ARGV[0] || '.';
    migrate_5_21_0(target_dir => $dbase_dir);
}

1;
