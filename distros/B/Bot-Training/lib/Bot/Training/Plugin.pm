package Bot::Training::Plugin;
our $AUTHORITY = 'cpan:AVAR';
$Bot::Training::Plugin::VERSION = '0.06';
use 5.010;
use Moose;
use File::ShareDir qw< :ALL >;
use File::Spec::Functions qw< catdir catfile >;
use namespace::clean -except => 'meta';

sub file {
    my ($self) = @_;

    my $class = ref $self;
    my ($last) = $class =~ m[::([^:]+)$];
    $class =~ s[::][-]g;

    my $file = dist_file( $class, lc($last) . '.trn');

    return $file;
}

__PACKAGE__->meta->make_immutable;
