#####################################################################
# Plain.pm 
# Copyright (c) 1999, 2000 by Markus Winand       <mws@fatalmind.com>
#
# Base class for cached config file reading
#
# $Id: Plain.pm,v 1.11 2000/06/25 17:08:56 mws Exp $
#

#####################################################################
# History see in pod part of file
# 
# TODO:
#    -> Translation tables
#    -> includes
#    -> time out
#    -> cgi-script (and related api) for statistics/error reporting...

package CONFIG::Plain;

use strict;
use FileHandle;
use Cwd;

#####################################################################
# initialize global structure for comment styles

BEGIN {
	$CONFIG::Plain::comment_style->{sh}->{COUNT}
 		= \&comment_type_sh_count;
	$CONFIG::Plain::comment_style->{sh}->{REMOVE}
		= \&comment_type_sh_remove;
	$CONFIG::Plain::comment_style->{sh}->{ANTIESCAPE}
		= \&comment_type_sh_antiescape;

	$CONFIG::Plain::comment_style->{'C++'}->{COUNT}
 		= \&comment_type_cpp_count;
	$CONFIG::Plain::comment_style->{'C++'}->{REMOVE}
		= \&comment_type_cpp_remove;
	$CONFIG::Plain::comment_style->{'C++'}->{ANTIESCAPE}
		= \&comment_type_cpp_antiescape;

	$CONFIG::Plain::comment_style->{'C'}->{COUNT}
 		= \&comment_type_c_count;
	$CONFIG::Plain::comment_style->{'C'}->{REMOVE}
		= \&comment_type_c_remove;
	$CONFIG::Plain::comment_style->{'C'}->{ANTIESCAPE}
		= \&comment_type_c_antiescape;
	
	$CONFIG::Plain::comment_style->{asm}->{COUNT}
 		= \&comment_type_asm_count;
	$CONFIG::Plain::comment_style->{asm}->{REMOVE}
		= \&comment_type_asm_remove;
	$CONFIG::Plain::comment_style->{asm}->{ANTIESCAPE}
		= \&comment_type_asm_antiescape;

	$CONFIG::Plain::comment_style->{'sql'}->{COUNT}
 		= \&comment_type_sql_count;
	$CONFIG::Plain::comment_style->{'sql'}->{REMOVE}
		= \&comment_type_sql_remove;
	$CONFIG::Plain::comment_style->{'sql'}->{ANTIESCAPE}
		= \&comment_type_sql_antiescape;

	$CONFIG::Plain::comment_style->{'pascal'}->{COUNT}
 		= \&comment_type_pascal_count;
	$CONFIG::Plain::comment_style->{'pascal'}->{REMOVE}
		= \&comment_type_pascal_remove;
	$CONFIG::Plain::comment_style->{'pascal'}->{ANTIESCAPE}
		= \&comment_type_pascal_antiescape;

	$CONFIG::Plain::comment_style->{'regexp'}->{COUNT}
 		= \&comment_type_regexp_count;
	$CONFIG::Plain::comment_style->{'regexp'}->{REMOVE}
		= \&comment_type_regexp_remove;
	$CONFIG::Plain::comment_style->{'regexp'}->{ANTIESCAPE}
		= \&comment_type_regexp_antiescape;
}

#####################################################################
# Important data structures used in this file
# 
# the mayor variable is 
#                             CONFIG::Plain::already_open_configs
# this hash holds a reference for every open file.
# the key is the ABSOLUTE filename.
# the data structure referenced by the value is called COMMON because
# it holds the information which have all instances in common.
# NOTE: this variable has got a class (no an object) scope!
# 
# every object has got a referenc to the correspondenting COMMON structure
# called $self->{COMMON}
# note: one common structure may referenced by more then one object
#
# and every object has got a private structure to hold the cursors
# this structure is referenced by $self->{CURSORS}


