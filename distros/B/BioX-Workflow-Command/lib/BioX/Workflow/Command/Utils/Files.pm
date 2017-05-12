package BioX::Workflow::Command::Utils::Files;

use MooseX::App::Role;
use MooseX::Types::Path::Tiny qw/AbsFile/;
use File::Basename;
use DateTime;
use Try::Tiny;
use Config::Any;
use File::Spec;

option 'workflow' => (
    is            => 'rw',
    isa           => AbsFile,
    required      => 1,
    coerce        => 1,
    documentation => 'Supply a workflow',
    cmd_aliases   => ['w'],
);

=head3 workflow_data

initial config file read into a perl structure

=cut

has 'workflow_data' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { return {} },
);

option 'outfile' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self     = shift;
        my $workflow = $self->workflow;
        my @files    = fileparse( $self->workflow, qr/\.[^.]*/ );
        my $dt       = DateTime->now( time_zone => 'local' );
        my $file_name =
          $files[0] . '_' . $dt->ymd . '_' . $dt->time('-') . '.sh';
        return File::Spec->rel2abs( $file_name );
    },
    documentation => 'Write your workflow to a file',
    cmd_aliases   => ['o'],
);

option 'stdout' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Write workflows to STDOUT',
    predicate     => 'has_stdout',
);

has 'fh' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $fh   = new IO::File;
        if ( $self->stdout ) {
            $fh->fdopen( fileno(STDOUT), "w" );
        }
        else {
            $fh->open( "> " . $self->outfile );
        }
        return $fh;
    },
);

sub load_yaml_workflow {
    my $self = shift;

    my $cfg;
    my @files = ( $self->workflow );
    my $valid = 1;

    $self->app_log->info( 'Loading workflow ' . $self->workflow . ' ...' );

    try {
        $cfg = Config::Any->load_files( { files => \@files, use_ext => 1 } );
    }
    catch {
        $self->app_log->warn(
            "Unable to load your workflow. The following error was received.\n"
        );
        $self->app_log->warn("$_\n");
        $valid = 0;
    };

    $self->app_log->info('Your workflow is valid'."\n") if $valid;

    #TODO Add Layering
    for (@$cfg) {
        my ( $filename, $config ) = %$_;
        $self->workflow_data($config);
    }

    if ( !exists $self->workflow_data->{global} ) {
        $self->workflow_data->{global} = [];
    }

    return $valid;
}

1;
