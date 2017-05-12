package TestConfig;
use Moo;
use MooX::Types::MooseLike::Base qw(Str);
use File::Spec;
extends 'Config::GitLike';

has 'tmpdir' => (
    is => 'rw',
    required => 1,
    isa => Str,
);

# override these methods so:
# (1) test cases don't need to chdir into the tmp directory in order to work correctly
# (2) we don't try loading configs from the user's home directory or the system
# /etc during tests, which could (a) cause tests to break and (b) change things on
# the user's system during tests
# (3) files in the test directory are not hidden (for easier debugging)

sub dir_file {
    my $self = shift;
    my $dirs = (File::Spec->splitpath( $self->tmpdir, 1 ))[1];
    return File::Spec->catfile($dirs, $self->confname);
}

sub user_file {
    my $self = shift;

    return File::Spec->catfile(
        ( File::Spec->splitpath( $self->tmpdir, 1 ) )[1],
        'home', $self->confname );
}

sub global_file {
    my $self = shift;

    return File::Spec->catfile(
        ( File::Spec->splitpath( $self->tmpdir, 1 ) )[1],
        'etc', $self->confname );
}

sub slurp {
    my $self = shift;
    my $file = shift || $self->dir_file;
    local ($/);
    open( my $fh, $file ) or die "Unable to open file $file: $!";
    return <$fh>;
}

sub burp {
    my $self = shift;
    my $content = pop;
    my $file_name = shift || $self->dir_file;

    open( my $fh, ">", $file_name )
        || die "can't open $file_name: $!";
    print $fh $content;
}

__PACKAGE__->meta->make_immutable;
no Moo;

1;

