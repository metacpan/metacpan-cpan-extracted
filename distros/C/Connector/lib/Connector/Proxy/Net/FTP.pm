package Connector::Proxy::Net::FTP;

use strict;
use warnings;
use English;
use File::Spec;
use File::Temp qw(tempfile tempdir);
use File::Basename;
use Net::FTP;
use Data::Dumper;
use Template;

use Moose;
extends 'Connector::Proxy';

has port => (
    is  => 'rw',
    isa => 'Int',
    default => 21,
);

has file => (
    is  => 'rw',
    isa => 'Str',
);

has path => (
    is  => 'rw',
    isa => 'Str',
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
);

has password => (
    is  => 'rw',
    isa => 'Str',
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

has active => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

has binary => (
    is  => 'rw',
    isa => 'Bool',
    default => 1,
);

# return the content of the file
sub get {

    my $self = shift;
    my $path = shift;

    my $source = $self->_sanitize_path( $path );


    my $tmpdir = tempdir( CLEANUP => 1 );
    my ($fh, $target) = tempfile( DIR => $tmpdir );

    my $ftp = $self->_client();

    my ($dirname, $filename) = $self->_sanitize_path( $path );

    if ($dirname && $dirname ne '.') {
        $self->log()->debug('Change dir to ' . $dirname );
        if (!$ftp->cwd($dirname)) {
            $self->log()->info("Cannot change working directory $dirname");
            return $self->_die_on_undef();
        }
    }

    $self->log()->debug('Send get '. $filename . ' => ' . $target );
    if (!$ftp->get( $filename, $target )) {
        $self->log()->info("Cannot read file $filename");
        return $self->_die_on_undef();
    }

    $ftp->quit;

    # read the content from temporary file
    my $content = do {
      local $INPUT_RECORD_SEPARATOR;
      open my $fh, '<', $target;
      <$fh>;
    };

    unlink $target;

    return $content;
}

sub get_keys {

    my $self = shift;
    my $path = shift;

    my $dirname = $self->_sanitize_path( $path );

    my $ftp = $self->_client();

    if ($dirname  && $dirname ne '.') {
        $self->log()->debug('Change dir to ' . $dirname );
        if (!$ftp->cwd($dirname)) {
            $self->log()->info("Cannot change working directory $dirname");
            return $self->_die_on_undef();
        }
    }

    my @files = $ftp->ls();
    $self->log()->debug('List content of directory ' . (join "|", @files));
    return map { $_ unless ($_ =~ /\A\.\.?\z/) } @files;

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

    my $ftp = $self->_client();

    my ($dirname, $filename) = $self->_sanitize_path( $file, $data );

    if ($dirname && $dirname ne '.') {
        $self->log()->debug('Change dir to ' . $dirname );
        $ftp->cwd($dirname) or
            $self->_log_and_die('Cannot change working directory: ' . $ftp->message);
    }


    $self->log()->debug('Send put '. $source . ' => ' . $filename );
    $ftp->put( $source, $filename)
        or $self->_log_and_die('put failed: ' . $ftp->message);

    $ftp->quit;

    return 1;
}

sub _sanitize_path {

    my $self = shift;
    my $inargs = shift;
    my $data = shift;

    my @args = $self->_build_path_with_prefix( $inargs );


    my $file;
    my $template = Template->new({});

    if ($self->path()) {
        my $pattern = $self->path();
        $self->log()->debug('Process template ' . $pattern);
        $template->process( \$pattern, { ARGS => \@args, DATA => $data }, \$file) || $self->_log_and_die("Error processing file template.");
    } elsif ($self->file()) {
        my $pattern = $self->file();
        my $template = Template->new({});
        $self->log()->debug('Process template ' . $pattern);
        $template->process( \$pattern, { ARGS => \@args, DATA => $data }, \$file) || $self->_log_and_die("Error processing file template.");
        if ($file =~ m{[\/\\]}) {
            $self->_log_and_die('Target file name contains directory seperator! Consider using path instead.');
        }
    } else {
        $self->log()->debug('Neither target pattern nor file set, join arguments');

        map {
            if ($_ =~ /\.\.|\//) {
                $self->_log_and_die("args contains invalid characters (double dot or slash)");
            }
        } @args;
        $file = join("/", @args);
    }

    $file =~ s/[^\s\w\.\-\\\/]//g;

    $self->log()->debug('Filename evaluated to ' . $file);

    if (wantarray) {
        return (dirname($file), basename($file));
    } else {
        return $file;
    }

}

sub _client {

    my $self = shift;

    my $ftp = Net::FTP->new( $self->LOCATION(),
        'Passive' => (not $self->active()),
        'Debug' => $self->debug(),
        'Port' => $self->port(),
    ) or $self->_log_and_die(sprintf("Cannot connect to %s (%s)", $self->LOCATION(), $@));

    if ($self->username()) {
        $ftp->login($self->username(),$self->password())
          or $self->_log_and_die("Cannot login " . $ftp->message);

    }

    if ($self->basedir()) {
        $self->log()->debug('Change basedir to ' . $self->basedir());
        $ftp->cwd($self->basedir()) or $self->_log_and_die("Cannot change base directory " . $ftp->message);
    }

    if ($self->binary()) {
        $ftp->binary();
        $self->log()->trace('Set binary transfer mode');
    } else {
        $ftp->ascii();
        $self->log()->trace('Set ascii transfer mode');
    }

    return $ftp;

}

1;
__END__

=head1 Name

Connector::Proxy::Net::FTP

=head1 Description

Read/Write files to/from a remote host using FTP.

LOCATION is the only mandatory parameter, if neither file nor path is
set, the file is constructed from the arguments given to the method call.

=head1 Parameters

=over

=item LOCATION

The DNS name or IP of the target host.

=item port

Port number (Integer), default is 21.

=item file

Pattern for Template Toolkit to build the filename. The connector path
components are available in the key ARGS. In set mode the unfiltered
data is also available in key DATA.
For security reasons, only word, space, dash, underscore and dot are
allowed in the filename. If you want to include a directory, add the path
parameter instead!

=item path

Same as file, but allows the directory seperator (slash and backslash)
in the resulting filename. Use this for the full path including the
filename as the file parameter is not used, when path is set!

=item basedir

A basedir which is always prepended to the path.

=item content

Pattern for Template Toolkit to build the content. The data is passed
"as is". If data is a scalar, it is wrapped into a hash using DATA as key.

=item username

FTP username

=item password

FTP password

=item timeout

FTP connection timeout, default is 30 seconds

=item debug (Boolean)

Set the debug flag for Net::FTP

=item active (Boolean)

Use FTP active transfer. The default is to use passive transfer mode.

=item binary (Boolean)

Use binary or ascii transfer mode. Note that binary is the default!

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

    my $conn = Connector::Proxy::Net::FTP->new({
       LOCATION => 'localhost',
       file => '[% ARGS.0 %].txt',
       basedir => '/var/data/',
       content => ' Hello [% NAME %]',
    });

    $conn->set('test', { NAME => 'John Doe' });

Results in a file I</var/data/test.txt> with the content I<Hello John Doe>.

=head1 A note on security

To enable the scp transfer, the file is created on the local disk using
tempdir/tempfile. The directory is created with permissions only for the
current user, so no other user than root and yourself is able to see the
content. The tempfile is cleaned up immediatly, the directory is handled
by the internal garbage collection.


