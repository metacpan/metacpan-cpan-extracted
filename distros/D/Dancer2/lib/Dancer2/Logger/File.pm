package Dancer2::Logger::File;
# ABSTRACT: file-based logging engine for Dancer2
$Dancer2::Logger::File::VERSION = '2.1.0';
use Carp 'carp';
use Moo;
use Dancer2::Core::Types;

with 'Dancer2::Core::Role::Logger';

use Fcntl qw(:flock SEEK_END);
use Path::Tiny ();
use IO::File;

has environment => (
    is       => 'ro',
    required => 1,
);

has location => (
    is       => 'ro',
    required => 1,
);

has log_dir => (
    is      => 'rw',
    isa     => sub {
        my $dir = shift;

        if ( !-d $dir && !mkdir $dir ) {
            die "log directory \"$dir\" does not exist and unable to create it.";
        }
        if ( !-w $dir ) {
            die "log directory \"$dir\" is not writable."
        }
    },
    lazy    => 1,
    builder => '_build_log_dir',
);

has _log_dir_path => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_log_dir_path',
    init_arg => undef,
);

has file_name => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_file_name',
    lazy    => 1
);

has log_file => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => '_build_log_file',
);

has _log_file_path => (
    is       => 'ro',
    lazy     => 1,
    builder  => '_build_log_file_path',
    init_arg => undef,
);

has fh => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_fh',
);

sub _build_log_dir { Path::Tiny::path( $_[0]->location, 'logs' )->stringify }

sub _build_log_dir_path {
    my $self = shift;
    return Path::Tiny::path( $self->log_dir );
}

sub _build_file_name {$_[0]->environment . ".log"}

sub _build_log_file {
    my $self = shift;
    return $self->_log_dir_path->child( $self->file_name )->stringify;
}

sub _build_log_file_path {
    my $self = shift;
    return Path::Tiny::path( $self->log_file );
}

sub _build_fh {
    my $self    = shift;
    my $logfile = $self->_log_file_path->stringify;

    my $fh = eval {
        $self->_log_file_path->filehandle(
            '>>', ':encoding(UTF-8)',
        );
    } or do {
        Carp::carp("unable to create or append to $logfile");
        return;
    };

    $fh->autoflush;

    return $fh;
}

sub log {
    my ( $self, $level, $message ) = @_;
    my $fh = $self->fh;

    return unless ( ref $fh && $fh->opened );

    flock( $fh, LOCK_EX )
      or carp "locking logfile $self->{logfile} failed: $!";
    seek( $fh, 0, SEEK_END );
    $fh->print( $self->format_message( $level => $message ) )
      or carp "writing to logfile $self->{logfile} failed";
    flock( $fh, LOCK_UN )
      or carp "unlocking logfile $self->{logfile} failed: $!";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer2::Logger::File - file-based logging engine for Dancer2

=head1 VERSION

version 2.1.0

=head1 DESCRIPTION

This is a logging engine that allows you to save your logs to files on disk.

Logs are not automatically rotated.  Use a log rotation tool like
C<logrotate> in C<copytruncate> mode.

=head1 METHODS

=head2 log($level, $message)

Writes the log message to the file.

=head1 CONFIGURATION

The setting C<logger> should be set to C<File> in order to use this logging
engine in a Dancer2 application.

The follow attributes are supported:

=over 4

=item * C<log_dir>

Directory path to hold log files.

Defaults to F<logs> in the application directory

=item * C<file_name>

The name of the log file.

Defaults to the environment name with a F<.log> suffix

=back

Here is an example configuration that use this logger and stores logs in F</var/log/myapp>:

  logger: "File"

  engines:
    logger:
      File:
        log_dir: "/var/log/myapp"
        file_name: "myapp.log"

=head1 AUTHOR

Dancer Core Developers

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Alexis Sukrieh.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
