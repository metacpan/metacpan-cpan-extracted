package Bio::KBase::InvocationService::InvocationServiceImpl;
use strict;
use Bio::KBase::Exceptions;

=head1 NAME

InvocationService

=head1 DESCRIPTION



=cut

#BEGIN_HEADER
use IPC::Run;
use Data::Dumper;
use Digest::MD5 'md5_hex';    
use Bio::KBase::InvocationService::PipelineGrammar;
use POSIX qw(strftime);
use Cwd;
use Cwd 'abs_path';
use File::Path;
use File::Basename;
use File::Copy;

use Bio::KBase::InvocationService::ValidCommands;

my @command_path = ("/kb/deployment/bin", "/home/olson/FIGdisk/FIG/bin", "/kb/deployment/modeling");

my $kb_top = $ENV{KB_TOP};
if ($kb_top)
{
    @command_path = ("$kb_top/bin");
}


my @valid_shell_commands = qw(sort grep cut cat head tail date echo wc diff join uniq);
my %valid_shell_commands = map { $_ => 1 } @valid_shell_commands;

sub validate_path
{
    my($self, $session_id, $cwd) = @_;
    my $base = $self->_session_dir($session_id);
    my $dir = $base.$cwd;
    my $ap = abs_path($dir);
    if ($ap =~ /^$base/ || $ap eq '/dev/null') {
        return $ap;
    } else {
        die "Invalid path $ap";
    }
}

sub _prepend_cwd
{
    my($cwd, $path) = @_;
    if ($path =~ m,^/,)
    {
	return $path;
    }
    else
    {
	return $cwd . "/" . $ path;
    }
}
     

sub _valid_session_name
{
    my($self, $session) = @_;

    return $session =~ /^[a-zA-Z0-9._-]+$/;
}

sub _validate_session
{
    my($self, $session) = @_;
    my $d = $self->_session_dir($session);
    return -d $d;
}

sub _session_dir
{
    my($self, $session) = @_;
    return $self->{storage_dir} . "/$session";
}

sub _expand_filename
{
    my($self, $session, $file, $cwd) = @_;
    if ($file eq '')
    {
	return $self->validate_path($session, $cwd);
    }
    elsif ($file =~ m,^(/?)(?:[a-zA-Z0-9_.-]*(?:/[a-zA-Z0-9_.-]*)*),)
    {
	if ($1)
	{
	    return $self->validate_path($session, $file);
	}
	else
	{
	    return $self->validate_path($session, $cwd."/".$file);
	}
    }
    else
    {
	die "Invalid filename $file";
    }
    
    #return $self->_session_dir($session) . "/$file";
}
sub validate_path
{
    my($self, $session_id, $cwd) = @_;

    if ($cwd eq '/dev/null')
    {
	return $cwd;
    }
    
    my $base = $self->_session_dir($session_id);
    my $dir = $base.$cwd;
    my $ap = abs_path($dir);
    if ($ap =~ /^$base/) {
        return $ap;
    } else {
        die "Invalid path '$ap'";
    }


}

sub _validate_command
{
    my($self, $cmd) = @_;

    my $path;
    if ($self->{valid_commands}->{$cmd})
    {
	for my $cpath (@command_path)
	{
	    if (-x "$cpath/$cmd")
	    {
		$path = "$cpath/$cmd";
		last;
	    }
	    else
	    {
		print STDERR "Not found: $cpath/$cmd\n";
	    }
	}
    }
    elsif ($valid_shell_commands{$cmd})
    {
	for my $dir ('/bin', '/usr/bin')
	{
	    if (-x "$dir/$cmd")
	    {
		$path = "$dir/$cmd";
		last;
	    }
	}
    }
    else
    {
	return undef;
    }

    if (! -x $path)
    {
	return undef;
    }
    return $path;
}

