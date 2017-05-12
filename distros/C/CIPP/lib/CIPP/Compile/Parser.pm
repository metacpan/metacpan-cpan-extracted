# $Id: Parser.pm,v 1.29 2006/05/16 14:58:54 joern Exp $

package CIPP::Compile::Parser;

use strict;
use Carp;
use vars qw ( @ISA );

use CIPP::Debug;
use CIPP::Compile::Message;
use CIPP::Compile::Cache;
use CIPP::Compile::PerlCheck;

use FileHandle;
use File::Basename;
use File::Path;
use File::Copy;
use IO::String;
use Data::Dumper;

@ISA = qw ( CIPP::Debug );

#---------------------------------------------------------------------
# Konstruktor
#---------------------------------------------------------------------

sub new {
	my $type = shift; $type->trace_in;
	my %par = @_;
	my  ($object_type, $project, $mime_type, $lib_path) =
	@par{'object_type','project','mime_type','lib_path'};
	my  ($program_name, $start_context, $magic_start, $magic_end) =
	@par{'program_name','start_context','magic_start','magic_end'};
	my  ($no_http_header, $dont_cache, $url_par_delimiter) =
	@par{'no_http_header','dont_cache','url_par_delimiter'};
	my  ($config_dir, $trunc_ws) =
	@par{'config_dir','trunc_ws'};

	confess "Unknown object type '$object_type'"
		if $object_type ne 'cipp' and
		   $object_type ne 'cipp-html' and
		   $object_type ne 'cipp-inc' and
		   $object_type ne 'cipp-module';

	confess "Please specify the following parameters:\n".
	      "object_type, project, and program_name.\n".
	      "Got: ".join(', ', keys(%par))."\n"
	      	unless $object_type and $project and $program_name;
	
	$magic_start       ||= '<?';
	$magic_end         ||= '>';
	$start_context     ||= 'html';
	$url_par_delimiter ||= '&';

	my $self = bless {
		object_type          => $object_type,
		start_context	     => $start_context,
		magic_start	     => $magic_start,
		magic_end	     => $magic_end,
		project		     => $project,
		program_name	     => $program_name,
		lib_path	     => $lib_path,
		mime_type	     => $mime_type,
		dont_cache	     => $dont_cache,
		no_http_header	     => $no_http_header,
		url_par_delimiter    => $url_par_delimiter,
		config_dir	     => $config_dir,
		trunc_ws	     => $trunc_ws,
		perl_code_sref	     => undef,
		cache_ok	     => 0,
		state		     => {},
		used_objects	     => {},
		used_objects_by_type => {},
		used_modules 	     => {},
		messages	     => [],
		context		     => [ $start_context ],
		context_data         => [ "" ],
		in_fh		     => undef,
		out_fh  	     => undef,
		tag_stack	     => [],
		out_fh_stack	     => [],
		command2method       => {
			'#' 		=> 'cmd_comment',
			'!#' 		=> 'cmd_comment',
			''  		=> 'cmd_expression',
			'!autoprint' 	=> 'cmd_autoprint',
			'!httpheader'	=> 'cmd_httpheader',
			'!profile'	=> 'cmd_profile',
		},
	}, $type;

	my $norm_name = $self->get_normalized_object_name (
		name => $program_name
	);
	
	$self->{norm_name} = $norm_name;
	$self->set_inc_trace ( ":$norm_name:" );

	return $self;
}

#---------------------------------------------------------------------
# Generator process method return codes
#---------------------------------------------------------------------

sub RC_SINGLE_TAG  { 1 }
sub RC_BLOCK_TAG   { shift; return {} if not @_;
		     my %par = @_; return \%par; }

#---------------------------------------------------------------------
# Read only attribute accessors
#---------------------------------------------------------------------

sub get_project			{ shift->{project}			}
sub get_program_name		{ shift->{program_name}			}
sub get_norm_name		{ shift->{norm_name}			}
sub get_object_type		{ shift->{object_type}			}
sub get_start_context		{ shift->{start_context}		}
sub get_lib_path		{ shift->{lib_path}			}
sub get_config_dir		{ shift->{config_dir}			}
sub get_mime_type		{ shift->{mime_type}			}
sub get_state			{ shift->{state}			}
sub get_command2method		{ shift->{command2method}		}
sub get_used_objects		{ shift->{used_objects}			}
sub get_used_objects_by_type	{ shift->{used_objects_by_type}		}
sub get_no_http_header		{ shift->{no_http_header}		}
sub get_used_modules		{ shift->{used_modules}			}
sub get_magic_start		{ shift->{magic_start}			}
sub get_magic_end		{ shift->{magic_end}			}
sub get_trunc_ws		{ shift->{trunc_ws}			}
sub get_text_domain {
    my $self = shift;
    return $self->{text_domain} if exists $self->{text_domain};
    return $self->{text_domain} = $self->determine_text_domain;
}

#---------------------------------------------------------------------
# Read and Write attribute accessors
#---------------------------------------------------------------------

sub get_in_filename		{ shift->{in_filename}			}
sub get_out_filename		{ shift->{out_filename}			}
sub get_prod_filename		{ shift->{prod_filename}		}
sub get_iface_filename		{ shift->{iface_filename}		}
sub get_dep_filename		{ shift->{dep_filename}			}
sub get_err_filename		{ shift->{err_filename}			}
sub get_err_copy_filename	{ shift->{err_copy_filename}		}
sub get_http_filename		{ shift->{http_filename}		}
sub get_url_par_delimiter	{ shift->{url_par_delimiter}		}
sub get_messages		{ shift->{messages}			}
sub get_interface_changed	{ shift->{interface_changed}		}
sub get_cache_ok		{ shift->{cache_ok}			}
sub get_dont_cache		{ shift->{dont_cache}			}
sub get_current_tag		{ shift->{current_tag}			}
sub get_current_tag_closed	{ shift->{current_tag_closed}		}
sub get_current_tag_line_nr	{ shift->{current_tag_line_nr}		}
sub get_current_tag_options	{ shift->{current_tag_options}		}
sub get_current_tag_options_case  { shift->{current_tag_options_case}	}
sub get_current_tag_options_order { shift->{current_tag_options_order}	}
sub get_inc_trace		{ shift->{inc_trace}			}
sub get_last_text_block		{ shift->{last_text_block}		}

