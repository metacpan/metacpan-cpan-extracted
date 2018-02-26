package App::Glacier::Command;
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

use strict;
use warnings;
use Carp;
use File::Basename;
use App::Glacier::EclatCreds;
use App::Glacier::Config;
use Net::Amazon::Glacier;
use App::Glacier::HttpCatch;
use App::Glacier::DB::GDBM;
use App::Glacier::Timestamp;
use App::Glacier::Directory;

use Digest::SHA qw(sha256_hex);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptionsFromArray :config gnu_getopt no_ignore_case require_order);
use Pod::Usage;
use Pod::Find qw(pod_where);

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

use constant MB => 1024*1024;

sub ck_number {
    my ($vref) = @_;
    return "not a number"
        unless $$vref =~ /^\d+/;
    return undef;
}

sub ck_size {
    my ($vref) = @_;
    if ($$vref =~ /^(\d+)\s*([kKmMgG])?$/) {
	my $size = $1;
	if ($2) {
	    my $suf = lc $2;
	    foreach my $m (qw(k m g)) {
		$size *= 1024;
		last if $m eq $suf;
	    }
	}
	$$vref = $size;
    } else {
	return 'invalid size specification';
    }
}

my %parameters = (
    glacier => {
	section => {
	    credentials => 1,
	    access => 1,
	    secret => 1,
	    region => 1,
	}
    },
    transfer => {
	section => {
	    'single-part-size' => { default => 100*MB, check => \&ck_size },
	    'jobs' => { default => 16, check => \&ck_number },
	    'retries' => { default => 10, check => \&ck_number },
	    upload => {
		section => {
		    'single-part-size' => { check => \&ck_size },
		    'jobs' => { check => \&ck_number },
		    'retries' => { check => \&ck_number },
		}
	    }, 
	    download => {
		section => {
		    'single-part-size' => { check => \&ck_size },
		    'jobs' => { check => \&ck_number },
		    'retries' => { check => \&ck_number },
		}
	    } 
	}
    },
    database => {
	section => {
	    job => {
		section => {
		    file => { default => '/var/lib/glacier/job.db' },
		    mode => { default => 0644 },
		    ttl => { default => 72000, check => \&ck_number },
		},
	    },
	    inv => {
		section => {
		    directory => { default => '/var/lib/glacier/inv' },
		    mode => { default => 0644 },
		    ttl => { default => 72000, check => \&ck_number },
		}
	    }
	}
    }
);

sub new {
    my $class = shift;
    local %_ = @_;
    my $self = bless {
	_debug => 0,
	_dry_run => 0
    }, $class;
    my $v;
    my $account;
    my $region;
    
    if ($v = delete $_{progname}) {
	$self->{_progname} = $v;
    } else {
	$self->{_progname} = basename($0);
    }

    if ($v = delete $_{debug}) {
	$self->{_debug} = $v;
    }

    if ($v = delete $_{dry_run}) {
	$self->{_dry_run} = $v;
	$self->{_debug}++;
    }

    if ($v = delete $_{usage_error}) {
	$self->abend(EX_USAGE, @$v);
    }
    
    if ($v = delete $_{account}) {
	$account = $v;
    }

    if ($v = delete $_{region}) {
	$region = $v;
    }

    my $config_file;
    if ($v = delete $_{config}) {
	$config_file = $v;
    } else {
	$config_file = $ENV{GLACIER_CONF} || "/etc/glacier.conf";
    }

    if (keys(%_)) {
	croak "unrecognized parameters: ".join(', ', keys(%_));
    }
    
    $self->{_config} = new App::Glacier::Config($config_file,
						debug => $self->{_debug},
						parameters => \%parameters);
    exit(EX_CONFIG) unless $self->{_config}->parse();

    unless ($self->{_config}->isset(qw(glacier access))
	    && $self->{_config}->isset(qw(glacier secret))) {
	if ($self->{_config}->isset(qw(glacier credentials))) {
	    my $creds = new App::Glacier::EclatCreds($self->{_config}->get(qw(glacier credentials)));
	    $account = $self->{_config}->get(qw(glacier access))
		unless defined $account;
	    if ($creds->has_key($account)) {
		$self->{_config}->set(qw(glacier access),
				      $creds->access_key($account));
		$self->{_config}->set(qw(glacier secret),
				      $creds->secret_key($account));
		$region = $creds->region($account) unless defined $region;
	    }
	}
	$self->abend(EX_CONFIG, "no access credentials found")
	    unless ($self->{_config}->isset(qw(glacier access))
		    && $self->{_config}->isset(qw(glacier secret)));
    }
    
    $self->{_config}->set(qw(glacier region), $region || 'eu-west-1');

    $self->{_glacier} = new Net::Amazon::Glacier(
	$self->{_config}->get(qw(glacier region)),
	$self->{_config}->get(qw(glacier access)),
	$self->{_config}->get(qw(glacier secret))
	);
    
    return $self;
}

sub touchdir {
    my ($self, $dir) = @_;
    unless (-d $dir) {
        make_path($dir, {error=>\my $err});
        if (@$err) {
            for my $diag (@$err) {
                my ($file, $message) = %$diag;
                $file = $dir if ($file eq '');
                $self->error("error creating $file: $message");
            }
            exit(EX_CANTCREAT);
        }
    }
}

sub jobdb {
    my $self = shift;
    unless ($self->{_jobdb}) {
	my $file = $self->cfget(qw(database job file));
	$self->touchdir(dirname($file));
	$self->{_jobdb} = new App::Glacier::DB::GDBM(
	    $file,
	    encoding => 'json',
	    mode => $self->cfget(qw(database job mode))
        );
    }
    return $self->{_jobdb};
}

