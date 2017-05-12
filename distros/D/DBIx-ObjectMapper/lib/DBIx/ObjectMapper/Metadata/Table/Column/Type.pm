package DBIx::ObjectMapper::Metadata::Table::Column::Type;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);

sub new {
    my $class = shift;
    my $pkg = __PACKAGE__;
    my ( $type ) = ( $class =~ /^$pkg\::(\w+)$/ );

    my $self = bless {
        type     => $type ? lc($type) : undef,
        size     => undef,
        utf8     => undef,
        realtype => undef,
    }, $class;

    $self->_init(@_);
    return $self;
}

sub type { $_[0]->{type} }

sub utf8 {
    my $self = shift;
    $self->{utf8} = shift if @_;
    return $self->{utf8};
}

sub size {
    my $self = shift;
    $self->{size} = shift if @_;
    return $self->{size};
}

sub realtype {
    my $self = shift;
    $self->{realtype} = shift if @_;
    return $self->{realtype};
}

sub _init {
    my $self = shift;
    if( @_ ) {
        my $size = shift;
        $self->{size} = $size if $size and looks_like_number( $size )
    }
}

sub from_storage {
    my ( $self, $val ) = @_;
    return $val;
}

sub to_storage {
    my ( $self, $val ) = @_;
    return $val;
}

sub set_engine_option {}

1;
