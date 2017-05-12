package Module::Install::PRIVATE::Crypt::GpgME;

use strict;
use warnings;
use Module::Install::Base;

use vars qw{$VERSION @ISA};
BEGIN {
    $VERSION = '0.01';
    @ISA     = qw{Module::Install::Base};
}

sub gpgme {
    my ($self) = @_;

    $self->requires_external_cc;

    my $config_exe = $self->find_config_exe;

    my %gpgme_config = $self->get_config($config_exe);
    printf "*** Found GpgME with api version %s\n", $gpgme_config{'api-version'};

    $self->check_api_version($gpgme_config{ 'api-version' });

    $self->makemaker_args(INC     => '-Iperl_glue'          );
    $self->makemaker_args(LIBS    => $gpgme_config{ libs   });
    $self->makemaker_args(CCFLAGS => $gpgme_config{ cflags }
        . sprintf(' -Wall -DGPGME_API_VERSION="%s"', $gpgme_config{'api-version'}) );

    $self->xs_files;
}

sub find_config_exe {
    my ($self) = @_;

    if (defined $ENV{GPGME_CONFIG}) {
        return $ENV{GPGME_CONFIG};
    }

    return 'gpgme-config';
}

sub get_config {
    my ($self, $exe) = @_;

    my %config = map {
        ($_ => $self->run_gpgme_config($exe, $_))
    } qw/prefix exec-prefix api-version libs cflags/;

    return %config;
}

sub run_gpgme_config {
    my ($self, $exe, $key) = @_;

    my $out = `$exe --$key`;
    chomp $out;

    return $out;
}

sub check_api_version {
    my ($self, $version) = @_;

    if (!defined $version) {
        die "*** Could not find gpgme api version.\n"
    }

    if ($version ne '1') {
        die <<EOM;
*** Your gpgme api version is incompatible to this module.
    Please inform the author.
EOM
    }
}

sub xs_files {
    my ($self) = @_;

    my @clean;
    my @OBJECT;
    my %XS;

    for my $xs (<xs/*.xs>) {
        (my $c = $xs) =~ s/\.xs$/\.c/i;
        (my $o = $xs) =~ s/\.xs$/\$(OBJ_EXT)/i;

        $XS{$xs} = $c;
        push @OBJECT, $o;
        push @clean, $o;
    }

    for my $c (<perl_glue/*.c>) {
        (my $o = $c) =~ s/\.c/\$(OBJ_EXT)/i;

        push @OBJECT, $o;
        push @clean, $o;
    }

    $self->makemaker_args(clean  => { FILES => join (q/ /, @clean) } );
    $self->makemaker_args(OBJECT => join (q/ /, @OBJECT)             );
    $self->makemaker_args(XS     => \%XS                             );

}

package MY;

use strict;
use warnings;
use Config;

sub const_cccmd {
    my $inherited = shift->SUPER::const_cccmd(@_);
    return '' unless $inherited;

    if ($Config{cc} eq 'cl') {
        warn 'you are using MSVC... my condolences.';
        $inherited .= ' /Fo$@';
    }
    else {
        $inherited .= ' -o $@';
    }

    return $inherited;
}

1;
