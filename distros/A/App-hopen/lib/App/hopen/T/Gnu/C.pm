# App::hopen::T::Gnu::C - support GNU toolset, C language
package App::hopen::T::Gnu::C;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

use App::hopen::BuildSystemGlobals;   # For $DestDir.
    # TODO make the dirs available to nodes through the context.
use App::hopen::Util::BasedPath;

use App::hopen::T::Gnu::C::CompileCmd;
use App::hopen::T::Gnu::C::LinkCmd;

use Config;
use Data::Hopen qw(getparameters);
use Data::Hopen::G::GraphBuilder;
use Data::Hopen::Util::Data qw(forward_opts);
use Data::Hopen::Util::Filename;
use File::Which ();
use Path::Class;

my $FN = Data::Hopen::Util::Filename->new;     # for brevity
our $_CC;   # Cached compiler name

# Docs {{{1

=head1 NAME

App::hopen::T::Gnu::C - support for the GNU toolset, C language

=head1 SYNOPSIS

In a hopen file:

    use language 'C';

    # Use via Data::Hopen::G::GraphBuilder:
    $Build->H::files(...)->C::compile->default_goal;

The inputs come from earlier in the build graph.
TODO support specifying compiler arguments.

=cut

# }}}1

=head1 STATIC FUNCTIONS

Arguments to the static functions are parsed using L<Getargs::Mixed>
(via L<Data::Hopen/getparameters>).
Therefore, named arguments start with a hyphen (e.g., C<< -name=>'foo' >>,
not C<< name=>'foo' >>).

=head2 compile

Create a new compilation command.  Inputs come from the build graph,
so parameters other than C<-name> are disregarded (TODO permit specifying
compilation options or object-file names).  Usage:

    use language 'C';
    $builder_or_dag->H::files('file1.c')->C::compile([-name=>'node name']);

=cut

sub _find_compiler; # forward

sub compile {
    my ($builder, %args) = getparameters('self', [qw(; name)], @_);
    _find_compiler unless $_CC;
    my $node = App::hopen::T::Gnu::C::CompileCmd->new(
        compiler => $_CC,
        forward_opts(\%args, 'name')
    );

    hlog { __PACKAGE__, 'Built compile node', Dumper($node) } 2;

    return $node;   # The builder will automatically add it
} #compile()

make_GraphBuilder 'compile';

=head2 link

Create a new link command.  Pass the name of the
executable.  Object files are on the incoming asset-graph edges.  Usage:

    use language 'C';
    $builder_or_dag->C::link([-exe=>]'output_file_name'[, [-name=>]'node name']);

TODO? Permit specifying that you want C<ld> or another linker instead of
using the compiler?

=cut

sub link {
    my ($builder, %args) = getparameters('self', [qw(exe; name)], @_);
    _find_compiler unless $_CC;

    my $dest = based_path(path => file($FN->exe($args{exe})), base => $DestDir);

    my $node = App::hopen::T::Gnu::C::LinkCmd->new(
        linker => $_CC,
        dest => $dest,
        forward_opts(\%args, 'name')
    );
    hlog { __PACKAGE__, 'Built link node', Dumper($node) } 2;

    return $node;
} #link()

make_GraphBuilder 'link';

=head1 INTERNALS

=head2 _find_compiler

Find the C compiler.  Called when this package is first loaded.

TODO permit the user to specify an alternative compiler to use

TODO should this happen when the DAG runs?
Maybe toolsets should get the chance to add a node to the beginning of
the graph, before anything else runs.  TODO figure this out.

=cut

sub _find_compiler {
    foreach my $candidate ($Config{cc}, qw[cc gcc clang]) {      # TODO also c89 or xlc?
        my $path = File::Which::which($candidate);
        next unless defined $path;

        hlog { __PACKAGE__, 'using C compiler', $path };    # Got it
        $_CC = $path;
        last;
    }

    croak "Could not find a C compiler" unless $_CC;
} #_find_compiler()

BEGIN { _find_compiler if eval '$App::hopen::RUNNING'; }

1;
__END__
# vi: set fdm=marker: #
