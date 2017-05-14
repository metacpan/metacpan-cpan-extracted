#####################################################################
# Hash.pm 
# Copyright (c) 1999, 2000 by Markus Winand       <mws@fatalmind.com>
#
# Class for reading config files into a hash 
#
# $Id: Hash.pm,v 1.10 2000/06/25 17:08:56 mws Exp $
#

package CONFIG::Hash;

use strict;
use CONFIG::Plain;

# the base class....
@CONFIG::Hash::ISA = qw(CONFIG::Plain);


#####################################################################
# new
#
# creates a new object from the class
#
# paramters: same as CONFIG::Plain->new 
sub new {
        my $proto    = shift;
        my $class    = ref($proto) || $proto;
	my $self;
	my $removetrailingblanks;

	if (ref($_[0]) eq "HASH") {
		$removetrailingblanks = $_[0]->{REMOVETRAILINGBLANKS};
		$_[0]->{REMOVETRAILINGBLANKS} = "0";
	} else {
		if (! defined $_[1]) {
			$_[1] = {};
		}
		$removetrailingblanks = $_[1]->{REMOVETRAILINGBLANKS};
		$_[1]->{REMOVETRAILINGBLANKS} = "0";
	}

        $self     = $class->SUPER::new(@_);

	if (! defined $removetrailingblanks) {
		$removetrailingblanks = "1";
	}

	$self->{COMMON}->{CONFIG}->{REMOVETRAILINGBLANKS} = $removetrailingblanks;

	bless ($self, $class);

	if ($self->reparse) {
		if (! defined $self->{COMMON}->{CONFIG}->{KEYREGEXP}) {
			$self->{COMMON}->{CONFIG}->{KEYREGEXP} = "^(\\S+)";
		}
		if (! defined $self->{COMMON}->{CONFIG}->{HASHREGEXP}) {
			$self->{COMMON}->{CONFIG}->{HASHREGEXP} = "\\s+(.*)\$";
		}

		$self->read_hash();

		if (ref($self->{COMMON}->{CONFIG}->{DEFAULT}) eq "HASH") {
			$self->make_defaults();
		}
	
		if (ref($self->{COMMON}->{CONFIG}->{REQUIRE}) eq "ARRAY") {
			$self->check_require();
		}
	}

	$self->{COMMON}->{'_CODE_TYPE'} = "Hash";	

	return $self;
}

