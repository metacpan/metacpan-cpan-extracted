package CPAN::Tarball::Patch;

use 5.006;
use strict;
use warnings;

use Archive::Tar;
use File::Basename;
use Cwd;
use File::Find;

=head1 NAME

CPAN::Tarball::Patch - Patch a CPAN tarball, via CPAN::Distroprefs mechanism

=head1 VERSION

Version 0.020000

=cut

our $VERSION = '0.020000';


=head1 SYNOPSIS

Patching a tarball using C<CPAN::Distroprefs>

    use CPAN::Tarball::Patch;

    my $patcher = CPAN::Tarball::Patch->new("$ENV{"HOME"}/.local/share/.cpan/prefs/", "$ENV{"HOME"}/.local/share/.cpan/patches/");

    $patcher->patch("CONTRA/Acme-LSD-0.04.tar.gz");
    # The argument format is NOT flexible since it would be used for matching by CPAN::Distroprefs
    # In other words, it should be: AUTHOR/tarball.tar.gz
    
As of today, this module internal functioning and API is not fixed, do not use it yet (or at your risks).

=cut

sub new {
    my $class = shift;
    my $prefs_dir = shift;
    my $patches_dir = shift;

    defined $prefs_dir or die "Need to pass prefs_dir parameter";
    defined $patches_dir or die "Need to pass patches_dir parameter";

    my $self = bless {}, $class;
    $self->{prefs_dir} = $prefs_dir;
    $self->{patches_dir} = $patches_dir;
    $self->{start_dir} = getcwd;

    return $self;
}

sub patches {
    my $self = shift;
    my $distribution = shift;

    defined $distribution or die "Need to pass distribution parameter";

    my $prefs_folder = $self->{prefs_dir};
    my $patches_folder = $self->{patches_dir};

    use CPAN::Distroprefs;
    use YAML;

    my %arg = (
        distribution => $distribution,
    );

    my %ext = ( yml => 'YAML' );
    my $finder = CPAN::Distroprefs->find($prefs_folder, \%ext);
    my @patches = ();
    while (my $result = $finder->next) {
        die $result->as_string if $result->is_fatal;
        warn($result->as_string), next if $result->is_warning;
        for my $pref (@{ $result->prefs }) {
            if ($pref->matches(\%arg)) {
                foreach my $patch ($pref->data->{patches}->@*) {
                    push @patches, $patch;
                }
            }
        }
    }

    return map  { File::Spec->catfile($self->{patches_dir}, $_) } @patches;
}

sub untar {
    my $self = shift;
    my $tarball = shift;
    defined $tarball or die "Need to pass tarball parameter";

    my $dir  = dirname($tarball);
    my $tar = Archive::Tar->new($tarball, 1);

    chdir($dir);
    $tar->extract();
    my $filename = basename($tarball);
    $filename =~ s/\.tar\.gz$//;
    chdir($filename);
}

sub tar {
    my $self = shift;
    my $tarball = shift;
    defined $tarball or die "Need to pass tarball parameter";

    my $dir = basename(getcwd());
    chdir(File::Spec->updir);

    my $tarfile = basename($tarball);

    my $tar = Archive::Tar->new;
    my @files;

    find(
        sub {
            push @files, $File::Find::name;
        },
    $dir
    );
    $tar->add_files(@files);

    $tar->write($tarfile, 1);
}

sub patch {
    my $self = shift;
    my $tarball = shift;
    defined $tarball or die "Need to pass tarball parameter";


    my @patches = $self->patches($tarball);
    if (scalar @patches > 0) {
	$self->untar($tarball);
        for my $patch (@patches) {
	    next if ! -f $patch;
            print 'patching ', $tarball, ' with ', $patch, "\n";
            system('cat ' . $patch . ' | patch --quiet --force -p1') and die 'failed';
            $self->tar($tarball);
            chdir(File::Spec->updir);
        }
    } else {
        print "Nothing to patch\n";
    }

}

1; # End of CPAN::Tarball::Patch