sub set_in_filename		{ shift->{in_filename}		= $_[1]	}
sub set_out_filename		{ shift->{out_filename}		= $_[1]	}
sub set_prod_filename		{ shift->{prod_filename}	= $_[1]	}
sub set_iface_filename		{ shift->{iface_filename}	= $_[1]	}
sub set_dep_filename		{ shift->{dep_filename}		= $_[1]	}
sub set_err_filename		{ shift->{err_filename}		= $_[1]	}
sub set_err_copy_filename	{ shift->{err_copy_filename}	= $_[1]	}
sub set_http_filename		{ shift->{http_filename}	= $_[1]	}
sub set_url_par_delimiter	{ shift->{url_par_delimiter}	= $_[1]	}
sub set_messages		{ shift->{messages}		= $_[1]	}
sub set_interface_changed	{ shift->{interface_changed}	= $_[1]	}
sub set_cache_ok		{ shift->{cache_ok}		= $_[1]	}
sub set_dont_cache		{ shift->{dont_cache}		= $_[1]	}
sub set_current_tag		{ shift->{current_tag}		= $_[1]	}
sub set_current_tag_closed	{ shift->{current_tag_closed}	= $_[1]	}
sub set_current_tag_line_nr	{ shift->{current_tag_line_nr}	= $_[1]	}
sub set_current_tag_options	{ shift->{current_tag_options}	= $_[1]	}
sub set_current_tag_options_case  { shift->{current_tag_options_case} = $_[1] }
sub set_current_tag_options_order { shift->{current_tag_options_order}= $_[1] }
sub set_inc_trace		{ shift->{inc_trace}		= $_[1]	}
sub set_last_text_block		{ shift->{last_text_block}	= $_[1]	}

#---------------------------------------------------------------------
# Parser internal methods
#---------------------------------------------------------------------

sub get_tag_stack		{ shift->{tag_stack}			}
sub get_in_fh			{ shift->{in_fh}			}
sub get_out_fh			{ shift->{out_fh}			}
sub get_out_fh_stack		{ shift->{out_fh_stack}			}
sub get_line_nr			{ shift->{line_nr}			}
sub get_quote_line_nr		{ shift->{quote_line_nr}		}

sub set_tag_stack		{ shift->{tag_stack}		= $_[1]	}
sub set_in_fh			{ shift->{in_fh}		= $_[1]	}
sub set_out_fh			{ shift->{out_fh}		= $_[1]	}
sub set_out_fh_stack		{ shift->{out_fh_stack}		= $_[1]	}
sub set_line_nr			{ shift->{line_nr}		= $_[1]	}
sub set_quote_line_nr		{ shift->{quote_line_nr}	= $_[1]	}

#---------------------------------------------------------------------
# These methods must be defined by CIPP::Compile::* classes
#---------------------------------------------------------------------

sub create_new_parser {
	die "create_new_parser not implemented";
}

sub generate_start_program {
	die "generate_start_program not implemented";
}

sub generate_project_handler {
	die "generate_project_handler not implemented";
}

sub generate_init_request {
	die "generate_init_request not implemented";
}

sub get_normalized_object_name {
	die "normalize_object_name not implemented";
}

sub get_object_filename {
	die "get_object_filename not implemented";
}

sub determine_object_type {
	die "determine_object_type not implemented";
}

sub get_object_url {
	die "get_object_url not implemented";
}

sub get_object_filenames {
	die "get_object_filenames not implemented";
}

sub get_relative_inc_path {
	die "get_relative_inc_path not implemented";
}

#---------------------------------------------------------------------
# Control methods for processing of CIPP Programs, Includes
# and Modules
#---------------------------------------------------------------------

sub process {
	my $self = shift; $self->trace_in;

	# if Cache is clean: nothing to do here
	return if $self->cache_is_clean;

	my $object_type = $self->get_object_type;

	if ( $object_type eq 'cipp' or
	     $object_type eq 'cipp-html' ) {
		$self->process_program;
	
	} elsif ( $object_type eq 'cipp-inc' ) {
		$self->process_include;

	} elsif ( $object_type eq 'cipp-module' ) {
		$self->process_module;

	} else {
		croak "Unknown object type '$object_type'";

	}

	1;
}

sub process_program {
	my $self = shift; $self->trace_in;
	
	# open files
	$self->open_files;
	return unless $self->get_out_fh and $self->get_in_fh;

	# process Program, generate code
	$self->generate_start_program;
	$self->generate_open_exception_handler;
	$self->generate_project_handler;

	# buffer output of the program parser
	my $buffer_sref = $self->open_output_buffer;
	$self->parse;
	$self->close_output_buffer;

	# write dependencies here, otherwise ->custom_http_header_file
	# in ->generate_open_request may fail, because it reads
	# the .dep file
	$self->write_dependencies;

	# now we can generate init request
	# (due to <?!HTTPHEADER>)
	$self->generate_open_request;
	
	# flush the output of the parser to the output file
	$self->flush_output_buffer ( buffer_sref => $buffer_sref );

	$self->generate_close_exception_handler;
	$self->generate_close_request;
	$self->close_files;
	$self->perl_error_check;
	$self->install_file;

	1;
}

sub process_module {
	my $self = shift; $self->trace_in;
	
	# open files
	$self->open_files;
	return unless $self->get_out_fh and $self->get_in_fh;

	$self->generate_module_open;
	$self->parse;
	$self->generate_module_close;
	$self->close_files;
	$self->perl_error_check;
	$self->install_file;
	$self->write_dependencies;
	
	1;
}

sub process_include {
	my $self = shift; $self->trace_in;
	
	# open files
	$self->open_files;
	return unless $self->get_out_fh and $self->get_in_fh;

	# buffer output from the parser
	my $buffer_sref = $self->open_output_buffer;
	$self->parse;
	$self->close_output_buffer;

	# generate the Include header (now the interface is known)
	$self->generate_include_open;

	# add result from the parser
	$self->flush_output_buffer ( buffer_sref => $buffer_sref );
	
	# close include
	$self->generate_include_close;
	$self->close_files;
	$self->perl_error_check;
	$self->install_file;

	#-------------------------------------------------------------
	# Now update meta data: interface and dependecy information
	#-------------------------------------------------------------

	my $iface_filename = $self->get_iface_filename;

	# remember atime and mtime of the interface file
	my ($last_interface_atime, $last_interface_mtime);
	($last_interface_atime, $last_interface_mtime) = 
		(stat($iface_filename))[8,9] if -f $iface_filename;

	# remember old interface (interface file may not exist)
	my $old_interface = eval { $self->read_include_interface_file };
	
	# store (possibly) new Include interface
	my $new_interface = $self->store_include_interface_file;

	# update dependencies
	$self->write_dependencies;
	
	# reset timestamps if interfaces are compatible
	if ( $self->check_interfaces_are_compatible (
			old_interface => $old_interface,
			new_interface => $new_interface
		) and $last_interface_atime ) {
		# set back timestamps
		utime $last_interface_atime, $last_interface_mtime,
		      $iface_filename;
	}
	
	1;
}

