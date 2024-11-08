# FastPack application (web client)
package Data::FastPack::App;
use strict;
use warnings;

use feature ":all";
our $VERSION="v0.1.0";


use Data::JPack;

use File::ShareDir ":ALL";

use File::Path qw<make_path>;
use File::Basename qw<dirname>;

my $share_dir=dist_dir "Data-FastPack";


sub js_paths {
  grep !/test/, <$share_dir/js/*>;
}

sub add_to_jpack_container {
  my $html_container=shift;
  # Given the html_container encode the js and resource files into the next available position
  #
  my $jpack=Data::JPack->new(jpack_compression=>"DEFLATE", jpack_type=>"app", html_container=>$html_container);


  $jpack->set_prefix("app/jpack/main");

  my @outputs;
  for(js_paths){
    my $out_path=$jpack->next_file_name();

    say STDERR "OUTPUT PATH IS $out_path";

    my $data=do {
      local $/=undef;
      open my $fh,"<", $_;
      <$fh>
    };
    $data=$jpack->encode($data);


    my $dir=dirname $out_path;
    make_path $dir;
    open my $fh, ">", $out_path;
    print $fh $data;
    push @outputs, $out_path;
  }
  @outputs;
}

1;
