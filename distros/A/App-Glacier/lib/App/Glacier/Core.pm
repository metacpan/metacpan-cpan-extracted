package App::Glacier::Core;
use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt no_ignore_case require_order);
use Pod::Man;
use Pod::Usage;
use Pod::Find qw(pod_where);
use File::Basename;
use Storable;
use Carp;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(usage_error
                 pod_usage_msg
                 EX_OK
                 EX_FAILURE
                 EX_USAGE       
                 EX_DATAERR     
                 EX_NOINPUT     
                 EX_NOUSER      
                 EX_NOHOST      
                 EX_UNAVAILABLE 
                 EX_SOFTWARE    
                 EX_OSERR       
                 EX_OSFILE      
                 EX_CANTCREAT   
                 EX_IOERR       
                 EX_TEMPFAIL    
                 EX_PROTOCOL    
                 EX_NOPERM      
                 EX_CONFIG);

use constant {
    EX_OK => 0,
    EX_FAILURE => 1,
    EX_USAGE        => 64, 
    EX_DATAERR      => 65, 
    EX_NOINPUT      => 66, 
    EX_NOUSER       => 67, 
    EX_NOHOST       => 68, 
    EX_UNAVAILABLE  => 69, 
    EX_SOFTWARE     => 70, 
    EX_OSERR        => 71, 
    EX_OSFILE       => 72, 
    EX_CANTCREAT    => 73, 
    EX_IOERR        => 74, 
    EX_TEMPFAIL     => 75, 
    EX_PROTOCOL     => 76, 
    EX_NOPERM       => 77, 
    EX_CONFIG       => 78 
};


sub new {
    my ($class, $argref) = (shift, shift);
    my $self = bless {
	_debug => 0,
	_dry_run => 0,
	_progname => basename($0)
    }, $class;

    $self->{_argref} = $argref // \@ARGV;
    my %opts;
    local %_ = @_;
    
    if (my $optmap = delete $_{optmap}) {
	foreach my $k (keys %{$optmap}) {
	    if (ref($optmap->{$k}) eq 'CODE') {
		$opts{$k} = sub { &{$optmap->{$k}}($self, @_ ) }
	    } elsif (ref($optmap->{$k})) {
		$opts{$k} = $optmap->{$k};
	    } else {
		$opts{$k} = \$self->{_options}{$optmap->{$k}}
	    }
	}
    }
    croak "unrecognized parameters" if keys(%_);

    $opts{'shorthelp|?'} = sub {
	pod2usage(-message => $self->pod_usage_msg,
		  -input => pod_where({-inc => 1}, ref($self)),
		  -exitstatus => EX_OK)
    };
    $opts{help} = sub {
	pod2usage(-exitstatus => EX_OK,
		  -verbose => 2,
		  -input => pod_where({-inc => 1}, ref($self)))
    };
    $opts{usage} = sub {
	pod2usage(-exitstatus => EX_OK,
		  -verbose => 0,
		  -input => pod_where({-inc => 1}, ref($self)))
    };
    $opts{'debug|D'} = sub { $self->{_debug}++ };
    $opts{'dry-run|n'} = sub { $self->{_debug}++; $self->{_dry_run} = 1 };
    $opts{'program-name=s'} = sub { $self->{_progname} = $_[1] };
    
    GetOptionsFromArray($self->{_argref}, %opts);
    
    return $self;
}

sub clone {
    my ($class, $orig) = @_;
    bless {
	_debug => $orig->{_debug},
	_dry_run => $orig->{_dry_run},
	_progname => $orig->{_progname},
	_argref => [ Storable::dclone($orig->{_argref}) ]
    }, $class
}

sub dry_run { shift->{_dry_run} }
sub argv { shift->{_argref} }
sub command_line { @{shift->{_argref}} }

sub progname {
    my $self = shift;
    if (my $v = shift) {
	croak "too many arguments" if @_;
	$self->{_progname} = $v;
    }
    $self->{_progname};
}

sub debug {
    my ($self, $l, @msg) = @_;
    if ($self->{_debug} >= $l) {
	print STDERR "$self->{_progname}: " if $self->{_progname};
	print STDERR "DEBUG: ";
	print STDERR "@msg\n";
    }
}

sub error {
    my ($self, @msg) = @_;
    print STDERR "$self->{_progname}: " if $self->{_progname};
    print STDERR "@msg\n";
}

sub abend {
    my ($self, $code, @msg) = @_;
    $self->error(@msg);
    exit $code;
}

sub usage_error {
    my $self = shift;
    $self->abend(EX_USAGE, @_);
}

sub pod_usage_msg {
    my ($self) = @_;
    my %args;

    my $msg = "";

    open my $fd, '>', \$msg;

    if (defined($self)) {
	if (my $r = ref($self)) {
	    $self = $r;
	}
	$args{-input} = pod_where({-inc => 1}, $self);
    }

    pod2usage(-verbose => 99,
	      -sections => 'NAME',
	      -output => $fd,
	      -exitval => 'NOEXIT',
	      %args);

    my @a = split /\n/, $msg;
    if ($#a < 1) {
	croak "missing or malformed NAME section in " . $args{-input} // $0;
    }
    $msg = $a[1];
    $msg =~ s/^\s+//;
    $msg =~ s/ - /: /;
    return $msg;
}

1;
__END__

=head1 NAME

App::Glacier::Core - Core class for glacier command line tool.

=head1 DESCRIPTION

Core class for all glacier commands. Provides basic command-line functionality.

=head1 METHODS

=head2 new

    new($argref, $optref)

I<$argref> is a reference to the list of command line arguments (if B<undef>,
B<\@ARGV> will be used), and I<$optref> is a reference to option definitions
in the style of B<Getopt::Long>. The constructor consumes the following
options and stores the rest of the arguments in the returned object structure:

=over 4

=item B<-h>, B<-?>

Displays short help list.

=item B<--help>

Formats entire manual page.

=item B<-d>, B<--debug>

Increases debug level associated with the returned object.

=item B<-n>, B<--dey-run>

Sets dry-run mode.

=back

=head2 progname
    
=head2 dry_run
    
=head2 debug    

    debug($level, @message)

=head2 error

    error(@message)

=head2 abend

    abend($code, @message)

=head2 pod_usage_msg    
    
