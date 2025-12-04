package builder::MyBuilder;
use strict;
use warnings;
use base 'Module::Build::XSUtil';

use File::Spec::Functions qw(catfile catdir);
use File::Which qw(which);
use Config;

my $MSGPACK_VERSION = '3.3.0';

__PACKAGE__->add_property(_cmake => undef);

sub new {
    my ($class, %argv) = @_;

    my $cmake = which 'cmake';
    if (!$cmake) {
        die "Need 'cmake' command for building Data::MessagePack::Stream\n";
    }
    my $self = $class->SUPER::new(
        %argv,
        include_dirs => [catdir("msgpack-$MSGPACK_VERSION", 'include')],
        generate_ppport_h => catfile('lib', 'Data', 'MessagePack', 'ppport.h'),
        cc_warnings => 1,
    );
    $self->_cmake($cmake);
    $self;
}

sub _cmake_version {
    my $self = shift;
    my $version = `cmake --version`;
    if ($version =~ m/version\s+(\d+)\.(\d+)/) {
        return (int $1, int $2);
    }

    (-1, -1);
}

sub _build_msgpack {
    my $self = shift;

    my @opt = qw(
        -DMSGPACK_ENABLE_SHARED=OFF
        -DMSGPACK_ENABLE_CXX=OFF
        -DMSGPACK_BUILD_EXAMPLES=OFF
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON
    );

    my ($major_version, $minor_version) = $self->_cmake_version;
    if ($major_version >= 4 || ($major_version >= 3 && $minor_version >= 5)) {
        push @opt, "-DCMAKE_POLICY_VERSION_MINIMUM=3.5";
    }

    chdir "msgpack-$MSGPACK_VERSION";
    my $ok = $self->do_system($self->_cmake, @opt, ".");
    $ok &&= $self->do_system($Config{make});
    chdir "..";
    $ok;
}

sub ACTION_code {
    my ($self, @argv) = @_;

    my $spec = $self->_infer_xs_spec(catfile("lib", "Data", "MessagePack", "Stream.xs"));
    my $archive = catfile("msgpack-$MSGPACK_VERSION", "libmsgpackc.a");
    if (!$self->up_to_date($archive, $spec->{lib_file})) {
        $self->_build_msgpack or die;
        push @{$self->{properties}{objects}}, $archive; # XXX
    }

    $self->SUPER::ACTION_code(@argv);
}

1;