#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

    my($storage_dir) = @args;

    if (! -d $storage_dir)
    {
	die "Storage directory $storage_dir does not exist";
    }

    $self->{storage_dir} = $storage_dir;
    $self->{count} = 0;

    $self->{valid_commands} = Bio::KBase::InvocationService::ValidCommands::valid_commands();
    $self->{command_groups} = Bio::KBase::InvocationService::ValidCommands::command_groups();
    
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 start_session

  $actual_session_id = $obj->start_session($session_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$actual_session_id is a string

</pre>

=end html

=begin text

$session_id is a string
$actual_session_id is a string


=end text



=item Description



=back

=cut

sub start_session
{
    my $self = shift;
    my($session_id) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to start_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'start_session');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($actual_session_id);
    #BEGIN start_session

    print STDERR "start_session '$session_id'\n";
    if (!$session_id)
    {
	my $dig = Digest::MD5->new();
	if (open(my $rand, "<", "/dev/urandom"))
	{
	    my $dat;
	    my $n = read($rand, $dat, 1024);
	    print STDERR "Read $n bytes of random data\n";
	    $dig->add($dat);
	    close($rand);
	}
	$dig->add($$);
	$dig->add($self->{counter}++);
	$dig->add($self->{storage_dir});
	
	$session_id = $dig->hexdigest;
    }
    elsif (!$self->_valid_session_name($session_id))
    {
	die "Invalid session id";
    }
    my $dir = $self->_session_dir($session_id);
    if (!-d $dir)
    {
	mkdir($dir) or die "Cannot create session directory";
    }
    $actual_session_id = $session_id;
    
    #END start_session
    my @_bad_returns;
    (!ref($actual_session_id)) or push(@_bad_returns, "Invalid type for return variable \"actual_session_id\" (value was \"$actual_session_id\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to start_session:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'start_session');
    }
    return($actual_session_id);
}




=head2 valid_session

  $return = $obj->valid_session($session_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$return is an int

</pre>

=end html

=begin text

$session_id is a string
$return is an int


=end text



=item Description



=back

=cut

sub valid_session
{
    my $self = shift;
    my($session_id) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to valid_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'valid_session');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($return);
    #BEGIN valid_session
    return $self->_validate_session($session_id);
    #END valid_session
    my @_bad_returns;
    (!ref($return)) or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to valid_session:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'valid_session');
    }
    return($return);
}




=head2 list_files

  $return_1, $return_2 = $obj->list_files($session_id, $cwd, $d)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$d is a string
$return_1 is a reference to a list where each element is a directory
$return_2 is a reference to a list where each element is a file
directory is a reference to a hash where the following keys are defined:
	name has a value which is a string
	full_path has a value which is a string
	mod_date has a value which is a string
file is a reference to a hash where the following keys are defined:
	name has a value which is a string
	full_path has a value which is a string
	mod_date has a value which is a string
	size has a value which is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$d is a string
$return_1 is a reference to a list where each element is a directory
$return_2 is a reference to a list where each element is a file
directory is a reference to a hash where the following keys are defined:
	name has a value which is a string
	full_path has a value which is a string
	mod_date has a value which is a string
file is a reference to a hash where the following keys are defined:
	name has a value which is a string
	full_path has a value which is a string
	mod_date has a value which is a string
	size has a value which is a string


=end text



=item Description



=back

=cut