#---------------------------------------------------------------------
# Elementary public Parser methods
#---------------------------------------------------------------------

sub parse {
	my $self = shift; $self->trace_in;
	
	my $in_fh = $self->get_in_fh;

	# these characters indicate CIPP commands
	my $magic_start        = $self->get_magic_start;
	my $magic_end          = $self->get_magic_end;
	my $magic_start_length = length($magic_start);
	my $magic_end_length   = length($magic_end);

	# holds actual read line
	my $line;		

	# holds actual lines which belongs together
	my $buffer = "";		

	# state of the parser. the following values are defined:
	#	'text'	: text between CIPP tags
	#	'tag	: we are inside a CIPP tag
	my $state = 'text';
	$self->set_current_tag ($state);
	$self->set_current_tag_line_nr (0);

	# $start_pos: 		starting position for searches inside lines
	# $pos:			temporary search position
	# $quote_pos:		position of quote sign
	# $backslash_pos:	position of backslash
	# $tag_name:		name of tag we are currently in
	my ($start_pos, $pos, $quote_pos, $backslash_pos);

	# line number counter
	my $line_nr = 0;
	
	READLINE: while ( $line = <$in_fh> ) {
		$self->set_line_nr (++$line_nr);
	
		# skip comments
		next READLINE if $line =~ m!^\s*#!;

		$start_pos = 0;
		PARSELINE: while ( $start_pos < length($line) ) {
			$self->debug ("nr=$line_nr start_pos=$start_pos state=$state line='$line'");
			if ( $state eq 'text' ) {
				# search next CIPP tag
				$pos = index($line, $magic_start, $start_pos);
				$self->debug ("text: index ($magic_start, $start_pos) = $pos");
				if ( -1 == $pos ) {
					# not found => read next line
					$buffer .= substr($line, $start_pos);
					next READLINE;
				} else {
					# found => add text beneath $pos to buffer
					$self->debug (
						"text: substr(".$start_pos.
						",".($pos-$start_pos).")"
					);
					$buffer .= substr(
						$line, $start_pos,
						$pos-$start_pos
					);
					$self->process_text (\$buffer);
					$start_pos = $pos + $magic_start_length;
					$buffer = '';
					$state = 'tag';
					$self->debug ("set tag line: $line_nr");
					$self->set_current_tag_line_nr ($line_nr);
					next PARSELINE;
				}
			}

			if ( $state eq 'tag' ) {
				# search end of CIPP tag
				$pos           = index($line, $magic_end, $start_pos);
				$quote_pos     = index($line, '"', $start_pos);
				$backslash_pos = index($line, '\\', $start_pos);

				$self->debug ("magic_end_pos=$pos quote_pos=$quote_pos");

				# found a backslash first?
				if ( $backslash_pos != -1 and
				     ($backslash_pos < $quote_pos or $quote_pos == -1 ) and
				     ($backslash_pos < $pos or $pos == -1 ) ) {
					# skip next character
					$buffer .= substr(
						$line, $start_pos,
						$backslash_pos-$start_pos+2
					);
					$start_pos = $backslash_pos + 2;
					next PARSELINE;
				}
				
				# found a quote first?
				if ( $quote_pos != -1 and ( $quote_pos < $pos or $pos == -1 ) ) {
					$buffer .= substr(
						$line, $start_pos,
						$quote_pos-$start_pos+1
					);
					$start_pos = $quote_pos+1;
					$state = 'quote';
					$self->set_quote_line_nr ($line_nr);
					next PARSELINE;
				}

				$self->debug ("tag: index ($magic_end, $start_pos) = $pos");

				if ( -1 == $pos ) {
					# not found => read next line
					$buffer .= substr($line, $start_pos);
					next READLINE;
				} else {
					$self->debug (
						"tag: substr(".$start_pos.
						",".($pos-$start_pos).")"
					);
					$buffer .= substr(
						$line, $start_pos,
						$pos-$start_pos
					);
					$start_pos = $pos + $magic_end_length;

					# process this tag
					$self->parse_tag ($buffer);
					$buffer = '';

					$state = 'text';
					$self->set_current_tag ($state);
					$self->set_current_tag_line_nr ($line_nr+1);

					next PARSELINE;
				}
			}
			
			if ( $state eq 'quote' ) {
				$quote_pos     = index($line, '"', $start_pos);
				$backslash_pos = index($line, '\\', $start_pos);

				# found a backslash first?
				if ( $backslash_pos != -1 and
				     $backslash_pos < $quote_pos ) {
					# skip next character
					$buffer .= substr(
						$line, $start_pos,
						$backslash_pos-$start_pos+2
					);
					$start_pos = $backslash_pos + 2;
					next PARSELINE;
				}
				
				# found a quote?
				if ( -1 == $quote_pos ) {
					$buffer .= substr($line, $start_pos);
					next READLINE;
					
				} else {
					$buffer .= substr(
						$line, $start_pos,
						$quote_pos-$start_pos+1
					);
					$start_pos = $quote_pos+1;
					$state = 'tag';
					next PARSELINE;
				}
			}
		}
	}
	
	if ( $state eq 'text' ) {
		$self->process_text (\$buffer);

	} elsif ( $state eq 'quote' ) {
		$self->add_message (
			message => "Double quote not closed.",
			line_nr => $self->get_quote_line_nr,
		);

	} else {
		$self->add_message (
			message => "Error parsing CIPP tag.",
			line_nr => $self->get_current_tag_line_nr,
		);
	}

	my $opened_tag;
	while ( $opened_tag = $self->pop_tag ) {
		$self->add_message (
			line_nr => $opened_tag->{line_nr},
			message => "Tag not closed.",
			tag     => $opened_tag->{tag},
		);
	}
}

sub parse_variable_option {
	my $self = shift; $self->trace_in;

	my $var2name = $self->parse_variable_option_hash (@_);
	
	if ( scalar keys %{$var2name} > 1 ) {
		$self->add_tag_message (
			message => "More than one variable specified."
		);
		return;
	} else {
		return (keys %{$var2name})[0];
	}
}

