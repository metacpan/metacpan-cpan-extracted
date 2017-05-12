package Mock::Bucket;
use base qw(Brick::Bucket);

use Brick;

sub new { bless {}, $_[0] }

sub add_to_bucket { return $_[1]->{code} }

sub bucket_class { Brick->bucket_class }

sub comprise {}

1;
