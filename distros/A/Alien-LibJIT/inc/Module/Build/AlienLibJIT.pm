package Module::Build::AlienLibJIT;

use warnings;
use strict;

use parent 'Module::Build';

use FindBin('$Bin');
use File::Spec;
use File::Basename ();
use Config;

our $LIBJIT_HOME = 'libjit';
our $LIBJIT_M4 = 'm4';
our $LIBJIT_INCLUDE = File::Spec->catfile($LIBJIT_HOME, 'include');
our $LIBJIT_RESULT = File::Spec->catfile($LIBJIT_HOME, 'jit', '.libs', 'libjit'.$Config::Config{lib_ext});

sub new {
    my ($class, @args) = @_;

    return $class->SUPER::new(
        #include_dirs       => [$LIBJIT_INCLUDE],
        #extra_linker_flags => [$LIBJIT_RESULT, '-lpthread'],
        @args,
    );
}

sub ACTION_code {
    my ($self) = @_;

    $self->depends_on('libjit');

    return $self->SUPER::ACTION_code(@_);
}

sub ACTION_depcheck {
    my ($self) = @_;
    foreach my $cmd (qw/autoreconf libtool flex bison/) {
        $self->log_info("Checking if '$cmd' is available\n");
        system("$cmd --help > /dev/null 2>&1")
            and die "You need to make sure you have a recent '$cmd' installed and " .
                'that it can be found in your PATH';
    }
    return 1;
}

sub build_libjit {
    my ($self) = @_;

    if (-f $LIBJIT_RESULT) {
        $self->log_info("libjit already built\n");
        return 1;
    }

    $self->depends_on('depcheck');

    my $orig = Cwd::cwd();

    eval {
        $self->log_info("Changing directories to build libjit\n");
        chdir($LIBJIT_HOME) or die "Failed to cd into '$LIBJIT_HOME'";

        $self->log_info("Creating '$LIBJIT_M4' directory for autoreconf\n");
        -d $LIBJIT_M4 or mkdir($LIBJIT_M4) or die "Failed to mkdir '$LIBJIT_M4'";

        $self->log_info("Running autoreconf\n");
        system('autoreconf', '-i', '-f')
            and die "Failed to run autoreconf";

        $self->log_info("Running ./configure\n");
        #system('./configure', '-enable-shared=false')
        $ENV{CFLAGS} .= " -fPIC";
        system('./configure')
            and die "Failed to configure libjit!";

        $self->log_info("Running make\n");
        system('make') and die "Failed to build libjit!";

        $self->log_info("Returning to our original directory\n");
        1;
    } or do {
        my $err = $@ || 'Zombie error';
        chdir($orig);
        die $err; # rethrow
    };
    chdir($orig);

    if (-f $LIBJIT_RESULT) {
        $self->log_info("Built libjit successfully\n");
    }
    else {
        die "We built libjit, but the lib isn't where I wanted it: $LIBJIT_RESULT";
    }
}

sub ACTION_libjit {
    my ($self) = @_;

    $self->build_libjit();

    # pm_to_blib equivalent for headers and static library
    my $libjit_files = $self->find_libjit_h_files;

    $libjit_files->{$LIBJIT_RESULT} = File::Spec->catdir(
        qw(libjit lib),
        File::Basename::basename($LIBJIT_RESULT)
    );
    foreach my $from (keys %$libjit_files) {
        my $to = File::Spec->catdir(qw(blib arch auto Alien LibJIT), $libjit_files->{$from});
        $self->copy_if_modified(from => $from, to => $to);
    }

    return 1;
}

sub find_libjit_h_files {
    my ($self) = @_;
    $self->_find_file_by_type(
        'h',
        File::Spec->catdir($LIBJIT_HOME, 'include')
    );
}

1;
