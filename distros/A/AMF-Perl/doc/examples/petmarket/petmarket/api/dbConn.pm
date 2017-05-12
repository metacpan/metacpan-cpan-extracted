package petmarket::api::dbConn;


# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

#This is server side for the Macromedia's Petmarket example.
#See http://www.simonf.com/amfperl for more information.

use warnings;
no warnings "uninitialized";
use strict;

my $dbhost = "localhost";
my $dbname = "database";
my $dbuser = "user";
my $dbpass = "password";

use DBI;
use AMF::Perl::Sql::MysqlRecordSet;

sub new
{
    my ($proto) = @_;
    my $self = {};
    bless $self, $proto;

    my $dbh = DBI->connect("DBI:mysql:host=$dbhost:db=$dbname","$dbuser","$dbpass",{ PrintError=>1, RaiseError=>1 }) or die "Unable to connect: " . $DBI::errstr . "\n";

    $self->dbh($dbh);

    my $recordset = AMF::Perl::Sql::MysqlRecordSet->new($dbh);
    $self->recordset($recordset);

    return $self;
}


sub recordset
{
    my ($self, $val) = @_;
    $self->{recordset} = $val if $val;
    return $self->{recordset};
}

sub dbh
{
    my ($self, $val) = @_;
    $self->{dbh} = $val if $val;
    return $self->{dbh};
}

1;
