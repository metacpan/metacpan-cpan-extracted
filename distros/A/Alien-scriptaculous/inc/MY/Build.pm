package MY::Build;

use strict;
use warnings;
use base qw(Module::Build);

sub ACTION_code {
    my $self = shift;
    $self->SUPER::ACTION_code;
    $self->fetch_scriptaculous();
    $self->install_scriptaculous();
}

sub scriptaculous_archive {
    return 'scriptaculous-js-1.8.0.tar.gz';
}

sub scriptaculous_dir {
    return 'scriptaculous-js-1.8.0';
}

sub scriptaculous_target_dir {
    return 'blib/lib/Alien/scriptaculous/';
}

sub scriptaculous_url {
    my $self = shift;
    return 'http://script.aculo.us/dist/' . $self->scriptaculous_archive();
}

sub fetch_scriptaculous {
    my $self = shift;
    return if (-f $self->scriptaculous_archive());

    require File::Fetch;
    print "Fetching script.aculo.us...\n";
    my $path = File::Fetch->new( 'uri' => $self->scriptaculous_url )->fetch();
    die "Unable to fetch archive" unless $path;
}

sub install_scriptaculous {
    my $self = shift;
    return if (-d $self->scriptaculous_target_dir());

    require Archive::Tar;
    print "Installing script.aculo.us...\n";
    my $tar   = Archive::Tar->new( $self->scriptaculous_archive(), 1 );
    my $src   = $self->scriptaculous_dir();
    my $dst   = $self->scriptaculous_target_dir();
    foreach my $file ($tar->list_files()) {
        my $filedst = $file;
        $filedst =~ s{$src}{$dst};
        $tar->extract_file( $file, $filedst );
    }
}

1;
