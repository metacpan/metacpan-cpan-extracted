package DDLock::Client::File;

use Fcntl qw{:DEFAULT :flock};
use File::Spec qw{};
use File::Path qw{mkpath};
use IO::File qw{};

use fields qw{name path tmpfile pid hooks};

our $TmpDir = File::Spec->tmpdir;

### (CONSTRUCTOR) METHOD: new( $lockname )
### Createa a new file-based lock with the specified I<lockname>.
sub new {
    my DDLock::Client::File $self = shift;
    $self = fields::new( $self ) unless ref $self;
    my ( $name, $lockdir ) = @_;

    $self->{pid} = $$;

    $lockdir ||= $TmpDir;
    if ( ! -d $lockdir ) {
        # Croaks if it fails, so no need for error-checking
        mkpath $lockdir;
    }

    my $lockfile = File::Spec->catfile( $lockdir, eurl($name) );

    # First open a temp file
    my $tmpfile = "$lockfile.$$.tmp";
    if ( -e $tmpfile ) {
        unlink $tmpfile or die "unlink: $tmpfile: $!";
    }

    my $fh = new IO::File $tmpfile, O_WRONLY|O_CREAT|O_EXCL
        or die "open: $tmpfile: $!";
    $fh->close;
    undef $fh;

    # Now try to make a hard link to it
    link( $tmpfile, $lockfile )
        or die "link: $tmpfile -> $lockfile: $!";
    unlink $tmpfile or die "unlink: $tmpfile: $!";

    $self->{path} = $lockfile;
    $self->{tmpfile} = $tmpfile;
    $self->{hooks} = {};

    return $self;
}

sub name {
    my DDLock::Client::File $self = shift;
    return $self->{name};
}

sub set_hook {
    my DDLock::Client::File $self = shift;
    my $hookname = shift || return;

    if (@_) {
        $self->{hooks}->{$hookname} = shift;
    } else {
        delete $self->{hooks}->{$hookname};
    }
}

sub run_hook {
    my DDLock::Client::File $self = shift;
    my $hookname = shift || return;

    if (my $hook = $self->{hooks}->{$hookname}) {
        local $@;
        eval { $hook->($self) };
        warn "DDLock::Client::File hook '$hookname' threw error: $@" if $@;
    }
}

### METHOD: release()
### Release the lock held by the object.
sub release {
    my DDLock::Client::File $self = shift;
    $self->run_hook('release');
    return unless $self->{path};
    unlink $self->{path} or die "unlink: $self->{path}: $!";
    unlink $self->{tmpfile};
}


### FUNCTION: eurl( $arg )
### URL-encode the given I<arg> and return it.
sub eurl
{
    my $a = $_[0];
    $a =~ s/([^a-zA-Z0-9_,.\\: -])/sprintf("%%%02X",ord($1))/eg;
    $a =~ tr/ /+/;
    return $a;
}


DESTROY {
    my $self = shift;
    $self->run_hook('DESTROY');
    $self->release if $$ == $self->{pid};
}

1;


# Local Variables:
# mode: perl
# c-basic-indent: 4
# indent-tabs-mode: nil
# End:
