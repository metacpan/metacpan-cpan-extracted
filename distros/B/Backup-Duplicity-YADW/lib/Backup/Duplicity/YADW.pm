package Backup::Duplicity::YADW;
$Backup::Duplicity::YADW::VERSION = '0.12';
$Backup::Duplicity::YADW::VERSION = '0.11';
use Modern::Perl;
use Moose;
use namespace::autoclean;
use warnings FATAL => 'all';
use Smart::Args;
use Carp;
use Config::ApacheFormat;
use File::Basename;
use String::Util 'crunch', 'trim';
use IPC::Run3;
use File::Path;
use Data::Dumper;
use Sys::Syslog;
use PID::File;

use constant CONF_DIR  => '/etc/yadw';
use constant CONF_FILE => 'default.conf';

use constant PID_EXISTS => 10;

use vars qw($ErrCode $ErrStr);

# ABSTRACT: Yet Another Duplicity Wrapper


has conf_dir => ( is => 'rw', isa => 'Str', default => CONF_DIR );


has conf_file => ( is => 'rw', isa => 'Str', default => CONF_FILE );


has dry_run => ( is => 'rw', isa => 'Bool', default => 0 );


has use_syslog => ( is => 'rw', isa => 'Bool' );


has verbose => ( is => 'rw', isa => 'Bool', default => 0 );

has _conf => ( is => 'rw', isa => 'Config::ApacheFormat' );

has _pid => ( is => 'rw', isa => 'PID::File' );


sub BUILD {
	my $self = shift;

	$ErrCode = 0;

	my $conf =
		Config::ApacheFormat->new( fix_booleans     => 1,
								   autoload_support => 0 );

	$conf->read( $self->conf_dir . "/" . $self->conf_file );
	$self->_conf($conf);
	$self->_init_logs;
	$self->_write_pidfile;
}

sub backup {

	args_pos
		my $self,
		my $type => 'Str';

	$type = $type eq 'inc' ? 'incremental' : $type;

	confess "invalid type: $type"
		if $type ne 'full' and $type ne 'incremental';

	my @cmd = ( 'duplicity', $type );

	$self->_get_verbosity( \@cmd );
	$self->_get_exclude_device_files( \@cmd );
	$self->_get_incl_excl_list( \@cmd );
	$self->_get_encrypt_key( \@cmd );
	$self->_get_log_file( \@cmd );
	$self->_get_async_upload( \@cmd );
	$self->_get_s3_new( \@cmd );
	$self->_get_sourcedir( \@cmd );
	$self->_get_targetdir( \@cmd );

	$self->_system(@cmd);

	return 1;
}

sub _get_sourcedir {

	args_pos
		my $self,
		my $cmds;

	push @$cmds, $self->_conf->get('sourcedir');
}

sub _get_targetdir {

	args_pos

		# required
		my $self, my $cmds,

		# optional
		my $locaction => { isa => 'Str', optional => 1 };

	my $str = $self->_conf->get('targeturl');
	$str .= "/$locaction" if $locaction;

	push( @$cmds, $str );
}

sub _get_async_upload {

	args_pos
		my $self,
		my $cmds;

	if ( $self->_conf()->get('asyncupload') ) {
		push @$cmds, '--asynchronous-upload';
	}
}

sub _get_incl_excl_list {

	args_pos
		my $self,
		my $cmds;

	my $conf  = $self->_conf;
	my $block = $conf->block('inclexcl');
	my @list  = $block->get('list');

	for ( my $i = 0; $i < @list; $i += 2 ) {

		my $key = trim $list[$i];
		my $val = trim $list[ $i + 1 ];

		if ( $key eq '-' ) {
			$key = '--exclude';
		}
		elsif ( $key eq '+' ) {
			$key = '--include';
		}
		else {
			confess "malformed InclExcl section";
		}

		push @$cmds, $key, $val;
	}
}

sub _write_pidfile {

	args_pos my $self;

	my $conf    = $self->_conf;
	my $pidfile = $conf->get('pidfile');

	$self->_log( 'info', "pidfile=$pidfile" );

	my $pid = PID::File->new( file => $pidfile);
	
	if ( -e $pid->file ) {
		if ( $pid->running ) {
			$ErrCode = PID_EXISTS;
			$ErrStr  = "yadw is already running";
			confess $ErrStr;
		}
		else {
			$self->_log( 'notice', "removing stale pidfile $pidfile" );
			unlink $pid->file or confess "failed to remove pidfile: $!";
		}
	}

	$pid->create or confess "failed to write pidfile: $!";
	$pid->guard;  # remove pidfile automatically when it goes out of scope
	$self->_pid($pid);
}

sub _get_expire_days {

	args_pos
		my $self,
		my $cmds;

	my $days = $self->_conf->get('days2keepbackups');

	if ( !defined $days ) {
		confess "missing configuration days2keepbackups";
	}
	elsif ( !$days ) {

		#		confess "days2keepbackups must be greater than 0";
	}

	push @$cmds, $days . 'D';
}


sub expire {

	args_pos my $self;

	$self->_log( 'info', "removing old backups" );

	my @cmd = ( 'duplicity', 'remove-older-than' );

	$self->_get_expire_days( \@cmd );
	push @cmd, '--force';
	push @cmd, '--extra-clean';
	$self->_get_targetdir( \@cmd );

	$self->_system(@cmd);

	return 1;
}


sub status {
	args_pos my $self;

	my @cmd = ( 'duplicity', 'collection-status' );

	$self->_get_encrypt_key( \@cmd );
	$self->_get_s3_new( \@cmd );
	$self->_get_targetdir( \@cmd );

	$self->_system(@cmd);

	return 1;
}


