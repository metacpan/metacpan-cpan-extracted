###############################################################################
#
# Apache::Voodoo::Install::Updater - Update xml processor
#
# This package provides the internal methods use by voodoo-control that do
# pre/post/upgrade commands as specified by the various .xml files in an
# application.  It's not intended to be use directly by end users.
#
###############################################################################
package Apache::Voodoo::Install::Updater;

$VERSION = "3.0200";

use strict;
use warnings;

use base("Apache::Voodoo::Install");

use Apache::Voodoo::Constants;

use CPAN;
use DBI;
use Digest::MD5;
use Sys::Hostname;
use XML::Checker::Parser;
use File::Find;
use Config::General qw(ParseConfig);

# make CPAN download dependancies
$CPAN::Config->{'prerequisites_policy'} = 'follow';

################################################################################
# Creates a new updater object with given configuration options.  It assumes
# that the files for the application have already been installed or exist in
# appropriate location.  A good database security setup would not allow the
# user the application connects as to have alter, create or drop privileges; thus
# the need for the database root password.  If pretend is set to a true value,
# the operations are stepped through, but nothing actually happens.
#
# usage:
#    Apache::Voodoo::Install::Updater->new(
#		dbroot   => $database_root_password,
#		app_name => $application_name,
#		verbose  => $output_verbosity_level,
#		pretend  => $boolean
#	);
################################################################################
sub new {
	my $class = shift;
	my %params = @_;

	my $self = {%params};

	my $ac = Apache::Voodoo::Constants->new();
	$self->{'_md5_'} = Digest::MD5->new;

	$self->{'install_path'} = $ac->install_path()."/".$self->{'app_name'};

	$self->{'conf_file'}    = $self->{'install_path'}."/".$ac->conf_file();
	$self->{'conf_path'}    = $self->{'install_path'}."/".$ac->conf_path();
	$self->{'updates_path'} = $self->{'install_path'}."/".$ac->updates_path();
	$self->{'apache_uid'}   = $ac->apache_uid();
	$self->{'apache_gid'}   = $ac->apache_gid();

	unless (-e $self->{'conf_file'}) {
		die "Can't open configuration file: $self->{'conf_file'}\n";
	}

	bless $self, $class;

	return $self;
}

# Causes the update chain to execute:  pre-setup.xml, unapplied updates, post-setup.xml
sub do_update      { $_[0]->_do_all(0); }

# Causes the new install chain to execute:  pre-setup.xml, setup.xml,
# post-setup.xml, mark all updates applied.  If this is executed on an
# existing system, Bad Things(tm) can happen depending on what commands
# are present in setup.xml
sub do_new_install { $_[0]->_do_all(1); }

# Wizard mode function.  This performs a replace into on the _updates table
# of a system to have entries and correct checksums for each update file
# without actually executing them.  If something went wrong with an install or
# upgrade and manual tinkering was required to get things back in order, this
# method can be used to ensure that the _updates table appears current.
sub mark_updates_applied {
	my $self = shift;

	my %conf = ParseConfig($self->{'conf_file'});

	$self->mesg("- Connection to database");
	$self->{'dbh'} = DBI->connect($conf{'database'}->{'connect'},'root',$self->{'dbroot'}) || die DBI->errstr;

	$self->mesg("- Looking for update command xml files");

	$self->_record_updates($self->_find_updates());

	$self->mesg("- All updates marked as applied");
}

sub _do_all {
	my $self = shift;
	my $new  = shift;

	my %conf = ParseConfig($self->{'conf_file'});

	if ($new) {
		$self->mesg("- Creating database");

		# FIXME create a factory structure to support multiple database types.
		my $c = $conf{'database'}->{'connect'};
		my ($dbname) = ($c =~/database=([^;]+)/);
		$c =~ s/database=[^;]+/database=test/;

		$self->{'dbh'} = DBI->connect($c,'root',$self->{'dbroot'}) || die DBI->errstr;
		$self->{'dbh'}->do("CREATE DATABASE $dbname"); # allowed to silently fail, db may already exist
		$self->{'dbh'}->disconnect;

		$self->{'dbh'} = DBI->connect($conf{'database'}->{'connect'},'root',$self->{'dbroot'}) || die DBI->errstr;

		$self->mesg("- Looking for setup command xml files");
	}
	else {
		$self->mesg("- Connection to database");
		$self->{'dbh'} = DBI->connect($conf{'database'}->{'connect'},'root',$self->{'dbroot'}) || die DBI->errstr;

		$self->mesg("- Looking for update command xml files");
	}

	# even if this is a new installation, we still need a list of the update files that came with
	# this distribution so that we'll know what updates to *not* perform in the event of an upgrade
	my @updates = $self->_find_updates();

	my @files;
	push(@files,$self->_find('pre-setup'));

	if ($new) {
		push(@files,$self->_find('setup'));
	}
	else {
		push(@files,@updates);
	}

	push(@files,$self->_find('post-setup'));

	# remove any "gaps".  There might not have been a pre/post/setup file.
	@files = grep { defined($_) } @files;

	my @commands = $self->_parse_commands(@files);

	$self->_execute_commands(@commands);

	# as noted above.  even for new installs we need to keep track of what updates
	# were part of this distro so we don't do them on the next update.
	$self->_record_updates(@updates);
}