sub describe_vault {
    my ($self, $vault_name) = @_;
    my $res = $self->glacier_eval('describe_vault', $vault_name);
    if ($self->lasterr) {
	if ($self->lasterr('code') == 404) {
	    return undef;
	} else {
	    $self->abend(EX_FAILURE, "can't list vault: ",
			 $self->last_error_message);
	}
    }
    return timestamp_deserialize($res);
}

sub _filename {
    my ($self, $name) = @_;
    $name =~ s/([^A-Za-z_0-9\.-])/sprintf("%%%02X", ord($1))/gex;
    return $name;
}

sub directory {
    my ($self, $vault_name) = @_;
    unless (exists($self->{_dir}{$vault_name})) {
	my $file = $self->cfget(qw(database inv directory))
	           . '/' . $self->_filename($vault_name) . '.db';
	unless (-e $file) {
	    return undef unless $self->describe_vault($vault_name);
	}
	$self->touchdir($self->cfget(qw(database inv directory)));
	$self->{_dir}{$vault_name} =
	    new App::Glacier::Directory(
		$file,
		encoding => 'json',
		mode => $self->cfget(qw(database inv mode)),
		ttl => $self->cfget(qw(database inv ttl))
	    );
    }
    return $self->{_dir}{$vault_name};
}

sub config {
    my ($self) = @_;
    return $self->{_config};
}

sub cfget {
    my ($self, @path) = @_;
    return $self->config->get(@path);
}

sub cf_transfer_param {
    my ($self, $type, $param) = @_;
    return $self->cfget('transfer', $type, $param)
	   || $self->cfget('transfer', $param);
}

sub error {
    my ($self, @msg) = @_;
    print STDERR "$self->{_progname}: " if $self->{_progname};
    print STDERR "@msg\n";
}

sub debug {
    my ($self, $l, @msg) = @_;
    if ($self->{_debug} >= $l) {
	print STDERR "$self->{_progname}: " if $self->{_progname};
	print STDERR "DEBUG: ";
	print STDERR "@msg\n";
    }
}

sub dry_run {
    my $self = shift;
    return $self->{_dry_run};
}

sub abend {
    my ($self, $code, @msg) = @_;
    $self->error(@msg);
    exit $code;
}

sub run {
    my $self = shift;
    $self->abend(EX_SOFTWARE, "command not implemented");
}

sub glacier_eval {
    my $self = shift;
    my $method = shift;
    my $wantarray = wantarray;
    my $ret = http_catch(sub {
	                    $wantarray ? [ $self->{_glacier}->${\$method}(@_) ]
				      : $self->{_glacier}->${\$method}(@_)
			 },
			 err => \my %err,
			 args => \@_);
    if (keys(%err)) {
	$self->{_last_http_err} = \%err;
    } else {
	$self->{_last_http_err} = undef;
    }
    return (wantarray && ref($ret) eq 'ARRAY') ? @$ret : $ret;
}

sub lasterr {
    my ($self, $key) = @_;
    return undef unless defined $self->{_last_http_err};
    return 1 unless defined $key;
    return  $self->{_last_http_err}{$key};
}

sub last_error_message {
    my ($self) = @_;
    return "No error" unless $self->lasterr;
    return $self->lasterr('mesg') || $self->lasterr('text');
}

sub getyn {
    my $self = shift;
    my $in;
    do {
	print "$self->{_progname}: @_? ";
	STDOUT->flush();
	$in = <STDIN>;
	$in =~ s/^\s+//;
    } while ($in !~ /^[yYnN]/);
        return $in =~ /^[yY]/;
}

# getopt(ARRAY, HASH)
sub getopt {
    my ($self, %opts) = @_;

    GetOptions("hhh|?" => sub {
		   pod2usage(-message => pod_usage_msg($self),
			     -input => pod_where({-inc => 1}, ref($self)),
			     -exitstatus => EX_OK);
	       },
	       "help" => sub {
		   pod2usage(-input => pod_where({-inc => 1}, ref($self)),
			     -exitstatus => EX_OK,
			     -verbose => 2);
	       },
	       "usage" => sub {
		   pod2usage(-input => pod_where({-inc => 1}, ref($self)),
			     -exitstatus => EX_OK,
			     -verbose => 0);
	       },
	       %opts) or exit(EX_USAGE);
}

sub set_time_style_option {
    my ($self, $style) = @_;
    
    eval {
	use App::Glacier::DateTime;
	my $x = new App::Glacier::DateTime(year=>1970);
	$x->canned_format($style);
    };
    if ($@) {
	$self->abend(EX_USAGE, "unrecognized time style: $style");
    }
    $self->{_options}{time_style} = $style;
}

sub format_date_time {
    my ($self, $obj, $field) = @_;
    return $obj->{$field}->canned_format($self->{_options}{time_style});
}

sub usage_error {
    new App::Glacier::Command(usage_error => \@_);
}

sub pod_usage_msg {
    my ($obj) = @_;
    my %args;

    my $msg = "";

    open my $fd, '>', \$msg;

    $args{-input} = pod_where({-inc => 1}, ref($obj)) if defined $obj;
    pod2usage(-verbose => 99,
	      -sections => 'NAME',
	      -output => $fd,
	      -exitval => 'NOEXIT',
	      %args);

    my @a = split /\n/, $msg;
    if ($#a < 1) {
	croak "missing or malformed NAME section for "
	      . (defined($obj) ? ref($obj): basename($0) );
    }
    $msg = $a[1];
    $msg =~ s/^\s+//;
    $msg =~ s/ - /: /;
    return $msg;
}



1;
