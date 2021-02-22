package Config::HAProxy::VirtualHost;
use strict;
use warnings;
use Carp;
use File::Spec;
use Config::HAProxy::Node::Empty;

sub find_file {
    my ($node, $hostdir) = @_;
    my $rx = qr($hostdir);
    my @argv = $node->argv;
    while (my $arg = shift @argv) {
	if ($arg eq '-f' && -f $argv[0]) {
	    if ($argv[0] =~ s{^($rx/.+)$}{$1}) {
		# Untaint the value
		return $1;
	    } else {
		last;
	    }
	}
    }
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    if (@_ == 2) {
	my ($node, $hostdir) = @_;
	$self->{node} = $node;
	$self->{file} = find_file($node, $hostdir);
	($self->{backend}) = $node->root->select(name => 'backend',
						 arg => { n => 0,
							  v => $node->arg(0) });
    } elsif (@_ == 4) {
	my ($cmd, $name, $port, $domains) = @_;

	$self->{file} = File::Spec->catfile($cmd->hostdir, $name);
	unlink $self->{file};
	$self->add_domain(@$domains);
	
	my $node = new Config::HAProxy::Node::Statement(
	    kw => 'use_backend',
	    argv => [ $name, qw/if { hdr(host) -f/, $self->{file}, '}' ]);
	$cmd->frontend->append_node_nonempty($node);
	$self->{node} = $node;
	
	$node = new Config::HAProxy::Node::Section(
	    kw => 'backend',
	    argv => [ $name ]);
	$node->append_node(new Config::HAProxy::Node::Statement(
			       kw => 'server',
			       argv => [
				   'localhost',
				   '127.0.0.1:'.$port
			       ]));
	$self->{backend} = $node;
	unless ($cmd->config->tree->ends_in_empty) {
	    $cmd->config->tree->append_node(new Config::HAProxy::Node::Empty);
	}
	$cmd->config->tree->append_node($node);
	$cmd->config->tree->mark_dirty;
	$self->mark_dirty;
    } else {
	croak "unrecognized arguments";
    }
    $self
}

sub valid {
    my $self = shift;
    return $self->file && $self->backend
}

sub file {
    my $self = shift;
    return $self->{file};
}

sub backend {
    my $self = shift;
    return $self->{backend};
}

sub node {
    my $self = shift;
    return $self->{node}
}

sub name {
    my $self = shift;
    return $self->node->arg(0);
}

sub _domainref {
    my $self = shift;
    unless ($self->{domains}) {
	croak "can't use this method on invalid backend" unless $self->file;
	if (-e $self->file) {
	    open(my $fd, '<', $self->file)
		or croak "can't open ".$self->file.": $!";
	    chomp(my @domains = <$fd>);
	    close $fd;
	    $self->{domains} = \@domains;
	} else {
	    $self->{domains} = [];
	}
    }
    return $self->{domains};
}

sub domains {
    my $self = shift;
    my $dom = $self->_domainref;
    if (my $n = shift) {
	return undef unless $n < @$dom;
	return $dom->[$n]
    }
    return @$dom;
}

sub has_domain {
    my ($self, $name) = @_;
    $name = lc $name;
    $name =~ s/\.$//;
    foreach my $dom ($self->domains) {
	return 1 if ($name eq $dom);
    }
    return 0
}

sub normalize_hostnames {
    map { lc } @_
}

sub writable {
    my $self = shift;
    -w $self->file;
}

sub add_domain {
    my $self = shift;
    push @{$self->_domainref()}, normalize_hostnames(@_);
    $self->mark_dirty;
}
    
sub del_domain {
    my $self = shift;
    my @hosts = normalize_hostnames(@_);
    my %dl;
    @dl{@hosts} = (1) x @hosts;
    $self->{domains} = [ 
	grep { 
	    if ($dl{$_}) {
		$self->mark_dirty;
		0;
	    } else {
		1
	    }
	} @{$self->_domainref()}
    ];
}
    
sub servers {
    my $self = shift;
    croak "can't use this method on invalid backend" unless $self->backend;
    my @ret = map { $_->arg(1) } $self->backend->select(name => 'server');
    if (@_) {
	my $n = shift;
	return undef unless $n < @ret;
	return $ret[$n];
    }
    @ret;
}

sub is_dirty {
    my $self = shift;
    return $self->{dirty}
}

sub mark_dirty {
    my $self = shift;
    $self->{dirty} = 1;
}

sub clear_dirty {
    my $self = shift;
    $self->{dirty} = 0;
}

sub save {
    my $self = shift;
    if ($self->is_dirty) {
	if ($self->domains == 0) {
	    if (unlink $self->file) {
		$self->clear_dirty;
		return;
	    }
	}
		    
	open(my $fd, '>', $self->file)
	    or croak "can't open ".$self->file." for writing: $!";
	foreach my $dom ($self->domains) {
	    print $fd $dom,"\n";
	}
	close $fd;

	$self->clear_dirty
    }
}

sub drop {
    my $self = shift;
    $self->node->drop;
    $self->backend->drop;
    $self->{domains} = [];
    $self->mark_dirty;
}

sub DESTROY {
    my $self = shift;
    $self->save()
}

1;
