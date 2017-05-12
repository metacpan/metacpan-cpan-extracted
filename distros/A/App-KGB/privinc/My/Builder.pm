package My::Builder;
use 5.010;
use strict;
use warnings;

use base qw(Module::Build);

sub ACTION_orig {
    my $self = shift;
    $self->ACTION_manifest();
    $self->ACTION_dist();
    my $dn       = $self->dist_name;
    my $ver      = $self->dist_version;
    my $pkg_name = 'kgb-bot';
    my $target_dist = "../$dn-$ver.tar.gz";
    my $target_orig = "../$pkg_name\_$ver.orig.tar.gz";

    rename "$dn-$ver.tar.gz", $target_orig or die $!;
    if ( -e $target_dist ) {
        unlink $target_dist or die "unlink($target_dist): $!\n";
    }
    link $target_orig, $target_dist or die "link failed: $!\n";

    $self->ACTION_distclean;
    unlink 'MANIFEST.bak';
    print "$target_orig ready.\n";
    print "with $target_dist linked to it.\n";
}

use Config;
use File::Spec;
use File::Copy;
use Pod::Man;

sub process_man_files {
    my $self = shift;

    for my $s ( 1 .. 9 ) {
        $self->install_path( "man$s", "/usr/share/man/man$s" )
            unless defined $self->install_path("man$s");

        my $dir = File::Spec->catdir( 'blib', "man$s" );
        my $files = $self->{"man${s}files"} // "man$s/*";
        $files = [$files] unless ref($files);
        ref($files) eq 'ARRAY' or die "man${s}files is not scalar/arayref";

        my $manner = Pod::Man->new( section => "${s}p" );
        my $man_ext = $Config{"man${s}ext"};
        unless ( defined($man_ext) ) {
            $man_ext = $Config{man1ext};
            $man_ext =~ s/1/$s/;
        }

        for my $pat (@$files) {
            for my $f ( glob($pat) ) {
                -d $dir or mkdir $dir;

                if ( $f =~ /\.(p|p$s)$/ ) {
                    copy( $pat, $dir );
                }
                elsif ( $f =~ /\.pod$/ ) {

                    my $manf = File::Spec->splitpath($f);
                    $manf =~ s/\.pod$/".$man_ext"/e;
                    $manner->parse_from_file( $f,
                        File::Spec->catfile( $dir, $manf ) );
                }
            }
        }
    }
}

1;

