package Bundler;
use version; our $VERSION = version->declare('v0.0.30');
1;


__END__

=head1 NAME 

Bundler

=head1 Author

Alexey Melezhik / melezhik@gmail.com

=head1 SYNOPSIS

    This is CPANPLUS pluggin. Install/Remove all packages from given `bundle' file.
    Inspired by ruby bundler.

    # in cpanp client session
    /? bundle
    /bundle install # installing
    /bundle remove # removing

=head1 USAGE

    /? bundle
    /bundle [install|remove] [options]


=head1 Format of .bunlde file

every line of .bundle file have a form of <MODULE-ITEM> [<MINIMAL-VERSION>] [# comments]

=head1 MODULE-ITEM

for the explanation of the module item  see "parse_module" method documentation on http://search.cpan.org/perldoc?CPANPLUS::Backend, in common case it should
be the name of CPAN module to install/remove

=head1 MINIMAL-VERSION

Minimal version of the module to be installed, if module already installed and has version higher or equal 
to minimal, it won't be installed.

If minimal version is not set, Bundler would update module to the latest version.

If minimal version is set to '0', Bundler would only install module if it's not installed at all.

=head1 Comments

may occur and should be started with #

 # this is comment

=head1 Examples of .bundle file

update CGI module to latest version 

 CGI
 
update CGI module to latest version  if current version < 3.58

 CGI 3.58
 
install CGI module only if not installed

 CGI 0
 
install from given url path

 http://search.cpan.org/CPAN/authors/id/M/MA/MARKSTOS/CGI.pm-3.59.tar.gz

=head1 OPTIONS

 --bundle_file # path to bundle file
 --dry-run # dry-run mode - just to show what would happen and to do nothing


=head1 ACKNOWLEDGMENTS

 to the authors of ruby bundler
 to Chris Williams - the author of the CPANPLUS

=head1 SEE ALSO

 http://search.cpan.org/perldoc?CPANPLUS 
 http://gembundler.com/
 
 
