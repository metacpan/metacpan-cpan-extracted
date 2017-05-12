package BioX::Workflow::Command::run::Utils::Files::TrackChanges;

use MooseX::App::Role;
use Data::Walk;
use File::Details;
use File::stat;
use Time::localtime;
use File::Basename;
use DateTime::Format::Strptime;
# use Memoize;

with 'BioX::Workflow::Command::Utils::Files::TrackChanges';

option 'make' => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Sets --use_timestamps and --autodeps to True.',
    trigger       => sub {
        my $self = shift;
        if ( $self->make ) {
            $self->use_timestamps(1);
            $self->auto_deps(1);
        }
    },
);

option 'use_timestamps' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    documentation =>
'Automatically select a rule if any of the INPUTs of that rule have changed.'
);

=head3 files

Files just for this rule

=cut

has 'files' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        files_pairs => 'kv',
        clear_files => 'clear',
    },
);

has 'seen_modify' => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        seen_modify_pairs => 'kv',
        clear_seen_modify => 'clear',
    },
);

sub walk_FILES {
    my $self = shift;
    my $attr = shift;

    $self->seen_modify->{local} = {};

    my $mod_input = $self->pre_FILES( $attr, 'INPUT' );
    $self->add_graph('INPUT');
    $self->clear_files;

    # $self->app_log->info('Between checks...');
    my $mod_output = $self->pre_FILES( $attr, 'OUTPUT' );
    $self->add_graph('OUTPUT');
    $self->clear_files;
    $self->local_attr->{_modified} = 1 if $mod_input;

    # TODO add check for when we have actually modified the output
}

sub pre_FILES {
    my $self = shift;
    my $attr = shift;
    my $cond = shift;

    # $self->app_log->info( 'Beginning modification checks for ' . $cond );
    # REF check?
    walk {
        wanted => sub { $self->walk_INPUT(@_) }
      },
      $attr->$cond;

    # Once we get to the input we want to see if we are processing a new file or no
    my $modify = $self->iterate_FILES;

    return $modify;
}

sub iterate_FILES {
    my $self = shift;

    my $modify = 0;
    for my $pair ( $self->files_pairs ) {
        my $file = $pair->[0];
        if ( $self->seen_modify->{all}->{$file} ) {
            my $tmodify = $self->seen_modify->{all}->{$file};
            $modify = 1 if $tmodify;
            $self->update_seen( $file, $modify );
            next;
        }
        elsif ( !-e $file ) {
            $self->update_seen( $file, 1 );
            $modify = 1;
            next;
        }

        if ( $self->process_file($file) ) {
            $modify = 1;
        }
    }

    return $modify;
}

=head3 process_file

=cut

sub process_file {
    my $self = shift;
    my $file = shift;

    my $details = File::Details->new($file);
    my $mtime   = ctime( stat($file)->mtime );

    if ( exists $self->track_files->{$file}->{mtime} ) {

        # Check to see if we have a difference
        my $p_mtime = $self->track_files->{$file}->{mtime};
        if ( compare_mtimes( $p_mtime, $mtime ) ) {
            $self->flag_for_process( $file, $p_mtime, $mtime );
            $self->update_seen( $file, 1 );

            return 1;
        }
        else {
            # This is the only time we should return 0
            $self->update_seen( $file, 0 );
            return 0;
        }
    }
    else {
        $self->update_seen( $file, 1 );
        return 1;
    }
}

# This is really more of a sanity check
sub flag_for_process {
    my $self    = shift;
    my $file    = shift;
    my $p_mtime = shift;
    my $mtime   = shift;

    my $basename = basename($file);

    #TO LOG OR NOT TO LOG
    $self->app_log->warn(
        'File ' . $file . ' has been modified since your last analysis.' );
    $self->app_log->warn( $basename
          . ":\n\tLast Recorded Modification:\t"
          . $p_mtime
          . "\n\tMost Recent Modification:\t"
          . $mtime );

    # TODO We only want this in run...
    # TODO Add an override here
    if ( !$self->check_select && !$self->use_timestamps ) {
        $self->app_log->warn( 'You have selected to skip rule '
              . $self->rule_name
              . ', but this file has changed since last your last analysis.' );

    }
}

sub walk_INPUT {
    my $self = shift;
    my $ref  = shift;

    return if ref($ref);
    return unless $ref;

    if ( !exists $self->files->{$ref} ) {
        $self->files->{$ref} = 1;
    }
}

# memoize('compare_mtimes');

sub compare_mtimes {
    my $pmtime = shift;
    my $mtime  = shift;

    my $strp = DateTime::Format::Strptime->new(
        pattern   => '%a %b %e %T %Y',
        time_zone => 'local',
    );

    my $dt1 = $strp->parse_datetime($pmtime);
    my $dt2 = $strp->parse_datetime($mtime);

    #For reasons unknown there is something off by 1 second either way
    #my $cmp = DateTime->compare( $dt1, $dt2 );
    my $dur = $dt2->subtract_datetime($dt1);

    # TODO Add this formatting to HPC::Runner
    my ( $days, $hours, $minutes, $seconds ) =
      $dur->in_units( 'days', 'hours', 'minutes', 'seconds' );

    if ( $days >= 1 || $hours >= 1 || $minutes >= 1 ) {
        return 1;
    }
    elsif ( $seconds >= 2 ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub update_seen {
    my $self   = shift;
    my $file   = shift;
    my $update = shift;

    $self->seen_modify->{all}->{$file}   = $update;
    $self->seen_modify->{local}->{$file} = $update;
}

sub write_file_log {
    my $self = shift;

    my $text  = "";
    my @files = keys %{ $self->seen_modify->{local} };
    @files = sort @files;

    $self->seen_modify->{local} = {};

    if (@files) {
        $text = <<EOF;
; \\
biox file_log \\
\t--exit_code `echo \$\?`  \\
EOF
    }

    my $last = pop(@files);
    foreach my $file (@files) {
        $text .= <<EOF;
\t--file $file \\
EOF
    }
    $text .= "\t--file $last\n\n" if $last;

    return $text;
}

1;
