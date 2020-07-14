package App::Acmeman::Apache::Layout::suse;
use strict;
use warnings;
use Carp;
use parent 'App::Acmeman::Apache::Layout';

our $PRIORITY = 40;

sub new {
    my $class = shift;
    my $ap = shift;

    if ($ap->server_config eq '/etc/apache2/httpd.conf'
	&& ! -f '/etc/apache2/apache2.conf') {
	return $class->SUPER::new($ap,
			incdir => '/etc/apache2/conf.d',
			restart_command => '/usr/sbin/service httpd restart'
	       );
    }
}

1;
