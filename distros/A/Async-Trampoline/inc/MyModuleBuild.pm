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

sub _construct {
    my ($class, @args) = @_;

    if ($ENV{AUTOMATED_TESTING}) {
        for my $var (qw( CXXFLAGS PERL_MB_OPT )) {
            if (exists $ENV{$var}) {
                warn sprintf "env %s=%s\n", $var, $ENV{$var} // q();
            }
            else {
                warn "env $var not set\n";
            }
        }
    }

    return $class->SUPER::_construct(@args);
}

sub __MyModuleBuild_CBuilder_patched_compile {
    my ($orig, $self, %args) = @_;
    my $source = $args{source};
    $args{'C++'} //= ($source =~ /\.(?:cpp|cxx|c\+\+)$/);
    return $self->$orig(%args);
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
