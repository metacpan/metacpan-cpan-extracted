package testutils;

use strict;
use warnings;
use 5.010;

use Expect;
use File::Temp;
use DBI;

sub initialize {
    unlink test_db();
    
    run_import(
        "01\t00000001",
        "02\t00000002",
        "03\t00000003",
        "04\t00000004",
        "05\t00000005",
    );
}

sub test_db {
    return 't/testdb';
}

sub test_password {
    return 't/testdb';
}

sub test_dbh {
    return DBI->connect("dbi:SQLite:dbname=" .testutils::test_db(),"","",{
        RaiseError => 1,
    });
}

sub run_import {
    my (@lines) = @_;
    
    my $tempfile = File::Temp->new(
        CLEANUP             => 1,
    );
    
    foreach my $line (@lines) {
        chomp($line);
        say $tempfile $line;
    }
    
    $tempfile->seek( 0, SEEK_END );
    
    run_command('import',
        file    => $tempfile->filename,
    );
}


sub run_command {
    my ($command,%params) = @_; 
    
    $params{database} ||= test_db();
    
    my @command = ($^X,'-I lib/','bin/itan',$command);
    while (my ($key,$value) = each %params) {
        push (@command,"--$key",$value);
    }
    
    my $exp = Expect->new;
    if ( defined $ENV{DEBUG_EXPECT} ) {
        $Expect::Debug        = 1;
        $Expect::Exp_Internal = 1;
        $exp->raw_pty(1);
    }
    my @output;
    $exp->log_stdout(0);
    $exp->spawn(join ' ',@command);
    $exp->expect(
        100,
        [   qr/Please \s enter \s your \s password:/x,
            sub {
                my $self = shift;
                $self->send(test_password."\n");
                exp_continue();
            },
        ],
        [   qr/(.+\n)/,
            sub {
                my $self = shift;
                push(@output,$self->match);
                exp_continue();
            },
        ],
#        [
#            qr/ERROR:\s+current\s+transaction\s+is\s+aborted/,
#            sub {}
#        ],
#        [   qr/(WARNING|ERROR):.+\n/,
#            sub {
#                my $self  = shift;
#                my $match = $self->match();
#                chomp($match);
#                push @log, $match;
#                exp_continue();
#                }
#
#        ],
    );
    
    $exp->soft_close();
    
    return @output;
}
1;