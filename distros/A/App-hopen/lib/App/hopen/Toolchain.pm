# App::hopen::Toolchain - SUPERSEDED base class for hopen toolchains
package Data::Hopen::Toolchain;
use Data::Hopen;
use Data::Hopen::Base;

our $VERSION = '0.000010';

use Class::Tiny qw(proj_dir dest_dir), {
    architecture => '',
};

# Docs {{{1

=head1 NAME

Data::Hopen::Toolchain - SUPERSEDED base class for hopen toolchains

=head1 SYNOPSIS

TODO
    - change this to "Tool" instead of "Toolchain"
    - permit loading any number of tools
    - The Generator specifies a default list of tools rather than a
        single default toolchain.
    - add G::ToolOp to invoke tools.  A ToolOp will take a language
        and an opcode and invoke a corresponding Tool.  E.g., a GNU C
        Tool will generate command-line options for gcc-style command lines.
    - Only one Tool may be loaded for each (language, opcode) pair.
        Otherwise the build would be ambiguous.
    - In Conventions, define the formats for languages and opcodes.

Maybe TODO:
    - Each Generator must specify a list of Content-Types (media types)
        it can consume.  Each Tool must specify a specific content-type
        it produces.  Mismatches are an error unless overriden on the
        hopen command line.

The code that generates command lines to invoke specific toolchains lives under
C<Data::Hopen::Toolchain>.  Those modules must implement the interface defined
here.

=head1 ATTRIBUTES

=head2 proj_dir

A L<Path::Class::Dir> instance specifying the root directory of the project

=head2 dest_dir

A L<Path::Class::Dir> instance specifying where the generated output
should be written.

=head1 FUNCTIONS

A toolchain (C<Data::Hopen::Toolchain> subclass) is a Visitor.

TODO Figure out if the toolchain has access to L<Data::Hopen::G::Link>
instances.

=cut

# }}}1

=head2 visit_goal

Do whatever the toolchain wants to do with a L<Data::Hopen::G::Goal>.
By default, no-op.

=cut

sub visit_goal { }

=head2 visit_op

Do whatever the toolchain wants to do with a L<Data::Hopen::G::Op> that
is not a Goal (see L</visit_goal>).  By default, no-op.

=cut

sub visit_op { }

=head2 finalize

Do whatever the toolchain wants to do to finish up.

=cut

sub finalize { }

false;  # SUPERSEDED --- will be removed.
__END__
# vi: set fdm=marker: #
