#!/usr/bin/perl -w
use strict;
use DBI;
use My::App;

=head1 USAGE

This program demonstrates how to change code in the database
(and thus in all running servers)
from an external script.

=cut

My::App->startup('dbi:SQLite:dbname=db/seed.sqlite',undef,undef,{RaiseError => 1});

My::App->redefine_sub('hello',<<'CODE');

    my ($cgi,$res) = @_;
    $res->{code} = 200;
    delete $res->{template};
    
    $res->{body} = <<HTML;
<html>
<body>
<h2>Welcome to $package, in version 12</h2>
</body>
</html>
HTML

+{}

CODE

print "Please reload your browser ;)";