my %TYPE2CHAR = (
	scalar => '$',
	hash   => '%',
	array  => '@'
);

sub parse_variable_option_hash {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($option, $types, $name2var) =
	@par{'option','types','name2var'};
	
	my $type_regex;
	if ( not $types ) {
		$type_regex = "[".quotemeta('$@%')."]";
	} else {
		$type_regex = "[".
			quotemeta(join('',map($TYPE2CHAR{$_}, @{$types}))).
		"]";
	}
	
	my $value = $self->get_current_tag_options->{$option};
	$value =~ s/^\s*//;
	$value =~ s/\s*$//;

	my ($name, $var, @untyped, %var2name, %name2var);
	foreach $var ( split(/\s*,\s*/, $value) ) {
		( $name = $var ) =~ s/^$type_regex//;
		if ( $name eq $var ) {
			push @untyped, $var;
		} else {
			$name2var{$name} = $var  if     $name2var;
			$var2name{$var}  = $name if not $name2var;
		}
	}
	
	$self->add_tag_message (
		message => "Untyped variables: ".
			    join(', ', @untyped)
	) if @untyped;
	
	return $name2var ? \%name2var : \%var2name;
}

sub parse_variable_option_list {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($option, $types) = @par{'option','types'};
	
	my $type_regex;
	if ( not $types ) {
		$type_regex = "[".quotemeta('$@%')."]";
	} else {
		$type_regex = "[".
			quotemeta(join('',map($TYPE2CHAR{$_}, @{$types}))).
		"]";
	}
	
	my $value = $self->get_current_tag_options->{$option};
	$value =~ s/^\s*//;
	$value =~ s/\s*$//;

	my ($name, $var, @untyped, @var);
	foreach $var ( split(/\s*,\s*/, $value) ) {
		( $name = $var ) =~ s/^$type_regex//;
		if ( $name eq $var ) {
			push @untyped, $var;
		} else {
			push @var, $var;
		}
	}
	
	$self->add_tag_message (
		message => "Untyped variables: ".
			    join(', ', @untyped)
	) if @untyped;
	
	return \@var;
}

sub context {
	my $self = shift; $self->trace_in;
	return $self->{context}->[@{$self->{context}}-1];
}

sub push_context {
	my $self = shift; $self->trace_in;
	my ($context, $data) = @_;
	
	push @{$self->{context}}, $context;
	push @{$self->{context_data}}, $data;

	return $context;
}

sub pop_context {
	my $self = shift; $self->trace_in;
	my ($context) = @_;
	
	my $context = pop @{$self->{context}};
	my $data    = pop @{$self->{context_data}};

	return ($context, $data) if wantarray;
	return $context;
}

sub check_object_type {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($name, $type, $message) = @par{'name','type','message'};

	$message ||= "Object '$name' is not of type '$type'.";

	return if not $self->object_exists (
		name               => $name,
		add_message_if_not => 1
	);

	my $object_type = $self->determine_object_type ( name => $name );

	if ( $object_type ne $type ) {
		$self->add_tag_message (
			message => $message
		);
		return;
	}
	
	1;
}

sub object_exists {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($name, $add_message_if_not) =
	@par{'name','add_message_if_not'};

	my $filename = $self->get_object_filename (
		name => $name
	);
	
	if ( not defined $filename and $add_message_if_not ) {
		$self->add_tag_message (
			message => "Object '$name' not found."
		);
	}

	return defined $filename;
}

sub query_tag_history {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($tag, $steps) = @par{'tag','steps'};
	
	$tag ||= $self->get_current_tag;
	
	# $steps == 0	=>	search back to bottom of the stack
	
	my $tag_stack = $self->get_tag_stack;
	my $i = @{$tag_stack} - 1;
	
	for (my $i = @{$tag_stack} - 1; $i >= 0 and $steps >= 0; --$i ) {
		return $tag_stack->[$i]->{data}
			if $tag_stack->[$i]->{tag} eq $tag;
		--$steps;
	}
	
	return;
}

sub check_options {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($mandatory, $optional) = @par{'mandatory','optional'};
	
	my $options = $self->get_current_tag_options;
	
	# check mandatory options
	my @missing;
	foreach my $name ( keys %{$mandatory} ) {
		push @missing, $name if not exists $options->{$name};
	}
	
	# check unknown options
	my @unknown;
	if ( not exists $optional->{'*'} ) {
		foreach my $name ( keys %{$options} ) {
			push @unknown, $name if not exists $mandatory->{$name} and
					        not exists $optional->{$name};
		}
	}

	my $ok = 1;

	# an optional => '*', mandatory => {} means: min. 1 parameter
	# is expected
	if ( exists $optional->{'*'} and scalar(keys %{$mandatory}) == 0 and
	     scalar(keys%{$options}) == 0 ) {
	     	$self->add_tag_message (
			message => 'Minimum one parameter is required.'
		);
		$ok = 0;
	}
	
	if ( @missing ) {
		$self->add_tag_message (
			message => 'Missing tag options: '.
				   join(', ', map uc($_), @missing)
		);
		$ok = 0;
	}

	if ( @unknown ) {
		$self->add_tag_message (
			message => 'Unknown tag options: '.
				   join(', ', map uc($_), @unknown)
		);
		$ok = 0;
	}

	return $ok;
}

#---------------------------------------------------------------------
# These methods manage output buffers
#---------------------------------------------------------------------

sub open_output_buffer {
	my $self = shift; $self->trace_in;

	push @{$self->get_out_fh_stack}, $self->get_out_fh;

	my $buffer = "";
	$self->set_out_fh ( IO::String->new($buffer) );

	return \$buffer;
}

sub close_output_buffer{
	my $self = shift; $self->trace_in;

	my $buffer_fh = $self->get_out_fh;

	$self->set_out_fh ( pop @{$self->get_out_fh_stack} );

	return $buffer_fh->string_ref;
}

sub flush_output_buffer{
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($buffer_sref) = @par{'buffer_sref'};

	# flush buffer
	$self->write ( $$buffer_sref );

	# free memory	
	$$buffer_sref = "";

	1;
}

#---------------------------------------------------------------------
# File I/O related methods
#---------------------------------------------------------------------

sub write {
	my $self = shift; $self->trace_in;
	my $fh = $self->get_out_fh;
	print $fh ref $_ eq 'SCALAR' ? $$_ : $_ for @_;
	1;
}

sub writef {
	my $self = shift; $self->trace_in;
	my $fh = $self->get_out_fh;
	printf $fh (@_);
	1;
}

