package DB::IntrospectorBaseTest;

use strict;

use base qw( Test::Unit::TestCase );

use DBI;


sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $self = $class->SUPER::new(@_);

    my $dbh = $_[1] || die("$class->new(name,dbh) requires a dbh");

    $self->{_dbh} = $dbh;
    return $self;
}


sub _dbh {
    my $self = shift;
    return $self->{_dbh};
}

sub _introspector {
    my $self = shift;

    $self->{_introspector} = shift if(@_);

    return $self->{_introspector};
}

sub set_up {
    my $self = shift;

    $self->_introspector( DB::Introspector->get_instance($self->_dbh) );
}

use Devel::Symdump;
sub suite {
    my $self = shift;

    my $suite = empty_new Test::Unit::TestSuite;
    my $symdump = new Devel::Symdump(ref($self) || $self);
    foreach my $method ( map{
                            $_ =~ s@.*::test@test@g; $_;
                         } grep { /^.*::test.*/ } $symdump->functions ) {
        $suite->add_test($self->new($method, $self->_dbh));
    }

    return $suite;
}


1;