#####################################################################
# new
# 
# constructor
#
# parameters: 1st -> class
#	      2nd -> scalar holding filename
#                    OR ref to hash holding config parameters 
#                    including the filename in the "FILE" key
#                    or the data itselve in the "DATA" key		
#             3rd -> ref to hash holding config parameters if the
#                    2nd arg was a scalar
#	      4th -> (optional) for internal use only
#                    include path (array ref)
#		     only allowed if 2nd arg is scalar!
#	   return -> undef or object referenc
sub new {
        my $proto    = shift;
        my $class    = ref($proto) || $proto;
        my $self     = {};
	my $filename = shift;
	my $config   = shift;
	my $include_path = shift;
	my @include_path;
	my $pwd;
	my %COMMON;
	my %CONFIG;
	my $key;

	# check parameters
	if (ref($filename) eq "HASH") {
		$config   = $filename;
		$filename = $filename->{FILE}; 
	}

	if (! defined $include_path) {
		$include_path = [];	
	}
	
	@include_path = ($include_path);

	# make absolute path
	if ($filename !~ /^\//) {
		$pwd = getcwd;
		chomp($pwd);
		$filename = $pwd ."/". $filename;
	}
	
	push @include_path, $filename;

	# if file is unknown
	if (! defined $CONFIG::Plain::already_open_configs{$filename}) {
		# create data struct for file
		$COMMON{FILENAME}	= $filename;
		$COMMON{GLOBALERROR}	= ();
		$COMMON{USED}		= 0;
		$COMMON{ACTIVE}		= 0;
		$COMMON{READS}		= 0;
		$COMMON{CACHELINES}	= 0;

		$CONFIG{COMMENT}	= 'sh C++ C';
		$CONFIG{ESCAPE}		= '\\\\';
		$CONFIG{DELEMPTYLINE}	= 1;	
		$CONFIG{REMOVETRAILINGBLANKS} = 1; 
		$CONFIG{INCLUDE}	= "include <(.*?)>";

		foreach $key (keys %$config) {
			$CONFIG{$key} = $config->{$key};	
		}
		
		$COMMON{CONFIG}   = \%CONFIG;
		$COMMON{CONFIG}->{COMMENT_FUNCTIONS} = 
			parse_comment_styles($COMMON{CONFIG}->{COMMENT});
		$CONFIG::Plain::already_open_configs{$filename} = \%COMMON;
	} 
	bless($self, $class);
	
	$self->{COMMON} = $CONFIG::Plain::already_open_configs{$filename};
	$self->{CURSORS}->{getline} = 0;
	$self->{CURSORS}->{getline_error} = 0;
	$self->{CURSORS}->{global_error} = 0;
	$self->{COMMON}->{USED}++;
	$self->{COMMON}->{ACTIVE}++;
	$self->{INCLUDEPATH} = \@include_path;

	$self->{COMMON}->{REPARSE} = '0';	
	$self->read_file;

	return $self;
}

sub close{
	my ($self) = @_;
}

sub reparse {
	my ($self) = @_;

	return $self->{COMMON}->{REPARSE};
}

sub open_configs {
	my @list = ();
	my $key;

	foreach $key (keys(%CONFIG::Plain::already_open_configs)) {
		if (defined $CONFIG::Plain::already_open_configs{$key}) {
			push @list, $key;
		}
	}
	return @list;	
}

sub config_type($) {
	my ($file) = @_;

	return $CONFIG::Plain::already_open_configs{$file}->{'_CODE_TYPE'};
}

sub file_last_changed($) {
	my ($self) = @_; 
	return $self->{COMMON}->{FILETIME};
}

sub file_last_read($) {
	my ($self) = @_;
	return $self->{COMMON}->{LASTREAD};
}

sub file_size($) {
	my ($self) = @_;
	return $self->{COMMON}->{FILEBYTES};
}

sub file_lines($) {
	my ($self) = @_;
	return $self->{COMMON}->{FILELINES};
}

sub cache_size($) {
	my ($self) = @_;
	return $self->{COMMON}->{CACHEBYTES};
}

sub cache_lines($) {
	my ($self) = @_;
	return $self->{COMMON}->{CACHELINES};
}
sub file_read($) {
	my ($self) = @_;
	return $self->{COMMON}->{USED};
}

sub file_config($) {
	my ($self) = @_;
	my %hash;
	
	%hash = %{$self->{COMMON}->{CONFIG}};	

	# remove internal stuff
	delete $hash{COMMENT_FUNCTIONS};
	return \%hash;
}


sub DESTROY {
	my ($self) = @_;

	$self->{COMMON}->{ACTIVE}--;
}

#####################################################################
# read_file
#
# check if file has to be (re)read
#
# parameters: 1st -> object ref
sub read_file ($) {
	my ($self) = @_;
	my @f_stat;

	$self->{COMMON}->{LASTCHECKED} = time;	
	$self->{COMMON}->{GLOBALERROR} = ();

	if (! defined $self->{COMMON}->{LASTREAD}) {
		return $self->force_read_file;
	}

	if (! defined $self->{COMMON}->{CONFIG}->{DATA}) {
		# no reread required if DATA option was used
		@f_stat = stat($self->{COMMON}->{FILENAME});
	
		if ($f_stat[9] > $self->{COMMON}->{LASTREAD}) {
			$self->{COMMON}->{LASTCHANGED} = 
						scalar(localtime($f_stat[9]));
			return $self->force_read_file;	
		}
	}
}