sub open_files {
	my $self = shift; $self->trace_in;
	
	my $filename;
	my $fh;

	$filename = $self->get_in_filename;
	$fh = FileHandle->new;

	if ( open ($fh, $filename) ) {
		$self->set_in_fh ($fh);
	} else {
		$self->add_message (
			message => "Can't read input file '$filename': $!"
		);
	}

	$filename = $self->get_out_filename;
	$self->make_path($filename);
	$fh = FileHandle->new;
	if ( open ($fh, ">$filename") ) {
		$self->set_out_fh ($fh);
	} else {
		$self->add_message (
			message => "Can't write output file '$filename': $!"
		);
	}

	1;
}

sub close_files {
	my $self = shift; $self->trace_in;
	
	close ($self->get_in_fh);
	close ($self->get_out_fh);

	1;
}

sub install_file {
	my $self = shift; $self->trace_in;

	if ( $self->has_errors ) {
		move ($self->get_out_filename, $self->get_err_copy_filename);
		unlink  $self->get_dep_filename;
		unlink  $self->get_iface_filename
			if $self->get_iface_filename;
		return;
	}

	unlink $self->get_err_copy_filename;

	my $object_type = $self->get_object_type;

	if ( $object_type eq 'cipp' )  {
		chmod 0775, $self->get_out_filename;

	} elsif ( $object_type eq 'cipp-inc' ) { 
		chmod 0664, $self->get_out_filename;

	} elsif ( $object_type eq 'cipp-module' ) {
		my $tmp_module_file = $self->get_out_filename;
		my $prod_filename;
		(undef, undef, $prod_filename) = $self->get_object_filenames;
		$self->set_prod_filename ( $prod_filename );

		my $prod_dir = dirname($prod_filename);
		if ( not -d $prod_dir ) {
			mkpath ([$prod_dir], 0, 0775) or $self->add_message (
				line_nr => 0,
				message => "Can't create dir $prod_dir"
			);
		}

		if ( -d $prod_dir and not move ($tmp_module_file, $prod_filename) ) {
			$self->add_message (
				line_nr => 0,
				message => "Can't move '$tmp_module_file' to ".
					   "'$prod_filename': $!"
			);
		}

	} elsif ( $object_type eq 'cipp-html' ) {
		# ->perl_error_check will execute the generated
		# perl program and install its output to

		unlink $self->get_out_filename;

	} else {
		confess "Unknown object type '$object_type'";
	}

	# delete http_file if no <?!HTTPHEADER> occured
	if ( not $self->get_state->{http_header_occured} ) {
		unlink ($self->get_http_filename);
	}

	1;
}

sub make_path {
	my $self = shift; $self->trace_in;
	
	my ($filename) = @_;
	my $dir = dirname $filename;
	
	return if -d $dir;

	mkpath ($dir, 0, 0770)
		or confess "can't mkpath '$dir': $!";
	
	1;
}

sub cache_is_clean {
	my $self = shift;

	return if $self->get_dont_cache;
	
	my $cache_status = CIPP::Compile::Cache->get_cache_status (
		dep_file => $self->get_dep_filename,
		if_file  => $self->get_iface_filename,
	);
	
	if ( $cache_status eq 'dirty' ) {
		$self->set_cache_ok (0);
		return;
	
	} elsif ( $cache_status eq 'clean' ) {
		$self->set_cache_ok (1);
		return 1;

	} elsif ( $cache_status eq 'cached err' ) {
		$self->set_cache_ok (1);
		$self->load_cached_errors;
		return 1;

	} else {
		croak "Unknown cache_status '$cache_status'";
	}
}

sub get_perl_code_sref {
	my $self = shift;
	
	my $sub_filename = $self->get_out_filename;

	return $self->{perl_code_sref}
		if defined $self->{perl_code_sref};

	my $fh = FileHandle->new;
	open ($fh, $sub_filename) or confess "can't read $sub_filename";
	my $perl_code = join ('',<$fh>);
	close $fh;

	$self->{perl_code_sref} = \$perl_code;

	return \$perl_code;
}

sub custom_http_header_file {
	my $self = shift;
	
	my $http_files = CIPP::Compile::Cache->get_custom_http_header_files (
		dep_file => $self->get_dep_filename
	);

	if ( @{$http_files} > 1 ) {
		$self->add_tag_message (
			message => "Multiple <?!HTTPHEADER> instances found: ".
				   join (", ", @{$http_files})
		);
		return;
	}

	if ( @{$http_files} == 1 ) {
		return $self->get_relative_inc_path (
			filename => $http_files->[0]
		);
	}

	return;
}

#---------------------------------------------------------------------
# Dependency related methods
#---------------------------------------------------------------------

sub add_used_object {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($name, $ext, $type, $normalized) =
	@par{'name','ext','type','normalized'};
	
	$ext ||= $type;

	$name = $self->get_normalized_object_name ( name => $name )
		if not $normalized;

	$self->get_used_objects->{"$name.$ext:$type"} = 1;
	$self->get_used_objects_by_type->{$type}->{$name} = 1;

	1;
}

sub add_used_module {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($name) = @par{'name'};
	
	$self->get_used_modules->{$name} = 1;

	1;
}

sub get_module_name {
	my $self = shift; $self->trace_in;
	return $self->get_state->{module_name};
}

sub write_dependencies {
	my $self = shift; $self->trace_in;

	my $used_includes_href = $self->get_used_objects_by_type->{'cipp-inc'};
	
	my %entries_hash;
	foreach my $name ( keys %{$used_includes_href} ) {
		# resolve filenames of this used include
		my ($in_filename, $out_filename, $prod_filename,
		    $dep_filename, $iface_filename, $err_filename,
		    $http_filename ) =
		    	$self->get_object_filenames (
				norm_name   => $name,
				object_type => 'cipp-inc'
			);

		# direct entry of this Include
		$entries_hash{$in_filename} =
			"$in_filename\t$prod_filename\t$iface_filename\t$http_filename";

		# load transitive dependencies of this Include
		# into our entries hash
		CIPP::Compile::Cache->load_dep_file_into_entries_hash (
			dep_file     => $dep_filename,
			entries_href => \%entries_hash,
		);
	}
	
	CIPP::Compile::Cache->write_dep_file (
		src_file      => $self->get_in_filename,
		dep_file      => $self->get_dep_filename,
		cache_file    => $self->get_prod_filename,
		err_file      => $self->get_err_filename,
		http_file     => $self->get_http_filename,
		entries_href  => \%entries_hash,
	);
	
	if ( $self->has_direct_errors ) {
		$self->save_cached_errors;
	} else {
		unlink ($self->get_err_filename) if -f $self->get_err_filename;
	}

	1;
}

