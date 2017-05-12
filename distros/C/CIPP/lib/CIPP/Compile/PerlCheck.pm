# $Id: PerlCheck.pm,v 1.9 2004/11/04 13:22:13 joern Exp $

package CIPP::Compile::PerlCheck;

@ISA = qw( CIPP::Debug );

$VERSION = "0.01";

use strict;
use Carp;
use FileHandle;
use IPC::Open2;
use Config;
use CIPP::Compile::Message;
use CIPP::Debug;

sub get_fh_read			{ shift->{fh_read}			}
sub get_fh_write		{ shift->{fh_write}			}
sub get_tmp_dir			{ shift->{tmp_dir}			}
sub get_pid			{ shift->{pid}				}

sub get_lib_path		{ shift->{lib_path}			}
sub get_config_dir		{ shift->{config_dir}			}
sub get_directory		{ shift->{directory}			}
sub get_name			{ shift->{name}				}

sub set_lib_path		{ shift->{lib_path}		= $_[1]	}
sub set_config_dir		{ shift->{config_dir}		= $_[1]	}
sub set_directory		{ shift->{directory}		= $_[1]	}
sub set_name			{ shift->{name}			= $_[1]	}

sub new {
	my $type = shift;
	my %par = @_;
	my  ($directory, $lib_path, $config_dir, $name) =
	@par{'directory','lib_path','config_dir','name'};
	
	my $fh_read  = FileHandle->new;
	my $fh_write = FileHandle->new;
	
	# find perlcheck.pl
	my $perlcheck_program;
	
	for ( @INC ) {
		if ( -x "$_/CIPP/Compile/cipp_perlcheck.pl" ) {
			$perlcheck_program =
				"$_/CIPP/Compile/cipp_perlcheck.pl";
			last;
		}
	}

	croak "No executable cipp_perlcheck.pl found"
		if not -x $perlcheck_program;

	my $perl = $Config{perlpath};

	my $pid = open2 ($fh_read, $fh_write, "$perl $perlcheck_program")
		or croak "can't call open2('$perl $perlcheck_program')";
	
	my $tmp_dir = ($^O =~ /win/i) ? "C:/TEMP" : "/tmp";

	$directory ||= $tmp_dir;

	my $self = {
		fh_read    => $fh_read,
		fh_write   => $fh_write,
		tmp_dir    => $tmp_dir,
		config_dir => $config_dir,
		lib_path   => $lib_path,
		directory  => $directory,
		pid        => $pid,
		name 	   => $name,
	};
	
	return bless $self, $type;
}

sub check {
	my $self = shift;
	my %par = @_;
	my  ($code_sref, $parse_result, $output_file) =
	@par{'code_sref','parse_result','output_file'};

	croak "code_sref missing" if not $code_sref;

	my $action = $output_file ? "execute $output_file" : "check";

	my $fh_write = $self->get_fh_write;
	
	my $delimiter = "__PERL_CODE_DELIMITER__";
	while ( $$code_sref =~ /$delimiter/ ) {
		$delimiter .= $$;
	}
	
	# send request to perlcheck.pl process

	my $directory  = $self->get_directory;
	my $lib_path   = $self->get_lib_path;
	my $tmp_dir    = $self->get_tmp_dir;
	my $config_dir = $self->get_config_dir;

	writelog("write request data: action='$action'");

	print $fh_write <<__EOP;
$action
$directory
$lib_path
$tmp_dir
$config_dir
$delimiter
$$code_sref
$delimiter
__EOP

	# read answer
	$delimiter = $self->read_line;
	chomp $delimiter;

	my $result = "";
	my $line;
	while ( $line = $self->read_line($delimiter) ) {
		chomp $line;
		last if $line eq $delimiter;
		$result .= "$line\n";
	}

	writelog("finished reading");
	
	return $result if not $parse_result;

	writelog("now parse result and return");

	my $messages = $self->parse_result (
		code_sref   => $code_sref,
		error_sref  => \$result
	);
	
	use Data::Dumper;
	writelog("result parsed, messages=".Dumper($messages));

	return $messages;
}	

sub read_line {
	my $self = shift;
	my ($delimiter) = @_;

	my $fh = $self->get_fh_read;

	my $line;

	writelog("read_line");
	
	eval {
		local $SIG{ALRM} = sub { die "timeout" };
		return $delimiter if eof($fh);
		alarm 5;
		$line = <$fh>;
		alarm 0;
	};

	if ( $@ =~ /timeout/ ) {
		writelog("got timeout");
		$line = $delimiter;
	}
	
	writelog("left read_line");

	return $line;
}

sub parse_result {
	my $self = shift;
	my %par = @_;
	my  ($code_sref, $error_sref) =
	@par{'code_sref','error_sref'};

	my @errors = split (/\n/, $$error_sref);
	my @code = split (/\n/, $$code_sref);

	my $found_error;
	my @messages;

	foreach my $error ( @errors ) {
		next if $error =~ /BEGIN not safe/;
		my ($line) = $error =~ m!\(eval\s+\d+\)\s+line\s+(\d+)!;
		next if not $line;

		my $i = $line+1;

		my $cipp_line = -1;
		my $cipp_call_path = "";

		$error =~ s/at\s+\(eval\s+\d+\).*//;

		my $code_line_found = 0;
		while ( $i > 0 ) {
			if ( $code[$i] =~ /^#\s+cipp_line_nr=(\d+)\s+(\w+)/ ) {
				push @messages, CIPP::Compile::Message->new (
					type    => 'perl_err',
					name    => $self->get_name,
					line_nr => $1,
					tag     => $2,
					message => $error,
				);
				$code_line_found = 1;
				last;
			}
			--$i;
		}

		if ( not $code_line_found ) {
			push @messages, CIPP::Compile::Message->new (
				type    => 'perl_err',
				name    => $self->get_name,
				line_nr => "unknown",
				tag     => "unknown",
				message => $error,
			);
		}

		$found_error = 1;
	}

	if ( not $found_error and $$error_sref ne '' ) {
		push @messages, CIPP::Compile::Message->new (
			type => 'perl_err',
			name => $self->get_name,
			line_nr => 0,
			tag => 'unknown',
			message => $$error_sref,
		);
	}

	return \@messages;
}

sub DESTROY {
	my $self = shift;

	my $fh_write = $self->get_fh_write;
	my $fh_read  = $self->get_fh_read;
	
	# an empty line let the perlcheck.pl process exit
	print $fh_write "\n";

	# close the filehandles
	close $fh_read;
	close $fh_write;
	
	# this prevents zombies, open2 doesn't call wait
	waitpid ($self->get_pid, 0);
	
	1;
}

sub writelog {
	my ($msg) = @_;
	return if not -f "/tmp/do.the.cipp3debug";
	my $date = scalar(localtime(time));
	open (LOG, ">> /tmp/perlcheck.log");
	select LOG; $| = 1; select STDOUT;
	print LOG "-" x 80, "\n";
	print LOG "PerlCheck: $date $$\t$msg\n";
	close LOG;
	
	1;
}

1;