#####################################################################
# read_hash
#
# reads the file linewhise into a hash
#
# parameters: 1st -> object
sub read_hash {
	my ($self) = @_;
	my %HASH   = ();	
	my %LINE   = ();
	my %FILE   = ();
	my ($line, $longline);
	my ($key, $value, $hlp);

	# this variables stores the start point of a KEY.
	# since a KEY/VALUE pair will no parsed until the next KEY or EOF
	# is found, this variables are needed to store the point where
	# the first KEY was found (for error reporting,...)
	my (    $lineno,     $file,     $line_cursor);
	my ($longlineno, $longfile, $longline_cursor);

	$longline = "";
	$longlineno = 0;
	$longfile = "unknown";
	$longline_cursor =0;
	while (defined ($line = $self->getline()) || (defined $longline && $longline ne "")) {
		if ( ! defined $line || $line =~ m/$self->{COMMON}->{CONFIG}->{KEYREGEXP}/s ) {
			$lineno = $self->getline_number;
			$file   = $self->getline_file;
			$line_cursor = $self->getline_cursor;
			if ($longline =~ m/$self->{COMMON}->{CONFIG}->{KEYREGEXP}$self->{COMMON}->{CONFIG}->{HASHREGEXP}/s) {	
				$key   = $1;
				if (defined $self->{COMMON}->{CONFIG}->{CASEINSENSITIVE}) {
					$key   =~ tr /A-Z/a-z/;
				}
				$value = $2;
				if (defined $HASH{$key}) {
					if ($self->{COMMON}->{CONFIG}->{ALLOWREDEFINE}){
						$HASH{$key} = $value;
					} else {
						# generate error
						$self->setline_error("Key <$key> already defined", $longline_cursor);
					}
				} else {
					$HASH{$key} = $value;
				}	
		
				# get complete include path
				push @{$LINE{$key}}, $longlineno;
				push @{$FILE{$key}}, $longfile;
				while (defined ($hlp = $self->getline_number)) {
					push @{$LINE{$key}}, $hlp; 
					push @{$FILE{$key}},$self->getline_file;
				}
			}
			if ($self->{COMMON}->{CONFIG}->{REMOVETRAILINGBLANKS} &&
			    defined $line) {
		                $line =~ s/^\s*//;
		                $line =~ s/\s*\n/\n/;
			}
			if (defined $self->{COMMON}->{CONFIG}->{SUBSTITUTENEWLINE} &&
			    defined $line) {
				$line =~ s/\n/$self->{COMMON}->{CONFIG}->{SUBSTITUTENEWLINE}/;
			}
			$longline = $line;
			$longlineno = $lineno;
			$longfile = $file;
			$longline_cursor = $line_cursor;
		} else {
			if ($self->{COMMON}->{CONFIG}->{REMOVETRAILINGBLANKS} &&
			    defined $line) {
		                $line =~ s/^\s*//;
		                $line =~ s/\s*\n/\n/;
			}
			if (defined $self->{COMMON}->{CONFIG}->{SUBSTITUTENEWLINE} &&
			    defined $line) {
				$line =~ s/\n/$self->{COMMON}->{CONFIG}->{SUBSTITUTENEWLINE}/;
			}
			# multi line, or error 
			$longline .= $line;
		}
	}

	$self->{COMMON}->{"Hash.pm"}->{HASH} = \%HASH;
	$self->{COMMON}->{"Hash.pm"}->{LINE} = \%LINE;
	$self->{COMMON}->{"Hash.pm"}->{FILE} = \%FILE;
}

#####################################################################
# make_defaults
#
# inserts the DEFUALT values into the local stored data
#
# parameters: 1st -> object
sub make_defaults {
	my ($self) = @_;
	my $key;

	foreach $key (keys (%{$self->{COMMON}->{CONFIG}->{DEFAULT}})) {
		if (defined $self->{COMMON}->{CONFIG}->{CASEINSENSITIVE}) {
			$key   =~ tr /A-Z/a-z/;
		}
		if (! defined $self->{COMMON}->{"Hash.pm"}->{HASH}->{$key}) {
			$self->{COMMON}->{"Hash.pm"}->{HASH}->{$key} = 
				$self->{COMMON}->{CONFIG}->{DEFAULT}->{$key};
			$self->{COMMON}->{"Hash.pm"}->{FILE}->{$key} = 
				['DEFAULT'];
			$self->{COMMON}->{"Hash.pm"}->{LINE}->{$key} = [0];
		}
	}

}

#####################################################################
# check_require
#
# checks for the required keys
#
# parameters: 1st -> object
sub check_require {
	my ($self) = @_;
	my $key;

	foreach $key (@{$self->{COMMON}->{CONFIG}->{REQUIRE}}) {
		if (defined $self->{COMMON}->{CONFIG}->{CASEINSENSITIVE}) {
			$key   =~ tr /A-Z/a-z/;
		}
		if (! defined $self->{COMMON}->{"Hash.pm"}->{HASH}->{$key}) {
			$self->setglobal_error("Required key <$key> not found.");
		}
	}
}
#####################################################################
# get
#
# returns the value to a given key, or a __reference__ to the hash
#
# parameters: 1st -> object
#             2nd -> (optional) key 
sub get {
	my ($self, $key) = @_;

	if (defined $key &&
                    $key ne "") {
		return $self->{COMMON}->{"Hash.pm"}->{HASH}->{$key};
	} else {
		return $self->{COMMON}->{"Hash.pm"}->{HASH};
	}
}


