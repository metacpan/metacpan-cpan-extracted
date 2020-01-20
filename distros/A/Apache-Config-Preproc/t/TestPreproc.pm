package TestPreproc;
use strict;
use warnings;
use parent 'Apache::Config::Preproc';
use Carp;
use File::Basename;
use File::Temp;
use File::Spec;
use File::Path qw /make_path/;
use Cwd;
use autodie;

sub import {
    my $class = shift;
    $class->SUPER::import($ENV{APACHE_CONFIG_PREPROC});
}

sub new {
    my $class = shift;
    my $expect_fail;
    if (@_ && $_[0] eq '-expect_fail') {
	shift;
	$expect_fail = 1;
    }
    my $dir = File::Temp->newdir('expXXXXXX');
    my $text;
    my $fd;
    my $confname;
    while (<main::DATA>) {
	last if /^__END__/;
	if (/^!%\s*(.+)\s*$/) {
	    $confname = File::Spec->catfile($dir, $1);
	} elsif (/^!>\s*(.+)\s*$/) {
	    my $name = File::Spec->catfile($dir, $1);
	    $confname //= $name;
	    my $subdir = dirname($name);
	    make_path($subdir) unless (-d $subdir);
	    close($fd) if $fd;
	    open($fd, '>', $name);
	} elsif (/^!\+\s*(.+)\s*$/) {
	    my $subdir = File::Spec->catfile($dir, $1);
	    make_path($subdir) unless (-d $subdir);
	} elsif (/^!=\s*$/) {
	    close($fd) if $fd;
	    open($fd, '>', \$text);
	} elsif (/!\$\s*$/) {
	    close($fd) if $fd;
	    $fd = undef;
	} elsif ($fd) {
	    s/\$server_root/$dir/;
	    print $fd $_;
	}
    }
    close($fd) if $fd;
    my $self = $class->SUPER::new($confname, @_);
    if ($self) {
	$self->{_expect} = $text;
	$self->{_cwd} = getcwd;
    } elsif (!$expect_fail) {
	croak $Apache::Admin::Config::ERROR;
    }
    return $self;
}

sub dump_expect { shift->{_expect} }

sub dump_test {
    my $self = shift;
    $self->dump_raw eq $self->{_expect};
}

sub dump_reformat_synclines {
    my $self = shift;
    dump_reformat_synclines_worker($self, qr{$self->{_cwd}});
}


sub dump_reformat_synclines_worker {
    my ($tree, $dir) = @_;
    join('', map {
	(my $l = $_->locus->format) =~ s{$dir/}{}g;
	"# $l\n" .
	do {
	    if ($_->type eq 'section') {
		$tree->write_section($_->name, $_->value) .
	        dump_reformat_synclines_worker($_, $dir) .
		$tree->write_section_closing($_->name)
	    } else {
		my $method = "write_".$_->type;
		my $name;
		if ($_->type eq 'directive') {
		    $name = $_->name;
		} elsif ($_->type eq 'comment') {
                    $name = $_->value;
                } elsif ($_->type eq 'blank') {
                    $name = $_->{length};
                }	
	        $tree->$method($name||'',$_->value//'');
            }
	};
    } $tree->select());
}	

1;

	
	
    
