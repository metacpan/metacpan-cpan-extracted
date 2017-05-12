package Dancer::Session::Storable;

use strict;
use warnings;
use base 'Dancer::Session::Abstract';
use vars qw($VERSION);

use Dancer::ModuleLoader;
use Dancer::Config 'setting';
use Dancer::FileUtils 'path';

$VERSION = '0.06';

# static

sub init {
    my ($class) = @_;

    $class->SUPER::init(@_);

    die "Storable is needed and is not installed"
      unless Dancer::ModuleLoader->load('Storable');

    # default value for session_dir
    setting('session_dir' => path(setting('appdir'), 'sessions'))
      if not defined setting('session_dir');

    # make sure session_dir exists
    my $session_dir = setting('session_dir');
    if (!-d $session_dir) {
        mkdir $session_dir
          or die "session_dir $session_dir cannot be created";
    }
    Dancer::Logger::core(
        __PACKAGE__ . " using session_dir : $session_dir"
    );
}

# create a new session and return the newborn object
# representing that session
sub create {
    my ($class) = @_;

    my $self = Dancer::Session::Storable->new;
    $self->flush;
    return $self;
}

# Return the session object corresponding to the given id
sub retrieve {
    my ($class, $id) = @_;

    return undef unless -f $class->session_file($id);
    return Storable::lock_retrieve($class->session_file($id));
}

# instance

sub session_file {
    my ($class,$id) = @_;
    return path(
        setting('session_dir'), 
        $class->session_name . "_$id.stor"
    );
}

sub destroy {
    my ($self) = @_;
    unlink $self->session_file($self->id) 
        if -f $self->session_file($self->id);
}

sub flush {
    my $self = shift;
    Storable::lock_nstore($self, $self->session_file($self->id));
    return $self;
}

1;
__END__

=pod

=head1 NAME

Dancer::Session::Storable - Storable-file-based session backend for Dancer

=head1 DESCRIPTION

This module implements a session engine by using L<Storable> to serialise data into
files.  Sessions are stored in a I<session_dir> as Storable files. 
 
Storable offers solid performance and reliable serialisation of various data
structures.

C<Storable::nstore> is used to store in network byte order, so sessions are
portable between different systems of differing endianness.

=head1 CONFIGURATION

The setting B<session> should be set to C<Storable> in order to use this session
engine in a Dancer application.

Files will be stored to the value of the setting C<session_dir>, whose default 
value is C<appdir/sessions>.

Here is an example configuration that use this session engine and stores session
files in /tmp/dancer-sessions

    session: Storable
    session_dir: /tmp/dancer-sessions

=head1 DEPENDENCY

This module depends on L<Storable>.

=head1 AUTHOR

David Precious, <davidp@preshweb.co.uk>

=head1 ACKNOWLEDGEMENTS

Alessandro Ranellucci

onelesd


=head1 SEE ALSO

See L<Dancer::Session> for details about session usage in route handlers, and
L<Dancer> for general information on the Dancer web framework.  See L<Storable>
for details on how the Storable serialiser works.

=head1 COPYRIGHT

This module is copyright (c) 2010-2011 David Precious <davidp@preshweb.co.uk>

=head1 LICENSE

This module is free software and is released under the same terms as Perl
itself.

=cut
