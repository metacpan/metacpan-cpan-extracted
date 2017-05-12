package Bookmarks::Delicious;
use base 'Bookmarks::Parser';
use Net::Delicious;
use warnings;

my %bookmark_fields = (
    'created'     => 'time',
    'modified'    => undef,
    'visited'     => undef,
    'charset'     => undef,
    'url'         => 'href',
    'name'        => 'description',
    'id'          => undef,
    'personal'    => undef,
    'icon'        => undef,
    'description' => 'extended',
    'expanded'    => undef,
);

sub _parse_bookmarks {
    my ($self, $user, $password) = @_;

    my $account = Net::Delicious->new(
        {   user => $user,
            pswd => $password,
        }
    );

    my @posts = $account->all_posts();

    foreach my $post (@posts) {
        my $item = {};
        foreach my $attrib (keys %bookmark_fields) {
            my $method = $bookmark_fields{$attrib};
            next if (!$method);

            my $value = $post->$method();
            $item->{$attrib} = $value;
        }
        my @tags = split(' ', $post->tags());

        foreach my $tag (@tags) {
            my $parent = $self->add_bookmark({ name => $tag });
            $self->add_bookmark($item, $parent);
        }
    }
}

=head1 NAME

Bookmarks::Parser::Delicious - Backend for delicious bookmarks

=head1 DESCRIPTION

This backend is completely untested, and probably does not work yet. use at own risk.

=cut