#---------------------------------------------------------------------
# Message and Error handling
#---------------------------------------------------------------------

sub add_message {
	my $self = shift; $self->trace_in;
	my %par = @_;

	my  ($type, $line_nr, $tag, $message) =
	@par{'type','line_nr','tag','message'};
	
	$type    ||= 'cipp_err';
	$line_nr ||= $self->get_line_nr;
	$tag     ||= $self->get_current_tag;

	push @{$self->get_messages}, CIPP::Compile::Message->new (
		line_nr   => $line_nr,
		type      => $type,
		tag       => $tag,
		message   => $message,
		name      => $self->get_program_name,
	);
	
	1;
}

sub add_tag_message {
	my $self = shift; $self->trace_in;
	my %par = @_;

	my  ($type, $message) =
	@par{'type','message'};
	
	$type ||= 'cipp_err';

	push @{$self->get_messages}, CIPP::Compile::Message->new (
		line_nr   => $self->get_current_tag_line_nr,
		type      => $type,
		tag       => $self->get_current_tag,
		message   => $message,
		name      => $self->get_program_name,
	);
	
	1;
}

sub add_message_object {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($object) = @par{'object'};
	
	push @{$self->get_messages}, $object;
	
	1;
}

sub has_errors {
	my $self = shift; $self->trace_in;
	return scalar(@{$self->get_messages});
}

sub has_direct_errors {
	my $self = shift; $self->trace_in;
	
	return if not $self->has_errors;
	return $self->get_normalized_object_name ( name => $self->get_messages->[0]->get_name ) eq
	       $self->get_norm_name;
}

sub get_direct_errors {
	my  $self = shift; $self->trace_in;
	
	my @direct_errors;
	my $name = $self->get_program_name;

	foreach my $err ( @{$self->get_messages} ) {
		push @direct_errors, $err
			if $err->get_name eq $name;
	}
	
	return \@direct_errors;
}

sub save_cached_errors {
	my $self = shift;
	
	my $direct_errors = $self->get_direct_errors;
	my $fh = FileHandle->new;
	open ($fh, "> ".$self->get_err_filename)
		or confess "can't write ".$self->get_err_filename;
	print $fh Dumper( $direct_errors );
	close $fh;

	1;
}

sub load_cached_errors {
	my $self = shift;
	
	my $err_filename = $self->get_err_filename;
	my $VAR1;
	do $err_filename;

	$self->set_messages ( do $err_filename );

	1;
}

#---------------------------------------------------------------------
# Include related methods
#---------------------------------------------------------------------

sub store_include_interface_file {
	my $self = shift; $self->trace_in;

	my $iface_filename = $self->get_iface_filename;
	my $interface = $self->get_state->{incinterface};
	
	$self->make_path ($iface_filename);

	open (OUT, "> $iface_filename")
		or die "INCLUDE\tcan't write $iface_filename";
	
	if ( $interface ) {
		print OUT join ("\t", %{$interface->{input}}),    "\n";
		print OUT join ("\t", %{$interface->{optional}}), "\n";
		print OUT join ("\t", %{$interface->{noquote}}),  "\n";
		print OUT join ("\t", %{$interface->{output}}),   "\n";
	} else {
		print OUT "\n\n\n\n";
	}

	close OUT;

	return $interface;
}	

sub read_include_interface_file {
	my $self = shift; $self->trace_in;

	my $iface_filename = $self->get_iface_filename;

	my $line;
	open (IN, $iface_filename)
		or confess "INCLUDE\tCan't load interface file ".
			   "'$iface_filename'";
	
	# input parameters
	chomp ($line = <IN>);
	my %input = split("\t", $line);
	
	# optional parameters
	chomp ($line = <IN>);
	my %optional = split("\t", $line);
	
	# noquote parameters
	chomp ($line = <IN>);
	my %noquote = split("\t", $line);
	
	# output parameters
	chomp ($line = <IN>);
	my %output = split("\t", $line);
	
	# close file
	close IN;
	
	# store and return
	return {
		input     => \%input,
		optional  => \%optional,
		output    => \%output,
		noquote   => \%noquote,
	};
}

sub check_interfaces_are_compatible {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($oi, $ni) = @par{'old_interface', 'new_interface'};

	my ($par, $incompatible);
	
	$self->set_interface_changed (1);
	
	# 1. incompatible, if we have a new INPUT parameter,
	#    or type has changed
	foreach $par ( keys %{$ni->{input}} ) {
		return if $oi->{input}->{$par} ne $ni->{input}->{$par};
	}
	
	# 2. an INPUT parameter was removed, but is no
	#    optional parameter (of same type)
	foreach $par ( keys %{$oi->{input}} ) {
		return if $oi->{input}->{$par} ne $ni->{input}->{$par} and
		          $oi->{input}->{$par} ne $ni->{optional}->{$par};
	}
	
	# 3. removal of an OPTIONAL parameter (or type switch)?
	foreach $par ( keys %{$oi->{optional}} ) {
		return if $oi->{optional}->{$par} ne $ni->{optional}->{$par};
	}
	
	# 4. removal of an OUTPUT parameter?
	foreach $par ( keys %{$oi->{output}} ) {
		return if $oi->{output}->{$par} ne $ni->{output}->{$par};
	}

	# 5. NOQUOTE differ?
	foreach $par ( keys %{$oi->{noquote}}, keys %{$ni->{noquote}} ) {
		return if $oi->{noquote}->{$par} ne $ni->{noquote}->{$par};
	}
	
	$self->set_interface_changed (0);

	return 1;
}

sub interface_is_correct {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my  ($include_parser, $input, $output) =
	@par{'include_parser','input','output'};

	my $error;

	# load interface information
	my $interface = $include_parser->read_include_interface_file;

	# any unknown input parameters?
	my @unknown_input;
	foreach my $par ( keys %{$input} ) {
		if ( not defined $interface->{input}->{$par} and
		     not defined $interface->{optional}->{$par} ) {
		     	$self->add_tag_message (
				message => "Unknown input paramter: $par"
			);
			$error = 1;
		}
	}
	
	# do we miss some parameters?
	foreach my $par ( keys %{$interface->{input}} ) {
		if ( not defined $input->{$par} ) {
		     	$self->add_tag_message (
				message => "Missing input paramter: $interface->{input}->{$par}"
			);
			$error = 1;
		}
	}

	# any unknown output parameters?
	foreach my $par ( keys %{$output} ) {
		if ( not defined $interface->{output}->{$par} ) {
		     	$self->add_tag_message (
				message => "Unknown output paramter: $par"
			);
			$error = 1;
		}
	}

	return not $error;	
}

