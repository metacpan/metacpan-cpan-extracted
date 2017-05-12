package TestApp::View::TT;

use strict;
use warnings;

use base 'Catalyst::View::TT';
use File::Basename;

(my $pkg_path = __PACKAGE__) =~ s{::}{/}g;
my (undef, $directory, undef) = fileparse(
    $INC{ $pkg_path .'.pm' }
);

__PACKAGE__->config(
    INCLUDE_PATH => "$directory../templates",
);

1;
__END__
