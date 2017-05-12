package MockCatalyst;
use Moose;
use MooseX::Types::Path::Class 'Dir';

has log => (
    is         => 'ro',
    isa        => 'MockLogger',
    lazy_build => 1,
);

sub _build_log { new MockLogger }

has stash => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

has action => (
    is      => 'rw',
    isa     => 'Str',
    default => 'root/index',
);

has debug => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has response => (
    is         => 'ro',
    isa        => 'MockResponse',
    lazy_build => 1,
);

sub _build_response { new MockRespnse }

has root_dir => (
    is       => 'ro',
    isa      => Dir,
    coerce   => 1,
    required => 1,
);

sub path_to {
    my $self = shift;
    
    my $dir = $self->root_dir->subdir(@_);
    
    return -d $dir
        ? $dir
        : $self->root_dir->file(@_);
}

sub error {}


{
    package MockLogger;
    use Moose;

    sub error {}
    sub warn {}
    sub info {}
    sub debug {}


    package MockResponse;
    use Moose;
    
    sub body {}
    sub content_type {}
}

1;
