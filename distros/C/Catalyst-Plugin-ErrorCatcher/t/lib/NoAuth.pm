package NoAuth;
# vim: ts=8 sts=4 et sw=4 sr sta
use Moose;
    extends 'Catalyst';
use namespace::autoclean;
use Catalyst::Runtime 5.80;

our $VERSION = '0.0.3';

# hide debug output at startup
{
    no strict 'refs';
    no warnings;
    *{"Catalyst\::Log\::debug"} = sub { };
    *{"Catalyst\::Log\::info"}  = sub { };
}

__PACKAGE__->config(
    name => 'NoAuth',
);

VERSION_MADNESS: {
    use version;
    my $vstring = version->new($VERSION)->normal;
    __PACKAGE__->config(
        version => $vstring
    );
}

__PACKAGE__->setup(
    qw<
        -Debug
        StackTrace
        ErrorCatcher
        ConfigLoader
    >
);

1;
__END__
