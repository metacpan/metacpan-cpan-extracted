package App::Acmeman::Apache::Layout::rh;
use strict;
use warnings;
use Carp;
use parent 'App::Acmeman::Apache::Layout';

our $PRIORITY = 30;

sub new {
    my $class = shift;
    my $ap = shift;

    if ($ap->server_config eq '/etc/httpd/conf/httpd.conf') {
	return $class->SUPER::new($ap,
			  incdir => '/etc/httpd/conf.d',
			  restart_command => '/usr/sbin/service httpd restart'
	       );
    }
}

1;
