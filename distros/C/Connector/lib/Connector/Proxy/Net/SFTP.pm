package Connector::Proxy::Net::SFTP;

use strict;
use warnings;
use English;
use File::Spec;
use File::Temp qw(tempfile tempdir);
use File::Basename;
use Net::SFTP;
use Template;
use Data::Dumper;
use Syntax::Keyword::Try;

use Moose;
extends 'Connector::Proxy';
with 'Connector::Role::LocalPath';

has port => (
    is  => 'rw',
    isa => 'Int',
    default => 22,
);

has basedir => (
    is  => 'rw',
    isa => 'Str',
);

has content => (
    is  => 'rw',
    isa => 'Str',
);

has username => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
);

has password => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
);

has timeout => (
    is  => 'rw',
    isa => 'Int',
    default => 30
);

has debug => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

has ssh_args => (
    is => 'rw',
    isa => 'HashRef',
    lazy => 1,
    default => sub { return {} }
);

has _client => (
    is  => 'ro',
    isa => 'Net::SFTP',
    lazy => 1,
    builder => '_init_client',
);

# return the content of the file
sub get {

    my $self = shift;
    my $path = shift;

    my $sftp = $self->_client();

    my $filename = $self->_sanitize_path( $path );
    $self->log()->debug('Fetch '. $filename );

    my $content = $sftp->get( $filename );
    return $content if (defined $content);

    $self->log()->info("Cannot read file $filename");
    return $self->_node_not_exists();
}

sub get_keys {

    my $self = shift;
    my $path = shift;

    my $dirname = $self->_sanitize_path( $path );

    $self->log()->debug('Fetch directory ' . $dirname );
    my $ftp = $self->_client();

    my @files = $ftp->ls($dirname);
    my @names = map { ($_->{filename} !~ /\A\.\.?\z/) ? $_->{filename} : () } @files;
    $self->log()->debug('List content of directory ' . (join "|", @names));
    return @names;

}

sub get_meta {
    my $self = shift;
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

    my $sftp = $self->_client();

    my $filename = $self->_sanitize_path( $file, $data );

    $self->log()->debug('Send put '. $source . ' => ' . $filename );
    $sftp->put( $source, $filename)
        or $self->_log_and_die('put failed: ' . $sftp->status);

    return 1;
}

sub _sanitize_path {

    my $self = shift;
    my $inargs = shift;
    my $data = shift;

    my @args = $self->_build_path_with_prefix( $inargs );

    my $file;
    my $template = Template->new({});

    if ($self->path() || $self->file()) {
        $file = $self->_render_local_path( \@args, $data );
    } else {
        $self->log()->debug('Neither target pattern nor file set, join arguments');
        map {
            if ($_ =~ /\.\.|\//) {
                $self->_log_and_die("args contains invalid characters (double dot or slash)");
            }
        } @args;
        $file = join("/", @args);
        $file =~ s/[^\s\w\.\-\\\/]//g;
    }

    $self->log()->debug('Filename evaluated to ' . $file);

    if (my $basedir = $self->basedir()) {
        $file = File::Spec->catfile($basedir, $file);
        $self->log()->debug('Added basedir: ' . $file);
    }
    if (wantarray) {
        return (dirname($file), basename($file));
    } else {
        return $file;
    }

}

sub _init_client {

    my $self = shift;
    my $sftp;
    try {
        my %args = (
            debug => $self->debug() ? 1 : 0,
            user => $self->username(),
            ssh_args => { %{$self->ssh_args()}, port => $self->port() },
    	);
	    $self->log()->trace(Dumper \%args);
        $sftp = Net::SFTP->new( $self->LOCATION(),
            %args,
            password => $self->password(),
            'warn' => sub { shift; $self->log()->warn('SFTP: ' . join(",", @_)) }
        );
    } catch ($error) {
        $self->_log_and_die(sprintf("Cannot connect to %s (%s)", $self->LOCATION(), $error));
    }
    return $sftp;
}

1;
__END__

=head1 Name

Connector::Proxy::Net::SFTP

=head1 Description

Read/Write files to/from a remote host using FTP.

LOCATION is the only mandatory parameter, if neither file nor path is
set, the file is constructed from the arguments given to the method call.

=head1 Parameters

=over

=item LOCATION

The DNS name or IP of the target host.

=item port

Port number (Integer), default is 22.

=item basedir

A basedir which is always prepended to the path.

=item content

Pattern for Template Toolkit to build the content. The data is passed
"as is". If data is a scalar, it is wrapped into a hash using DATA as key.

=item username

SFTP username

=item password

SFTP password

=item timeout

SFTP connection timeout, default is 30 seconds

=item debug (Boolean)

Set the debug flag for Net::SFTP

=item ssh_args

HashRef holding additional arguments to pass to underlying object.
@see Net::SFTP / Net::SSH::Perl

=back

=head1 Supported Methods

=head2 set

Write data to a file.

    $conn->set('filename', { NAME => 'John Doe', 'ROLE' => 'Administrator' });

See the file parameter how to control the filename.

=head2 get

Fetch data from a file. See the file parameter how to control the filename.

    my $data = $conn->set('filename');

=head2 get_keys

    Return the file names in the given directory.

=head1 Example

    my $conn = Connector::Proxy::Net::SFTP->new({
       LOCATION => 'localhost',
       file => '[% ARGS.0 %].txt',
       basedir => '/var/data/',
       content => ' Hello [% NAME %]',
    });

    $conn->set('test', { NAME => 'John Doe' });

Results in a file I</var/data/test.txt> with the content I<Hello John Doe>.

=head1 A note on security

To enable the transfer, the file is created on the local disk using
tempdir/tempfile. The directory is created with permissions only for the
current user, so no other user than root and yourself is able to see the
content. The tempfile is cleaned up immediatly, the directory is handled
by the internal garbage collection.

