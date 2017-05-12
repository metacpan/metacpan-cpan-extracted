package Connector::Builtin::File::SCP;

use strict;
use warnings;
use English;
use File::Spec;
use File::Temp qw(tempfile tempdir);
use Proc::SafeExec;
use Data::Dumper;
use Template;

use Moose;
extends 'Connector::Builtin';

has noargs => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

has file => (
    is  => 'rw',
    isa => 'Str',
);

has path => (
    is  => 'rw',
    isa => 'Str',
);

has content => (
    is  => 'rw',
    isa => 'Str',
);

has command => (
    is  => 'rw',
    isa => 'Str',
    default => '/usr/bin/scp'
);

has identity => (
    is  => 'rw',
    isa => 'Str',
    default => ''
);

has sshconfig => (
    is  => 'rw',
    isa => 'Str',
    default => ''
);

has port => (
    is  => 'rw',
    isa => 'Str',
    default => ''
);

has timeout => (
    is  => 'rw',
    isa => 'Int',
    default => 30
);

has _scp_option => (
    is  => 'rw',
    isa => 'ArrayRef',
    lazy => 1,
    builder => '_init_scp_option',
);

has filemode => (
    is  => 'rw',
    isa => 'Str',
    default => ''
);

sub _build_config {

    my $self = shift;
    if (! -d $self->{LOCATION}) {
       confess("Cannot open directory " . $self->{LOCATION} );
    }

    return 1;
}

sub _init_scp_option {

    my $self = shift;

    my @options;
    push @options, '-P'. $self->port() if ($self->port());
    push @options, '-F'. $self->sshconfig() if ($self->sshconfig());
    push @options, '-i'. $self->identity() if ($self->identity());

    return \@options;

}

# return the content of the file
sub get {

    my $self = shift;
    my $path = shift;

    my $source = $self->_sanitize_path( $path );

    # We need to double encode the backslash escape (for local and remote) 
    $source =~ s/\\/\\/g;

    my $tmpdir = tempdir( CLEANUP => 1 );    
    my ($fh, $target) = tempfile( DIR => $tmpdir );

    my $res = $self->_transfer($source, $target );

    # soemthing went wrong
    if ($res) {
        unlink $target if (-e $target);
        return $self->_node_not_exists();
    }

    # read the content from temporary file
    my $content = do {
      local $INPUT_RECORD_SEPARATOR;
      open my $fh, '<', $target;
      <$fh>;
    };

    unlink $target;

    return $content;
}

sub get_meta {
    my $self = shift;

    # If we have no path, we tell the caller that we are a connector
    # but if noargs is set, we behave like a scalar...
    my @path = $self->_build_path_with_prefix( shift );
    if (scalar @path == 0 && !$self->noargs()) {
        return { TYPE  => "connector" };
    }

    return {TYPE  => "scalar" };
}


sub exists {

    my $self = shift;

    # No path = connector root which always exists
    my @path = $self->_build_path_with_prefix( shift );
    if (scalar @path == 0) {
        return 1;
    }

    return 1;

}


# return the content of the file
sub set {

    my $self = shift;
    my $file = shift;
    my $data = shift;

    my $content;
    if ($self->content()) {
        $self->log()->debug('Process template for content ' . $self->content());
        my $template = Template->new({});

        $data = { DATA => $data } if (ref $data eq '');

        $template->process( \$self->content(), $data, \$content) || die "Error processing content template.";
    } else {
        if (ref $data ne '') {
            die "You need to define a content template if data is not a scalar";
        }
        $content = $data;
    }


    my $tmpdir = tempdir( CLEANUP => 1 );
    my ($fh, $source) = tempfile( DIR => $tmpdir );
    
    open FILE, ">$source" || die "Unable to open file for writing";
    print FILE $content;
    close FILE;
    
    if ($self->filemode()) {
        my $mode = $self->filemode();
        $mode = oct($mode) if $mode =~ /^0/;
        chmod $mode, $source;
    }

    my $target = $self->_sanitize_path( $file, $data );

    my $res = $self->_transfer( $source, $target );

    unlink $target if (-e $target);

    if ($res) {
        die "Unable to transfer data";
    }

    return 1;
}

sub _transfer {

    my $self = shift;
    my $source  = shift;
    my $target = shift;

    my %filehandles;
    my $stdout = File::Temp->new();
    $filehandles{stdout} = \*$stdout;

    my $stderr = File::Temp->new();
    $filehandles{stderr} = \*$stderr;

    # compose the system command to execute
    my @cmd = @{$self->_scp_option()};

    unshift @cmd, $self->command();

    push @cmd, $source;
    push @cmd, $target;

    $self->log()->debug("scp command: " . join(" ",@cmd));

    my $command = Proc::SafeExec->new({
        exec => \@cmd,
        no_autowait => 1,
        %filehandles,
    });

    eval{
        local $SIG{ALRM} = sub { die "alarm\n" };
        alarm $self->timeout();
        $command->wait();
    };

    alarm 0;

    if ($EVAL_ERROR) {
        $self->log()->debug($EVAL_ERROR);
        $self->log()->error("SCP tranfer timed out");
        return 2;
    }

    if ($command->exit_status() != 0) {
        $self->log()->error("SCP tranfer failed, exit status was " . $command->exit_status());
        return 1;
    }

    return 0;

}


