package Crop::Install;
use base qw/ Crop /;

=begin nd
Class: Crop::Install
	Generate the Apache config and run sql scripts.

Example:
(start code)
#! /usr/bin/perl

use v5.14;
use warnings;

use Crop::Install;

my $install = Crop::Install->new(__FILE__);

$install->generate_fcgi_config('init.conf');
$install->sql('http.sql');
$install->complete;
(end)
=cut

use v5.14;
use warnings;

use IO::File;
use Pg::CLI::psql;

use constant {
# 	FCGI_TPL_PATH  => '/fcgi',
# 	FCGI_CONF_PATH => '/conf/fcgid.conf.example',
	SQL_PATH       => '/sql',
	DONE_PATH => '/steps.done',
	DEFAULT_DB     => 'main',
};

=begin nd
Constructor new ($stepname, $db)
	Remember $stepname and $db.
	
Parameters:
	$stepname - step filename withou dir
	$db       - optinal database name
	
Returns:
	$self
=cut
sub new {
	my ($class, $stepname, $db) = @_;

	$stepname =~ s!^.*/!!;
	$db //= DEFAULT_DB;

	bless {
		stepname => $stepname,
		db       => $db,
	}, $class;
}

=begin nd
Method: complete ($message)
	Finalize step.
	
Parameters:
	$message - to caller
=cut
sub complete {
	my ($self, $message) = @_;

	my $path = $self->C->{install}{path} . DONE_PATH;
	
	my $completed = IO::File->new(">> $path") or die "Can't open special 'steps.completed' file '$path': $!";
	say $completed "$self->{stepname}";
	close $completed or die "Can't close special 'steps.completed' file $path: $!";

	binmode STDOUT, ":utf8";
	say $message || "Done";
}

=begin nd
Method: sql ($filename)
=cut
sub sql {
	my ($self, $filename) = @_; 

	my $undo = $ARGV[0];
	if ($undo && $undo eq '--undo') {
		$filename =~ s/(\.sql)\Z/\.undo$1/g;
		print "> SQL undo step: ".$self->{stepname}." called\n";
		print "> undo filename=$filename;\n";
	} else {
		print "> SQL commit step: ".$self->{stepname}." called\n";
		print "> filename=$filename;\n";
	}
	
	die 'No sql filename specified' unless defined $filename and $filename =~ /\.sql$/;

	my $C = $self->C;

# 	die "It's not allowed to alter tables with that script. Check the <sql_master> tag in global.xml." unless $C->{sql_master};

	my $dbconf = $C->{warehouse}{db}{$self->{db}};
	my $statement_file = $C->{install}{path} . SQL_PATH . "/$filename";
	
	my $fh = IO::File->new("< $statement_file") or die "Can't open SQL file $statement_file: $!";
	my $statement;
	while (<$fh>) {
		s/\@{2}DBUSER\@{2}/$dbconf->{role}{user}{login}/g;
		$statement .= $_;
	}

	$fh->close or die "Can not close SQL file: $!";

	my $psql = Pg::CLI::psql->new(
		username => $dbconf->{role}{admin}{login},
		password => $dbconf->{role}{admin}{pass},
		host     => $dbconf->{server}{host},
		port     => $dbconf->{server}{port},
	);

	my $errors;
	my $s = $psql->run(
		database => $dbconf->{name},
		stdin    => \$statement,
		stderr   => \$errors
	);

	die "Can not execute:\n$statement \n $errors" if $errors =~ /ERROR:/;
}

1;