#####################################################################
# force_read_file
#
# try to open file, (create error if neccessary) and set timestamp
sub force_read_file {
	my ($self) = @_;
	my $fh = new FileHandle;
	my @f_stat;

	if (defined $self->{COMMON}->{CONFIG}->{DATA}) {
		$self->{COMMON}->{LASTREAD} = time;
		$self->{COMMON}->{FILETIME} = time;
		$self->read_file_into_cache();
	} elsif ($fh->open($self->{COMMON}->{FILENAME})) {
		$self->{COMMON}->{LASTREAD} = time;
		@f_stat = stat($fh);
		$self->{COMMON}->{FILETIME} = $f_stat[9];
		$self->read_file_into_cache($fh);	
	} else {
		push(@{$self->{COMMON}->{GLOBALERROR}}, $!);
	} 
}

#####################################################################
# read_file_into_cache
#
# reads the file linewhise into the memory and applyies the
# configuration options (remove comments and so on...)
#
# parameters: 1st -> object
#             2nd -> filehandle
sub read_file_into_cache {
	my ($self, $fh) = @_;
	my $linenr = undef;	# first input_linenr of multi line
	my $input_linenr = 0;
	my $line;
	my $long_line = "";
	my $cache_bytes = 0;
	my $file_bytes  = 0;

	$self->{COMMON}->{REPARSE}     = '1';
	$self->{COMMON}->{PLAINFILE}   = "";	
	$self->{COMMON}->{LINESFILE}   = ();
	$self->{COMMON}->{LINESFILE_unparsed} = ();
	$self->{COMMON}->{INPUTLINE}   = ();
	$self->{COMMON}->{FILELINE}    = ();
	$self->{COMMON}->{GLOBALERROR} = ();
	$self->{COMMON}->{LINEERROR}   = ();
	
	if (defined $fh) {
		$line = $fh->getline;
	} else {
		if ($self->{COMMON}->{CONFIG}->{DATA} !~ m/\n$/s) {
			$self->{COMMON}->{CONFIG}->{DATA} .= "\n";
		}

		$self->{COMMON}->{CONFIG}->{DATA} =~ s/^(.*?\n)(.*)$/$2/s; 
		$line = $1;
	}

	while (defined $line) {
		$input_linenr ++;
		$self->{COMMON}->{LINESFILE_unparsed}->[$input_linenr] = $line;
		$file_bytes += length($line);
		$long_line .= $line;
		if ($self->apply_config(\$long_line)) {
			# line contains "\n", so store in cache
			if (! defined $linenr) {
				$linenr = $input_linenr;
			}
			$self->check_for_include($long_line, $linenr);

			undef $linenr;
			$long_line = "";
		} else {
			# line contains no "\n", so merge with next line
			if (! defined $linenr && $long_line ne "") {
				$linenr = $input_linenr;
			}
		}
		if (defined $fh) {
			$line = $fh->getline;
		} else {
			$self->{COMMON}->{CONFIG}->{DATA} =~ 
							s/^(.*?\n)(.*)$/$2/s; 
			$line = $1;
		}
	}
	$self->{COMMON}->{FILELINES}  = $input_linenr;
	$self->{COMMON}->{FILEBYTES}  = $file_bytes;
	$self->{COMMON}->{CACHEBYTES} =	length($self->{COMMON}->{PLAINFILE});	
	$self->{COMMON}->{CACHELINES} = $#{$self->{COMMON}->{LINESFILE}}+1;
	$self->{COMMON}->{READS}++;

	$self->{COMMON}->{_CODE_TYPE} = 'Plain';
	
	$self->parse_file;
}

