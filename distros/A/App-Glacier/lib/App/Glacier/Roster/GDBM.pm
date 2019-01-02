package App::Glacier::Roster::GDBM;
use parent 'App::Glacier::DB::GDBM';

sub configtest {
    my ($class, $cfg, @path) = @_;
    unless ($cfg->isset(@path, 'file')) {
	$cfg->set(@path, 'file', '/var/lib/glacier/job.db');
    }
    $class->SUPER::configtest($cfg, @path);
}

1;
