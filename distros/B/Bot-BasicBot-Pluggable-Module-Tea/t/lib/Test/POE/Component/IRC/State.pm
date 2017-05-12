package Test::POE::Component::IRC::State;

sub new {
    my ($class) = @_;
    my $self = {};
    bless($self,$class);
    return $self;
}

sub channel_list {
    my @nicks = qw/ foo bar baz qux /;
    return @nicks;
}

1;
