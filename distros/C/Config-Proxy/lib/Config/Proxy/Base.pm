package Config::Proxy::Base;
use 5.010;
use strict;
use warnings;
use Text::Locus;
use Config::Proxy::Node::Root;
use Config::Proxy::Node::Section;
use Config::Proxy::Node::Statement;
use Config::Proxy::Node::Comment;
use Config::Proxy::Node::Empty;
use File::Basename;
use File::Temp qw(tempfile);
use File::stat;
use File::Spec;
use IPC::Cmd qw(run);
use Carp;

sub new {
    my ($class, $filename, $linter) = @_;
    my $self = bless { _filename => $filename }, $class;
    if ($linter) {
	$self->{_lint} = { enable => 1, command => $linter };
    } else {
	$self->{_lint} = { enable => 0 }
    }
    $self->reset();
    return $self;
}

sub filename { shift->{_filename} }

sub parse {
    croak "not implemented"
}

sub reset {
    my $self = shift;
    $self->{_tree} = new Config::Proxy::Node::Root();
}

sub tree { shift->{_tree} }

sub select {
    my $self = shift;
    $self->tree->select(@_);
}

sub iterator {
    my $self = shift;
    $self->tree->iterator(@_);
}

sub write {
    my $self = shift;
    $self->tree->write(@_)
}

sub content {
    my $self = shift;
    my $s;
    open(my $fh, '>', \$s) or croak "can't write to string: $!";
    $self->write($fh);
    close($fh);
    return $s
}

sub lint {
    my $self = shift;

    if (@_) {
	if (@_ == 1) {
	    $self->{_lint}{enable} = !!shift;
	} elsif (@_ % 2 == 0) {
	    local %_ = @_;
	    my $v;
	    if (defined($v = delete $_{enable})) {
		$self->{_lint}{enable} = $v;
	    }
	    if (defined($v = delete $_{command})) {
		$self->{_lint}{command} = $v;
	    }
	    if (defined($v = delete $_{path})) {
		$self->{_lint}{path} = $v;
	    }
	    croak "unrecognized keywords" if keys %_;
	} else {
	    croak "bad number of arguments";
	}
    }

    if ($self->{_lint}{enable}) {
	if ($self->{_lint}{path}) {
	    my ($prog, $args) = split /\s+/, $self->{_lint}{command}, 2;
	    if (!File::Spec->file_name_is_absolute($prog)) {
		foreach my $dir (split /:/, $self->{_lint}{path}) {
		    my $name = File::Spec->catfile($dir, $prog);
		    if (-x $name) {
			$prog = $name;
			last;
		    }
		}
		if ($args) {
		    $prog .= ' '.$args;
		}
		$self->{_lint}{command} = $prog;
	    }
	}
	return $self->{_lint}{command};
    }
}

sub save {
    my $self = shift;
    croak "bad number of arguments" if @_ % 2;
    local %_ = @_;
    my $dry_run = delete $_{dry_run};
    my @wrargs = %_;

    return unless $self->tree;# FIXME
    return unless $self->tree->is_dirty;
    my ($fh, $tempfile) = tempfile('proxy.conf.XXXXXX',
				   DIR => dirname($self->filename));
    $self->write($fh, @wrargs);
    close($fh);
    if (my $cmd = $self->lint) {
	my ($ok, $err, $full, $outbuf, $errbuf) =
	    run(command => "$cmd $tempfile");
	unless ($ok) {
	    unlink $tempfile;
	    if ($errbuf && @$errbuf) {
		croak "Syntax check failed: ".join("\n", @$errbuf)."\n";
	    }
	    croak $err;
	}
    }
    return 1 if $dry_run;

    my $sb = stat($self->filename);
    $self->backup;
    rename($tempfile, $self->filename)
	or croak "can't rename $tempfile to ".$self->tempfile.": $!";

    # This will succeed: we've created the file, so we're owning it.
    chmod $sb->mode & 0777, $self->filename;
    # This will fail unless we are root, let it be so.
    chown $sb->uid, $sb->gid, $self->filename;

    $self->tree->clear_dirty;
    return 1;
}

sub backup_name {
    my $self = shift;
    $self->filename . '~'
}

sub backup {
    my $self = shift;
    my $backup = $self->backup_name;
    if (-f $backup) {
	unlink $backup
	    or croak "can't unlink $backup: $!"
    }
    rename $self->filename, $self->backup_name
	or croak "can't rename :"
		 . $self->filename
		 . " to "
		 . $self->backup_name
		 . ": $!";
}

1;
