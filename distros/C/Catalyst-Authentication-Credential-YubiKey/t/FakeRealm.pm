package FakeRealm;
use Moose;
use namespace::autoclean;

# A fake "Realm" for use in testing.

has 'name' => (
    is => 'rw',
    isa => 'Str',
    default => 'default',
);

sub find_user {
    my ($self, $args) = @_;
    if ($args->{id} eq 'foobar') {
        return bless { name => 'John', id => 'foobar' }, 'Fake::User';
    }
    return;
}

__PACKAGE__->meta->make_immutable;
1;