sub verify {

	args_pos my $self;

	$self->_log( 'info', "verifying backups" );

	my @cmd = ( 'duplicity', 'verify' );

	$self->_get_verbosity( \@cmd );
	$self->_get_exclude_device_files( \@cmd );
	$self->_get_incl_excl_list( \@cmd );
	$self->_get_encrypt_key( \@cmd );
	$self->_get_log_file( \@cmd );
	$self->_get_s3_new( \@cmd );
	$self->_get_targetdir( \@cmd );
	$self->_get_sourcedir( \@cmd );

	$self->_system(@cmd);

	return 1;
}

sub _system {

	my $self = shift;

	$self->_log( 'info', "@_" );

	my @stderr;
	run3( [@_], undef, undef, \@stderr );
	my $exit = $? >> 8;
	if ($exit) {
		$self->_log( 'err', "@stderr" );
		confess "duplicity exited with $exit";
	}

	$self->_log( 'info', "done" );
}

sub _log {

	args_pos
		my $self,
		my $level,
		my $msg;

	if ( $self->use_syslog ) {
		syslog( $level, $msg );
	}

	$self->_verbose($msg);
}

sub _get_exclude_device_files {

	args_pos
		my $self,
		my $cmds;

	if ( $self->_conf->get('excludedevicefiles') ) {
		push @$cmds, '--exclude-device-files';
	}
}

sub _get_verbosity {

	args_pos
		my $self,
		my $cmds;

	my $level = $self->_conf->get('verbosity');

	push @$cmds, "-v$level";
}

sub _get_log_file {

	args_pos
		my $self,
		my $cmds;

	my $fullpath = $self->_conf->get('logfile');

	mkpath( dirname $fullpath);

	push @$cmds, "--log-file", $fullpath;
}

sub _get_syslog {
	args_pos my $self;

	my $toggle = $self->_conf->get('syslog');

	if ($toggle) {
		$self->use_syslog(1);
	}
	else {
		$self->use_syslog(0);
	}
}

sub _get_s3_new {

	args_pos
		my $self,
		my $cmds;

	if ( $self->_conf->get('s3usenewstyle') ) {
		push @$cmds, '--s3-use-new-style';
	}
}

sub _get_encrypt_key {

	args_pos
		my $self,
		my $cmds;

	my $key = $self->_conf->get('encryptkey');

	if ( !$key ) {
		push @$cmds, '--no-encrypt';
	}
	else {

		push @$cmds, "--encrypt-key", $key;
	}
}


sub restore {
	args

		# required
		my $self     => __PACKAGE__,
		my $location => 'Str',

		# optional
		my $days => { isa => 'Int', optional => 1 };

	$self->_log( 'info', "restoring $location" );

	my @cmd = ( 'duplicity', 'restore' );

	$self->_get_verbosity( \@cmd );
	$self->_get_encrypt_key( \@cmd );
	$self->_get_log_file( \@cmd );
	$self->_get_s3_new( \@cmd );
	$self->_get_targetdir( \@cmd );
	push( @cmd, $location );

	$self->_system(@cmd);

	return 1;
}

sub _get_dry_run {

	# TODO
}

sub _init_logs {

	args_pos my $self;

	$self->_get_syslog;

	if ( $self->use_syslog ) {
		openlog( 'backups', $$, 'user' );
	}

	$self->_log( 'info', "$0 @ARGV" );
}

sub _verbose {

	my $self = shift;

	print STDERR "[VERBOSE] @_\n" if $self->verbose;
}

__PACKAGE__->meta->make_immutable;

1;    # End of Backup::Duplicity::YADW

__END__

=pod

=encoding UTF-8

=head1 NAME

Backup::Duplicity::YADW - Yet Another Duplicity Wrapper

=head1 VERSION

version 0.12

=head1 SYNOPSIS

  $yadw = Backup::Duplicity::YADW->new;
 
  $yadw = Backup::Duplicity::YADW->new(
               conf_dir   => '/etc/mydir',
               conf_file  => 'other.conf',
               dry_run    => 0,
               use_syslog => 1,
               verbose    => 0
               );
              
  $yadw->backup();
  $yadw->verify();
  $yadw->expire();

  $yadw->restore("/my/file/location");

=head1 DESCRIPTION

This is a wrapper for Duplicity.  I found my command lines for invoking 
Duplicity getting quite lengthy and wanted a way to persist my configurations
in an intuitive manner.  I looked at several other Duplicity wrappers, but
none of them quite fit what I wanted.  So Backup::Duplicity::YADW was born.

=head1 NAME

Backup::Duplicity::YADW - Yet Another Duplicity Wrapper

=head1 VERSION

version 0.11

=head1 ATTRIBUTES

=head2 conf_dir

Config file path.  Default is /etc/yadw.

=head2 conf_file

Config file name.  Default is default.conf.

=head2 dry_run

Do a dry run.

=head2 use_syslog

Tells the module to write log data using the syslog facility

=head2 verbose

Print extra messages about whats going on.

=head1 METHODS

=head2 new( [ %attributes ] )

Constructor - 'nuff said

=head2 backup( $type )

Tell duplicity to do a backup.  Requires either 'full' or 'inc' for a type.
Returns true on success.

=head2 expire( )

Tell duplicity to "remove-older-than <days in conf file>".

=head2 status( )

Equivalent to "collection-status" in duplicity.  Returns true on success.

=head2 verify( )

Tell duplicity to verify backups.  Returns true on success.

=head2 restore( %args )

Tell duplicity to do a restore.

Required args:

  location => $path

Optional args:

  time => $time (see duplicity manpage)

Returns true on success.

=head1 SEE ALSO

yadw (ready to use backup script)

=head1 AUTHOR

John Gravatt <john@gravatt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by John Gravatt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

John Gravatt <john@gravatt.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by John Gravatt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