sub check_for_include($$$) {
	my ($self, $line, $linenr) = @_;
	my ($before, $filename, $after);
	my ($file, $pwd, $error, $src_line, $src_file);
	my $cursor;

	my $hlp;

	$cursor = $#{$self->{COMMON}->{LINESFILE}}+1;

	
	if ($line =~ m/(.*?)$self->{COMMON}->{CONFIG}->{INCLUDE}(.*)/) {
		$before   = $1;
		$filename = $2;
		$after    = $3;
		
		# make absolute path
		if ($filename !~ /^\//) {
			$pwd = getcwd;
			chomp($pwd);
			$filename = $pwd ."/". $filename;
		}

		if (! in_list($filename, $self->{INCLUDEPATH})) {
			$file = CONFIG::Plain->new($filename,
						   $self->{COMMON}->{CONFIG},
						   $self->{INCLUDEPATH});
			# global errors
			while (defined($error = $file->getline_error)) {
				push @{$self->{COMMON}->{LINEERROR}->
					[$cursor]},
					$error; 
			}
			while (defined ($src_line = $file->getline())) {
				$self->{COMMON}->{LINESFILE}->[$cursor] = 
								$src_line;
				# errors to this line
				while (defined ($error = $file->getline_error)){
					push @{$self->{COMMON}->{LINEERROR}->
						[$cursor]}, $error;	
				}
				while (defined ($src_file = $file->getline_file)) {
					push @{$self->{COMMON}->{FILELINE}->
					     [$cursor]}, $src_file;
					push @{$self->{COMMON}->{FILELINE}->
					     [$cursor]}, $self->{COMMON}->{FILENAME};
					push @{$self->{COMMON}->{INPUTLINE}->
					     [$cursor]}, $file->getline_number;	
					push @{$self->{COMMON}->{INPUTLINE}->
					     [$cursor]}, $linenr;	
				}	
				$cursor++;
			}

			$line = $before . $after;
			
		} else {
			# CYCLIC include!!
			push @{$self->{COMMON}->{LINEERROR}->
				[$cursor]}, 
				"Cyclic include ignored";
	
			$line = $before . $after;
		}

	} else {
		# no include -> normal operation
	}	
       	push @{$self->{COMMON}->{LINESFILE}}, $line;
        push @{$self->{COMMON}->{INPUTLINE}->[$cursor]}, $linenr;
	push @{$self->{COMMON}->{FILELINE}->[$cursor]}, $self->{COMMON}->{FILENAME};

        $self->{COMMON}->{PLAINFILE} .= $line;
}

#####################################
# overload this function..:)
#
sub parse_file {
	my ($self) = @_;
}

#####################################################################
# apply_config
#
# apllies the configuration to a source line
#
# parameters: 1st -> object-ref
#             2nd -> reference to scalar holding the sources
#          return -> (the scalar referenced by the second argument
#                    may changed)
#                    the return value(boolsch) is true if the line
#                    was finished, the retrun value is false if
#                    the line is incomplete (e.g. multi-line comments)
sub apply_config {
	my ($self, $line_ref) = @_;
	my $line = $$line_ref;

	$line = $self->remove_comments($line);

	# NewLineESCape
	if (defined $self->{COMMON}->{CONFIG}->{ESCAPE} &&
                    $self->{COMMON}->{CONFIG}->{ESCAPE} ne "") {
		$line =~ m /($self->{COMMON}->{CONFIG}->{ESCAPE}+)\n/;
		if ((length ($1) % 2) != 0) {
			# new line is escaped -> delete it
			$line =~ s/$self->{COMMON}->{CONFIG}->{ESCAPE}\n//;
		}
	}	

	if ($self->{COMMON}->{CONFIG}->{DELEMPTYLINE}) {
		if ($line eq "\n") {
			$line = "";
		}
	}

	if ($self->{COMMON}->{CONFIG}->{REMOVETRAILINGBLANKS}) {
		$line =~ s/^\s*//;
		$line =~ s/\s*\n/\n/; 
	}
	
	# now handle escaped escape signs :)
	if (defined $self->{COMMON}->{CONFIG}->{ESCAPE} &&
                    $self->{COMMON}->{CONFIG}->{ESCAPE} ne "") {
		$line =~ s/($self->{COMMON}->{CONFIG}->{ESCAPE}){2}/$1/g;
	}

	$$line_ref = $line;

	if ($line =~ /\n/) {
		return 1;
	} else {
		return 0;
	}
}

#####################################################################
# remove_comments
#
# delete the comments from the sources
#
# parameters: 1st -> object-ref
#             2nd -> scalar holding source 
#          return -> the scalar which was referenced by the 2nd parameter
#                    without comments OR (if a
#                    multi-line comment starts but doesn´t end) the 
#                    source line without the trailing new line char
sub remove_comments {
	my ($self, $line) = @_;
	my ($type);
	my ($hit_type, $hit_val, $hit_param,  $parameter, $value);
	
	do {
		$hit_type  = 0;
		$hit_val   = 0;
		$hit_param = 0;
		foreach $type (keys %{$self->{COMMON}->
					     {CONFIG}->{COMMENT_FUNCTIONS}}) {
			foreach $parameter (@{$self->{COMMON}->{CONFIG}->
                                             {COMMENT_FUNCTIONS}->{$type}}) {
				$value = &{$CONFIG::Plain::comment_style->
					  {$type}->{COUNT}} 
					  ($self, $line, $parameter);

				if (($value > 0) && (($value < $hit_val) 
							|| ($hit_val == 0))) {
					$hit_val  = $value;
					$hit_type = $type; 
					$hit_param= $parameter;
				}
			}
		}
		if ($hit_val > 0) {
			$line = &{$CONFIG::Plain::comment_style->
				  {$hit_type}->{REMOVE}}
				($self, $line, $hit_param);
		}
	} while (($hit_val > 0) && ($line =~ /\n$/));

	if ($line =~ /\n$/) {
		foreach $type (keys %{$self->{COMMON}->{CONFIG}->
						{COMMENT_FUNCTIONS}}) {
			foreach $parameter (@{$self->{COMMON}->{CONFIG}->
				             {COMMENT_FUNCTIONS}->{$type}}) {
				$line = &{$CONFIG::Plain::comment_style->
					  {$type}->{ANTIESCAPE}}
					  ($self, $line, $parameter);
			}
		}
	}
	return $line;
}

