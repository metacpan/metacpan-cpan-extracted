package App::Glacier::Command;

use strict;
use warnings;
use Carp;
use App::Glacier::Core;
use parent 'App::Glacier::Core';
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
    my $argref = shift;
    local %_ = @_;

    my $config_file = delete $_{config}
                      || $ENV{GLACIER_CONF}
                      || "/etc/glacier.conf";
    my $account = delete $_{account};
    my $region = delete $_{region};

    my $debug = delete $_{debug};
    my $dry_run = delete $_{dry_run};
    my $progname = delete $_{progname};
    
    my $self = $class->SUPER::new($argref, %_);

    $self->{_debug} = $debug if $debug;
    $self->{_dry_run} = $dry_run if $dry_run;
    $self->progname($progname) if $progname;
    
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

    if ($region) {
	$self->{_config}->set(qw(glacier region), $region);
    } elsif (!$self->{_config}->isset(qw(glacier region))) {
	$self->{_config}->set(qw(glacier region), 'eu-west-1');
    }
    
    $self->{_glacier} = new Net::Amazon::Glacier(
	$self->{_config}->get(qw(glacier region)),
	$self->{_config}->get(qw(glacier access)),
	$self->{_config}->get(qw(glacier secret))
	);

    return $self;
}

# Produce a semi-flat clone of $orig, blessing it into $class.
# The clone is semi-flat, because it shares the parsed configuration and
# the glacier object with the $orig.
sub clone {
    my ($class, $orig) = @_;
    my $self = $class->SUPER::clone($orig);
    $self->{_config} = $orig->config; 
    $self->{_glacier} = $orig->{_glacier};
    $self
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

1;
