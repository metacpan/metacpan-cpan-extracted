package Apache::Config::Preproc::Server::Probe;
use strict;
use warnings;
use File::Spec;
use IPC::Open3;
use Shell::GetEnv;
use DateTime::Format::ISO8601;
use Symbol 'gensym';
use Carp;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    local %_ = @_;
    my $v;
    my @servlist;
    if ($v = delete $_{server}) {
	if (ref($v) eq 'ARRAY') {
	    @servlist = @$v;
	} else {
	    @servlist = ( $v );
	}
    } else {
	@servlist = qw(/usr/sbin/httpd /usr/sbin/apache2);
    }
    
    if (my @select = grep { -x $_ } @servlist) {
	$self->{server} = shift @select;
    } else {
	croak "No suitable httpd binary found";
    }

    if ($v = delete $_{environ}) {
	$self->{environ} = Shell::GetEnv->new('sh', ". $v", startup => 0)
	                                ->envs;
    }

    croak "unrecognized arguments" if keys(%_);
    return $self;
}	    

sub server { shift->{server} }
sub environ { shift->{environ} }

sub probe {
    my ($self, $cb, @opt) = @_;

    open(my $nullout, '>', File::Spec->devnull);
    open(my $nullin, '<', File::Spec->devnull);

    my $fd = gensym;
    local %ENV = %{$self->{environ}} if $self->{environ};
    if (my $pid = open3($nullin, $fd, $nullout, $self->server, @opt)) {
	while (<$fd>) {
	    chomp;
	    last if &{$cb}($_);
	}
    }
    close $fd;
    close $nullin;
    close $nullout;
}    

sub version {
    my $self = shift;
    unless ($self->{version}) {
	$self->probe(sub {
	    local $_ = shift;
	    if (/^Server version:\s+(.+?)/(\S+)\s+\((.*?)\)/) {
		$self->{version}{name} = $1;
		$self->{version}{number} = $2;
		$self->{version}{platform} = $3;
	    } elsif (/^Server built:\s+(.+)/) {
		$self->{version}{built} =
		    DateTime::Format::ISO8601->parse_datetime($1);
	    }
        }, '-v');
    }	     
    return $self->{version}
		

1;
