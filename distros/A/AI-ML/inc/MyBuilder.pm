package MyBuilder;
use base 'Module::Build';

use warnings;
use strict;

use Config;
use ExtUtils::ParseXS;
use ExtUtils::Mkbootstrap;

use Path::Tiny;

my $EXTRA_O_FLAGS = "";
my $EXTRA_FLAGS = "-lblas -llapack";

sub ACTION_code {
    my $self = shift;

    $EXTRA_O_FLAGS .= " -DUSE_REAL" unless exists $self->args->{'with-float'};

    $self->update_XS("XS/ML.xs.inc");

    $self->dispatch("create_objects");
    $self->dispatch("compile_xs");

    $self->SUPER::ACTION_code;
}

sub update_XS {
    my ($self, $file) = @_;
    my $output = $file;
    $output =~ s/\.inc$//;

    open my $i_fh, "<", $file   or die "$!";
    open my $o_fh, ">", $output or die "$!";
    while (<$i_fh>) {
        s/REAL/float/g;
        print {$o_fh} $_;
    }
    close $o_fh;
    close $i_fh;
}

sub ACTION_create_objects {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $c_progs = $self->rscan_dir("C", qr/\.c$/);
    for my $file (@$c_progs) {
        my $object = $file;
        $object =~ s/\.c$/.o/;
        next if $self->up_to_date($file, $object);
        $cbuilder->compile(
            object_file => $object,
            extra_compiler_flags => $EXTRA_O_FLAGS,
            source => $file,
            include_dirs => ["."]
        );
    }
}

sub ACTION_compile_xs {
    my $self = shift;
    my $cbuilder = $self->cbuilder;

    my $archdir = path($self->blib, "arch", "auto", "AI", "ML");
    $archdir->mkpath unless -d $archdir;

    my $xs = path("XS", "ML.xs");
    my $xs_c = path("XS", "ML.c");

    if (!$self->up_to_date($xs, $xs_c)) {
        ExtUtils::ParseXS::process_file(
            filename => $xs->stringify, 
            prototypes => 0,
            output => $xs_c->stringify
        );
    }

    my $xs_o = path("XS", "ML.o");
    if (!$self->up_to_date($xs_c, $xs_o)) {
        $cbuilder->compile(
            source => $xs_c,
            extra_compiler_flags => $EXTRA_O_FLAGS,
            include_dirs => ["."], 
            object_file => $xs_o
        );
    }
    my $bs_file = path( $archdir, "ML.bs");
    if (!$self->up_to_date($xs_o, $bs_file) ) {
        ExtUtils::Mkbootstrap::Mkbootstrap($bs_file);
        if (!-f $bs_file) {
            $bs_file->touch;
        }
    }

    my $objects = $self->rscan_dir("C", qr/\.o$/);
    push @$objects, $xs_o;
    my $lib_file = path($archdir, "ML.$Config{dlext}");
    if (!$self->up_to_date( $objects, $lib_file )) {
        $cbuilder->link(
            module_name => 'AI::ML',
            extra_linker_flags => $EXTRA_FLAGS,
            objects => $objects,
            lib_file => $lib_file,
        );
    }
}

1;