sub list_files
{
    my $self = shift;
    my($session_id, $cwd, $d) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($d)) or push(@_bad_arguments, "Invalid type for argument \"d\" (value was \"$d\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to list_files:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_files');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($return_1, $return_2);
    #BEGIN list_files

    
    my $dir  = $self->_expand_filename($session_id, $d, $cwd);
    my $fpath;
    my $base = $self->_session_dir($session_id);
   if ($dir =~ /^$base(.*)/)
    {
	$fpath = $1 ? $1 : "/";
    }
    else
    {
	die "Invalid path $dir";
    }

    my @dirs;
    my @files;
    my $dh;
    opendir($dh, $dir) or die "Cannot open directory: $!";
    while (my $file = readdir($dh)) {
	next if ($file =~ m/^\./);
	my($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat("$dir/$file");

	my $date= strftime("%b %d %G %H:%M:%S", localtime($mtime));

        if (-f "$dir/$file") {
	    push @files, { name => $file, full_path => "$fpath/$file", mod_date => $date, size => $size};
        } elsif (-d "$dir/$file") {
	    push @dirs, { name => $file, full_path => "$fpath/$file", mod_date => $date };
        }
    }

    $return_1  = \@dirs;
    $return_2 =  \@files;

    closedir($dh);

    #END list_files
    my @_bad_returns;
    (ref($return_1) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return_1\" (value was \"$return_1\")");
    (ref($return_2) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return_2\" (value was \"$return_2\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_files:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_files');
    }
    return($return_1, $return_2);
}




=head2 remove_files

  $obj->remove_files($session_id, $cwd, $filename)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$filename is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$filename is a string


=end text



=item Description



=back

=cut

sub remove_files
{
    my $self = shift;
    my($session_id, $cwd, $filename) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument \"filename\" (value was \"$filename\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to remove_files:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'remove_files');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN remove_files
    my $ap;

    my $ap = $self->_expand_filename($session_id, $filename, $cwd);

    unlink($ap);
    #END remove_files
    return();
}




=head2 rename_file

  $obj->rename_file($session_id, $cwd, $from, $to)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$from is a string
$to is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$from is a string
$to is a string


=end text



=item Description



=back

=cut

sub rename_file
{
    my $self = shift;
    my($session_id, $cwd, $from, $to) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($from)) or push(@_bad_arguments, "Invalid type for argument \"from\" (value was \"$from\")");
    (!ref($to)) or push(@_bad_arguments, "Invalid type for argument \"to\" (value was \"$to\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to rename_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'rename_file');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN rename_file

    my $apf;
    my $apt;

    my $apf  = $self->_expand_filename($session_id, $from, $cwd);
    my $apt  = $self->_expand_filename($session_id, $to, $cwd);

   if (-d $apt) {
       my $f = basename $from;
       $apt = $self->_expand_filename($session_id, "$to/$f", $cwd);
   }

    rename($apf, $apt) || die ( "Error in renaming" );
    #END rename_file
    return();
}




=head2 copy

  $obj->copy($session_id, $cwd, $from, $to)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$from is a string
$to is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$from is a string
$to is a string


=end text



=item Description



=back

=cut

sub copy
{
    my $self = shift;
    my($session_id, $cwd, $from, $to) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($from)) or push(@_bad_arguments, "Invalid type for argument \"from\" (value was \"$from\")");
    (!ref($to)) or push(@_bad_arguments, "Invalid type for argument \"to\" (value was \"$to\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to copy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'copy');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN copy
    my $apf;
    my $apt;
    
    
    $apf = $self->_expand_filename($session_id, $from, $cwd);
    if (-d $apf) {
	die "Cannot copy a directory";
    }
    $apt = $self->_expand_filename($session_id, $to, $cwd);
    if (-d $apt) {
	my $f = basename $from;
	$apt = $self->_expand_filename($session_id, "$to/$f", $cwd);
    }

    File::Copy::copy($apf, $apt) || die ( "Error in renaming" );
    #END copy
    return();
}




=head2 make_directory

  $obj->make_directory($session_id, $cwd, $directory)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$directory is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$directory is a string


=end text



=item Description



=back

=cut

sub make_directory
{
    my $self = shift;
    my($session_id, $cwd, $directory) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument \"directory\" (value was \"$directory\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to make_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'make_directory');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN make_directory

    my $ap;

    $ap = $self->_expand_filename($session_id, $directory, $cwd);

    mkdir($ap) || die ( "Error in mkdir" );
    #END make_directory
    return();
}




=head2 remove_directory

  $obj->remove_directory($session_id, $cwd, $directory)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$directory is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$directory is a string


=end text



=item Description



=back

=cut

sub remove_directory
{
    my $self = shift;
    my($session_id, $cwd, $directory) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument \"directory\" (value was \"$directory\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to remove_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'remove_directory');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN remove_directory

    my $ap;

    $ap = $self->_expand_filename($session_id, $directory, $cwd);

    rmtree($ap) || die ( "Error in rmdir" );
    #END remove_directory
    return();
}




=head2 change_directory

  $obj->change_directory($session_id, $cwd, $directory)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$cwd is a string
$directory is a string

</pre>

=end html

=begin text

$session_id is a string
$cwd is a string
$directory is a string


=end text



=item Description



=back

=cut

sub change_directory
{
    my $self = shift;
    my($session_id, $cwd, $directory) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    (!ref($directory)) or push(@_bad_arguments, "Invalid type for argument \"directory\" (value was \"$directory\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to change_directory:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'change_directory');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN change_directory

    my $base = $self->_session_dir($session_id);

    my $ap;

    $ap = $self->_expand_filename($session_id, $directory, $cwd);

    if (-d $ap) {
	print "$ap is a dir";
	if ($ap =~ /^$base(.*)/) {
	    if (!$1) {
		return "/";
	    } else {
		return $1;
	    }
	} else {
	    die "invalid path";
	}
    } else { die "$directory not a directory";}
    
    #END change_directory
    return();
}




=head2 put_file

  $obj->put_file($session_id, $filename, $contents, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$filename is a string
$contents is a string
$cwd is a string

</pre>

=end html

=begin text

$session_id is a string
$filename is a string
$contents is a string
$cwd is a string


=end text



=item Description



=back

=cut

sub put_file
{
    my $self = shift;
    my($session_id, $filename, $contents, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument \"filename\" (value was \"$filename\")");
    (!ref($contents)) or push(@_bad_arguments, "Invalid type for argument \"contents\" (value was \"$contents\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to put_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'put_file');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN put_file

    #
    # Filenames can't have any special characters or start with a /.
    #
    if ($filename !~ /^([a-zA-Z][a-zA-Z0-9-_]*(?:\/[a-zA-Z][a-zA-Z0-9-_]*)*)/)
    {
	die "Invalid filename";
    }
    my $ap;

    $ap = $self->_expand_filename($session_id, $filename, $cwd);

    open(my $fh, ">", $ap) or die "Cannot open $ap: $!";
    print $fh $contents;
    close($fh);

    #END put_file
    return();
}




=head2 get_file

  $contents = $obj->get_file($session_id, $filename, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$filename is a string
$cwd is a string
$contents is a string

</pre>

=end html

=begin text

$session_id is a string
$filename is a string
$cwd is a string
$contents is a string


=end text



=item Description



=back

=cut

sub get_file
{
    my $self = shift;
    my($session_id, $filename, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($filename)) or push(@_bad_arguments, "Invalid type for argument \"filename\" (value was \"$filename\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_file:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_file');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($contents);
    #BEGIN get_file

    my $ap;

    $ap = $self->_expand_filename($session_id, $filename, $cwd);

    open(my $fh, "<", $ap) or die "Cannot open $ap: $!";
    local $/;
    undef $/;
    $contents = <$fh>;
    close($fh);
    #END get_file
    my @_bad_returns;
    (!ref($contents)) or push(@_bad_returns, "Invalid type for return variable \"contents\" (value was \"$contents\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_file:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_file');
    }
    return($contents);
}




=head2 run_pipeline

  $output, $errors = $obj->run_pipeline($session_id, $pipeline, $input, $max_output_size, $cwd)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string
$pipeline is a string
$input is a reference to a list where each element is a string
$max_output_size is an int
$cwd is a string
$output is a reference to a list where each element is a string
$errors is a reference to a list where each element is a string

</pre>

=end html

=begin text

$session_id is a string
$pipeline is a string
$input is a reference to a list where each element is a string
$max_output_size is an int
$cwd is a string
$output is a reference to a list where each element is a string
$errors is a reference to a list where each element is a string


=end text



=item Description



=back

=cut

sub run_pipeline
{
    my $self = shift;
    my($session_id, $pipeline, $input, $max_output_size, $cwd) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    (!ref($pipeline)) or push(@_bad_arguments, "Invalid type for argument \"pipeline\" (value was \"$pipeline\")");
    (ref($input) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"input\" (value was \"$input\")");
    (!ref($max_output_size)) or push(@_bad_arguments, "Invalid type for argument \"max_output_size\" (value was \"$max_output_size\")");
    (!ref($cwd)) or push(@_bad_arguments, "Invalid type for argument \"cwd\" (value was \"$cwd\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to run_pipeline:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_pipeline');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($output, $errors);
    #BEGIN run_pipeline

    print STDERR "Parse: '$pipeline'\n";
    $pipeline =~ s/\xA0/ /g;
    print STDERR "Parse: '$pipeline'\n";
    my $parser = Bio::KBase::InvocationService::PipelineGrammar->new;
    $parser->input($pipeline);
    my $tree = $parser->Run();

    if (!$tree)
    {
	die "Error parsing command line";
    }

    #
    # construct pipeline for IPC::Run
    #

    my @cmds;

    print STDERR Dumper($tree);

    $output = [];
    $errors = [];

    my $harness;

    my $dir = $self->validate_path($session_id, $cwd);
    my @cmd_list;
    my @saved_stderr;
 PIPELINE:
    for my $idx (0..$#$tree)
    {
	my $ent = $tree->[$idx];
	
	my $cmd = $ent->{cmd};
	my $redirect = $ent->{redir};
	my $args = $ent->{args};

	my $cmd_path = $self->_validate_command($cmd);
	if (!$cmd_path)
	{
	    push(@$errors, "$cmd: invalid command");
	    next;
	}

	
	if (@cmds)
	{
	    push(@cmds, '|');
	}
	$saved_stderr[$idx] = [];
	push(@cmd_list, $cmd);
	if ($cmd eq 'sort')
	{
	    if (!grep { $_ eq '-t' } @$args)
	    {
		unshift(@$args, "-t", "\t");
	    }
	}
	push(@cmds, [$cmd_path, map { s/\\t/\t/g; $_ } @$args]);
	push @cmds, init => sub {
	    chdir $dir or die $!;
	};
	my $have_output_redirect;
	my $have_stderr_redirect;
	my $have_stdin_redirect;
	for my $r (@$redirect)
	{
	    my($what, $file) = @$r;
	    if ($what eq '<')
	    {
		my $path = $self->_expand_filename($session_id, $file, $cwd);
		if (! -f $path)
		{
		    push(@$errors, "$file: input not found");
		    next PIPELINE;
		}
		$have_stdin_redirect = 1;
		push(@cmds, '<', $path);
	    }
	    elsif ($what eq '>' || $what eq '>>' || $what eq '2>' || $what eq '2>>')
	    {
		my $path = $self->_expand_filename($session_id, $file, $cwd);
		push(@cmds, $what, $path);
		if ($what =~ /^2/)
		{
		    $have_stderr_redirect = 1;
		}
		else
		{
		    $have_output_redirect = 1;
		}
	    }
	    
	}
	if ($idx == 0)
	{
	    if (!$have_stdin_redirect)
	    {
		push(@cmds, '<', '/dev/null');
	    }
	}
	if ($idx == $#$tree)
	{
	    if (!$have_output_redirect)
	    {
		push(@cmds, '>', IPC::Run::new_chunker, sub {
		    my($l) = @_;
		    push(@$output, $l);
		    if ($max_output_size > 0 && @$output >= $max_output_size)
		    {
			push(@$errors, "Output truncated to $max_output_size lines");
			$harness->kill_kill;
		    }
		});
	    }
	}
	if (!$have_stderr_redirect)
	{
	    push(@cmds, '2>', IPC::Run::new_chunker, sub {
		my($l) = @_;
		push(@{$saved_stderr[$idx]}, $l);
	    });
	}
    }

    print STDERR Dumper(\@cmds);
    $output = [];

    if (@$errors == 0)
    {
	my $h = IPC::Run::start(@cmds);
	$harness = $h;
	eval {
	    $h->finish();
	};

	my $err = $@;
	if ($err)
	{
	    push(@$errors, "Error invoking pipeline");
	    warn "error invooking pipeline: $err";
	}
	
	my @res = $h->results();
	for (my $i = 0; $i <= $#res; $i++)
	{
	    push(@$errors, "Return code from $cmd_list[$i]: $res[$i]");
	    push(@$errors, @{$saved_stderr[$i]});
	}
    }

    if ($max_output_size > 0 && @$output > $max_output_size)
    {
	my $removed = @$output - $max_output_size;
	$#$output = $max_output_size - 1;
	push(@$errors, "Elided $removed lines of output");
    }
	
    
    #END run_pipeline
    my @_bad_returns;
    (ref($output) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"output\" (value was \"$output\")");
    (ref($errors) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"errors\" (value was \"$errors\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to run_pipeline:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'run_pipeline');
    }
    return($output, $errors);
}




=head2 exit_session

  $obj->exit_session($session_id)

=over 4

=item Parameter and return types

=begin html

<pre>
$session_id is a string

</pre>

=end html

=begin text

$session_id is a string


=end text



=item Description



=back

=cut

sub exit_session
{
    my $self = shift;
    my($session_id) = @_;

    my @_bad_arguments;
    (!ref($session_id)) or push(@_bad_arguments, "Invalid type for argument \"session_id\" (value was \"$session_id\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to exit_session:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'exit_session');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    #BEGIN exit_session
    #END exit_session
    return();
}




=head2 valid_commands

  $return = $obj->valid_commands()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a reference to a list where each element is a command_group_desc
command_group_desc is a reference to a hash where the following keys are defined:
	name has a value which is a string
	title has a value which is a string
	items has a value which is a reference to a list where each element is a command_desc
command_desc is a reference to a hash where the following keys are defined:
	cmd has a value which is a string
	link has a value which is a string

</pre>

=end html

=begin text

$return is a reference to a list where each element is a command_group_desc
command_group_desc is a reference to a hash where the following keys are defined:
	name has a value which is a string
	title has a value which is a string
	items has a value which is a reference to a list where each element is a command_desc
command_desc is a reference to a hash where the following keys are defined:
	cmd has a value which is a string
	link has a value which is a string


=end text



=item Description



=back

=cut

sub valid_commands
{
    my $self = shift;

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($return);
    #BEGIN valid_commands
    return $self->{command_groups};
    #END valid_commands
    my @_bad_returns;
    (ref($return) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"return\" (value was \"$return\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to valid_commands:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'valid_commands');
    }
    return($return);
}




=head2 get_tutorial_text

  $text, $prev, $next = $obj->get_tutorial_text($step)

=over 4

=item Parameter and return types

=begin html

<pre>
$step is an int
$text is a string
$prev is an int
$next is an int

</pre>

=end html

=begin text

$step is an int
$text is a string
$prev is an int
$next is an int


=end text



=item Description



=back

=cut

sub get_tutorial_text
{
    my $self = shift;
    my($step) = @_;

    my @_bad_arguments;
    (!ref($step)) or push(@_bad_arguments, "Invalid type for argument \"step\" (value was \"$step\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to get_tutorial_text:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_tutorial_text');
    }

    my $ctx = $Bio::KBase::InvocationService::Service::CallContext;
    my($text, $prev, $next);
    #BEGIN get_tutorial_text

    my $gpath = sub { sprintf "/home/olson/public_html/kbt/t%d.html", $_[0]; };

    my $path = &$gpath($step);
    if (! -f $path)
    {
	$step = 1;
	$path = &$gpath($step);
    }

    if (open(my $fh, "<", $path))
    {
	local $/;
	undef $/;
	$text = <$fh>;

	$prev = $step - 1;
	$next = $step + 1;
	if (! -f &$gpath($prev))
	{
	    $prev = -1;
	}
	if (! -f &$gpath($next))
	{
	    $next = -1;
	}
	close($fh);
    }
    #END get_tutorial_text
    my @_bad_returns;
    (!ref($text)) or push(@_bad_returns, "Invalid type for return variable \"text\" (value was \"$text\")");
    (!ref($prev)) or push(@_bad_returns, "Invalid type for return variable \"prev\" (value was \"$prev\")");
    (!ref($next)) or push(@_bad_returns, "Invalid type for return variable \"next\" (value was \"$next\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to get_tutorial_text:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'get_tutorial_text');
    }
    return($text, $prev, $next);
}




=head1 TYPES



=head2 directory

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
name has a value which is a string
full_path has a value which is a string
mod_date has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
name has a value which is a string
full_path has a value which is a string
mod_date has a value which is a string


=end text

=back



=head2 file

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
name has a value which is a string
full_path has a value which is a string
mod_date has a value which is a string
size has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
name has a value which is a string
full_path has a value which is a string
mod_date has a value which is a string
size has a value which is a string


=end text

=back



=head2 command_desc

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
cmd has a value which is a string
link has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
cmd has a value which is a string
link has a value which is a string


=end text

=back



=head2 command_group_desc

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
name has a value which is a string
title has a value which is a string
items has a value which is a reference to a list where each element is a command_desc

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
name has a value which is a string
title has a value which is a string
items has a value which is a reference to a list where each element is a command_desc


=end text

=back



=cut

1;
