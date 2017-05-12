package Bio::KBase::InvocationService::Client;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;

=head1 NAME

Bio::KBase::InvocationService::Client

=head1 DESCRIPTION



=cut

sub new
{
    my($class, $url) = @_;

    my $self = {
	client => Bio::KBase::InvocationService::Client::RpcClient->new,
	url => $url,
    };
    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);

    return bless $self, $class;
}




=head2 $result = start_session(session_id)



=cut

sub start_session
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function start_session (received $n, expecting 1)");
    }
    {
	my($session_id) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to start_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'start_session');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.start_session",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'start_session',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method start_session",
					    status_line => $self->{client}->status_line,
					    method_name => 'start_session',
				       );
    }
}



=head2 $result = valid_session(session_id)



=cut

sub valid_session
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function valid_session (received $n, expecting 1)");
    }
    {
	my($session_id) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to valid_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'valid_session');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.valid_session",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'valid_session',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method valid_session",
					    status_line => $self->{client}->status_line,
					    method_name => 'valid_session',
				       );
    }
}



=head2 $result = list_files(session_id, cwd, d)



=cut

sub list_files
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_files (received $n, expecting 3)");
    }
    {
	my($session_id, $cwd, $d) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($d)) or push(@_bad_arguments, "Invalid type for argument 3 \"d\" (value was \"$d\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_files:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_files');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.list_files",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'list_files',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_files",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_files',
				       );
    }
}



=head2 $result = remove_files(session_id, cwd, filename)



=cut

sub remove_files
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function remove_files (received $n, expecting 3)");
    }
    {
	my($session_id, $cwd, $filename) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument 3 \"filename\" (value was \"$filename\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to remove_files:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'remove_files');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.remove_files",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'remove_files',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method remove_files",
					    status_line => $self->{client}->status_line,
					    method_name => 'remove_files',
				       );
    }
}



=head2 $result = rename_file(session_id, cwd, from, to)



=cut

sub rename_file
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function rename_file (received $n, expecting 4)");
    }
    {
	my($session_id, $cwd, $from, $to) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($from)) or push(@_bad_arguments, "Invalid type for argument 3 \"from\" (value was \"$from\")");
        (!ref($to)) or push(@_bad_arguments, "Invalid type for argument 4 \"to\" (value was \"$to\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to rename_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'rename_file');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.rename_file",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'rename_file',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method rename_file",
					    status_line => $self->{client}->status_line,
					    method_name => 'rename_file',
				       );
    }
}



=head2 $result = copy(session_id, cwd, from, to)



=cut

sub copy
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function copy (received $n, expecting 4)");
    }
    {
	my($session_id, $cwd, $from, $to) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($from)) or push(@_bad_arguments, "Invalid type for argument 3 \"from\" (value was \"$from\")");
        (!ref($to)) or push(@_bad_arguments, "Invalid type for argument 4 \"to\" (value was \"$to\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to copy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'copy');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.copy",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'copy',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method copy",
					    status_line => $self->{client}->status_line,
					    method_name => 'copy',
				       );
    }
}



=head2 $result = make_directory(session_id, cwd, directory)



=cut

sub make_directory
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function make_directory (received $n, expecting 3)");
    }
    {
	my($session_id, $cwd, $directory) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument 3 \"directory\" (value was \"$directory\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to make_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'make_directory');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.make_directory",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'make_directory',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method make_directory",
					    status_line => $self->{client}->status_line,
					    method_name => 'make_directory',
				       );
    }
}



=head2 $result = remove_directory(session_id, cwd, directory)



=cut

sub remove_directory
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function remove_directory (received $n, expecting 3)");
    }
    {
	my($session_id, $cwd, $directory) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument 3 \"directory\" (value was \"$directory\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to remove_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'remove_directory');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.remove_directory",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'remove_directory',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method remove_directory",
					    status_line => $self->{client}->status_line,
					    method_name => 'remove_directory',
				       );
    }
}



=head2 $result = change_directory(session_id, cwd, directory)



=cut

