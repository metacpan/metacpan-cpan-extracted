#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Pod::Usage;
use DBIx::Migration;

my $debug = 0;
my $help  = 0;
my ( $username, $password );

GetOptions(
    'debug'      => \$debug,
    'help|?'     => \$help,
    'password=s' => \$password,
    'username=s' => \$username
);
pod2usage(1) if ( $help || !$ARGV[0] );

unless ( $ARGV[1] ) {
    my $m = DBIx::Migration->new(
        {
            debug    => $debug,
            dsn      => $ARGV[0],
            password => $password,
            username => $username
        }
    );
    my $version = $m->version;
    if ( defined $version ) { print "Database is at version $version\n" }
    else { print "Database is not yet under DBIx::Migration management\n" }
    exit;
}

pod2usage(1) if !$ARGV[1];

my $m = DBIx::Migration->new(
    {
        debug    => $debug,
        dsn      => $ARGV[0],
        dir      => $ARGV[1],
        password => $password,
        username => $username
    }
);
$m->migrate( $ARGV[2] );

1;
__END__

=head1 NAME

dbix-migration - Seamless DB up- and downgrades

=head1 SYNOPSIS

dbix-migration.pl [options] dsn [directory version]

 Options:
   -debug       enable debug messages
   -help        display this help and exits
   -password    database password
   -username    database username

  Examples:
    dbix-migration.pl dbi:SQLite:/some/dir/myapp.db
    dbix-migration.pl dbi:SQLite:/some/dir/myapp.db/some/dir
    dbix-migration.pl dbi:SQLite:/some/dir/myapp.db/some/dir 23

=head1 DESCRIPTION

Seamless DB up- and downgrades.

=head1 SEE ALSO

L<DBIx::Migration>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 COPYRIGHT

Copyright 2004-2005 Sebastian Riedel. All rights reserved.

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

