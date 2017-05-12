use Apache::Session::DBI;
use DBI;
use Benchmark;

use vars qw($dbh $id);

$dbh = DBI->connect('dbi:mysql:sessions', 'test', '', {RaiseError => 1});


sub new_session {
    my $s;
    tie %$s, 'Apache::Session::DBI', undef, {Handle => $dbh};
}

sub get_id {
    my $s;
    tie %$s, 'Apache::Session::DBI', undef, {Handle => $dbh};
    
    $id = $s->{_session_id};
}

sub reopen {
    my $s;
    tie %$s, 'Apache::Session::DBI', $id, {Handle => $dbh};
}

sub openread {
    my $s;
    tie %$s, 'Apache::Session::DBI', $id, {Handle => $dbh};
    
    my $sid = $s->{_session_id};
}

sub openwrite {
    my $s;
    tie %$s, 'Apache::Session::DBI', $id, {Handle => $dbh};

    $s->{foo} = 'bar';
}

&get_id;

timethese(10000, {
    'New' => \&new_session,
    'Reopen' => \&reopen,
    'Read Old' => \&openread,
    'Write Old' => \&openwrite,
});
