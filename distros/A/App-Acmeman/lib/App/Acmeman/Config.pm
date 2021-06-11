package App::Acmeman::Config;

use strict;
use warnings;
use Carp;
use parent 'Config::Parser::Ini';
use Text::ParseWords;
use App::Acmeman::Log qw(debug_level :sysexits);
use File::Spec;

sub new {
    my $class = shift;
    my $filename = shift;
    my %args;
    if (-e $filename) {
	$args{filename} = $filename;
    }
    my $self = $class->SUPER::new(%args);
    if (!$args{filename}) {
	$self->commit or croak "configuration failed";
    }
    $self
}

sub mangle {
    my $self = shift;
    my $err;

    if (debug_level() == 0 && $self->core->verbose) {
	debug_level($self->core->verbose);
    }
    $self->set(qw(core files default))
	unless $self->is_set(qw(core files));

    unless ($self->is_set(qw(files))) {
	if ($self->get(qw(core files)) ne 'default') {
	    $self->error("section files." . $self->get(qw(core files))." not defined");
	    ++$err;
	}
    }

    unless ($self->is_set(qw(files default))) {
	$self->set(qw(files default type), 'split');
	$self->set(qw(files default key-file), 
		     '/etc/ssl/acme/$domain/privkey.pem');
	$self->set(qw(files default certificate-file),
		     '/etc/ssl/acme/$domain/cert.pem');
	$self->set(qw(files default ca-file),
		     '/etc/ssl/acme/$domain/ca.pem');
    }
    
    if (my $fnode = $self->getnode('files')) {
	while (my ($k, $v) = each %{$fnode->subtree}) {
	    $v->set('files', $k, 'type', 'split')
		unless $v->has_key('type');
	    if ($v->subtree('type') eq 'single') {
		unless ($v->has_key('certificate-file')) {
		    $self->error("files.$k.certificate-file not defined");
		    ++$err;
		} else {
		    if ($v->has_key('key-file')) {
			$self->error("files.$k.key-file ignored");
		    }
		    if ($v->has_key('ca-file')) {
			$self->error("files.$k.ca-file ignored");
		    }
		}
	    } else {
		unless ($v->has_key('key-file')) {
		    $self->error("files.$k.key-file not defined");
		    ++$err;
		}
		unless ($v->has_key('certificate-file')) {
		    $self->error("files.$k.ca-file not defined");
		    ++$err;
		}
	    }
	}
    }

    if (my $files = $self->get(qw(core files))) {
	unless ($self->is_set('files', $files)) {
	    $self->error("files.$files is referenced from [core], but never declared");
	    ++$err;
	}
    }

    if (my $source_node = $self->getnode(qw(core source))) {
	$self->unset(qw(core source));	
	foreach my $s ($source_node->value) {
	    my ($name, @args) = quotewords('\s+', 0, $s);
	    my $pack = 'App::Acmeman::Source::' . ucfirst($name);
	    my $obj = eval "use $pack; new $pack(\@args);";
	    if ($@) {
		$self->error("error loading source module $name: $@",
			     locus => $source_node->locus);
	        ++$err;
	        next;
	    }
	    if ($obj->configure($self)) {
		$self->set(qw(core source), $obj);
	    } else {
		++$err;
	    }
	}
    }

    my $dir = $self->get(qw(account directory));
    for my $k (qw(id key)) {
	my $file = $self->get('account', $k);
	unless (File::Spec->file_name_is_absolute($file)) {
	    $self->set('account', $k, File::Spec->catfile($dir, $file));
	}
    }
    
    exit(EX_CONFIG) if $err;
}

1;
__DATA__
[core]
    postrenew = STRING :array
    rootdir = STRING :default=/var/www/acme
    files = STRING
    time-delta = NUMBER :default=86400
    source = STRING :default=default :array
    check-alt-names = BOOL :default=0
    check-dns = BOOL :default=1
    my-ip = STRING :array
    key-size = NUMBER :default=4096
    verbose = NUMBER :default=0
[account]
    directory = STRING :default=/etc/ssl/acme
    id = STRING :default=key.id
    key = STRING :default=key.pem
[files ANY]
    type = STRING :re="^(single|split)$"
    certificate-file = STRING
    key-file = STRING
    ca-file = STRING
    argument = STRING
[domain ANY]
    alt = STRING :array
    files = STRING
    key-size = NUMBER
    postrenew = STRING :array

    


    
