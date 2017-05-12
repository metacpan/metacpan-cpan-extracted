#!perl

use strict;
use warnings;

use lib 'lib';
use CGI::PSGI;
use Time::Duration;
use Number::Format qw(:subs);
use Proc::ProcessTable;
use Data::Google::Visualization::DataTable;
use Data::Google::Visualization::DataSource;

sub {
    my $env = shift;

    # Local addresses only!
    my $q = CGI::PSGI->new($env);

    # Step 1: Create the container based on the HTTP request
    my $datasource = Data::Google::Visualization::DataSource->new({
        tqx => ($q->param('tqx') || undef),
        xda => ($q->header('X-DataSource-Auth') || undef),
    });

    $datasource->add_message({
        type => 'warning',
        reason => 'other',
        message => 'Flux capacitor',
        detailed_message => 'Flux capacitor just isnae working',
    });

    my $datatable = Data::Google::Visualization::DataTable->new();
    $datatable->add_columns(
        { id => 'pid',   label => "PID",     type => 'number', },
        { id => 'uid',   label => "User",    type => 'number', },
        { id => 'size',  label => "Size",    type => 'number', },
        { id => 'cmd',   label => "Command", type => 'string', },
        { id => 'since', label => "Since",   type => 'datetime' },
    );

    foreach my $p (@{ Proc::ProcessTable->new()->table() }) {

        # Only show processes for this user
        next unless $p->{'uid'} == $>;

        $datatable->add_rows({
            pid   => $p->{'pid'},
            uid   => { v => $p->{'uid'},  f => (getpwuid( $p->{'uid'} ))[0] },
            size  => { v => $p->{'size'}, f => format_bytes( $p->{'size'} ) },
            cmd   => $p->{'cmndline'},
            since => { v => $p->{'start'}, f => ago( time - $p->{'start'} ) }
        });
    }

    # Step 2: Add data
    $datasource->datatable( $datatable );

    SERIALIZE:
    # Step 3: Show the user...
    my ( $headers, $body ) = $datasource->serialize;
    my %headers = map { @$_ } @$headers;
    return [ $q->psgi_header(\%headers), [ $body ] ];
}
