# Connector::Proxy::Proc::SafeExec
#
# Connector class for running system commands
#
# Written by Martin Bartosch for the OpenXPKI project 2012
#
package Connector::Proxy::Proc::SafeExec;

use strict;
use warnings;
use English;
use Proc::SafeExec;
use File::Temp qw(tempdir tempfile);
use Syntax::Keyword::Try;
use Template;

use Data::Dumper;

use Moose;
extends 'Connector::Proxy';

has args => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { [] },
);

has timeout => (
    is => 'rw',
    isa => 'Int',
    default => 5,
);

has chomp_output => (
    is => 'rw',
    isa => 'Bool',
    default => 1,
);

has stdin => (
    is => 'rw',
    isa => 'Str|ArrayRef[Str]|Undef',
);

has env => (
    is => 'rw',
    isa => 'HashRef[Str]',
);

has content => (
    is  => 'rw',
    isa => 'Str',
);

sub _build_config {
    my $self = shift;

    if (! -x $self->LOCATION()) {
        die("Specified system command is not executable: " . $self->LOCATION());
    }

    return 1;
}

# this method always returns the file contents, regardless of the specified
# key
sub get {

    my $self = shift;
    my @args = $self->_build_path( shift );

    # compose a list of command arguments
    return $self->_run_command({ ARGS => \@args });
}

sub set {

    my $self = shift;
    my @args = $self->_build_path( shift );
    my $data = shift;

    my $content;
    if ($self->content()) {
        $self->log()->debug('Process template for content ' . $self->content());
        my $template = Template->new({});
        $data = { DATA => $data } if (ref $data eq '');
        $template->process( \$self->content(), $data, \$content) || $self->_log_and_die("Error processing content template.");
    } else {
        if (ref $data ne '') {
            $self->_log_and_die("You need to define a content template if data is not a scalar");
        }
        $content = $data;
    }

    my $tmpdir = tempdir( CLEANUP => 1 );
    my ($fh, $source) = tempfile( DIR => $tmpdir );

    open FILE, ">$source" || $self->_log_and_die("Unable to open file for writing");
    print FILE $content;
    close FILE;

    return $self->_run_command({ ARGS => \@args, FILE => $source, DATA => $data });

}


sub _run_command {

    my $self = shift;
    my $template_vars = shift;

    my $template = Template->new({});

    # process configured system command arguments and replace templates
    # in it with the passed arguments, accessible via [% ARGS.0 %]
    my @cmd_args;
    foreach my $item (@{$self->args()}) {
        my $value;
        $template->process(\$item, $template_vars, \$value) || die "Error processing argument template.";
        push @cmd_args, $value;
    }

    my %filehandles;

    my @feed_to_stdin;
    if (defined $self->stdin()) {
        my @raw_stdin_data;
        if (ref $self->stdin() eq '') {
            push @raw_stdin_data, $self->stdin();
        } elsif (ref $self->stdin() eq 'ARRAY') {
            push @raw_stdin_data, @{$self->stdin()};
        }
        foreach my $line (@raw_stdin_data) {
            my $value;
            $template->process(\$line, $template_vars, \$value) || die "Error processing stdin template.";
            push @feed_to_stdin, $value;
        }

        # we have data to pipe to stdin, create a filehandle
        $filehandles{stdin} = 'new';
    }

    if (defined $self->env()) {
        if (ref $self->env() eq 'HASH') {
            foreach my $key (keys %{$self->env()}) {
                my $value;
                $template->process(\$self->env()->{$key}, $template_vars, \$value) || die "Error processing environment template.";
                $ENV{$key} = $value;
            }
        }
    }

    my $stdout = File::Temp->new();
    $filehandles{stdout} = \*$stdout;

    my $stderr = File::Temp->new();
    $filehandles{stderr} = \*$stderr;


    # compose the system command to execute
    my @cmd;
    push @cmd, $self->{LOCATION};
    push @cmd, @cmd_args;

    my $command = Proc::SafeExec->new({
        exec => \@cmd,
        %filehandles,
    });

    try {
        local $SIG{ALRM} = sub { die "alarm\n" };
        if (scalar @feed_to_stdin) {
            my $stdin = $command->stdin();
            print $stdin join("\n", @feed_to_stdin);
        }
        alarm $self->timeout();
        $command->wait();
    } catch ($error) {
        if ($error eq "alarm\n") {
            die "System command timed out after " . $self->timeout() . " seconds";
        }
        die $error;
    } finally {
        alarm 0;
    };

    my $stderr_content = do {
        open my $fh, '<', $stderr->filename;
        local $INPUT_RECORD_SEPARATOR;
        <$fh>;
    };

    if ($command->exit_status() != 0) {
        die "System command exited with return code " . ($command->exit_status() >> 8) . ". STDERR: $stderr_content";
    }

    my $stdout_content = do {
        open my $fh, '<', $stdout->filename;
        local $INPUT_RECORD_SEPARATOR;
        <$fh>;
    };

    if ($self->chomp_output()) {
        chomp $stdout_content;
    }

    return $stdout_content;
}

sub get_meta {
    my $self = shift;

    # If we have no path, we tell the caller that we are a connector
    my @path = $self->_build_path( shift );
    if (scalar @path == 0) {
        return { TYPE  => "connector" };
    }

    return {TYPE  => "scalar" };
}

sub exists {

    my $self = shift;

    # No path = connector root which always exists
    my @path = $self->_build_path( shift );
    if (scalar @path == 0) {
        return 1;
    }
    my $val;
    eval {
        $val = $self->get( \@path );
    };
    return defined $val;

}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 Name

Connector::Builtin::System::Exec

=head1 Description

Run a command using Proc::SafeExec.

Allows passing of arguments, stdin and env, each item of those lists is
parsed as a template with the path arguments set in I<ARGS>. In I<set> mode
the filename generated from content is set to I<FILE>.

=head1 Usage

=head2 Configuration

    my $con = Connector::Proxy::DBI->new({
        LOCATION => '/usr/bin/script',
        args     => ['--foo','ARGS.0'],
        content  => '[% payload %]',
        env => {
            BAR => 'bar'
        },
        chomp_output  => 1,
        timeout  => 2,
    });

=head2 Parameters

=over

=item  args

List of parameters that are passed as arguments to the command.

=item timeout

Timeout to wait for the command in seconds, default is 5

=item chomp_output

=item stdin

A string or an array of strings to pipe as stdin to the command.
Items are joined with a newline.

=item env

Expects a HashRef where the key is the name of the ENV variable.

=item content

A template string used to generate a tempfile when I<set> mode is used.

The following call will create a tempfile with the content 'Hello World'
and afterwards runs the systems copy command using the first path
argument from the connector call as target filename.

    my $con = Connector::Proxy::DBI->new({
        LOCATION => '/usr/bin/cp',
        args     => ['[% FILE %]', '[% ARGS.0 %]''],
        content  => '[% payload %]',
    });
    $conn->set('foo.txt', { payload => 'Hello World' } );

=back