# App::hopen::Gen - base class for hopen generators
package App::hopen::Gen;
use Data::Hopen qw(:default $QUIET);
use Data::Hopen::Base;

our $VERSION = '0.000010';

use parent 'Data::Hopen::Visitor';
use Class::Tiny qw(proj_dir dest_dir), {
    architecture => '',

    # private
    _assets => undef,   # A Data::Hopen::G::DAG of the assets
    _assetop_by_asset => sub { +{} },   # Indexed by refaddr($asset)
};

use App::hopen::BuildSystemGlobals;
use Data::Hopen::G::DAG;
use Data::Hopen::Util::Data qw(forward_opts);
use File::pushd qw(pushd);
use Path::Class ();
use Scalar::Util qw(refaddr);

# Docs {{{1

=head1 NAME

Data::Hopen::Gen - Base class for hopen generators

=head1 SYNOPSIS

The code that generates blueprints for specific build systems
lives under C<Data::Hopen::Gen>.  L<Data::Hopen::Phase::Gen> calls modules
under C<Data::Hopen::Gen> to create the blueprints.  Those modules must
implement the interface defined here.

=head1 ATTRIBUTES

=head2 proj_dir

(Required) A L<Path::Class::Dir> instance specifying the root directory of
the project.

=head2 dest_dir

(Required) A L<Path::Class::Dir> instance specifying where the generated output
(e.g., blueprint or other files) should be written.

=head2 _assets (Internal)

A L<Data::Hopen::G::DAG> of L<App::hopen::G::AssetOp> instances representing
the L<App::Hopen::Asset>s to be created when a build is run.

=head1 FUNCTIONS

A generator (C<Data::Hopen::Gen> subclass) is a Visitor plus some.

B<Note>:
The generator does not have access to L<Data::Hopen::G::Link> instances.
That lack of access is the primary distinction between Ops and Links.

=cut

# }}}1

=head2 asset

Called by an Op (L<App::hopen::G::Op> subclass) to add an asset
(L<App::hopen::G::AssetOp> instance) to the build.  Usage:

    $Generator->asset([-asset=>]$asset, [-from=>]$from[, [-how=>]$how]);

If C<$how> is specified, it will be saved in the C<AssetOp> for use later.
Later calls with the same asset and a defined C<$how> will overwrite the
C<how> value in the C<AssetOp>.  Specify 'UNDEF' as the C<$how> to
expressly undefine a C<how>.

Returns the C<AssetOp>.

=cut

sub asset {
    my ($self, %args) = getparameters('self', [qw(asset; how)], @_);
    hlog { 'Generator adding asset at',refaddr($args{asset}),$args{asset} } 3;

    my $existing_op = $self->_assetop_by_asset->{refaddr($args{asset})};

    # Update an existing op
    if(defined $existing_op) {
        if( ($args{how}//'') eq 'UNDEF') {
            $existing_op->how(undef);
        } elsif(defined $args{how}) {
            $existing_op->how($args{how});
        }
        return $existing_op;
    }

    # Create a new op
    my $class = $self->_assetop_class;
    eval "require $class";
    my $op = $class->new(name => 'Op:<<' . $args{asset}->target . '>>',
                            forward_opts(\%args, qw(asset how)));
    $self->_assetop_by_asset->{refaddr($args{asset})} = $op;
    $self->_assets->add($op);
    return $op;
} #asset()

=head2 connect

Add a dependency edge between two assets or goals.  Any assets must have already
been added using L</asset>.  Usage:

    $Generator->connect([-from=>]$from, [-to=>$to]);

TODO add missing assets automatically?

=cut

sub connect {
    my ($self, %args) = getparameters('self', [qw(from to)], @_);
    my %nodes;

    # Get the nodes if we were passed assets.
    foreach my $field (qw(from to)) {
        if(eval { $args{$field}->DOES('App::hopen::Asset') }) {
            $nodes{$field} = $self->_assetop_by_asset->{refaddr($args{$field})};
        } else {
            $nodes{$field} = $args{$field};
        }
    }

    # TODO better error messages
    croak "No From node for asset " . refaddr($args{from}) unless $nodes{from};
    croak "No To node for asset " . refaddr($args{to}) unless $nodes{to};
    $self->_assets->connect($nodes{from}, $nodes{to});
} #connect()

=head2 run_build

Runs the build tool for which this generator has created blueprint files.
Runs the tool with the destination directory as the current dir.

=cut

sub run_build {
    my $self = shift or croak 'Need an instance';
    my $abs_dir = $DestDir->absolute;
        # NOTE: You have to call this *before* pushd() or chdir(), because
        # it may be a relative path, and absolute() converts with respect
        # to cwd at the time of the call.
    my $dir = pushd($abs_dir);
    say "Building in ${abs_dir}..." unless $QUIET;
    $self->_run_build();
} #run_build()

=head2 BUILD

Constructor.

=cut

sub BUILD {
    my ($self, $args) = @_;

    # Enforce the required argument types
    croak "Need a project directory (Path::Class::Dir)"
        unless eval { $self->proj_dir->DOES('Path::Class::Dir') };
    croak "Need a destination directory (Path::Class::Dir)"
        unless eval { $self->dest_dir->DOES('Path::Class::Dir') };

    # Create the asset graph
    $self->_assets(hnew DAG => 'asset graph');
} #BUILD()

=head1 FUNCTIONS TO BE IMPLEMENTED BY SUBCLASSES

=head2 _assetop_class

(Required) Returns the name of the L<App::hopen::G::AssetOp> subclass that
should be used to represent assets in the C<_assets> graph.

=cut

sub _assetop_class { ... }

=head2 default_toolset

(Required) Returns the package stem of the default toolset for this generator.

When a hopen file invokes C<use language "Foo">, hopen will load
C<< Data::Hopen::T::<stem>::Foo >>, where C<< <stem> >> is the return
value of this function.

As a sanity check, hopen will first try to load C<< Data::Hopen::T::<stem> >>,
so make sure that is a valid package.

=cut

sub default_toolset { ... }

=head2 finalize

(Optional)
Do whatever the generator wants to do to finish up.  By default, no-op.
Is provided the L<Data::Hopen::G::DAG> instance as a parameter.  Usage:

    $generator->finalize(-phase=>$Phase, -graph=>$dag)

=cut

sub finalize { }

=head2 _run_build

(Optional)
Implementation of L</run_build>.  The default does not die, but does warn().

=cut

sub _run_build {
    warn "This generator is not configured to run a build tool.  Sorry!";
} #_run_build()

=head2 visit_goal

(Optional)
Do whatever the generator wants to do with a L<Data::Hopen::G::Goal>.
For example, the generator may change the goal's C<outputs>.
By default, no-op.  Usage:

    $generator->visit_goal($goal);

=cut

sub visit_goal { }

=head2 visit_node

(Optional)
Do whatever the generator wants to do with a L<Data::Hopen::G::Node> that
is not a Goal (see L</visit_goal>).  By default, no-op.  Usage:

    $generator->visit_node($node)

=cut

sub visit_node { }

1;
__END__
# vi: set fdm=marker: #