sub _find {
	my $self = shift;
	my $file = shift;

	my $path = $self->{'conf_path'};
	if (-e "$path/$file.xml") {
		$self->debug("    $file.xml");
		return "$path/$file.xml";
	}

	return undef;
}

sub _find_updates {
	my $self = shift;

	return () unless (-e $self->{'updates_path'});

	my @updates;
	find({
			wanted => sub {
				my $file = $_;
				if ($file =~ /\d+\.\d+\.\d+(-[a-z\d]+)?\.xml$/) {
					push(@updates,$file);
				}
			},
			no_chdir => 1,
			follow   => 1
		},
		$self->{'updates_path'}
	);

	# Swartzian transform
	@updates = map {
		$_->[0]
	}
	sort {
		$a->[1] <=> $b->[1] ||
		$a->[2] <=> $b->[2] ||
		$a->[3] <=> $b->[3] ||
		defined($b->[4]) <=> defined($a->[4]) ||
		$a->[4] cmp $b->[4]
	}
	map {
		my $f = $_;
		s/.*\///;
		s/\.xml$//;
		[ $f , split(/[\.-]/,$_) ]
	}
	@updates;

	$self->_touch_updates_table();

	return grep { ! $self->_is_applied($_) } @updates;
}

sub _touch_updates_table {
	my $dbh = $_[0]->{'dbh'};

	my $res = $dbh->selectall_arrayref("SHOW TABLES LIKE '_updates'");
	unless (defined($res->[0]) && $res->[0]->[0] eq "_updates") {
		# not there.  create it.
		$dbh->do("
			CREATE TABLE _updates (
				file VARCHAR(255) NOT NULL PRIMARY KEY,
				checksum VARCHAR(32) NOT NULL
			)") || die DBI->errstr;
	}
}

sub _record_updates {
	my $self  = shift;
	my @files = @_;

	$self->_touch_updates_table();

	my $dbh = $self->{'dbh'};

	foreach my $file (@files) {
		my $sum = $self->_md5_checksum($file);
		$file =~ s/.*\///;
		$file =~ s/\.xml//;
		$dbh->do("REPLACE INTO _updates(file,checksum) VALUES(?,?)",undef,$file,$sum) || die DBI->errstr;
	}
}

sub _is_applied {
	my $self = shift;
	my $file = shift;

	my $dbh = $self->{'dbh'};

	my $f = $file;
	$f =~ s/.*\///;
	$f =~ s/\.xml//;

	my $res = $dbh->selectall_arrayref("
		SELECT
			checksum
		FROM
			_updates
		WHERE
			file = ?",undef,
		$f) || die DBI->errstr;

	if (defined($res->[0]->[0])) {
		if ($res->[0]->[0] ne $self->_md5_checksum($file)) {
			# YIKES!!! this update file doesn't match the one
			# we think we've already ran.
			print "MD5 checksum of $f doesn't match the one store in the DB.  aborting\n";
			exit;
		}
		else {
			return 1;
		}
	}
	else {
		return 0;
	}
}

sub _md5_checksum {
	my $self = shift;
	my $file = shift;

	my $md5 = $self->{'_md5_'};
	$md5->reset;

	open(F,$file) || die "Can't md5 file $file: $!";
	$md5->add(<F>);
	close(F);

	return $md5->hexdigest;
}

sub _parse_commands {
	my $self  = shift;

	my @commands;
	foreach my $file (@_) {
		my $data = $self->_parse_xml($file);

		if (!defined($data)) {
			print "\n* Parse of $file failed. Aborting *\n";
			exit;
		}
		print "    parsed $file\n";
		push(@commands,[$file,$data]);
	}
	return @commands;
}

sub _parse_xml {
	my $self    = shift;
	my $xmlfile = shift;

	my $parser = new XML::Checker::Parser(
		'Style' => 'Tree',
		'SkipInsignifWS' => 1
	);

	my $dtdpath = $INC{'Apache/Voodoo/Install/Updater.pm'};
	$dtdpath =~ s/Install\/Updater\.pm$//;

	$parser->set_sgml_search_path($dtdpath);

	my $data;
	eval {
			# parser checker only dies on catastrophic errors.  Adding this handler
			# makes it die on ALL errors.
			local $XML::Checker::FAIL = sub {
				my $errcode = shift;

				print "\n ** Parse of $xmlfile failed **\n";
				die XML::Checker::error_string ($errcode, @_) if $errcode < 200;
				XML::Checker::print_error ($errcode, @_);
			};

			$data = $parser->parsefile($xmlfile);
	};
	if ($@) {
			print $@;
			return undef;
	}
	return $data;

}

sub _execute_commands {
	my $self = shift;
	my @set  = @_;

	my $pretend      = $self->{'pretend'};
	my $install_path = $self->{'install_path'};

	chdir($install_path);

	# find out what our hostname is
	my $hostname = Sys::Hostname::hostname();

	$self->info("- Running setup/update commands");
	foreach (@set) {
		my $file = $_->[0];
		my @commands = @{$_->[1]->[1]};

		$self->debug("    $file");
		for (my $i=1; $i < $#commands; $i+=2) {
			my $type = $commands[$i];
			my $data = $commands[$i+1]->[2];

			if (defined($commands[$i+1]->[0]->{'onhosts'})) {
				next unless grep { /^$hostname$/ } split(/\s*,\s*/,$commands[$i+1]->[0]->{'onhosts'});
			}

			# Reset the current working directory back to the install path
			chdir($install_path);

			$data =~ s/^\s*//;
			$data =~ s/\s*$//;

			if ($type eq "shell") {
				$self->debug("        SHELL: ", $data);
				unless ($self->{pretend}) {
					if (system($data)) {
						$self->{ignore} or die "Shell command failed: $!";
					}
				}
			}
			elsif ($type eq "sql") {
				$self->_execute_sql($data);
			}
			elsif ($type eq "mkdir") {
				$self->debug("        MKDIR: ", $data);
				$self->make_writeable_dirs("$install_path/$data");
			}
			elsif ($type eq "mkfile") {
				$self->debug("        TOUCH/CHMOD: ", $data);
				$self->make_writeable_files("$install_path/$data");
			}
			elsif ($type eq "install") {
				$self->debug("        CPAN Install: ", $data);
				unless ($pretend) {
					CPAN::Shell->install($data);
				}
			}
			else {
				print "\n* Unsupported command type ($type). Aborting *\n";
				exit;
			}
		}
	}
}

sub _execute_sql {
	my $self = shift;
	my $data = shift;

	$self->debug("        SQL: ", $data);
	return if $self->{'pretend'};

	my $path = $self->{'install_path'};
	my $dbh  = $self->{'dbh'};

	if ($data =~ /^source\s/i) {
		$data =~ s/^source\s*//i;

		my ($query,$in_quote,$close_quote);
		open(SQL,"$path/$data") || die "Can't open $path/$data: $!";
		while (!eof(SQL)) {
			my $c = getc SQL;
			if (!$in_quote && $c eq ';') {
				$query =~ s/^\s*//;
				$query =~ s/\s$//;
				next if ($query =~ /^[\s;]*$/);        # an empty query turns a do into a don't
				next if ($query =~ /^(UN)?LOCK /i);    # do yacks on these too

				unless ($dbh->do($query)) {
					$self->{ignore} or die "sql source failed $query: " . DBI->errstr;
				}

				$query = '';
				$c = getc SQL;
			}

			if ($c eq '\\') {
				$query .= $c;
				$c = getc SQL;  # automatically add the next character
			}
			elsif ($c eq "'") {
				if ($in_quote && $close_quote eq "'") {
					$in_quote = 0;
					$close_quote = '';
				}
				elsif (!$in_quote) {
					$in_quote = 1;
					$close_quote = "'";
				}
			}
			elsif ($c eq '"') {
				if ($in_quote && $close_quote eq '"') {
					$in_quote = 0;
					$close_quote = '';
				}
				elsif (!$in_quote) {
					$in_quote = 1;
					$close_quote = '"';
				}
			}

			$query .= $c;
		}
		close(SQL);
	}
	else {
		unless ($dbh->do($data)) {
			$self->{ignore} or die "sql failed: DBI->errstr\n\n$data";
		}
	}
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
