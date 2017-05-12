package CPANPLUS::Shell::Default::Plugins::Repo;
our $VERSION = '0.0.3';
use strict;
our %handlers;

my $cache_file = "$ENV{HOME}/.cpan-repo";

sub plugins { ( repo => 'repo' ) }

sub repo { 

 # /helloworld bob --nofoo --bar=2 joe
    
 my $class   = shift;    # CPANPLUS::Shell::Default::Plugins::HW
 my $shell   = shift;    # CPANPLUS::Shell::Default object
 my $cb      = shift;    # CPANPLUS::Backend object
 my $cmd     = shift;    # 'helloworld'
 my $input   = shift;    # 'bob joe'
 my $opts    = shift;    # { foo => 0, bar => 2 }

 my ($action,@params) = split /\s+/, $input;
         
 $action ||= 'list';  

 s/\s//g for ($action,@params);
 
 my $handler_id = $action;
 if (exists $handlers{$handler_id}){
   print "fire handler : $handler_id \n";
   $handlers{$handler_id}->($cb,@params),
 }else{
   print "handler [$handler_id] not found \n";
 }
 
 return;
}



$handlers{'list'} = sub {
            my $cb = shift;
	    if(my $repo_server = load_repo_server_from_file()){
	      print "[fetching repos from $repo_server]\n";
 	      system ("curl -s $repo_server/list/");
	      print "\n";
	    }else{
	      print "CPAN::Repo server not set; use /repo server <url> to setup it\n"
	    }
	    
	    
	    
};

$handlers{'set'} = sub {
	    my $cb = shift;
	    my @repos = @_;
	    commit_repos_to_cs($cb,@repos);
	    return;
};


$handlers{'server'} = sub {
            my $cb = shift;
            my $uri = shift; 
	    save_repo_server_to_file($uri);
	    return;
};


sub repo_help { 

    return <<MESSAGE;

    # Provides interface to CPAN::Repo server.
    # See http://search.cpan.org/perldoc?CPAN::Repo for details.
    
    /? repo
    /repo server <url> # setup CPAN::Repo server
    /repo list # list available repos from CPAN::Repo server
    /repo set <repo-id> <repo_id> ... # setup repos and save it as custom sources
    
    
MESSAGE

}

sub load_repo_server_from_file {

 `touch $cache_file`;
 my $uri;
 print "load $cache_file ...\n";
 
 if(open F, $cache_file){
   while (my $l = <F>){
    chomp $l; s/\s//g for $l;
    $l=~/\S+/ or next;
    $uri = $l;
    last;
   }
   close F;
 }else{
  print "error : cannot open file [$cache_file] : $!\n";
 }
 return $uri;
}

sub save_repo_server_to_file {
 my $uri = shift;
 `touch $cache_file`;
 if(open F, '>', $cache_file){
   print F $uri, "\n"; close F;
   print "save $uri to $cache_file\n";       
 }else{
  print "error : cannot open repo file [$cache_file] to write : $!\n";
 }
 return;
}

sub commit_repos_to_cs {

 my $cb = shift;
 my @repos = @_;

 print "commit repos to custom source file ...\n";
 
 if (@repos){
    my $uri = load_repo_server_from_file();
    my %cs = $cb->list_custom_sources;
    for my $cs (values %cs){
	$cb->remove_custom_source( uri => $cs, verbose => 1 );
    }
  $uri = "http://" unless $uri=~/^http:\/\//;    
  $uri.='/'.(join '/', @repos);
  $cb->add_custom_source( uri => $uri, verbose => 1 );
  $cb->update_custom_source();
 }else{
  print "warn : repos list is empty, nothing to do with it\n";
 }
 return; 
}


1;

__END__

=head1 NAME 

CPANPLUS::Shell::Default::Plugins::Repo

=head1 Author

Alexey Melezhik / melezhik@gmail.com

=head1 SYNOPSIS

This is CPANPLUS plugin. Provides interface to CPAN::Repo. 
See http://search.cpan.org/perldoc?CPAN::Repo for details about CPAN::Repo server.
    
    # in cpanp client session
    /? repo
    /repo server <url> # setup CPAN::Repo server
    /repo list # list available repos from CPAN::Repo server
    /repo set <repo-id> <repo_id> ... # setup repos and save it as custom sources


=head1 See Also

http://search.cpan.org/perldoc?CPAN::Repo
