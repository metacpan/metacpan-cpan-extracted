package App::HTRender;

use 5.010;
use strict;
use warnings;

our $VERSION = '1.00';


# Preloaded methods go here.

1;
__END__

=head1 NAME

App::HTRender - tool to work with HTML::Template templates from the command line

=head1 SYNOPSIS

 ht_render --template=template.html --values=values.json --output=output.html [--config=config.json] 
 
 # Render template tmpl.html with values from values.json into webpage.html
 # You can use single-letter shortcuts as well as the full option names
 ht_render -t tmpl.html -V values.json -o webpage.html
 
 # Same as above, but configure the template object using values from 
 # the config.json file
 ht_render -t tmpl.html -V values.json -o webpage.html --config=config.json
  

=head1 DESCRIPTION

App::HTRender is a tool for working with HTML::Template templates from the 
command line.  It is designed to be useful during the development process to 
design templates and model the data to drive them, as well as a diagnostic tool
to help troubleshoot problems with templates and/or the data used with them.

=head1 OPTIONS

=head2 --template

The path the template file.  The template file is a normal HTML::Template file.

=head2 --values

The path to the values file.  The values file should describe a JSON object, 
which will be parsed into a Perl hash.  The keys of the hash should correspond 
to variables in the template file.

The single letter shortcut for --values is -V to distinguish it from --version.

=head2 --output

The path to the output file.  The values will be substituted into the template 
and the resulting HTML will be written to this file.

=head2 --config

An optional config file.  Normally the HTML::Template object is created with 
a couple of options already set by default:

 die_on_bad_params => 0
 loop_context_vars => 1

These defaults may not match the application's needs, however, so you can 
specify a config file to override these HTML::Template config options or 
set your own.  Like the values file, the config file should define a JSON 
object, which will be parsed into a Perl hash and passed to the HTML::Template 
object at creation time.

For example, if your template requires all of its values to use the HTML 
escaping scheme, and you wish to disable including other template files, you 
can specify a JSON object with requisite HTML::Template options:

 {
 	"default_escape" : "html",
 	"no_includes": 1
 } 
 
=head2 --version

Displays the application version.

=head1 SEE ALSO

L<HTML::Template>, L<JSON::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Andrew Johnson.

This library is free software; you can redistribute it and/or modify it under 
the terms of the Artistic License 2.0.  See the included LICENSE file for 
details.

=head1 WARRANTY

This software comes with no warranty of any kind.


=cut
