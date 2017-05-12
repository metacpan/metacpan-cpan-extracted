package # hide from PAUSE
Catalyst::Model::KiokuDB::Test::User;
use Moose;

use namespace::clean -except => 'meta';

with qw(KiokuX::User);

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__
