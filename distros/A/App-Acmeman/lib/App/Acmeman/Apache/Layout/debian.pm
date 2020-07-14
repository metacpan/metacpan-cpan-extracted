package App::Acmeman::Apache::Layout::debian;
use strict;
use warnings;
use Carp;
use parent 'App::Acmeman::Apache::Layout';
use File::Basename;

our $PRIORITY = 20;

sub new {
    my $class = shift;
    my $ap = shift;

    if ($ap->server_config eq '/etc/apache2/apache2.conf') {
	return $class->SUPER::new($ap,
		     restart_command => '/usr/sbin/service apache2 restart'
	       );
    }
}

sub incdir {
    for my $dir ('/etc/apache2/conf-available', '/etc/apache2/conf.d') {
	return $dir if -d $dir;
    }
    carp 'none of the expected configuration directories found; falling back to /etc/apache2';
    return '/etc/apache2';
}

sub post_setup {
    my ($self,$filename) = @_;
    my $dir = dirname($filename);
    my $name = basename($filename);

    unless ($self->apache_modules('macro')) {
	system("a2enmod macro");
	$self->apache_modules(undef);
    }
    if ($dir eq '/etc/apache2/conf-available') {
	chdir('/etc/apache2/conf-enabled');
	symlink "../conf-available/$name", $name;
    }
}

1;