#####################################################################
# get_line
#
# returns the linenumber where the key was found. 
# Call often to get include path
#
# parameters: 1st -> object
#             2nd -> key
sub get_line {
	my ($self, $key) = @_;

	if (! defined $key) {
		$self->{CURSORS}->{get_line_LASTKEY} = "";
		return undef;
	}

	if (defined $self->{CURSORS}->{get_line_LASTKEY} &&
		    $self->{CURSORS}->{get_line_LASTKEY} ne $key) {
		$self->{CURSORS}->{get_line} = 0;
		$self->{CURSORS}->{get_line_LASTKEY} = $key;
	}

	return $self->{COMMON}->{"Hash.pm"}->{LINE}->{$key}->
			[$self->{CURSORS}->{get_line}++];	
}

#####################################################################
# get_file
#
# returns the filename where the key was found.
# Call often to get include path
#
# parameters: 1st -> object
#             2nd -> key
sub get_file ($$) {
	my ($self, $key) = @_;

	if (! defined $key) {
		$self->{CURSORS}->{get_file_LASTKEY} = "";
		return undef;
	}

	if ($self->{CURSORS}->{get_file_LASTKEY} ne $key) {
		$self->{CURSORS}->{get_file} = 0;
		$self->{CURSORS}->{get_file_LASTKEY} = $key;
	}	

	return $self->{COMMON}->{"Hash.pm"}->{FILE}->{$key}->
			[$self->{CURSORS}->{get_file}++];	
}
1;


__END__

=head1 NAME

CONFIG::Hash - Class to read 2-column files into a hash

=head1 SYNOPSIS

   use CONFIG::Hash;

   my $file = CONFIG::Hash->new($filename, \%config);

   $hash_ref = $file->get();

   $value = $file->get($key);

=head1 DESCRIPTION

Parses a two-column formated file into a hash. The module uses the
CONFIG::Plain class so you can use all features of the Plain module. 

=head1 METHODS

=head2 new - parse file (read via CONFIG::Plain) into hash

Configuration Options:

   -> all described in CONFIG::Plain are known


   KEYREGEXP

	Scalar holding a regular expression which must match every key.

	DEFAULT: "^(\\S+)"

	HINT: Since the first character of a line has to be a non-white-space
	      character it is possible to make multi-line values.
	      Have a look at the examples.

   HASHREGEXP

	Scalar holding a regular expression which matches the content.

	DEFAULT: "\\s+(.*)\$"

   SUBSTITUTENEWLINE

	If defined all NewLine characters in the value will be substituted
	with this scalar.

	DEFAULT: "\n"
	
   REQUIRE

	Reference to a Array which holds list of required variables.

	DEFAULT: []

   DEFAULT
	
	Reference to Hash holding default Values.

	DEFAULT: {}

   ALLOWREDEFINE

	Scalar switch to suppress error messages if the same key is
	redefined at a later point in file.

	DEFAULT: 1

   CASEINSENSITIVE

	All keys are convertet into lower case if this option was defined.

	DEFAULT: undef

=head2 get - get a reference to the hash or a specified field

   $hash_ref = $file->get();

      Returns a reference to the hash holding all data from file.

   $value = $file->get($key);

      Returns the value to the specified key.

=head2 get_line - get the linenumber where this key was found

   $line_nr = $file->get_line($key);
 
      Returns a scalar holding the line number. Call often to get
      include path.

=head2 get_file - get the filename where this key was found

   $filename = $file->get_file($key);

      Returns a scalar holding the filename. Call often to get
      include path.

=head1 EXAMPLES

	Assumes default configuration

	>KEY	This is a very stupid text
	>	but it shows the functionality \
	>	of this module

	Will get into
	'KEY' => "This is a very stupid text\nbut it shows the functionality of this module"

	With the config setting 'SUBSTITUTENEWLINE' => ' '
	
	>INSERT	insert into 
	>	table dummy
	>		(col1, col2, col3)
	>	values
	>		(1, "value", "value2");

	Will get into
	'INSERT' => 'insert into table dummy (col1, col2, col3) values (1, "value", "value2");'

=head1 SEE ALSO

CONFIG::Plain(3pm)

The CONFIG:: Guide at http://www.fatalmind.com/programs/CONFIG/

=head1 COPYRIGHT

    Copyright (C) 1999, 2000 by Markus Winand <mws@fatalmind.com>

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