#---------------------------------------------------------------------
# Error checking related methods
#---------------------------------------------------------------------

my ( $perl_check_instance_cnt,
     $perl_check_instance );

sub perl_error_check {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($perl_code_sref) = @par{'perl_code_sref'};

	return if not $perl_code_sref and $self->has_errors;

	$perl_code_sref  ||= $self->get_perl_code_sref;

	my $src_filename = $self->get_in_filename;
	my $sub_filename = $self->get_prod_filename;

	my $pc;
	if ( $self->get_object_type eq 'cipp-html' ) {
		# code will be executed. we create a single
		# instance for this case
		$pc = CIPP::Compile::PerlCheck->new;
		
	} else {
		# syntax check only: an instance may check
		# several programs
		if ( not $perl_check_instance or
		     $perl_check_instance_cnt == 20 ) {
			$perl_check_instance = CIPP::Compile::PerlCheck->new;
			$perl_check_instance_cnt = 0;
		}
		$pc = $perl_check_instance;
		++$perl_check_instance_cnt;
	}
	
	my $dir = dirname $sub_filename;

	$pc->set_directory ( $dir );
	$pc->set_lib_path ( $self->get_lib_path  );
	$pc->set_name ( $self->get_program_name );
	$pc->set_config_dir ( $self->get_config_dir );

	my $output_file;
	if ( $self->get_object_type eq 'cipp-html' ) {
		$output_file = $self->get_prod_filename,
	}
	
	my $msg_lref = $pc->check (
		code_sref    => $perl_code_sref,
		parse_result => 1,
		output_file  => $output_file
	);

	foreach my $msg ( @{$msg_lref} ) {
		$self->add_message_object (
			object => $msg
		);
	}

	1;
}

sub format_debugging_source {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($brief) = @par{'brief'};

	my $msg_lref = $self->get_messages;
	return if @{$msg_lref} == 0;

	my $line;
	my $html = "";		# Scalar für den HTML-Code
	my $font = '<font face="Helvetica,Arial,Geneva">';

	my $what = $msg_lref->[0]->get_type eq 'perl_err' ?
		"Perl Syntax" : "CIPP Syntax";

	$html .= qq{$font<font color="red">}.
		 qq{<b>There are $what errors:</b>}.
		 qq{</font></font><p>\n};

	# First generate a list of error messages.
	my $nr = 0;
	$html .= "<pre>\n";
	my %anchor;
	foreach my $err (@{$msg_lref}) {
		my $name = $err->get_name;
		my $line = $err->get_line_nr;
		my $tag  = $err->get_tag;
		my $msg  = $err->get_message;
		
		$msg =~ s/</&lt;/g;
		
		if ( not defined $anchor{"${name}_$line"} ) {
			$html .= qq{<a name="cipperrortop_${name}_$line"></a>};
			$anchor{"${name}_$line"} = 1;
		}

		$html .= qq{<a href="#cipperror_${name}_$line">};
		if ( $tag eq 'TEXT' ) {
			$html .= "$name (line $line): HTML Context: $msg";
		} else {
			$html .= "$name (line $line): <?$tag>: $msg";
		}
		$html .= "</a>\n";
		++$nr;
	}
	$html .= "</pre>\n";

	return \$html if $brief;

	# Nun alle betroffenen Objekte extrahieren und dabei die Fehlermeldungen
	# in ein Hash umschichten
	my %object;
	my %error;
	my @object;
	
	my $i_have_an_error = undef;
	foreach my $err (@{$msg_lref}) {
		my $name = $err->get_name;
		my $line = $err->get_line_nr;
		my $tag  = $err->get_tag;
		my $msg  = $err->get_message;

		if ( not defined $object{$name} ) {
			$object{$name} = $self->get_object_filename ( name => $name );
			if ( $name ne $self->{object_name} ) {
				push @object, $name;
			} else {
				$i_have_an_error = 1;
			}
		}
		push @{$error{$name}->{$line}}, $msg;
	}

	@object = sort @object;

	unshift @object, $self->{object_name} if $i_have_an_error;
	
	# Alle betroffenen Objekte einlesen
	my %object_source;
	my ($object, $filename);
	while ( ($object, $filename) = each %object ) {
		my $fh = new FileHandle ();
		if ( open ($fh, $filename) ) {
			local ($_);
			while (<$fh>) {
				s/&/&amp;/g;
				s/</&lt;/g;
				s/>/&gt;/g;
				push @{$object_source{$object}}, $_;
			}
			close $fh;
		}
	}
	
	# nun haben wir ein Hash von Listen mit den Quelltextzeilen
	$nr = 0;
	foreach $object (@object) {
		$html .= qq{<a name="object_$object"></a>};
		$html .= "<P><HR>$font<H1>$object</H1></FONT><P><PRE>\n";
		my ($i, $line);
		$i = 0;
		foreach $line (@{$object_source{$object}}) {
			++$i;
			my $color = "red";
			if ( defined $error{$object}->{$i} ) {
				my $html_msg = "<B><FONT COLOR=blue>";
				my $msg;
				foreach $msg (@{$error{$object}->{$i}}) {
					if ( $msg eq '__INCLUDE_CALL__' ) {
						$color = "green";
						next;
					}
					$html_msg .= "\t$msg\n";
				}
				$html_msg .= "</FONT></B>\n";
				$html .= "\n";
				if ( $color eq 'red' ) {
					# error highlighting
					$html .= qq{<a name="cipperror_${object}_$i"></a>};
					$html .= qq{<B><a href="#cipperrortop_${object}_$i">}.
						 qq{<FONT COLOR=$color>$i\t}.
						 qq{$line</FONT></a></B>\n};
				} else {
					# include reference highlighting
					$html .= "<B><FONT COLOR=$color>$i\t$line</FONT></B>\n";
				}
				$html .= $html_msg;
			} else {
				$html .= "$i\t$line";
			}
		}
		$html .= "</PRE>\n";
	}
	
	$html .= "<HR>\n";
	
	return \$html;
}

#---------------------------------------------------------------------
# Elementary Private methods for Parsing
#---------------------------------------------------------------------

