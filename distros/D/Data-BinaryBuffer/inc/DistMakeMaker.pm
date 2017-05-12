package inc::DistMakeMaker;
use Moose;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
    my $self = shift;
    my $full_tmpl = super();
    my $configure_tmpl = $self->_configure_tmpl();

    $full_tmpl =~ s/(^WriteMakefile\(.+?\);\s*$)/$configure_tmpl\n$1/ms;
    return $full_tmpl;
};

sub _configure_tmpl {
    my $self = shift;
    my $tmpl = <<'TEMPLATE';
use Config ();
use Text::ParseWords 'shellwords';
use inc::CConf;

$WriteMakefileArgs{CONFIGURE} = sub {
    my %args;

    my $c = inc::CConf->new(config_file=>'binarybuffer-config.h');

    $c->need_cplusplus;
    $c->need_stl;

    my $test_sys_endian_h = <<"ENDCODE";
#include <sys/endian.h>
int main() { return 0; }
ENDCODE
    my $test_endian_h = <<"ENDCODE";
#include <endian.h>
int main() { return 0; }
ENDCODE

    $c->try_build(
        on_error => sub { die "Can't find hto* funtions on this platform" },
        try => [
            {
                code => $test_sys_endian_h,
                defs => { HAS_SYS_ENDIAN_H => 1 },
            },
            {
                code => $test_endian_h,
                defs => { HAS_ENDIAN_H => 1 },
            }
        ]
    );

    my $test_original_endian_macros = <<"ENDCODE";
#include "binarybuffer-config.h"
#if defined(HAS_ENDIAN_H)
    #include <endian.h>
#elif defined(HAS_SYS_ENDIAN_H)
    #include <sys/endian.h>
#endif
int main() {
    int val = betoh32(htobe32(0x11223344));
    return 0;
}
ENDCODE
    $c->try_build(
        on_error => sub { },
        try => [
            {
                code => $test_original_endian_macros,
                defs => { HAS_ORIGINAL_ENDIAN_MACROS => 1 },
            }
        ]
    );

    $c->generate_config_file;

    %args = $c->makemaker_args;

    $args{TYPEMAPS} = ['perlobject.map'];

    return \%args;
};
TEMPLATE
    return $tmpl;
}

__PACKAGE__->meta->make_immutable;
