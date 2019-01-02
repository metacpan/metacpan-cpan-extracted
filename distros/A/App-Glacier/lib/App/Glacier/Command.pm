package App::Glacier::Command;

use strict;
use warnings;
use Carp;
use App::Glacier::Core;
use parent 'App::Glacier::Core';
use File::Basename;
use File::Spec;
use App::Glacier::EclatCreds;
use App::Glacier::Config;
use App::Glacier::Bre;
use App::Glacier::Timestamp;
use App::Glacier::Directory;
use App::Glacier::Roster;

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
		    'cachedir' => { default => '/var/lib/glacier/cache' }	
		}
	    }
	}
    },
    database => {
	section => {
	    job => {
		section => {
		    backend => { default => 'GDBM' },
		    '*' => '*'
		},
	    },
	    inv => {
		section => {
		    backend => { default => 'GDBM' },
		    '*' => '*'
		}
	    }
	}
    }
);

sub new {
    my $class = shift;
    my $argref = shift;
    local %_ = @_;

    my $config_file = delete $_{config} || $ENV{GLACIER_CONF};
    unless ($config_file) {
	$config_file = -f '/etc/glacier.conf'
	                ? '/etc/glacier.conf' : '/dev/null';
    }
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

    App::Glacier::Roster->configtest($self->cfget(qw(database job backend)),
				     $self->config, 'database', 'job')
	or exit(EX_CONFIG);
    App::Glacier::Directory->configtest($self->cfget(qw(database inv backend)),
					$self->config, 'database', 'inv')
	or exit(EX_CONFIG);

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
    }

    $self->{_glacier} = new App::Glacier::Bre($self->config->as_hash('glacier'));
    if ($self->{_glacier}->lasterr) {
	$self->abend(EX_CONFIG, $self->{_glacier}->last_error_message);
    }
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
    $self->{_jobdb} = $orig->{_jobdb};
    $self
}

sub option {
    my ($self, $opt, $val) = @_;
    if (defined($val)) {
	$self->{_options}{$opt} = $val;
    }
    return $self->{_options}{$opt};
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
        my $be = $self->cfget(qw(database job backend));
	$self->{_jobdb} = new App::Glacier::Roster(
	    $be,
	    $self->config->as_hash(qw(database job))
	);
    }
    return $self->{_jobdb};
}

sub describe_vault {
    my ($self, $vault_name) = @_;
    my $res = $self->glacier->Describe_vault($vault_name);
    if ($self->glacier->lasterr) {
	if ($self->glacier->lasterr('code') == 404) {
	    return undef;
	} else {
	    $self->abend(EX_FAILURE, "can't list vault: ",
			 $self->glacier->last_error_message);
	}
    }
    return timestamp_deserialize($res);
}

sub directory {
    my ($self, $vault_name) = @_;
    unless (exists($self->{_dir}{$vault_name})) {
	my $be = $self->cfget(qw(database inv backend));
	$self->{_dir}{$vault_name} =
	    new App::Glacier::Directory(
		$be,
		$vault_name,
		$self->glacier,
		$self->config->as_hash(qw(database inv))
	    );
    }
    return $self->{_dir}{$vault_name};
}

sub config { shift->{_config} }

sub glacier { shift->{_glacier} }

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

sub archive_cache_filename {
    my ($self, $vault_name, $archive_id) = @_;
    return File::Spec->catfile($self->cfget(qw(transfer download cachedir)),
			       $vault_name,
			       $archive_id);
}

sub check_job {
    my ($self, $key, $descr, $vault) = @_;

    $self->debug(2, "$descr->{JobId} $descr->{Action} $vault");
    if ($descr->{StatusCode} eq 'Failed') {
	$self->debug(1,
		     "deleting failed $key $vault "
		     . ($descr->{JobDescription} || $descr->{Action})
		     . ' '
		     . $descr->{JobId});
	$self->jobdb()->delete($key) unless $self->dry_run;
	return;
    }

    my $res = $self->glacier->Describe_job($vault, $descr->{JobId});
    if ($self->glacier->lasterr) {
	if ($self->glacier->lasterr('code') == 404) {
	    $self->debug(1,
			 "deleting expired $key $vault "
			 . ($descr->{JobDescription} || $descr->{Action})
			 . ' '
			 . $descr->{JobId});
	    App::Glacier::Job->fromdb($self, $vault, $key, $res)->delete()
		unless $self->dry_run;
	} else {
	    $self->error("can't describe job $descr->{JobId}: ",
			 $self->glacier->last_error_message);
	}
	return;
    } elsif (ref($res) ne 'HASH') {
	croak "describe_job returned wrong datatype (".ref($res).") for \"$descr->{JobId}\"";
    }
    return $res;
}

1;
