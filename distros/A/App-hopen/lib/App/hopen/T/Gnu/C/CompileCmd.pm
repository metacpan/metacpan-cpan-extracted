# App::hopen::T::Gnu::C::CompileCmd - compile C source using the GNU toolset
# TODO RESUME HERE - put .o files in the dest dir
package App::hopen::T::Gnu::C::CompileCmd;
use Data::Hopen;
use Data::Hopen::Base;

our $VERSION = '0.000010';

use parent 'App::hopen::G::Cmd';
use Class::Tiny qw(compiler);

use App::hopen::BuildSystemGlobals;   # For $DestDir.
    # TODO make the dirs available to nodes through the context.
use App::hopen::Util::BasedPath;
use Config;
use Data::Hopen qw(getparameters);
use Data::Hopen::G::GraphBuilder;
#use Data::Hopen::Util::Data qw(forward_opts);
use Data::Hopen::Util::Filename;
use Deep::Hash::Utils qw(deepvalue);
use File::Which ();
use Path::Class;

my $_FN = Data::Hopen::Util::Filename->new;     # for brevity

# Docs {{{1

=head1 NAME

App::hopen::T::Gnu::C::CompileCmd - compile C source using the GNU toolset

=head1 SYNOPSIS

In a hopen file:

    my $cmd = App::hopen::T::Gnu::C::CompileCmd->new(
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

=head2 _run

Create the compile command line.

=cut

sub _run {
    my ($self, %args) = getparameters('self', [qw(phase visitor ; *)], @_);

    # Currently we only do things at gen time.
    return $self->passthrough(-nocontext=>1) if $args{phase} ne 'Gen';

    # Pull the inputs
    my $lrSourceFiles = $self->input_assets;
    hlog { 'found source files', Dumper($lrSourceFiles) } 2;

    my @objFiles;
    foreach my $src (@$lrSourceFiles) {
        die "Cannot compile non-file $src" unless $src->isdisk;

        my $to = based_path(path => file($_FN->obj($src->target->path)),
                            base => $DestDir);
        my $how = $self->compiler . " -c #first -o #out";
        my $obj = App::hopen::Asset->new(
            target => $to,
            made_by => $self,
        );
        push @objFiles, $obj;

        $args{visitor}->asset($obj, -how => $how);
        $args{visitor}->connect($src, $obj);
    }
    $self->make(\@objFiles);
    return {};
} #_run()

1;
__END__
# vi: set fdm=marker: #
