# JPack application (web client)
package Data::JPack::App;
our $VERSION="v0.1.0";

use strict;
use warnings;

use Data::JPack;

use File::ShareDir ":ALL";
my $share_dir=dist_dir "Data-JPack";

# returns a list of input paths to site output relative pairs suitable for builing a webbase client
sub resource_map {
  say STDERR "In resouce map";
  my @inputs=_bootstrap();

  #<$share_dir/js/*>;
  #
  my @outputs;

  # put bootstrap into 0/0
  push @outputs, "app/jpack/boot/00000000000000000000000000000000/00000000000000000000000000000000.jpack";

  map {($inputs[$_],$outputs[$_])} 0..$#inputs;
}

# Javascript resources absolute paths. These file are are to be copied into target output
sub js_paths {
  #use feature ":all";
  #say STDERR "Share dir is $share_dir";
  grep !/pako/, <$share_dir/js/*>;
}


# Encode the bootstrapping segment into a tempfile, return the path to this temp file
# This file contains the pako.js module as a chunk. Also prefixed with the
# chunkloader and worker pool contents
#
my $dir;
sub  _bootstrap {

    use File::Temp qw<tempdir>;
    $dir//=tempdir(CLEANUP=>1);

    my $data_file="$dir/bootstrap.jpack";

    return $data_file if -e $data_file;

    print STDERR "Regenerating  JPack bootstrap file\n";

    # If the file doesn't exist, create it
    my @pako=grep /pako/, <$share_dir/js/*>;


    my $packer=Data::JPack->new(jpack_compression=>undef, jpack_type=>"boot");

    my $pako= do {
        local $/=undef;
        open my $fh, "<", $pako[0]; #sys_path_src "client/components/jpack/pako.min.js";
        <$fh>;
    };

    # Process the contents of the chunkloader and workerpool scripts
    my @js=js_paths;
    my $prefix="";
    for(@js){
      $prefix.=do { open my $fh, "<", $_; local $/; <$fh>};
      $prefix.="\n";
    }

    # Pre encode pako into jpack format
    my $encoded="if(window.chunkLoader.booted){\n";
    $encoded.=$packer->encode($pako);
    $encoded.="\n }";

    #do {
    open my $of, ">", $data_file; #"site/data/jpack/boot.jpack";

    print $of $prefix;
    print $of $encoded;

      #};
    $data_file;
}


1;
