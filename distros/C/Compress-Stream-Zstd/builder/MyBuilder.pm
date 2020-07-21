package builder::MyBuilder;
use 5.008_001;
use strict;
use warnings;
use parent 'Module::Build';

use Config;

my $LIBZSTD_DIR = 'ext/zstd/lib';

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(%args);
    if ($self->is_debug && !-d $LIBZSTD_DIR) {
        $self->do_system('git', 'submodule', 'update', '--init');
    }
    my @extra_compiler_flags = (qw/
        -Wall -Wextra -Wno-parentheses
        -Wno-unused -Wno-unused-parameter
    /, ('-I.', "-I$LIBZSTD_DIR"), ('-DZSTD_LEGACY_MULTITHREADED_API'));
    my $ld = $self->config('ld');
    if ($ld =~ s/^\s*env MACOSX_DEPLOYMENT_TARGET=[^\s]+ //) {
        $self->config(ld => $ld);
    }
    if ($self->is_debug) {
        $self->config(optimize => '-g -O0');
    }
    $self->extra_compiler_flags(@extra_compiler_flags);
    $self->extra_linker_flags('-pthread', "$LIBZSTD_DIR/libzstd.a");
    $self;
}

sub is_debug {
    -d '.git';
}

sub ACTION_build {
    my $self = shift;
    $self->ACTION_ppport_h() unless -e 'ppport.h';
    unless (-f "$LIBZSTD_DIR/libzstd.a") {
        local $ENV{CFLAGS} = '-DZSTD_MULTITHREAD -DZSTD_LEGACY_MULTITHREADED_API -O3 -fPIC';
        my $make = 'make';
        $make = 'gmake' if $^O =~ /bsd$/ && $^O !~ /gnukfreebsd$/;
        $self->do_system($make => '-C', $LIBZSTD_DIR, 'libzstd.a');
    }
    $self->SUPER::ACTION_build();
}

sub ACTION_ppport_h {
    require Devel::PPPort;
    Devel::PPPort::WriteFile('ppport.h');
}

1;
__END__
