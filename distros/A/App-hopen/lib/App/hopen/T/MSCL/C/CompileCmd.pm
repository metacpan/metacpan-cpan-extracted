# App::hopen::T::MSCL::C::CompileCmd - compile C source using the GNU toolset
package App::hopen::T::MSCL::C::CompileCmd;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

use parent 'App::hopen::G::OutputPerFileCmd';
use Class::Tiny qw(compiler);

use App::hopen::Asset;
use App::hopen::BuildSystemGlobals;   # For $DestDir.
    # TODO make the dirs available to nodes through the context.
use App::hopen::Util::BasedPath;
use Data::Hopen qw(getparameters);
use Data::Hopen::Util::Filename;
use Path::Class;

my $_FN = Data::Hopen::Util::Filename->new;     # for brevity

# Docs {{{1

=head1 NAME

App::hopen::T::MSCL::C::CompileCmd - compile C source using the GNU toolset

=head1 SYNOPSIS

In a hopen file:

    my $cmd = App::hopen::T::MSCL::C::CompileCmd->new(
        compiler => '/usr/bin/gcc',
        name => 'compilation command'   # optional
    );

The inputs come from earlier in the build graph.
TODO support specifying compiler arguments.

=head1 ATTRIBUTES

=head2 compiler

The compiler to use.  TODO is this a full path or just a name?

=head1 MEMBER FUNCTIONS

=cut

# }}}1

=head2 _process_input

Create the compile command line for a given asset.

=cut

sub _process_input {
    my ($self, %args) = getparameters('self', [qw(asset phase visitor ; *)], @_);
    my $src = $args{asset};

    die "Cannot compile non-file $src" unless $src->isdisk;

    my $to = based_path(path => file($_FN->obj($src->target->path)),
                        base => $DestDir);
    my $how = '"' . $self->compiler . '" /c "#first" "/Fo#out"';
        # TODO? escape quotes in #first and #out?
        # => No, instead permit the asset node to carry the compiler ID
        #    in its scope, so that the generator can quote appropriately
        #    for the platform.

        # TODO better: T::MSCL::C should put the compiler name in the
        # global Scope of the DAG.  Then this node can set how to, e.g.,
        # '#compiler /c #first /Fo#out', and let the generator escape
        # appropriately for the platform.  If a particular node needs a
        # different compiler, that compiler can be added to the Scope of
        # that particular node to override what the generator sees.

    my $obj = App::hopen::Asset->new(
        target => $to,
        made_by => $self,
    );

    return [$obj, $how];
} #_process_input()

=head2 _should_act

Returns truthy if L</_process_input> should be called.

=cut

sub _should_act {
    my ($self, %args) = getparameters('self', [qw(phase visitor ; *)], @_);
    return ($args{phase} eq 'Gen');
} #_should_act()

1;
__END__
# vi: set fdm=marker: #
