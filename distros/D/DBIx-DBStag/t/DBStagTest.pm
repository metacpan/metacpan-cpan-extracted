package DBStagTest;
use strict;
use base qw(Exporter);
use DBIx::DBStag;

BEGIN {
    use Test;
    if (0) {
        plan tests=>1;
        skip(1, 1);
        exit 0;
    }
    # this file defines sub connect_args()
    unless (defined(do 'db.config')) {
        die $@ if $@;
        die "Could not reade db.config: $!\n";
    }
}

use vars qw(@EXPORT);

our $driver;
#our $dbname = "dbistagtest";
#our $testdb = "dbi:Pg:dbname=$dbname;host=localhost";


@EXPORT = qw(connect_to_cleandb dbh drop cvtddl);


sub dbh {
    # this file defines sub connect_args()
#    unless (defined(do 'db.config')) {
#        die $@ if $@;
#        die "Could not reade db.config: $!\n";
#    }
    my $dbh;
    my @conn = connect_args();

    eval {
        $dbh = DBIx::DBStag->connect(@conn);    
    };
    if (!$dbh) {
        printf STDERR "COULD NOT CONNECT USING DBI->connect(@conn)\n\n";
        die;
    }
    $driver = $dbh->{_driver};
    $dbh;
}

*connect_to_cleandb = \&dbh;

sub ddl {
    my $dbh = dbh();
    my $ddl = shift;
    
}

sub cvtddl {
    my $ddl = shift;
    if ($driver eq 'mysql') {
        $ddl =~ s/ serial / INTEGER AUTO_INCREMENT /i;
    }
    return $ddl;
}

sub alltbl {
    qw(person2address person address );
}

sub drop {
#    unless (defined(do 'db.config')) {
#        die $@ if $@;
#        die "Could not reade db.config: $!\n";
#    }
    # this sub is defined in config file
    my $cmd = recreate_cmd();
    $cmd =~ s/\;/\;sleep 2\;/g;
#    if (system($cmd)) {
#        # allowed to fail first time...
#        # (pg sometimes won't let you create a db immediately after dropping)
#        sleep(2);
#    }
    if (system($cmd)) {
        # must pass 2nd time
	print STDERR "PROBLEM recreating using: $cmd\n";
    }
}

sub zdrop {
#    my @t = @_;
    my @t = alltbl;
    my $dbh = dbh();
    my %created = ();
    if (1) {
	use DBIx::DBSchema;
	my $s = DBIx::DBSchema->new_native($dbh->dbh);
	use Data::Dumper;
	%created = map {$_=>1} $s->tables;
    }
    
#    foreach (@t) {
#        eval {
#            $dbh->do("DROP TABLE $_");
#        };
    
    foreach (@t) {
	if ($created{$_}) {
	    eval {
		$dbh->do("DROP TABLE $_");
	    };
	}
    }
    $dbh->disconnect;
}

1;