sub _sanitize_path {

    my $self = shift;
    my $inargs = shift;
    my $data = shift;

    my $host = $self->{LOCATION};

    if ($self->noargs()) {
        $self->log()->debug('Skip filename rendering, noargs options is set');
        return $host;
    }

    my @args = $self->_build_path_with_prefix( $inargs );


    my $file;
    my $template = Template->new({});

    if ($self->path()) {
        my $pattern = $self->path();
        $self->log()->debug('Process template ' . $pattern);
        $template->process( \$pattern, { ARGS => \@args, DATA => $data }, \$file) || die "Error processing file template.";
    } elsif ($self->file()) {
        my $pattern = $self->file();
        my $template = Template->new({});
        $self->log()->debug('Process template ' . $pattern);
        $template->process( \$pattern, { ARGS => \@args, DATA => $data }, \$file) || die "Error processing file template.";
        if ($file =~ m{[\/\\]}) {
            $self->log()->error('Target file name contains directory seperator! Consider using path instead.');
            die "Target file name contains directory seperator! Consider using path instead.";
        }
    } else {
        $self->log()->error('Neither target pattern nor noargs set');
        die "You must set either file or path or use the noargs option.";
    }

    $file =~ s/[^\s\w\.\-\\]//g;

    my $filename;
    # check if the LOCATION already has a path spec
    if ($host !~ /:/) {
        # if the file name has a leading slash, just concat with :
        if ($file =~ /^\//) {
            $filename = $host.':'.$file;
        # otherwise add ~/ for users home
        } else {
            $filename = $host.':~/'.$file;
        }

    } else {
        # if a path spec is given, check if it has a trailing slash
        if ($host !~ /\/$/) {
            $host .= '/';
        }
        $filename = $host.$file;
    }

    $self->log()->debug('Filename evaluated to ' . $filename);

    $filename =~ s/ /\\ /g;

    return $filename;
}

1;
__END__

=head1 Name

Connector::Builtin::File::SCP

=head1 Description

Read/Write files to/from a remote host using SCP.

=head1 Parameters

=over

=item LOCATION

The target host specification, minimal the hostname, optional including
username and a base path specification. Valid examples are:

   my.remote.host
   otheruser@my.remote.host
   my.remote.host:/tmp
   otheruser@my.remote.host:/tmp

Note: If the connector is called with arguments, those are used to build a
filename / path which is appended to the target specification. If you call
the connector without arguments, you need to set the noargs parameter and
must LOCATION point to a file (otherwise you will end up with the temporary
file name used as target name).

=item noargs

Set to true, if you want to use the value given by LOCATION as final
target. This makes additional path arguments and the file/path parameter
useless.

=item file

Pattern for Template Toolkit to build the filename. The connector path
components are available in the key ARGS. In set mode the unfiltered
data is also available in key DATA. The result is appended to LOCATION.
NB: For security reasons, only word, space, dash, underscore and dot are
allowed in the filename. If you want to include a directory, add the path
parameter instead!

=item path

Same as file, but allows the directory seperator (slash and backslash)
in the resulting filename. Use this for the full path including the
filename as the file parameter is not used, when path is set!

=filemode (set mode only)

By default, the file is created with restrictive permissions of 0600. You 
can set other permissions using filemode. Due to perls lack for variable
types, you must give this either as octal number with leading zero or as 
string without the leading zero. Otherwise you might get wrong permissions.


=item content

Pattern for Template Toolkit to build the content. The data is passed
"as is". If data is a scalar, it is wrapped into a hash using DATA as key.

=item command, optional

Path to the scp command, default is /usr/bin/scp.

=item port, optional

Port to connect to, added with "-P" to the command line.

=item identity, optional

Path to an ssh identity file, added with "-i" to the command line.

=item sshconfig, optional

Path to an ssh client configuration, added with "-F" to the command line.

=item timeout, optional

Abort the transfer after timeout seconds.

=back

=head1 Supported Methods

=head2 set

Write data to a file.

    $conn->set('filename', { NAME => 'John Doe', 'ROLE' => 'Administrator' });

See the file parameter how to control the filename. 

=head2 get

Fetch data from a file. See the file parameter how to control the filename.

    my $data = $conn->set('filename');

=head1 Example

    my $conn = Connector::Builtin::File::SCP->new({
       LOCATION => 'localhost:/var/data',
       file => '[% ARGS.0 %].txt',
       content => ' Hello [% NAME %]',
       filemode => 0644
    });

    $conn->set('test', { NAME => 'John Doe' });

Results in a file I</var/data/test.txt> with the content I<Hello John Doe>.

=head1 A note on security

To enable the scp transfer, the file is created on the local disk using 
tempdir/tempfile. The directory is created with permissions only for the 
current user, so no other user than root and yourself is able to see the 
content. The tempfile is cleaned up immediatly, the directory is handled
by the internal garbage collection.

 

