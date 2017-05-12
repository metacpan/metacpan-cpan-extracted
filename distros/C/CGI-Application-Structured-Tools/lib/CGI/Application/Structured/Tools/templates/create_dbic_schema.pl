#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw/$Bin/;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;
use Config::Auto;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";

$| = 1;

my $config = Config::Auto::parse( 
	File::Spec->catfile("..","config","config.pl"), format => "perl" 
	);


make_schema_at(
        '<tmpl_var main_module>::DB',
        { debug => 1,relationships => 1, use_namespaces => 1, 
          dump_directory => File::Spec->catdir("$Bin","..","lib" )
        },
        [ $config->{db_dsn}, $config->{db_user}, $config->{db_pw} ],
);

=head1 NAME

Template DBIC schema generator for CGI::Application::Structured apps.

=cut 


=head1 SYNOPSIS

	~/dev/My-App1$ perl script/create_dbic_schema.pl 
	Dumping manual schema for DB to directory /home/gordon/dev/MyApp1/lib/MyApp1/DB ...
	Schema dump completed.


The generated files, using the example database would look like this:

    ~/dev/MyApp1$ find lib/MyApp1/ | grep DB
    lib/MyApp1/DB
    lib/MyApp1/DB/Result
    lib/MyApp1/DB/Result/Orders.pm
    lib/MyApp1/DB/Result/Customer.pm
    lib/MyApp1/DB.pm


=cut


=head1 AUTHOR


=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

