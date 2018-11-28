package docker;

use charm;
use Moo;

has version => (is => 'ro');

sub is_installed {
    print("What's installed?\n");
}
