# JPack application (web client)
package Data::JPack::App;
our $VERSION="v0.1.2";

use v5.36;

use Data::JPack;
use Template::Plexsite::URLTable;
use Template::Plexsite;

use File::ShareDir ":ALL";
my $share_dir=dist_dir "Data-JPack";

# returns a list of input paths to site output relative pairs suitable for builing a JPack app
##############################################################################################################
# sub resource_map {                                                                                         #
#   my @inputs=_bootstrap();                                                                                 #
#                                                                                                            #
#   my @outputs;                                                                                             #
#                                                                                                            #
#   # put bootstrap into 0/0                                                                                 #
#   push @outputs, "app/jpack/boot/00000000000000000000000000000000/00000000000000000000000000000000.jpack"; #
#                                                                                                            #
#   map {($inputs[$_],$outputs[$_])} 0..$#inputs;                                                            #
# }                                                                                                          #
#                                                                                                            #
##############################################################################################################
# Javascript resources absolute paths. These file are are to be copied into target output
sub js_paths {
  #use feature ":all";
  grep !/pako/, <$share_dir/js/*>;
}


# Encode the source files for JPack App into the bootstrapping segment into a
# tempfile. Return the path to this temp file.
# This file contains the pako.js module as a chunk. Also prefixed with the
# chunkloader and worker pool contents
#
my $dir;
my $out_bs="app/jpack/boot/00000000000000000000000000000000/00000000000000000000000000000000.jpack";
sub  _bootstrap {

    use File::Temp qw<tempdir>;
    $dir//=tempdir(CLEANUP=>1);

    my $data_file="$dir/bootstrap.jpack";

    return ($data_file, $out_bs) if -e $data_file;

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

    $prefix=Data::JPack::minify_js $prefix;

    # Pre encode pako into jpack format
    my $encoded="if(window.chunkLoader.booted){\n";
    $encoded.=$packer->encode($pako);
    $encoded.="\n }";

    #do {
    open my $of, ">", $data_file; #"site/data/jpack/boot.jpack";

    print $of $prefix;
    print $of $encoded;

      #};
    ($data_file, $out_bs);
}

# API

# An application that wants to extend the JPack app template needs to implement this 
#
sub template_path {
    use File::ShareDir ":ALL";
    my $share=dist_dir "Data-JPack";
    my $parent_root= "$share";

    #Return the root relative path and the root
    ("app.plt", $share);
    
}

# An application that wants to extend the this base applcation should implement this subroutine
# It takes 
sub add_to_jpack_container {
  # Return the paths to the encoded jpack files
}


# Wrapper around a sub to localize changes to the urltable object. 
# Adjusts the URL table to load resources relative to a new src.
# executes the sub with new source and then resets
# Optional package name to use for calling template path
sub localize_table {
  my (undef, $t, $sub, $package)=@_;
  #say STDERR "LOCALISING TABLE in package:", __PACKAGE__;
  return unless $t isa Template::Plexsite;

  my $html_container=$t->sys_path_build;
  #my $root=$t->sys_path_src;
  
  my $caller=$package//caller;
  my (undef, $root)=$caller->template_path;
  #say STDERR "LOCALISING TABLE to $root";

  my $new_table=Template::Plexsite::URLTable->new(src=>$root, html_root=>$html_container, locale=>$t->args->{locale});


  # Link to internal table from template (so resources share the same namespace)
  $new_table->table = $t->args->{table}->table;


  # Use the magical perl local
  #local $t->table=$new_table;
  #$sub->($t);

  my $prev_table=$t->table;

  use feature "try";
  no warnings "experimental";
  try {
    $t->table=$new_table;
    $sub->($t);
  }
  catch($e){
    
  }
  $t->table=$prev_table;
}


# ==========
# Application (routes to middleware)
use Object::Pad;
class Data::JPack::App;

field $_dynamic;    

BUILD{
 
  #$_dynamic="site";

}

sub app {
  # Only load middleware if needed.
  require uSAC::HTTP::Middleware::Static;
  sub {

    my $parent=shift;
    my %options;

    my $_dynamic="site";
    # Add routes for jpack applciations
    $parent->add([qw[GET HEAD]], "app"
      => uSAC::HTTP::Middleware::Static::uhm_static_root(
        prefix=>"/",
        roots=> [$_dynamic],
      ));

    # For external libs...
    $parent->add([qw[GET HEAD]], "lib"
      => uSAC::HTTP::Middleware::Static::uhm_static_root(
        prefix=>"/",
        roots=> [$_dynamic],
      ));

  }
}

\&app;
