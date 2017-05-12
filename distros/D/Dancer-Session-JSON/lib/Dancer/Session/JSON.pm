use strict;
use warnings;
package Dancer::Session::JSON;
# ABSTRACT: JSON session backend for Dancer
$Dancer::Session::JSON::VERSION = '0.002';
use Carp;
use base 'Dancer::Session::Abstract';

use JSON;
use Fcntl ':flock';
use Dancer::Logger;
use Dancer::ModuleLoader;
use Dancer::Config 'setting';
use Dancer::FileUtils qw(path set_file_mode);

# static

my %session_dir_initialized;
my $json = JSON->new;

sub init {
    my $self = shift;

    $self->SUPER::init(@_);

    # default value for session_dir
    defined setting('session_dir')
        or setting( session_dir => path( setting('appdir'), 'sessions' ) );

    my $session_dir = setting('session_dir');
    if ( ! exists $session_dir_initialized{$session_dir} ) {
        $session_dir_initialized{$session_dir} = 1;

        # make sure session_dir exists
        if ( ! -d $session_dir ) {
            mkdir $session_dir
                or croak "session_dir $session_dir cannot be created";
        }

        Dancer::Logger::core("session_dir: $session_dir");
    }
}

# create a new session and return the newborn object
# representing that session
sub create {
    my ($class) = @_;

    my $self = Dancer::Session::JSON->new;
    $self->flush;

    return $self;
}

# deletes the dir cache
sub reset {
    my ($class) = @_;
    %session_dir_initialized = ();
}

# Return the session object corresponding to the given id
sub retrieve {
    my $class        = shift;
    my $id           = shift;
    my $session_file = _json_file($id);

    return unless -f $session_file;

    open my $fh, '+<', $session_file or die "Can't open '$session_file': $!\n";
    flock $fh, LOCK_EX or die "Can't lock file '$session_file': $!\n";
    my $json_data = do { local $/ = undef; <$fh>; };
    my $content   = $json->decode($json_data);
    close $fh or die "Can't close '$session_file': $!\n";

    return bless $content => 'Dancer::Session::JSON';
}

# instance
sub _json_file {
    my $id = shift;
    return path( setting('session_dir'), "$id.json" );
}

sub destroy {
    my ($self) = @_;

    my $file = _json_file( $self->id );
    Dancer::Logger::core("trying to remove session file: $file");

    -f $file and unlink $file;
}

sub flush {
    my $self         = shift;
    my $session_file = _json_file( $self->id );

    open my $fh, '>', $session_file or die "Can't open '$session_file': $!\n";
    flock $fh, LOCK_EX or die "Can't lock file '$session_file': $!\n";
    set_file_mode($fh);
    print {$fh} $json->allow_blessed->convert_blessed->encode(
        +{ %{$self} }
    );

    close $fh or die "Can't close '$session_file': $!\n";

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dancer::Session::JSON - JSON session backend for Dancer

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This module implements a session engine based on JSON files. Session are stored
in a I<session_dir> as JSON files. The idea behind this module was to provide a
transparent session storage for the developer. 

This backend is intended to be used in development environments, when looking
inside a session can be useful.

It's not recommended to use this session engine in production environments.

Typically you would want to use L<Dancer::Session::YAML> for this, which comes
in core, but a demand for a faster-but-still-file-based session backend arose,
and thus you now have JSON. :)

=head1 CONFIGURATION

The setting B<session> should be set to C<JSON> in order to use this session
engine in a Dancer application.

Files will be stored to the value of the setting C<session_dir>, whose default 
value is C<appdir/sessions>.

Here is an example configuration that use this session engine and stores session
files in /tmp/dancer-sessions

    session:     "JSON"
    session_dir: "/tmp/dancer-sessions"

=head1 SUBROUTINES/METHODS

=head2 init

Initializes the session backend.

=head2 create

Creates a new object, runs C<flush> and returns the object.

=head2 flush

Writes the session information to the session dir.

=head2 retrieve

Retrieves session information from the session dir.

=head2 destroy

Deletes session information from the session dir.

=head2 reset

Wipes the sessions directory, forcing a test for existence of the sessions
directory next time a session is created. It takes no argument.

This is particulary useful if you want to remove the sessions directory on the
system where your app is running, but you want this session engine to continue
to work without having to restart your application.

=head1 SEE ALSO

L<Dancer::Session::YAML> - the original core development session backend.

L<Dancer::Session::Simple> - a faster in-memory core session backend.

L<Dancer::Session::Cookie> - an encrypted cookie session backend, suitable
for production.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
