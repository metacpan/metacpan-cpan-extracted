# NAME

Dependencio - Simple utility to find perl modules dependencies recursively in your project.

# SYNOPSIS
cd yourawesemeproject
now run...
dependencio

this will read recursively into your project evaluating all the modules, if they are not installed, dependecio will warn you.
if you run 'dependencio -c', automagically will try to install the missing modules via cpanm

# DESCRIPTION

This module aims to autodetect all the module dependencies recursively in a project.
To be used as standalone application to be part of your continous integration to deploy.
Could be added the execution of Dependencio as a post hook git, jenkins, etc.

## EXPORT

checkDeps

# AUTHOR

dani remeseiro, &lt;jipipayo at cpan dot org&lt;gt>

# COPYRIGHT AND LICENSE

Copyright (C) 2015 by dani remeseiro
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.
