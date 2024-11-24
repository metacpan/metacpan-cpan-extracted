# App::hopen::T::MSCL::C::LinkCmd - link object files using the GNU toolset
package App::hopen::T::MSCL::C::LinkCmd;
use Data::Hopen;
use strict; use warnings;
use Data::Hopen::Base;

our $VERSION = '0.000015'; # TRIAL

use parent 'App::hopen::G::Cmd';
use Class::Tiny qw(dest linker);

use App::hopen::BuildSystemGlobals;   # For $DestDir.
    # TODO make the dirs available to nodes through the context.
use App::hopen::Util::BasedPath;
use Data::Hopen qw(getparameters);
use Data::Hopen::Util::Filename;
use Path::Class;

# Docs {{{1

=head1 NAME

App::hopen::T::MSCL::C::LinkCmd - link object files using the GNU toolset

=head1 SYNOPSIS

In a hopen file:

    my $cmd = App::hopen::T::MSCL::C::LinkCmd->new(
        linker => 'gcc',
        dest => 'foo.exe',
        name => 'some linker node',     # optional
    );

The inputs come from earlier in the build graph.
TODO support specifying linker arguments.

=head1 ATTRIBUTES

=head2 linker

The linker to use.  TODO is this a full path or just a name?

=head2 dest

The destination file to produce, as an L<App::hopen::Util::BasedPath> instance.
TODO? accept string or L<Path::Class::File> instance?

=head1 MEMBER FUNCTIONS

=cut

# }}}1

=head2 _run

Create the link command line.

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(phase visitor ; *)], @_);

    # Currently we only do things at gen time.
    return $self->passthrough(-nocontext=>1) if $args{phase} ne 'Gen';

    # Pull the inputs
    my $lrObjFiles = $self->input_assets;
    hlog { 'found object files', Dumper($lrObjFiles) } 2;

    my $exe = App::hopen::Asset->new(
        target => $self->dest,
        made_by => $self,
    );
    $args{visitor}->asset($exe,
        -how => '"' . $self->linker . '" "/Fe#out" #all',
            # TODO permit escaping #out and #all - see comments in
            # App::hopen::T::MSCL::C::CompileCmd.
    );      # TODO refactor out common code with T::Gnu::C::LinkCmd

    foreach my $obj (@$lrObjFiles) {
        die "Cannot link non-file $obj" unless $obj->isdisk;
        $args{visitor}->connect($obj, $exe);
    }

    $self->make($exe);
    return {};
} #_run()

1;
__END__
# vi: set fdm=marker: #