#####################################################################
# parse_comment_styles 
#
# parses the comment discription line (scalar) and creates a hash
# holding the comemnt types as key and the parameters as value
#
# parameters: 1st -> scalar holding comment style description 
#          return -> reference to hash holding COMMENT_FUNCTION struct
sub parse_comment_styles {
	my ($config) = @_;
	my ($style, $type, $parameters);
	my @styles;
	my %COMMENT_FUNCTIONS = ();

	while (($config =~ s/^(.*?[^\\]) (.*)$/$2/) || ($config =~ s/(.+)//)) {
		$style = $1;
		if ($style =~ /^(.*):(.*)/) {
			# parameters given
			$type = $1;
			$parameters = $2;
		} else {
			# no parameters given
			$type = $style;
			$parameters = '';
		}
		if (defined $CONFIG::Plain::comment_style->{$type}) {
			push (@{$COMMENT_FUNCTIONS{$type}}, $parameters);
		}
	}
	return \%COMMENT_FUNCTIONS;
}

sub getline_unparsed($$) {
	my ($self, $linenr) = @_;

	return $self->{COMMON}->{LINESFILE_unparsed}->[$linenr];
}

#####################################################################
# get_errors
#
# returns a scalar holding a preformated string with all error
# messages occured while parsing the file.
# NOTE: this method uses the api, so the CURSORS are resettet 
#       after this method
#
# Include support: Full 
#
sub get_errors($) {
	my ($self) = @_;
	my $outtext = '';
	my ($line, $error, $filename);

	$self->getline_reset();

	# global errors
	while (defined ($error = $self->getline_error)) {
		$outtext .= $error . "\n";
	}

	while (defined ($line = $self->getline)) {
		$error = $self->getline_error;
		if (defined $error) {
			$outtext .= sprintf("ERROR in         %s:%d\n", 
				$self->getline_file, $self->getline_number);

			while ($filename = $self->getline_file) {
				$outtext .= sprintf("   included from %s:%d\n", 
							$filename, 
							$self->getline_number)
			}
			do {
				$outtext .= sprintf("      %s\n", $error);
			} while (defined ($error = $self->getline_error));
		}
	}

	$self->getline_reset();
	
	return $outtext;
}



#####################################################################
# getfile
#
# returns a scalar holding the whole file
sub getfile {
	my ($self) = @_;

	return $self->{COMMON}->{PLAINFILE};
}

#####################################################################
# getline
#
# returns the file linewhise, returns undef on end of file
sub getline {
	my ($self) = @_;
	my $line = "";
	
	if ($self->{CURSORS}->{getline} >= $self->{COMMON}->{CACHELINES}) {
		undef $line;
	} else {
		$line = $self->{COMMON}->{LINESFILE}->
						[$self->{CURSORS}->{getline}];
		$self->{CURSORS}->{getline}++;	
	}
	$self->{CURSORS}->{getline_error} = 0;
	$self->{CURSORS}->{getline_number} = 0;
	$self->{CURSORS}->{getline_file} = 0;
	return $line;
}

#####################################################################
# getline_cursor
#
# returns the internal linecursor, usefull only for the setline_error
# method
sub getline_cursor {
	my ($self) = @_;

	return $self->{CURSORS}->{"getline"}-1;
}

#####################################################################
# getline_number
#
# returns the input line number of the last line got via getline
sub getline_number {
	my ($self) = @_;
	my $rc;

	$rc = $self->{COMMON}->{INPUTLINE}->[$self->{CURSORS}->{"getline"}-1]->
					    [$self->{CURSORS}->{"getline_number"}];
	$self->{CURSORS}->{"getline_number"}++;
	
	if ((! defined $rc) || ($self->{CURSORS}->{"getline_number"} < 1)) {
		return undef;
	} else {
		return $rc;
	}
}

#####################################################################
# getline_file
#
# returns the filename of the file from which the last line got via
# getline comes.
sub getline_file {
	my ($self) = @_;
	my $rc;

	$rc = $self->{COMMON}->{FILELINE}->[$self->{CURSORS}->{"getline"}-1]->
					   [$self->{CURSORS}->{"getline_file"}];
	$self->{CURSORS}->{"getline_file"}++;

	if ((! defined $rc) || ($self->{CURSORS}->{"getline_file"} < 1)) {
		return undef;
	} else {
		return $rc;
	}
}

#####################################################################
# getline_error
#
# returns errormessages of this line
sub getline_error {
	my ($self) = @_;
	my $rc = undef;

	if ($self->{CURSORS}->{"getline"} == 0) {
		$rc = $self->{COMMON}->{GLOBALERROR}[
				$self->{CURSORS}->{global_error}];
		$self->{CURSORS}->{global_error}++;
	} else {
		$rc = $self->{COMMON}->{LINEERROR}->
					[$self->{CURSORS}->{"getline"}-1]->
					[$self->{CURSORS}->{"getline_error"}];
		$self->{CURSORS}->{"getline_error"}++;
	}
	return $rc;	
}

#####################################################################
# getline_reset
#
# resets the linepointer for getline
sub getline_reset {
	my ($self) = @_;

	$self->{CURSORS}->{"getline"} = 0;
}

#####################################################################
# setline_error
#
# stores a error message to the last line got via getline
#
# Parameters: 1st -> object
#             2nd -> error string
#             3rd -> (optional) line nr. (if ommited, error is assigned
#                    to the last line got via getline)
sub setline_error {
	my ($self, $error, $line_cursor) = @_;

	if (! defined $line_cursor) {
		if ($self->{CURSORS}->{"getline"} > 0) {
			push @{$self->{COMMON}->{LINEERROR}->
				[$self->{CURSORS}->{"getline"}-1]}, $error;
		}
	} else {
		push @{$self->{COMMON}->{LINEERROR}->[$line_cursor]}, $error;
	}
}

sub setglobal_error {
	my ($self, $error) = @_;

	push @{$self->{COMMON}->{GLOBALERROR}}, $error;
}

#####################################################################
#
# stupid translations functions for comment styles ;)

##### sh #####

sub comment_type_sh_count {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_count($self, $line, "#|\$");
}

sub comment_type_sh_remove {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_remove($self, $line, "#|\$");
}

sub comment_type_sh_antiescape {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_antiescape($self, $line, "#|\$");
}

##### C++ #####

sub comment_type_cpp_count {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_count($self, $line, "\/\/|\$");
}

sub comment_type_cpp_remove {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_remove($self, $line, "\/\/|\$");
}

sub comment_type_cpp_antiescape {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_antiescape($self, $line, "\/\/|\$");
}

##### C #####

sub comment_type_c_count {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_count($self, $line, "\/[*]|[*]\nn/");
}

sub comment_type_c_remove {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_remove($self, $line, "\/[*]|[*]\/");
}

sub comment_type_c_antiescape {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_antiescape($self, $line, "\/[*]|[*]\/");
}

##### asm #####

sub comment_type_asm_count {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_count($self, $line, ";|\$");
}

sub comment_type_asm_remove {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_remove($self, $line, ";|\$");
}

sub comment_type_asm_antiescape {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_antiescape($self, $line, ";|\$");
}

##### sql #####

sub comment_type_sql_count {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_count($self, $line, "--|\$");
}

sub comment_type_sql_remove {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_remove($self, $line, "--|\$");
}

sub comment_type_sql_antiescape {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_antiescape($self, $line, "--|\$");
}

##### pascal #####

sub comment_type_pascal_count {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_count($self, $line, "\{|\}");
}

sub comment_type_pascal_remove {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_remove($self, $line, "\{|\}");
}

sub comment_type_pascal_antiescape {
	my ($self, $line, $param) = @_;
	return comment_type_regexp_antiescape($self, $line, "\{|\}");
}

sub comment_type_regexp_count {
	my ($self, $line, $param) = @_;
	my ($start_re, $stop_re) = split /\|/, $param;
	my $before_comment = "";;
	my $comment_found;
	
	($before_comment, $comment_found, undef) = 
			search_unescaped_regexp($line, $start_re, 
			$self->{COMMON}->{CONFIG}->{ESCAPE});
	
	if ($comment_found) { 
		return length($before_comment)+1;
	} else {
		return 0;
	}
}

sub comment_type_regexp_remove {
	my ($self, $line, $param) = @_;
	my ($start_re, $stop_re) = split /\|/, $param;
	my $before_comment = "";;
	my ($comment, $matched_start_re, $matched_stop_re);	

	($before_comment, $matched_start_re, $line) = 
			search_unescaped_regexp($line, $start_re, 
			$self->{COMMON}->{CONFIG}->{ESCAPE});
	
	($comment, $matched_stop_re, $line) =
			search_unescaped_regexp($line, $stop_re,
			$self->{COMMON}->{CONFIG}->{ESCAPE});

	if (! defined $matched_stop_re) {
		chomp $line;
	} else {
		$matched_start_re = "";
		$comment          = "";
		$matched_stop_re  = "";
	}

	return $before_comment . $matched_start_re . $comment . 
	       $matched_stop_re . $line;
}

sub comment_type_regexp_antiescape {
	my ($self, $line, $param) = @_;
	my ($start_re, $stop_re) = split /\|/, $param;
	my ($before_comment) = ("");

	($before_comment, undef, $line) =
		search_unescaped_regexp($line, $start_re,
		$self->{COMMON}->{CONFIG}->{ESCAPE}, 1);

	return $before_comment . $line;	
}

sub in_list {
        my ($scalar, $list) = @_;
        my $element;
        my $count = 0;
	my @list = @{$list};

        foreach $element (@list) {
                if ($element eq $scalar) {
                        $count ++;
                }
        }
        return $count;
}


sub search_unescaped_regexp {
	my ($line, $regexp, $esc, $remove_escapes) = @_;
	my ($before_regexp, $matched_regexp) = ("", "");
	my ($len, $found) = (0, 0);;

	do {
		$before_regexp .= $matched_regexp;
		if ($found = ($line =~ /^(.*?)($regexp)(.*)$/s)) {
			$before_regexp  .=  $1;
			$matched_regexp  =  $2;
			$line            =  $3;
			$before_regexp   =~  m/($esc*)$/;
			$len 		 =  length($1);
			if ((($len % 2) != 0) && $remove_escapes) {
				$before_regexp =~ s/$esc$//;
			}
		}
	} while ((($len % 2) != 0) && ($found));

	if (! $found) {
		$matched_regexp = undef;
	}	
	return ($before_regexp, $matched_regexp, $line);
}

1;


__END__

=head1 NAME

CONFIG::Plain - Base class for cached file reading

=head1 SYNOPSIS

  use CONFIG::Plain;

  my $file = CONFIG::Plain->new($filename, \%config);

  my $file_content = $file->getfile;

  while (defined $line = $file->getline) {
 	printf("%s:%d> %s\n", $file->getline_file, 
			      $file->getline_number, 
                              $line);
  }

  # example for error reporting

  while (defined ($line = $file->getline)) {
        $error = $file->getline_error;
        if (defined $error) {
                printf("ERROR in         %s:%d\n", $file->getline_file,
                                                   $file->getline_number);

                while ($filename = $file->getline_file) {
                        printf("   included from %s:%d\n", $filename,
                                                   $file->getline_number);
                }
                do {
                        printf("   %s\n", $error);
                } while (defined ($error = $file->getline_error));
        }
  }

=head1 ABSTRACT

This perl module is highly useful in connection with mod_perl cgi
scripts. It caches files (re-reads the files if necessary) to speed
up the file reading. It is possible to configure the module to remove
comments, trailing blanks, empty lines or to do other useful things
only once.

=head1 DESCRIPTION

The methods of this module are very similar to the IO methods to read a file.
The two major differences are:

=head2 Caching

If you open/read a file twice (or often) the file will be cached after the
first access. So the second (and third, and forth, ...) access is much faster.
This feature is very useful in connection with mod_perl CGI scripts.

=head2 Preparsing

You can configure this class to preparse the input file immediatly after the 
disk access (NOTE: the preparsed file will be cached). Some default preparse
algorithms are available (delete empty lines, remove comments, remove trailing
blanks, ...) but it's possible to overload a method to implement special 
preparse functionality.

=head1 METHODS

Overview:

	new            - opens, reads and preparses a file
	close          - close the file
        parse_file     - empty method, overload this for specific preparse
                         functionality
        getfile        - returns a scalar holding the preparsed file
	getline        - returns a scalar holding a line of the file
	getline_reset  - resets the cursor for getline
	getline_number - returns the inputfile number of the last line got
			 via getline
			 (cursor handled for includes)
	getline_file   - returns the inputfilename of the last line got
                         via getline
			 (cursor handled for includes)
	getline_error  - returns error messages in for this line
			 (cursor handled) 
	setline_error  - stores a errormessage to the last line got via
			 getline
	get_errors     - returns a human readable string holding ALL error
			 messages

=head2 new - open, read and preparse file

(1) $ref = CONFIG::Plain->new($filename);

(2) $ref = CONFIG::Plain->new($filename, \%CONFIG);

(3) $ref = CONFIG::Plain->new(\%CONFIG);

This method creates a new object from the class. 

You can specify the filename as first argument (see syntax (1) or (2)) or 
include the filename into the options hash (use "FILE" as key).

Configuration Options: 

   COMMENT - define comment styles

	Known comment styles are:
		
		sh	- shell like comments
			  (from '#' to end of line)
		C	- C like comments
			  (from '/*' to '*/', multi line)
		C++	- C++ like comments
			  (from '//' to end of line)
		asm     - assembler like comments
                          (from ';' to end of line)
		pascal  - pascal like comments
                          (from '{' to '}', multi line)
		sql     - oracle sql style
                          (from '--' to end of line)
		regexp  - define comments by regular expression for start
                          and end.
			  This style accepts two parameters, the syntax is:
			  "regexp:<startre>|<stopre>"
			  where <startre> is the regular expression for the
                          start of the comment, and <stopre> the regexp for
                          the end.

			  EXAMPLE:
			  "regexp:#|\$"
			  comments goes from "#" to new line (same as
                          "sh" style).
	
	DEFAULT: "sh C C++"

   DATA - use given data instaed of read it from a file

	Use the data given in this argument instaed of read it from disk.

   DELEMPTYLINE - delete empty lines

	Boolsch, if true empty lines will be deleted.	

	DEFAULT: 1 

   ESCAPE - specifies a escape character

	Use the ESCAPE character in front of magic sequences (or 
	characters) to make them non magic.

	EXAMPLE: (escape a comment)
		>this line includes a hash sign \# but no comment<
	will get into
		>this line includes a hash sign # but no comment<
	of 
		>no \/*comment /* comment \*/ still comment */ no comment<
	will get into
		>no /*comment no comment<	

	EXAMPLE: (escape a escape character)
		>a backslash:\\<
	will get into
		>a backslash:\<

	EXAMPLE: (escape a new line)
		>line one \
		 line two<
	will get into
		>line one                  line two<


	DEFAULT: `\\\\` # -> one backslash 

   FILE - specify the filename

	If you use the syntax (3) the filename is got from this option.

   INCLUDE - specify a regexp for includes
  
	If this regexp matches, the specified file will be included 
	at this point.

	This regexp must store the filename in the $1 varaible.

	DEFAULT: "include <(.*?)>"
		  (filename in <> is stored)

   REMOVETRAILINGBLANKS - remove trailing blanks
	
	Boolsch, if true trailing blanks will be removed.
		
	EXAMPLE:
		>		ho ho 	<
	will get into
		>ho ho< (no leading or trailing white spaces)

	DEFAULT: 1

=head2 close - closes a object instance

   This method accually does nothing, but this may changed in future
   releases, so please use it for compatibily.

=head2 getfile - returns a scalar holding the whole file

   $file_contents = $file->getfile;

   returns the preparsed file.

=head2 getline - returns a scalar holding a line

   $line = $file_getline;

   returns the file line by line until the end of the file is reached.
   The method will return an undefined value on end of file.

   NOTE: the first call to this method need not return the first line of
	 the file (e.g. if the line was empty and DELEMPTYLINE was enabled)
	 Use the method getline_number to get the linenumber of the last got
	 line.

=head2 getline_reset - reset the cursor for getline

   $file->getline_reset;

   If you call this method, the next call to the getline method will 
   start the filereading from the top of the file.

=head2 getline_number - returns the input line number

   $line_number = $file->getline_number;

   Returns the input line number of the last line got via getline.
   
   Because of the INCLUDE feature this method may called often to get
   the include path (see example below).

=head2 getline_file - returns the input filename

   $filename = $file->getline_file;

   Returns the filename of the sourcefile of the last line got via getline.

   Because of the INCLUDE feature this mathod may called often to get
   the include path (see example below).


=head2 getline_error - returns errors of this line

   $error = $file->getline_error;

   Returns for every error occurred in this line a human readable error message
   or an undefined value if no error occures.
	
   NOTE: Since one line may contain more then one error, this method may called
	 often to get all error messages. The list will be terminated by
         an undefined value.

   NOTE: If you call this method before the first call to getline, you will
	 get the global error messages (such as "file not found").

=head2 get_errors - returns ALL error messages

   print $file->get_errors;

   Returns a scalar holding ALL error messages in a preformated style.

=head2 setline_error - stores a errormessage

  $file->setline_error(sprintf("File %s not found", $filename)); 

  Stores a error message to a line.
  Every line may contain more then one error(message).

=head1 SEE ALSO

CONFIG::Hash(3pm)

The CONFIG:: Guide at http://www.fatalmind.com/programs/CONFIG

=head1 TODO

Since this module is grown, the design is horrible! I should 
re-implement the whole module (I'll do this in V2.0).

=head1 BUGS 

Many, but in most cases it will work correct ;)

Note: the include stuff is very beta

=head1 AUTHOR

Markus Winand <mws@fatalmind.com>

=head1 COPYRIGHT

    Copyright (C) 1999, 2000 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.


