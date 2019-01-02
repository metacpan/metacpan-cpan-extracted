package App::Glacier::Directory::GDBM;
use parent 'App::Glacier::DB::GDBM';

sub configtest {
    my ($class, $cfg, @path) = @_;
    unless ($cfg->isset(@path, 'file')) {
	$cfg->set(@path, 'file', '/var/lib/glacier/inv/$vault.db');
    }
    $class->SUPER::configtest($cfg, @path);
}

1;
