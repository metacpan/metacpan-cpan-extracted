package CPAN::Repo;
our $VERSION = '0.0.5';
1;

__END__

=head1 NAME

CPAN::Repo

=head1 SYNOPSIS

CPAN server for private cpan modules.


=head1 Usage

Well, it's very simple!
 
 1. make repository
 mkdir -p repo-root/repo-one/
 
 2. copy distributives 
 cp Foo-v0.0.1.tar.gz Bar-v0.0.2 repo-root/repo-one/
 
 3. create cpan index 
 echo Foo-v0.0.1.tar.gz > repo-root/repo-one/packages.txt
 echo Bar-v0.0.2 repo-one >> repo-root/repo-one/packages.txt
  
 3. start cpan repo server
 cpan_repo repo-root/
 
 4. now all the modules are available to install via cpan plus client!
 cpanp
 %cpanp /cs --add http://<cpan-repo-server>/repo-one/
 %cpanp x
 %cpanp i Foo

 * <cpan-repo-server> - IP of CPAN::Repo server, if you run cpanp client on the same host where
 CPAN::Repo server run it could be 127.0.0.1
 

=head1 Features

 - simple maintenance - thanks to the author of CPANPLUS, custom sources idea is cool! for details see
 'CUSTOM MODULE SOURCES' section in http://search.cpan.org/perldoc?CPANPLUS::Backend
 - multiply cpan repos accessible via one cpan server, see datails below
 - index merge, see datails below
 - no need to care about global cpan mirrors synchronization as with CPAN::Mini, because in cpanplus
 they exist separately (as custom sources)


=head1 Multiple cpan repositoies

As with example above only one repository with private cpan modules was addes. What if you want more?
It's okay, just create as many as you wish, cpan repo server will care about further details:

 1 making repositories and copy distribuitves
 mkdir -p repo-root/repo-two/
 mkdir -p repo-root/repo-three/
 cp Baz-v0.0.1 repo-root/repo-two/
 cp Bazz-v0.0.1 repo-root/repo-three/

 # generate index 
 echo Baz-v0.0.1.tar.gz > repo-root/repo-two/packages.txt
 echo Bazz-v0.0.1 > repo-root/repo-three/packages.txt
 
 
 2 re-setup cpanp client
 cpanp
 %cpanp /cs --remove http://<cpan-repo-server>/repo/
 %cpanp /cs --add http://<cpan-repo-server>/repo-one/repo-two/repo-three/
 %cpanp x
 
 3 all three repos are available via cpan server!
 
 cpanp -i Foo
 cpanp -i Baz
 cpanp -i Bazz

The common approach with multiple repositories is to setup custom sources as:

 http://<cpan-repo-server>/repo/repo2/repo-<i>/../

where I<repo, repo2, repo-<i>, ...> are names of repositories.


=head1 Index merge 

It's time to say about one great feature of CPAN::Repo called 'index merge'. 
Let's say we have module called 'Foo' of the version 'v0.0.2' in repository named 'repo-one' and module 
with the same name of the version 'v0.0.1' in another repository called 'repo-two', what happen 
if one add both repositories to cpan server as with following custom source url:

 http://<cpan-repo-server>/repo-one/repo-two

As it's seen from the url 'repo-one' is added first and 'repo-two' is added last.
'Index merge' means that repositorie's B<indexes> added to cpan server are B<merged in order>.

The modules from repository which added last will win and override versions of their "predecessors" . 
In the example above, one will get final version v0.0.1 of module Foo, all this logic is handled by cpan server 
and called 'index merge'.


'Index merge' is great possibility for:

 * Delevloper's "sandbox" cpan repos which may be merged with "trunk" cpan repository during development cycle.
 * Repositories for patched modules coming from official cpan mirrors.
 * Repositoris with "frozen" versions of modules, allow to tag versions of your cpan modules and avoid installing 
 last version of module when it's inadmissible.
 
 The main idea here is an isolation of your private cpan modules and capability to merge arbitrary cpan repositories
 during deploment process.


=head1 Limitations 

 - repositories names should follow pattern /a-zA-Z_-/
 - nested repositories are not supported, it means repo_root/foo/bar/ as repository place won't work, the same
 for distributives - they should be placed in the repository directory as plain list without subdirectroies
 - packages.txt - are custom source indexes should be kept actual and mantained by someone else, CPAN::Repo only
 provide read access for repository distributives and indexes and does proper index merge.


=head1 Author

Alexey Melezhik / melezhik@gmail.com

=head1 See also

http://search.cpan.org/dist/CPANPLUS/
http://search.cpan.org/perldoc?CPAN::Mini

