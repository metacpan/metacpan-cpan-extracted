package App::DualLivedList;

use 5.005;
use strict;

our $VERSION = '0.05';

1;
__END__

=head1 NAME

App-DualLivedList - Perl extension to determine if 
                    a module is Dual-Lived.

=head1 SYNOPSIS

dual-lived <module_name> 
  
=head1 DESCRIPTION

This script provides an easy way to determine if a module
is Dual-Lived or is not Dual-Lived.

=head2 USAGE

dual-lived CGI - returns the module name, author, 
                 current version on CPAN, installed
                 version number, status as dual-lived 
                 or core or not.
                 
dual-lived /^CGI/ - returns all the modules on CPAN
                    that start with CGI.
                    
dual-lived /CGI/  - returns all the modules on CPAN
                    that have CGI somewhere in the
                    namespace.
                    
dual-lived /word/ - searchs the entire CPAN for "word"
                    or parts of that word. Note:: "entire"
                    means just that.
     For example: dual-lived /hog/ could return
     hog, ho, hog-tied, etc.
     
dual-lived /^*/   - returns all of the modules on CPAN.                                        

=head2 OPTIONS

You can use one option at a time, or you may bundle them.
For example:
             
dual-lived CPAN -f

dual-lived CPAN -df
             
dual-lived CPAN -dfu
             
To check the module list and author list:
             
dual-lived // -al

-A | --alpha   = alphabetical list of authors by CPAN_ID

-a | --authors = list of authors by module appearance

-d | --distributions = gives the distribution name from 

which the dual-lived modules derives

-f | --filestats = gives file size, line length, and word count

-l | --list      = DualLivedList of modules

-u | --update    = installs or upgrades a module

-v | --version   = App::DualLivedList version number 
                  
=head1 AUTHOR

Version 0.04 Kevin W. Henwood <Khen1950fx@yahoo.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by Kevin W. Henwood

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.5.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
