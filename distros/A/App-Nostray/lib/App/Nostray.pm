package App::Nostray;
$App::Nostray::VERSION = '1.01';
use File::Next;
use Getopt::Std;
use JavaScript::V8;
use JSON;
use File::Slurp;

=head1 NAME

App::Nostray - Detect and eliminate stray commas in Javascript source files

=head1 SYNOPSIS

 usage: nostray [-v|h|n|R] file|startdir
     -v  be verbose
     -h  print this help
     -m  modify source files
     -R  print all jshint reports
     
=cut

=head1 AUTHORS

 Michael Langner, mila at cpan dot org

=head1 THANKS

This script uses an embedded copy of
JSHINT (L<http://www.jshint.com/about/>) to do all the javascript
parsing and error detection.

=head1 COPYRIGHT & LICENSE

Copyright 2014 Michael Langner, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.

=cut

1; # track-id: 3a59124cfcc7ce26274174c962094a20
