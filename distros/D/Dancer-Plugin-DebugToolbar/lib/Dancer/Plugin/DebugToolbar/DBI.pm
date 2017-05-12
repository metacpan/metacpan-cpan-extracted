package Dancer::Plugin::DebugToolbar::DBI;

require 5.008;

use strict;
use warnings;
use DBI;

our @ISA = qw(DBI);

my $_dbi_trace;
my $_dbi_queries = [];

sub get_dbi_trace {
    return $_dbi_trace;
}

sub get_dbi_queries {
    return $_dbi_queries;
}

sub reset {
    $_dbi_trace = undef;
    $_dbi_queries = [];
}

my $_DBI_connect = \&DBI::connect;
my $_DBI_st_execute = \&DBI::st::execute;

sub DBI_connect {
    my ($drh, $dsn, $user, $pass, $attr) = @_;
    
    if (!defined $_dbi_trace) {
        $_dbi_trace = "";
        open(my $fh, ">", \$_dbi_trace);
        DBI->trace("1", $fh);
    }

    return &$_DBI_connect($drh, $dsn, $user, $pass, $attr);
}

sub DBI_st_execute {
    push @$_dbi_queries, { 'query' => $_[0]->{Statement} };
    
    return &$_DBI_st_execute(@_);
}

{ 
    no strict 'refs';
    *{"DBI::connect"} = \&DBI_connect;
    *{"DBI::st::execute"} = \&DBI_st_execute;
}

1;