sub change_directory
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function change_directory (received $n, expecting 3)");
    }
    {
	my($session_id, $cwd, $directory) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 2 \"cwd\" (value was \"$cwd\")");
        (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument 3 \"directory\" (value was \"$directory\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to change_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'change_directory');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.change_directory",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'change_directory',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method change_directory",
					    status_line => $self->{client}->status_line,
					    method_name => 'change_directory',
				       );
    }
}



=head2 $result = put_file(session_id, filename, contents, cwd)



=cut

sub put_file
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function put_file (received $n, expecting 4)");
    }
    {
	my($session_id, $filename, $contents, $cwd) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument 2 \"filename\" (value was \"$filename\")");
        (!ref($contents)) or push(@_bad_arguments, "Invalid type for argument 3 \"contents\" (value was \"$contents\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 4 \"cwd\" (value was \"$cwd\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to put_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'put_file');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.put_file",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'put_file',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method put_file",
					    status_line => $self->{client}->status_line,
					    method_name => 'put_file',
				       );
    }
}



=head2 $result = get_file(session_id, filename, cwd)



=cut

sub get_file
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_file (received $n, expecting 3)");
    }
    {
	my($session_id, $filename, $cwd) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument 2 \"filename\" (value was \"$filename\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 3 \"cwd\" (value was \"$cwd\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_file');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.get_file",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_file',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_file",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_file',
				       );
    }
}



=head2 $result = run_pipeline(session_id, pipeline, input, max_output_size, cwd)



=cut

sub run_pipeline
{
    my($self, @args) = @_;

    if ((my $n = @args) != 5)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function run_pipeline (received $n, expecting 5)");
    }
    {
	my($session_id, $pipeline, $input, $max_output_size, $cwd) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        (!ref($pipeline)) or push(@_bad_arguments, "Invalid type for argument 2 \"pipeline\" (value was \"$pipeline\")");
        (ref($input) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 3 \"input\" (value was \"$input\")");
        (!ref($max_output_size)) or push(@_bad_arguments, "Invalid type for argument 4 \"max_output_size\" (value was \"$max_output_size\")");
        (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument 5 \"cwd\" (value was \"$cwd\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to run_pipeline:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'run_pipeline');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.run_pipeline",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'run_pipeline',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method run_pipeline",
					    status_line => $self->{client}->status_line,
					    method_name => 'run_pipeline',
				       );
    }
}



=head2 $result = exit_session(session_id)



=cut

sub exit_session
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function exit_session (received $n, expecting 1)");
    }
    {
	my($session_id) = @args;

	my @_bad_arguments;
        (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument 1 \"session_id\" (value was \"$session_id\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to exit_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'exit_session');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.exit_session",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'exit_session',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method exit_session",
					    status_line => $self->{client}->status_line,
					    method_name => 'exit_session',
				       );
    }
}



=head2 $result = valid_commands()



=cut

sub valid_commands
{
    my($self, @args) = @_;

    if ((my $n = @args) != 0)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function valid_commands (received $n, expecting 0)");
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.valid_commands",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'valid_commands',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method valid_commands",
					    status_line => $self->{client}->status_line,
					    method_name => 'valid_commands',
				       );
    }
}



=head2 $result = get_tutorial_text(step)



=cut

sub get_tutorial_text
{
    my($self, @args) = @_;

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_tutorial_text (received $n, expecting 1)");
    }
    {
	my($step) = @args;

	my @_bad_arguments;
        (!ref($step)) or push(@_bad_arguments, "Invalid type for argument 1 \"step\" (value was \"$step\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_tutorial_text:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_tutorial_text');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "InvocationService.get_tutorial_text",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'get_tutorial_text',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_tutorial_text",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_tutorial_text',
				       );
    }
}




package Bio::KBase::InvocationService::Client::RpcClient;
use base 'JSON::RPC::Client';

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $obj) = @_;
    my $result;

    if ($uri =~ /\?/) {
       $result = $self->_get($uri);
    }
    else {
        Carp::croak "not hashref." unless (ref $obj eq 'HASH');
        $result = $self->_post($uri, $obj);
    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


1;
