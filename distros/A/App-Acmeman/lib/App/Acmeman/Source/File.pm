package App::Acmeman::Source::File;

use strict;
use warnings;
use Carp;
use File::Spec;
use parent 'App::Acmeman::Source';
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt no_ignore_case);
use App::Acmeman::Log qw(:all);

sub new {
    my $class = shift;
    my $pattern = shift || croak "file name or globbing pattern must be given";
    my $ignore = '^\.|~$|\.bak$|^#.*#$';
    my $host;
    GetOptionsFromArray(\@_,
			'ignore|i=s' => \$ignore,
			'host|h=s' => \$host);
    unless ($pattern =~ m{[][*?]}) {
	$pattern =~ s{/$}{};
	if (-d $pattern) {
	    $pattern = File::Spec->catfile($pattern, '*');
	}
    }
    bless { pattern => $pattern,
	    ignore => $ignore,
	    host => $host }, $class;
}

sub scan {
    my ($self) = @_;
    debug(1, "initializing file list from $self->{pattern}");
    my $err = 0;
    if ($self->{host}) {
	$self->define_domain($self->{host});
    }
    foreach my $file (glob $self->{pattern}) {
	next if $file =~ m{$self->{ignore}};
	unless ($self->load($file)) {
	    ++$err;
	}
    }
    return $err == 0;
}

sub load {
    my ($self, $file) = @_;
    debug(1, "reading $file");
    open(my $fh, '<', $file)
	or do {
	    error("can't open $file: $!");
	    return 0;
        };
    chomp(my @lines = <$fh>);
    close $fh;
    if (@lines) {
	if ($self->{host}) {
	    $self->define_alias($self->{host}, @lines);
        } else {
	    my $cn = shift @lines;
	    $self->define_domain($cn);
	    $self->define_alias($cn, @lines);
	}
    }
    return 1;
}

1;

    
