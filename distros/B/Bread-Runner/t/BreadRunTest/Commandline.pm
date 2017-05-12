package BreadRunTest::Commandline;
use Moose;

has 'string' => (
    is=>'ro',
    isa=>'Str',
    required=>1,
);

has 'flag' => (
    is=>'ro',
    isa=>'Bool',
    required=>1,
);

has 'int' => (
    is=>'ro',
    isa=>'Int',
    default=>42,
);

has array => (
    is=>'ro',
    isa=>'ArrayRef',
);


sub run {
    my $self = shift;
    return "We did it, let's head home!";
}

__PACKAGE__->meta->make_immutable;