sub parse_tag {
	my $self = shift; $self->trace_in;
	my ($text) = @_;

	# debugging output
	my $dbg = $text;
	$dbg =~ s/\n/\\n/g;
	$self->debug("GOT TAG: '$dbg'\n");
	
	# extract tag name, tag close marker and tag content
	my $magic_start = $self->get_magic_start;
	my $magic_end   = $self->get_magic_end;

	my ($closed, $tag);
	$text =~ s!^\s*(/?)([^\s>]*)\s*!!;
	($closed, $tag) = ($1, lc($2));
	$closed = 1 if $closed;

	# check whether we are inside a comment block
	return 1 if $self->context eq 'comment' and $tag ne '#'
						and $tag ne '!#';

	# parse tag content for options
	$text =~ s/\s+$//;
	my $closed_immediate = 1 if $text =~ s!/$!!;
	
	if ( $closed and $closed_immediate ) {
		$self->add_message (
			message => "Tag closed twice.",
			tag     => $tag,
			line_nr => $self->get_current_tag_line_nr,
		);
		return;
	}
	
	my ($options, $options_case, $options_order) =
		$self->parse_tag_options ($text);

	if ( $options < 0 ) {
		if ( $options == -2 ) {
			$self->add_message (
				message => "Multiple options.",
				tag     => $tag,
				line_nr => $self->get_current_tag_line_nr,
			);
		} else {
			$self->add_message (
				message => "Error parsing options.",
				tag     => $tag,
				line_nr => $self->get_current_tag_line_nr,
			);
		}
		return;
	}

	$self->debug("TAG=$tag, CLOSED=$closed");

	# check nesting
	if ( $closed ) {
		my $opened_tag = $self->pop_tag;
		if ( not $opened_tag ) {
			$tag =~ tr/a-z/A-Z/;
			$self->add_message (
				line_nr => $self->get_current_tag_line_nr,
				message => "Found ${magic_start}/$tag> ".
					   "without opening it.",
			);
			return;
		}

		if ( $opened_tag->{tag} ne $tag ) {
			$tag =~ tr/a-z/A-Z/;
			$opened_tag->{tag} =~ tr/a-z/A-Z/;
			$self->add_message (
				line_nr => $self->get_current_tag_line_nr,
				message => "Found ${magic_start}/$tag> ".
					   "instead of ${magic_start}/".
					   "$opened_tag->{tag}> opened ".
					   "at line $opened_tag->{line_nr}.",
			);
			return;
		}
		
		# give the tag process method state data
		# which was generated when processing the
		# opening tag
		$closed = $opened_tag->{data};
	}

	# save information of the current tag
	$self->set_current_tag ($tag);
	$self->set_current_tag_closed ($closed);
	$self->set_current_tag_options ($options);
	$self->set_current_tag_options_case ($options_case);
	$self->set_current_tag_options_order ($options_order);

	# execute tag handler
	my $handler = $self->get_command2method->{$tag};
	$handler ||= "cmd_$tag";
	
	if ( $self->can ($handler) ) {
		$self->generate_debugging_code;
		my $rc = $self->$handler();
		if ( $rc != $self->RC_SINGLE_TAG and not $closed ) {
			$self->push_tag (
				tag     => $tag,
				line_nr => $self->get_current_tag_line_nr,
				data    => $rc,
			);
		}
		if ( $closed_immediate ) {
			$self->set_current_tag_closed ($self->pop_tag->{data});
			$self->set_current_tag_options ({});
			$self->set_current_tag_options_case ({});
			$self->set_current_tag_options_order ({});
			$self->$handler();
		}
		
	} else {
		my $big_tag = uc($tag);
		$self->add_message (
			tag     => $tag,
			line_nr => $self->get_current_tag_line_nr,
			message => "Unknown CIPP tag: <?$big_tag>."
		);
	}

	1;
}

sub parse_tag_options {
	my $self = shift; $self->trace_in;
	my ($options) = @_;

	my %options;
	my %options_case;
	my @options_order;
	return ({},{}) if $options eq '';

	my ($name_var, $name_flag, $value);

	$options =~ s/\\\"/\001/g;	# maskiere escapte Quotes
	$options =~ s/\\\\/\\/g;	# demaskiere escapte \
	$options =~ s/^\s+//;
	$options .= " ";

	while ( $options ne '' ) {
		# Suche 1. Parametername mit Zuweisung
		($name_var) = $options =~ /^([^\s=]+\s*=\s*)/;
		# Suche 1. Parametername ohne Zuweisung
		($name_flag) = $options =~ /^([^\s=]+)[^=]/;

		return -1 if not defined $name_var and
			     not defined $name_flag;

		# Wenn ein " oder < im Parameternamen vorkommt, muß
		# ein Syntaxfehler vorliegen

		return -1 if defined $name_var  and $name_var =~ /["<]/;
		return -1 if defined $name_flag and $name_flag =~ /["<]/;

		# Was wurde gefunden, Zuweisung oder Flag?
		if ( defined $name_var ) {
			# wir haben eine Zuweisung
			my $clear = quotemeta $name_var;
			$options =~ s/^$clear//;
			$name_var =~ s/\s*=\s*//;
			if ( $options =~ /^\"/ ) {
				# Parameter ist gequotet!
				($value) = $options =~ /^\"([^\"]*)/;
				$options =~ s/\"([^\"]*)\"\s*//;
			} else {
				# Parameter ist nicht gequotet!
				($value) = $options =~ /^([^\s]*)/;
				return -1 if $value eq '';
				$options =~ s/^([^\s]*)\s*//;
			}
			$value =~ tr/\001/\"/;
			my $name_case = $name_var;
			$name_var = lc($name_var);
			if (defined $options{$name_var}) {
				return -2;
			} else {
				$options{$name_var} = $value;
				$options_case{$name_var} = $name_case;
				push @options_order, $name_case;
			}
		} else {
			# wir haben ein Flag
			my $clear = quotemeta $name_flag;
			$options =~ s/^$clear\s*//;
			my $name_case = $name_flag;
			$name_flag = lc($name_flag);
			$options{$name_flag} = 1;
			$options_case{$name_flag} = $name_case;
			push @options_order, $name_case;
		}
	}

	return (\%options, \%options_case, \@options_order);
}

sub push_tag {
	my $self = shift; $self->trace_in;
	my %par = @_;
	
	push @{$self->get_tag_stack}, \%par;
	
	return \%par;
}

sub pop_tag {
	my $self = shift; $self->trace_in;
	my ($context) = @_;
	
	return pop @{$self->get_tag_stack};
}


1;
