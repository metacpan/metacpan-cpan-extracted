package App::Acmeman::Apache::Layout;

use strict;
use warnings;
use Carp;
use File::Basename;

require Exporter;
our @ISA = qw(Exporter);

my %apache_layout_tab = (
    slackware => {
	_test => sub { -d '/etc/httpd/extra' },
	_config_file => '/etc/httpd/httpd.conf',
	_incdir => '/etc/httpd/extra',
	_restart => '/etc/rc.d/rc.httpd restart'
    },
    debian =>    {
	_config_file  => '/etc/apache2/apache2.conf',
	_incdir  => sub {
	    for my $dir ('/etc/apache2/conf-available',
			 '/etc/apache2/conf.d') {
		return $dir if -d $dir;
	    }
	    carp 'none of the expected configuration directories found; falling back to /etc/apache2';
	    return '/etc/apache2';
	},
	_restart => '/usr/sbin/service apache2 restart',
	_post_setup => sub {
	    my ($filename) = @_;
	    my $dir = dirname($filename);
	    my $name = basename($filename);
	    if ($dir eq '/etc/apache2/conf-available') {
		chdir('/etc/apache2/conf-enabled');
		symlink "../conf-available/$name", $name;
	    }
	}
    },
    rh => {
	_config_file => '/etc/httpd/conf/httpd.conf',
	_incdir => '/etc/httpd/conf.d',
	_restart => '/usr/sbin/service httpd restart'
    },
    suse => {
	_config_file => '/etc/apache2/httpd.conf',
	_test => sub { ! -f '/etc/apache2/apache2.conf' },
	_incdir => '/etc/apache2/conf.d',
	_restart => '/usr/sbin/service httpd restart'
	    # or systemctl restart apache2.service
    }
);

# new(NAME)
# new()
sub new {
    my $class = shift;
    my $self = bless { }, $class;
    my $name;
    
    if (@_ == 0) {
	# Autodetect
	while (my ($n, $layout) = each %apache_layout_tab) {
	    if (-f $layout->{_config_file}) {
		if (exists($layout->{_test}) && !&{$layout->{_test}}) {
		    next;
		}
		$name = $n;
		last;
	    }
	}
	croak "unrecognized Apache layout" unless defined $name;
    } elsif (@_ == 1) {
	$name = shift;
    }
    
    if (exists($apache_layout_tab{$name})) {
	@{$self}{keys %{$apache_layout_tab{$name}}} =
	    values %{$apache_layout_tab{$name}};
    } else {
	croak "undefined Apache layout $name";
    }

    $self->{_layout_name} = $name;
    
    return $self;
}

sub name {
    my $self = shift;
    return $self->{_layout_name};
}

sub config_file {
    my $self = shift;
    return $self->{_config_file};
}

sub restart_command {
    my $self = shift;
    return $self->{_restart};
}

sub incdir {
    my $self = shift;
    if (exists($self->{_incdir})) {
	if (ref($self->{_incdir}) eq 'CODE') {
	    return &{$self->{_incdir}};
	} else {
	    return $self->{_incdir};
	}
    }
    return dirname($self->{_config_file});
}

1;
