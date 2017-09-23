package MyModuleBuild;
use strict;
use warnings;
use utf8;
use feature 'state';

use parent 'Module::Build';

use ExtUtils::CBuilder  0.280226;  # contains bug fix for C++ compiler detection

sub cbuilder {
    # patch CBuilder to infer C++ness of files
    state $require_once = do {
        require ExtUtils::CBuilder;
        my $orig = ExtUtils::CBuilder->can('compile');
        *ExtUtils::CBuilder::compile = sub {
            return __MyModuleBuild_CBuilder_patched_compile($orig, @_);
        };
    };
    my $cbuilder = shift->SUPER::cbuilder(@_);
    $cbuilder->have_cplusplus or die "C++ compiler required";
    return $cbuilder;
}

sub __MyModuleBuild_CBuilder_patched_compile {
    my ($orig, $self, %args) = @_;
    my $source = $args{source};
    $args{'C++'} //= ($source =~ /\.(?:cpp|cxx|c\+\+)$/);
    return $self->$orig(%args);
}

sub _construct {
    my ($class, %args) = @_;
    my $extra_config = delete $args{args}{config} // {};

    my $self = $class->SUPER::_construct(%args);

    if (my $cxxflags = delete $extra_config->{cxxflags}) {
        my $existing_flags =
                $class->config('cxxflags')
            ||  $class->config('cflags');
        $class->config(cxxflags => "$existing_flags $cxxflags");
    }

    $class->config($_ => $extra_config->{$_}) for sort keys %$extra_config;

    return $self;
}

sub _infer_xs_spec {
    my ($self, $file) = @_;
    my $spec = $self->SUPER::_infer_xs_spec($file);

    # The spec always infers a ".c" file.
    # Fix it: .xs -> .c, .xs++ -> .cpp
    $spec->{c_file} =~ s/\.c$/.cpp/ if $file =~ /\.xs\+\+$/;

    return $spec;
}

sub find_xs_files {
    shift->_find_file_by_type(qr/xs|xs\+\+/, 'lib');
}

1;
