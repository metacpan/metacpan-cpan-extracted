package ArangoDB::ConnectOptions;
use strict;
use warnings;
use utf8;
use 5.008001;
use Data::Util qw(:check);
use List::MoreUtils qw(none);

sub new {
    my ( $class, $options ) = @_;

    if ( !defined $options ) {
        $options = {};
    }
    elsif ( !is_hash_ref($options) ) {
        die "Argument must be HASH reference";
    }

    my %opts = ( %{ $class->_get_defaults() }, %$options );
    my $self = bless { _options => \%opts }, $class;
    $self->_validate();
    return $self;
}

for my $name (qw/host port timeout keep_alive proxy auth_type auth_user auth_passwd inet_aton/) {
    next if __PACKAGE__->can($name);
    no strict 'refs';
    *{ __PACKAGE__ . '::' . $name } = sub {
        $_[0]->{_options}{$name};
    };
}

my @supported_auth_type = qw(Basic);

sub _validate {
    my $self    = shift;
    my $options = $self->{_options};
    die "host should be a string"
        if !defined $options->{host} || !is_string( $options->{host} );
    die "port should be an integer"
        if !defined $options->{port}
            || !is_integer( $options->{port} );

    die "timeout should be an integer"
        if defined $options->{timeout}
            && !is_integer( $options->{timeout} );

    if ( $options->{auth_type} && none { $options->{auth_type} eq $_ } @supported_auth_type ) {
        die sprintf( "unsupported auth_type value '%s'", $options->{auth_type} );
    }

    die "auth_user should be a string"         if $options->{auth_user}   && !is_string( $options->{auth_user} );
    die "auth_passwd should be a string"       if $options->{auth_passwd} && !is_string( $options->{auth_passwd} );
    die "inet_aton should be a CODE reference" if $options->{inet_aton}   && !is_code_ref( $options->{inet_aton} );

}

sub _get_defaults {
    return {
        host        => 'localhost',
        port        => 8529,
        timeout     => 300,           # Same value as default timeout of arangosh
        auth_user   => undef,
        auth_passwd => undef,
        auth_type   => undef,
        keep_alive  => 0,
        proxy       => undef,
        inet_aton   => undef,
    };
}

1;
__END__
