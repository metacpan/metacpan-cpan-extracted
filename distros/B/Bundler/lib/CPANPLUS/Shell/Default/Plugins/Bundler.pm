package CPANPLUS::Shell::Default::Plugins::Bundler;
use CPAN::Version;
use strict;
our %handlers;

### return command => method mapping
sub plugins { ( bundle => 'bnd' ) }

### method called when the command '/myplugin1' is issued
sub bnd { 

 # /helloworld bob --nofoo --bar=2 joe
    
 my $class   = shift;    # CPANPLUS::Shell::Default::Plugins::HW
 my $shell   = shift;    # CPANPLUS::Shell::Default object
 my $cb      = shift;    # CPANPLUS::Backend object
 my $cmd     = shift;    # 'helloworld'
 my $input   = shift;    # 'bob joe'
 my $opts    = shift;    # { foo => 0, bar => 2 }

 my $handler_id;
 unless ($input){
  $handler_id = 'install::dry-run';
 }else{
  s/\s//g for $input;
  my $mode = $opts->{'dry-run'} ? 'dry-run' : 'real';
  $handler_id = $input.'::'.$mode;
 }        
 if (exists $handlers{$handler_id}){
   print "fire handler : $handler_id \n";
   _bundle_file_itterator(
      $opts->{'bundle_file'} || "$ENV{PWD}/.bundle",
      $handlers{$handler_id},
      $cb
   );
 }else{
   print "handler [$handler_id] not found \n";
 }
 
 return;
}


sub _mod_is_uptodate {
 my $m = shift;
 (CPAN::Version->vcmp($m->package_version,$m->installed_version)>=0) ? 0 : 1
}

sub _mod_need_upgrade {
 my $m = shift;
 my $required_version = shift;
 my $st;
 if ((defined $required_version) && defined $m->installed_version) {
  $st = CPAN::Version->vgt($required_version,$m->installed_version)
 }else{
  $st = (defined $m->installed_version) ? 0 : 1;
 }
 return $st;
}

sub _parse_module_item_line {
 my $line = shift;
 my $cb = shift;
 my ($mod_name,$v) = split /\s+/, $line;
 s/\s//g for ($mod_name,$v);
 my $m_obj = $cb->parse_module(module => $mod_name);
 if ($m_obj){
  $v || $m_obj->package_version unless defined $v;
 }
 return ($mod_name,$v,$m_obj);
}



$handlers{'install::dry-run'} = sub {
	    my $line = shift;
	    my $cb = shift;
	    my ($mod_name,$v,$m) = _parse_module_item_line($line,$cb);
	    my $info; my $status;
	     if ($m){
	       if ($m->installed_version){
	          if (_mod_is_uptodate($m)){
	            $info = 'is uptodate';
	            $status = 'SKIP';
	           }elsif(_mod_need_upgrade($m,$v)){
	            $info = "UPDATE from version ".($m->installed_version)." to version : ".($m->package_version);
	            $status = 'OK';
	           }else{
	            $info = "KEEP current version installed version ".($m->installed_version).' is higher or equal than required - '.$v;
	            $status = 'SKIP';
	           }
	       }else{
	        $info = "INSTALL at version : ".($m->package_version);
	        $status = 'OK';
	       }
	     }else{
	      $status = 'FAIL';
	      $info = "[$mod_name] - not found!";
	     }
	     print "[$status] - [$line] - $info \n";
};

$handlers{'install::real'} = sub {
	    my $line = shift;
	    my $cb = shift;
	    my ($mod_name,$v,$m) = _parse_module_item_line($line,$cb);
	    if ($m){
	     if ((! _mod_is_uptodate($m)) && _mod_need_upgrade($m,$v)){
	 	 $cb->install(modules=>[$mod_name]);
	      }
	    }else{
 	        print "[FAIL] - [$line] - $mod_name not found! \n";
	    }

};

$handlers{'remove::dry-run'} = sub {
	    my $line = shift;
	    my $cb = shift;
	    my ($mod_name,$v,$m) = _parse_module_item_line($line,$cb);
	    if ($m){
	    	if ($m->installed_version){
	    	    print "[OK] - [$line] - remove $mod_name \n";
	        }else{
	             print "[SKIP] - [$line] - $mod_name is not installed \n";    
	        }
	    }else{
	        print "[FAIL] - [$line] - $mod_name not found! \n";
	    }
};

$handlers{'remove::real'} = sub {
	    my $line = shift;
	    my $cb = shift;
	    my ($mod_name,$v,$m) = _parse_module_item_line($line,$cb);
	    if ($m){
	     $m->uninstall();
	    }else{
 	        print "[FAIL] - [$line] - $mod_name not found! \n";
	    }

};


### method called when the command '/? myplugin1' is issued
sub bnd_help { 

    return <<MESSAGE;

    # Install all packages form .bundle file in current directory 
    # or from file chosen by --bundle-file option.
    # See Bundler for details.

    /bundle [install|remove] [--bundle_file <path>] [--dry-run]

MESSAGE

}


sub _bundle_file_itterator {

 my $bundle_file = shift;
 my $handler = shift;
 my $cb = shift;

 if (-f $bundle_file){
  print "found bundle file [$bundle_file] \n";
    if (open BUNDLE_F, $bundle_file){
	while (my $line = <BUNDLE_F>){
	    chomp $line;
	    next if $line=~/^#\s/;
	    next if $line=~/^#/;
	    s/(.*?)#.*/$1/ for $line; # cutoff comments chunks
	    next unless $line=~/\S/;
	    $handler->($line,$cb);
	}
	close BUNDLE_F;
    }else{
	print "error: cannot open .bundle file [$bundle_file]: $!\n";
    }
 }else{
  print "error: .bundle file [$bundle_file] not found\n";
 }

}

1;

