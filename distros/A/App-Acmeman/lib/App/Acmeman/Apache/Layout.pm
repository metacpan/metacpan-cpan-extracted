package App::Acmeman::Apache::Layout;

use strict;
use warnings;
use Carp;
use File::Basename;
use feature 'state';
use App::Acmeman::Log qw(:all);
use Apache::Defaults;
use Carp;

sub _find_httpd {
    my $httpd;
    foreach my $d (split /:/, $ENV{PATH}) {
	foreach my $n (glob "$d/apachectl $d/httpd") {
	    if (-x $n) {
		return $n;
	    }
	}
    }
}

sub modules {
    my $class = shift;
    my @path = split /::/, $class;
    
    state $loaders //=
	[map { $_->[1] }
	 sort { $a->[0] <=> $b->[0] }
	 map {
	     my ($modname) = $class . '::' . fileparse($_, '.pm');
	     eval {
		 no strict 'refs';
		 if (scalar %{ $modname.'::' }) {
		     ()
		 } else {
		     require $_;
		     my $prio = ${$modname.'::PRIORITY'} // 0;
		     [ $prio, $modname ]
	         }
	     };
	 }
	 map { glob File::Spec->catfile($_, '*.pm') }
	 grep { -d $_ }
	 map { File::Spec->catfile($_, @path) } @INC];
    @$loaders;
}

sub new {
    my ($class, $ap, %args) = @_;

    unless ($ap->isa('Apache::Defaults')) {
    	croak "unrecognized argument";
    }

    my $self = bless { _defaults => $ap }, $class;
    foreach my $kw (qw(layout_name incdir restart_command)) {
	if (defined(my $v = delete $args{$kw})) {
	    $self->{$kw} = $v;
	}
    }

    return $self;
}

sub detect {
    my $class = shift;
    my $server = $class->_find_httpd;

    if (my $name = shift) {
	my $mod = "${class}::$name";
	eval "require $mod";
	croak "undefined Apache layout $name" if ($@);
        my $self = $mod->new(new Apache::Defaults(server => $server), @_);
	if (!$self) {
	    croak "can't use layout $name";
	}
	return $self;
    }
    
    # Autodetect
    debug(3, "detecting Apache configuration layout"
	      .(defined($server) ? " (using httpd binary $server)" : ''));
    my $ap = new Apache::Defaults(server => $server, on_error => 'return');
    if ($ap->status) {
	croak "unable to get Apache defaults: " . $ap->error;
    }

    foreach my $mod ($class->modules) {
	debug(3, "trying layout module $mod");
	if (my $obj = eval { $mod->new($ap) }) {
	    return $obj;
	}
	if ($@) {
	    debug(3, "layout module failed: $@");
	}
    }

    return new App::Acmeman::Apache::Layout($ap, layout_name => 'auto');
}

sub apache { shift->{_defaults} }

sub apache_modules {
    my $self = shift;

    if (@_ == 1 && !defined $_[0]) {
	delete $self->{apache_modules};
	shift;
    }
    unless ($self->{apache_modules}) {
	if (open(my $fd, '-|',
		 $self->server_command, '-t', '-D', 'DUMP_MODULES')) {
	    while (<$fd>) {
		chomp;
		if (/^\s+(\w+)_module\s+\((static|shared)\)$/) {
		    $self->{apache_modules}{$1} = $2;
		}
	    }
	    close $fd;
	} else {
	    croak "can't run ".$self->server_command.": $!";
	}
    }
    my %ret;
    if (@_) {
	foreach my $m (@_) {
	    $ret{$m} = $self->{apache_modules}{$m}
	        if exists $self->{apache_modules}{$m};
	}
    } else {
	%ret = %{$self->{apache_modules}};
    }
    if (wantarray) {
	return %ret;
    } else {
	return keys %ret;
    }
}

sub name {
    my $self = shift;
    unless ($self->{layout_name}) {
	$self->{layout_name} = ref($self);
	$self->{layout_name} =~ s/.*:://;
	$self->{layout_name} =~ s/\.pm$//;
    }
    return $self->{layout_name};
}

sub config_file { shift->apache->server_config }

sub incdir {
    my $self = shift;
    unless ($self->{incdir}) {
	$self->{incdir} = dirname($self->config_file);
    }
    return $self->{incdir};
}

sub server_command { join(' ', shift->apache->server_command) }

sub restart_command {
    my $self = shift;

    unless (exists($self->{restart_command})) {
	if ($self->server_command =~ m{/apachectl$}) {
	    $self->{restart_command} = $self->server_command . ' restart';
	} else {
	    error("no postrenew command defined", prefix => 'warning');
	    $self->{restart_command} = undef
	}
    }
    return $self->{restart_command};
}

sub pre_setup {}
sub post_setup {}

1;
