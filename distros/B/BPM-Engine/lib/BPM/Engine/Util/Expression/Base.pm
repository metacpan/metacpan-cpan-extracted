package BPM::Engine::Util::Expression::Base;
BEGIN {
    $BPM::Engine::Util::Expression::Base::VERSION   = '0.01';
    $BPM::Engine::Util::Expression::Base::AUTHORITY = 'cpan:SITETECH';
    }

use namespace::autoclean;
use Moose;
use MooseX::StrictConstructor;

has 'params' => (
    traits   => [ 'Hash' ],
    isa      => 'HashRef',
    is       => 'rw',
    default  => sub { {} },
    handles  => {
        get_param => 'get',        
        set_param => 'set',
        variables => 'keys',
        set_activity => [ set => 'activity' ],
        },
    );

has 'process_instance' => (
    is       => 'ro',
    isa      => 'BPM::Engine::Store::Result::ProcessInstance',
    required => 1,
    );

sub type {
    my ($self) = @_;

    my $type = ref $self;
    $type =~ s/.*Expression:://xms;
    $type =~ tr/A-Z/a-z/;

    return $type;
    }

__PACKAGE__->meta->make_immutable;

1;
__END__