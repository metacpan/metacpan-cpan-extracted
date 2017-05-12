package Canella::Context;
use Moo;
use Guard;
use Hash::MultiValue;
use Canella::Exec::Local;
use Canella::Log;
use Canella::TaskRunner;
our $CTX;

has docs => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has concurrency => (
    is => 'rw',
    default => 8,
    isa => sub { die "concurrency must be > 0" unless $_[0] > 0 }
);

has override_parameters => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has parameters => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has roles => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has tasks => (
    is => 'ro',
    default => sub { Hash::MultiValue->new() }
);

has runner => (
    is => 'ro',
    lazy => 1,
    builder => 'build_runner',
);

has mode => (
    is => 'rw',
    default => '',
);

has config => (
    is => 'rw'
);

sub load_config {
    my $self = shift;
    my $file = $self->config;
    debugf("Loading config %s", $file);

    # Eval the code under a different namespace so not to pollute Context
    my $namespace = sprintf "Canella::LoadedDeployFile::%s",
        (my $temp = $file) =~ s/\//::/g
    ;
    my $code = "package $namespace;\n";
    open my $fh, '<', $file or die "Could not open file $file: $!";
    $code .= do { local $/; <$fh> };
    close $fh;
    eval $code;
    if ($@ || $!) {
        croakf("Error loading file: %s", $@ || $!);
    }
}

sub dump_config {
    my $self = shift;
    require JSON;
    print JSON->new->pretty->utf8->allow_blessed(1)->convert_blessed(1)->encode({
        config      => $self->config,
        parameters  => $self->parameters->as_hashref_mixed,
        roles       => $self->roles->as_hashref_mixed,
        tasks       => [ map {
            { (name => $_->name, ($_->description ? (description => $_->description) : ()) ) }
        } $self->tasks->values ]
    });
}

sub show_help {
    my $self = shift;

    # be lazy. use perldoc
    require File::Temp;
    require Pod::Perldoc;
    my $tempfile = File::Temp->new();
    print $tempfile <<EOM;
=encoding utf-8

=head1 NAME

Documentation For Deploy File '@{[$self->config]}'

=head1 SYNOPSIS

EOM

    if (my $synopsis = $self->docs->get('SYNOPSIS')) {
        print $tempfile $synopsis;
    } else {
        foreach my $task ($self->tasks->values) {
            print $tempfile <<EOM;
    canella -c @{[$self->config]} I<role> @{[$task->name]}
EOM
        }
    }

    print $tempfile <<EOM;

=head1 ROLES

EOM
    foreach my $role ($self->roles->values) {
        print $tempfile <<EOM;
=head2 @{[$role->name]}

EOM
    }

    print $tempfile <<EOM;

=head1 TASKS

EOM
    foreach my $task ($self->tasks->values) {
        print $tempfile <<EOM
=head2 @{[ $task->name ]}

@{[$task->description || '']}

EOM
    }

    foreach my $section (grep { !/^SYNOPSIS$/ } $self->docs->keys) {
        print $tempfile <<EOM
=head1 $section

@{[ $self->docs->get($section) ]}

EOM
    }

    print $tempfile "\n=cut\n";
    $tempfile->flush;

    local @ARGV = ('-F', $tempfile->filename);
    exit(Pod::Perldoc->run());
}

# Thread-specific stash
sub stash {
    my $self = shift;
    my $stash = $Coro::current->{Canella} ||= {};

    if (@_ == 0) {
        return $stash;
    }

    if (@_ == 1) {
        return $stash->{$_[0]};
    }

    while (my ($key, $value) = splice @_, 0, 2) {
        $stash->{$key} = $value;
    }
}

sub get_param {
    my ($self, $name) = @_;
    return $self->parameters->get($name);
}

sub set_param {
    my ($self, $name, $value) = @_;

    # If the same parameter has been overriden in the command line, respect
    # that instead of the actual parameter given
    if (defined(my $o_value = $self->override_parameters->get($name))) {
        return;
    }
    $self->parameters->set($name, $value);
}

sub get_role {
    $_[0]->roles->get($_[1]);
}

sub add_role {
    my ($self, $name, %args) = @_;

    if ($args{parameters}) {
        $args{parameters} = Hash::MultiValue->new(%{$args{parameters}});
    }

    $self->roles->set($name, Canella::Role->new(name => $name, %args));
}

sub get_task {
    $_[0]->tasks->get($_[1]);
}

sub add_task {
    my $self = shift;
    $self->tasks->set($_[0]->name, $_[0]);
}

sub call_task {
    my ($self, $task) = @_;
    my $host = $self->stash('current_host');

    debugf "Starting task %s on host %s", $task->name, $host;
    my $guard = guard {
        debugf "End task %s on host %s", $task->name, $host;
    };
    local $@;
    eval { $task->execute($host) };
    if (my $E = $@) {
        critf("[%s] %s", $host, $E);
    }
}

sub build_cmd_executor {
    my ($self, @cmd) = @_;

    if ($self->stash('sudo')) {
        unshift @cmd, "sudo";
    }

    my $cmd;
    if (my $remote = $self->stash('current_remote')) {
        $remote->cmd(\@cmd);
        $cmd = $remote;
    } else {
        $cmd = Canella::Exec::Local->new(cmd => \@cmd);
    }
    return $cmd;
}

sub run_cmd {
    my ($self, @cmd) = @_;

    my $cmd = $self->build_cmd_executor(@cmd);
    $cmd->execute();
    if ($cmd->has_error) {
        croakf("Error executing command: %d", $cmd->error);
    }
    return ($cmd->stdout, $cmd->stderr);
}

sub build_runner {
    return Canella::TaskRunner->new;
}

1;