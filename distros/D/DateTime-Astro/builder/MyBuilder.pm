package builder::MyBuilder;
use strict;
use warnings;
use base 'Module::Build::XSUtil';

sub new {
    my ($class, %args) = @_;

    my (@libs, @includes);

    print "Probing for mpfr and gmp libraries and header files...\n";
    for my $env (grep { exists $ENV{$_} } qw(GMP_HOME MPFR_HOME)) {
        push @includes, File::Spec->catdir($ENV{$env}, "include");
        push @libs,     File::Spec->catdir($ENV{$env}, "lib");
    }

    if (@includes) {
        $ENV{MPFR_INCLUDES} ||= join " ", @includes;
    }
    if (@libs) {
        $ENV{MPFR_LIBS}     ||= join " ", map { "-L$_" } @libs;
    }

    if (! @includes) {
        print "No include directories detected\n";
    }
    if (! @libs) {
        print "No link directories detected\n";
    }

    print "Detected the following MPFR settings:\n";

    foreach my $env (qw(MPFR_HOME MPFR_INCLUDES MPFR_LIBS)) {
        printf " + %s = %s\n", $env, exists $ENV{$env} ? $ENV{$env} : "(null)";
    }

    $class->SUPER::new(
        %args,
        extra_linker_flags  => [ (map { "-L$_" } @libs), "-lmpfr", "-lgmp" ],
        generate_ppport_h   => 'xs/ppport.h',
        generate_xshelper_h => 'xs/xshelper.h',
        include_dirs        => [@includes, 'xs'],
    );
}

sub ACTION_test {
    my $self = shift;
    if ($self->pureperl_only) {
        $ENV{PERL_DATETIME_ASTRO_BACKEND} = 'PP';
    }
    $self->SUPER::ACTION_test(@_);
}

1;
