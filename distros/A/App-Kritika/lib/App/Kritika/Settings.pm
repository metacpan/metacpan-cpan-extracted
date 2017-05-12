package App::Kritika::Settings;

use strict;
use warnings;

use Cwd qw(getcwd);
use File::Basename qw(dirname);
use File::Spec;
use File::HomeDir ();

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{file} = $params{file};

    return $self;
}

sub settings {
    my $self = shift;

    my $rc_file = $self->_detect;
    die "Error: Can't find rc file\n" unless defined $rc_file;

    my $config = do { local $/; open my $fh, '<', $rc_file or die $!; <$fh> };

    my $settings = $self->_parse($config);

    if (!$settings->{root}) {
        $settings->{root} = dirname $rc_file;
    }

    return $settings;
}

sub _detect {
    my $self = shift;

    my $dirname = dirname($self->{file});

    if (!File::Spec->file_name_is_absolute($dirname)) {
        $dirname = File::Spec->catdir(getcwd(), $dirname);
    }

    my ($volume, $dirs, $file) = File::Spec->splitpath($dirname);
    $dirs = File::Spec->catdir($dirs, $file) if $file ne '';

    my @dir = File::Spec->splitdir($dirs);

    while (@dir) {
        my $location = File::Spec->catfile(@dir, '.kritikarc');

        return $location if -f $location;

        pop @dir;
    }

    my $location = File::Spec->catfile(File::HomeDir->my_home, '.kritikarc');
    return $location if -f $location;

    return;
}

sub _parse {
    my $self = shift;
    my ($input) = @_;

    my @lines = split /\r?\n/, $input;

    my $options = {};
    foreach my $line (@lines) {
        next if $line =~ m/^\s*#/;
        next if $line eq '';

        my ($key, $value) = split /=/, $line, 2;
        $key =~ s{^\s+}{};
        $key =~ s{\s+$}{};
        $value =~ s{^\s+}{};
        $value =~ s{\s+$}{};

        $options->{$key} = $value;
    }

    return $options;
}

1;
