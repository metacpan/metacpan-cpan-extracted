package BioX::Workflow::Command::run::Rules::Directives::Types::Path;

use Moose::Role;
use namespace::autoclean;

use MooseX::Types::Path::Tiny qw/Path Paths AbsPath AbsFile/;
use Path::Tiny;
use Cwd;
use Data::Walk 2.01;

=head2 File Options

=head3 indir outdir

The initial indir is where samples are found

All output is written relative to the outdir

=cut

has 'indir' => (
    is            => 'rw',
    isa           => Path,
    coerce        => 1,
    required      => 0,
    default       => sub { cwd(); },
    predicate     => 'has_indir',
    clearer       => 'clear_indir',
    documentation => q(Directory to look for samples),
);

has 'outdir' => (
    is            => 'rw',
    isa           => Path,
    coerce        => 1,
    required      => 0,
    default       => sub { cwd(); },
    predicate     => 'has_outdir',
    clearer       => 'clear_outdir',
    documentation => q(Output directories for rules and processes),
);

has 'cwd' => (
    is            => 'rw',
    isa           => Path,
    coerce        => 1,
    required      => 0,
    default       => sub { cwd(); },
    predicate     => 'has_cwd',
    clearer       => 'clear_cwd',
    documentation => q(Placeholder for the cwd.),
);

=head3 INPUT OUTPUT

Special variables that can have input/output

=cut

has 'OUTPUT' => (
    is            => 'rw',
    required      => 0,
    predicate     => 'has_OUTPUT',
    documentation => q(At the end of each process the OUTPUT becomes
    the INPUT.)
);

has 'INPUT' => (
    is            => 'rw',
    required      => 0,
    predicate     => 'has_INPUT',
    documentation => q(See OUTPUT)
);

=head3 coerce_abs_dir

Coerce dirs to absolute paths (True)
Keep paths as relative directories (False)

=cut

has 'coerce_abs_dir' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 1,
    documentation => q{Coerce '*_dir' to absolute directories},
    predicate     => 'has_coerce_abs_dir',
    clearer       => 'clear_coerce_abs_dir',
);

=head3 create_outdir

=cut

has 'create_outdir' => (
    is        => 'rw',
    isa       => 'Bool',
    predicate => 'has_create_outdir',
    clearer   => 'clear_create_outdir',
    documentation =>
q(Create the outdir. You may want to turn this off if doing a rule that doesn't write anything, such as checking if files exist),
    default => 1,
);

after 'BUILD' => sub {
    my $self = shift;

    $self->set_register_process_directives(
        'path',
        {
            builder => 'process_directive_path',
            lookup =>
              [ '^indir$', '^outdir$', '^INPUT$', '^OUTPUT$', '.*_dir$', '^cwd$' ]
        }
    );
};

=head2 Type Specific Process Directives

Sometimes you want a type specific way of processing directives. This will generally require two different methods

  process_directive*
  walk_directives*

process_directive gives some official parameters
walk_directives walks the data structure

Take a look at the methods in 'BioX::Workflow::Command::run::Rules::Directives::Walk'

Your functions will probably be very similar

=cut

sub process_directive_path {
    my $self = shift;
    my $k    = shift;
    my $v    = shift;

    if ( ref($v) ) {
        walk {
            wanted => sub { $self->walk_directives_path(@_) }
          },
          $self->$k;
    }
    else {
        my $text = '';
        $text = $self->interpol_directive($v) if $v;
        if ( $text ne '' ) {
            $text = $self->return_path($text);
        }
        $self->$k($text);
    }
}

=head3 walk_directives_paths

Invoke with
  walk { wanted => sub { $self->directives(@_) } }, $self->other_thing;

Acts funny with $self->some_other_thing is not a reference

=cut

sub walk_directives_path {
    my $self = shift;
    my $ref  = shift;

    return if ref($ref);
    return unless $ref;

    my $text = '';
    $text = $self->interpol_directive($ref) if $ref;
    $text = $self->return_path($text);

    $self->update_directive($text);
}

sub return_path {
    my $self = shift;
    my $text = shift;

    if ( $self->coerce_abs_dir ) {
        $text = path($text)->absolute;
        $text = path($text);
    }
    else {
        $text = path($text);
    }
    return "$text";
}

no Moose;

1;
