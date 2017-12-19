package Apache::Config::Preproc::include;
use strict;
use warnings;
use Apache::Admin::Config;
use Apache::Config::Preproc;
use File::Spec;
use Cwd 'abs_path';
use IPC::Open3;
use Carp;

our $VERSION = '1.02';

sub new {
    my $class = shift;
    my $conf = shift;
    my $self = bless { context => [], conf => $conf }, $class;
    local %_ = @_;
    $self->{server_root} = delete $_{server_root};
    if (my $v = delete $_{probe}) {
	if (ref($v) eq 'ARRAY') {
	    $self->probe(@$v);
	} else {
	    $self->probe;
	}
    }
    croak "unrecognized arguments" if keys(%_);
    $self->{check_included} = $^O eq 'MSWin32'
	? \&_check_included_path
	: \&_check_included_stat;
    return $self;
}

sub conf { shift->{conf} }
    
sub server_root {
    my $self = shift;
    if (my $v = shift) {
	$self->{server_root} = $self->conf->dequote($v);
    }
    return $self->{server_root};
}

sub context_string {
    my ($self, $file) = @_;
    my ($dev,$ino) = stat($file);
    $file = abs_path($file);
    return "\"$file\" $dev $ino";
}

sub context_push {
    my ($self,$file,$dev,$ino) = @_;
    push @{$self->{context}}, { file => $file, dev => $dev, ino => $ino };
}

sub context_pop {
    my $self = shift;
    pop @{$self->{context}};
}

sub expand {
    my ($self, $d, $repl) = @_;

    if ($d->type eq 'directive') {
	if (lc($d->name) eq 'serverroot') {
	    $self->server_root($d->value);
	} elsif ($d->name =~ /^include(optional)?$/i) {
	    my $optional = $1;

	    my $pat = $self->conf->dequote($d->value);
	    unless (File::Spec->file_name_is_absolute($pat)) {
		if (my $d = $self->server_root) {
		    $pat = File::Spec->catfile($d, $pat);
		}
	    }

	    my @filelist = glob $pat;
	    if (@filelist) {
		foreach my $file (@filelist) {
		    if ($self->check_included($file)) {
			croak "file $file already included";
		    }
		    if (my $inc = new Apache::Admin::Config($file,
							    @{$self->conf->options})) {
			$inc->add('directive',
				  '$PUSH$' => $self->context_string($file),
				  '-ontop');
			$inc->add('directive',
				  '$POP$' => 0,
				  '-onbottom');
			# NOTE: make sure each item is cloned
			push @$repl, map { $_->clone } $inc->select;
		    } else {
			croak $Apache::Admin::Config::ERROR;
		    }
		}
	    }
	    return 1;
	} elsif ($d->name eq '$PUSH$') {
	    if ($d->value =~ /^\"(.+)\" (\d+) (\d+)$/) {
		$self->context_push($1, $2, $3);
	    }
	    return 1;
	} elsif ($d->name eq '$POP$') {
	    $self->context_pop;
	    return 1;
	}
    }
	    
    return 0;
}

sub probe {
    my ($self, @servlist) = @_;
    unless (@servlist) {
	@servlist = qw(/usr/sbin/httpd /usr/sbin/apache2);
    }

    open(my $nullout, '>', File::Spec->devnull);
    open(my $nullin, '<', File::Spec->devnull);
    foreach my $serv (@servlist) {
        use Symbol 'gensym';
        my $fd = gensym;
        eval {
        	if (my $pid = open3($nullin, $fd, $nullout, $serv, '-V')) {
			while (<$fd>) {
			    chomp;
			    if (/^\s+-D\s+HTTPD_ROOT=(.+)\s*$/) {
				$self->server_root($1);
				last;
			    }
			}
		}
	};
	close $fd;
	last unless ($@)
    }
    close $nullin;
    close $nullout;
}    

sub check_included {
    my ($self, $file) = @_;
    return $self->${ \ $self->{check_included} }($file);
}

# Default included file table for unix-like OSes
sub _check_included_stat {
    my ($self, $file) = @_;
    my ($dev,$ino) = stat($file) or return 0;
    return grep { $_->{dev} == $dev && $_->{ino} == $ino } @{$self->{context}};
}

# Path-based file table, for defective OSes (MSWin32)
sub _check_included_path {
    my ($self, $file) = @_;
    my $path = abs_path($file);
    return grep { $_->{file} eq $path } @{$self->{context}}; 
}

1;

__END__

=head1 NAME    

Apache::Config::Preproc::include - expand Include statements

=head1 SYNOPSIS

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
                -expand => [ qw(include) ];

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
                -expand => [
                    { include => [ server_root => $dir ] }
                ];

    $x = new Apache::Config::Preproc '/path/to/httpd.conf',
                -expand => [
                    { include => [ probe => [ '/usr/sbin/httpd' ] ] }
                ];

=head1 DESCRIPTION

Processes B<Include> and B<IncludeOptional> statements and replaces them
with the contents of the files supplied in their arguments. If the argument
is not an absolute file name, it is searched in the server root directory.

Keyword arguments:

=over 4

=item B<server_root =E<gt>> I<DIR>

Sets default server root value to I<DIR>.

=item B<probe =E<gt>> I<LISTREF> | B<1>

Determine the default server root value by analyzing the output of
B<httpd -V>. If I<LISTREF> is given, it contains alternative pathnames
of the Apache B<httpd> binary. Otherwise, 

    probe => 1

is a shorthand for

    probe => [qw(/usr/sbin/httpd /usr/sbin/apache2)]
        
=back

When the B<ServerRoot> statement is seen, its value overwrites any
previously set server root directory.
    
=cut

    
