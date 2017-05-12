package BioX::Workflow::Command::file_log;

use v5.10;
use MooseX::App::Command;

use File::Details;
use File::stat;
use Time::localtime;
use File::Basename;

extends 'BioX::Workflow::Command';
use BioX::Workflow::Command::Utils::Traits qw(ArrayRefOfStrs);

with 'BioX::Workflow::Command::Utils::Log';
with 'BioX::Workflow::Command::Utils::Plugin';
with 'BioX::Workflow::Command::Utils::Files::TrackChanges';

command_short_description 'After each process log your files modified time.';
command_long_description 'Each rule has a process, which is a series of tasks.'
  . ' Each of these tasks has one or more INPUTs and OUTPUTs.'
  . ' BioX-Workflow will track the modified times of these INPUT/OUTPUT.'
  . ' You can take advantage of this feature by using --use_timestamps or --make with biox-workflow.pl run'
  . ' Please see the options of biox-workflow.pl run for more information. ';

option 'files' => (
    traits        => ['Array'],
    is            => 'rw',
    required      => 0,
    isa           => ArrayRefOfStrs,
    documentation => 'Files to log',
    default       => sub { [] },
    cmd_split     => qr/,/,
    handles       => {
        all_files  => 'elements',
        has_files  => 'count',
        join_files => 'join',
    },
);

#Put a default to keep from breaking backwards compatibility
option 'exit_code' => (
    is       => 'rw',
    required => 0,
    default  => 0,
);

sub execute {
    my $self = shift;

    foreach my $file ( $self->all_files ) {

        if ( -e $file ) {
            $self->app_log->info( 'File ' . $file . ' exists' );
        }
        else {
            $self->app_log->info( 'File ' . $file . ' does not exist' );
            next;
        }

        my $details = File::Details->new($file);
        my $mtime   = ctime( stat($file)->mtime );
        $self->track_files->{$file}->{mtime} = $mtime;
    }

    #Preserve the exit code of the previous process
    exit($self->exit_code);

}

1;
