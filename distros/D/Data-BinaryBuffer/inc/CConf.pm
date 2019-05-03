package inc::CConf;
use strict;
use warnings;
use ExtUtils::CBuilder;
use File::Spec ();

sub new {
    my $class = shift;
    my %args = @_;

    my $cbuilder = ExtUtils::CBuilder->new(quiet=>1);

    my $self = bless {
        cbuilder => $cbuilder,

        defs => {},
        header_search_paths => [],
        ccflags => [],
        ldflags => [],
        libs => [],
    }, $class;

    return $self;
}

sub makemaker_args {
    my $self = shift;
    my %args;
    if (@{$self->{ccflags}}) {
        $args{CCFLAGS} = join(' ',@{$self->{ccflags}});
    }
    if (@{$self->{libs}}) {
        $args{LIBS} = [join(' ',map { "-l$_" } @{$self->{libs}})];
    }
    if (@{$self->{ldflags}}) {
        $args{dynamic_lib}{OTHERLDFLAGS} = join(' ',@{$self->{ldflags}});
    }
    if (@{$self->{header_search_paths}}) {
        $args{INC} = join(' ',map { "-I$_" } @{$self->{header_search_paths}});
    }
    return (%args);
}

sub merge_args {
    my $self = shift;
    my %args = @_;
    $self->{ccflags} = [@{$self->{ccflags}}, @{$args{ccflags}}] if @{$args{ccflags}||[]};
    $self->{ldflags} = [@{$self->{ldflags}}, @{$args{ldflags}}] if @{$args{ldflags}||[]};
    $self->{libs} = [@{$self->{libs}}, @{$args{libs}}] if @{$args{libs}||[]};
    if ($args{defs}) {
        $self->{defs}{$_} = $args{defs}{$_} foreach keys %{$args{defs}};
    }
    return;
}

sub cbuilder_compile_args {
    my $self = shift;
    my %args = @_;
    return (
        source => $args{source},
        extra_compiler_flags => [@{$self->{ccflags}},@{$args{ccflags}||[]}],
    );
}

sub cbuilder_linker_args {
    my $self = shift;
    my %args = @_;
    return (
        objects => $args{objects},
        extra_linker_flags => [@{$self->{ldflags}},@{$args{ldflags}||[]},map { "-l$_" } (@{$self->{libs}},@{$args{libs}||[]})],
    );
}

sub try_build {
    my $self = shift;
    my %args = @_;

    my $on_error = $args{on_error};
    my $try_list = $args{try} || [{}];

    my $test_file = "cconftest.c";

    foreach my $try_args (@$try_list) {
        my $code = $args{code} || $try_args->{code};
        die "try_build: code argument required" unless $code;

        open my $fh, ">", $test_file or die("Can't write $test_file: $!");
        print $fh $code;
        close $fh;
        
        my %compile_args = $self->cbuilder_compile_args(source => $test_file, %$try_args);
        my $obj = eval { $self->{cbuilder}->compile(%compile_args) };
        unless ($obj) {
            unlink $test_file;
            next;
        }

        my %link_args = $self->cbuilder_linker_args(objects => $obj, %$try_args);
        my $exe = eval { $self->{cbuilder}->link_executable(%link_args); };
        unless ($exe) {
            unlink $test_file;
            unlink $obj;
            next;
        }
        my $exe_path = File::Spec->catfile(File::Spec->curdir, $exe);
        unless (system($exe_path) == 0) {
            unlink $test_file;
            unlink $obj;
            unlink $exe;
            next;
        }

        unlink $test_file;
        unlink $obj;
        unlink $exe;
        $self->merge_args(%$try_args);
        return 1;
    }

    $on_error->() if $on_error;
    return;
}

sub need_cplusplus {
    my $self = shift;

    my $code = <<'ENDCODE';
#include <vector>

class SomeClass {
public:
    int test() { return 0; }
};

int main() {
    std::vector<int> c(10);
    c[0] = 1;
    return c[0] - 1;
}
ENDCODE

    $self->try_build(
        on_error => sub { die "Can't build C++ program on this platform" },
        try => [
            {ccflags=>['-xc++'],ldflags=>['-lc++']},
            {ccflags=>['-xc++'],ldflags=>['-lstdc++']},
            {ccflags=>['-TP','-EHsc'],ldflags=>['msvcprt.lib']}
        ],
        code => $code
    );
}

sub add_header_search_path {
    my $self = shift;
    my $path = shift;

    push @{$self->{header_search_paths}}, $path;
}

1;
