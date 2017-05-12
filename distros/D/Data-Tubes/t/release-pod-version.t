
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use Test::More tests => 1;
use Data::Tubes;

(my $filename = $INC{'Data/Tubes.pm'}) =~ s{pm$}{pod};

my $pod_version;

{
   open my $fh, '<', $filename
     or BAIL_OUT "can't open '$filename'";
   binmode $fh, ':raw';
   local $/;
   my $module_text = <$fh>;
   ($pod_version) = $module_text =~ m{
      ^This\ document\ describes\ Data::Tubes\ version\ (.*?)\.$
   }mxs;
}

is $pod_version, $Data::Tubes::VERSION, 'version in POD';
