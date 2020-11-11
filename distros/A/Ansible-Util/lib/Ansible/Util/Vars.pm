package Ansible::Util::Vars;
$Ansible::Util::Vars::VERSION = '0.001';
=head1 NAME

Ansible::Util::Vars

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  $vars = Ansible::Util::Vars->new;
  
  $href = $vars->getVar('foo');
  $href = $vars->getVars(['foo', 'bar']);
  $val  = $vars->getValue('foo');
   
=head1 DESCRIPTION

Read Ansible runtime vars into native Perl.  

To indicate which vars to read, you use the variable dot notation similar to 
what is described in the Ansible documentation.  Further information about the 
Perl implementation can be found in L<Hash::DotPath>.

An optional cache layer is used to speed up multiple invocations.   
 
=cut

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka 'method';
use Data::Printer alias => 'pdump';
use File::Temp 'tempfile', 'tempdir';
use Hash::DotPath;
use JSON;
use YAML ();
use Ansible::Util::Run;

with 'Ansible::Util::Roles::Constants';

##############################################################################
# PUBLIC ATTRIBUTES
##############################################################################

=head1 ATTRIBUTES

=head2 vaultPasswordFiles

A list of vault-password-files to pass to the command line.

=over

=item type: ArrayRef[Str]

=item required: no

=back

=cut

with
  'Ansible::Util::Roles::Attr::VaultPasswordFiles',
  'Util::Medley::Roles::Attributes::Cache',
  'Util::Medley::Roles::Attributes::Logger',
  'Util::Medley::Roles::Attributes::File';

=head2 cacheEnabled

Toggle to disable/enable caching.

=over

=item type: Bool

=item required: no

=item default: 1

=back

=cut

has cacheEnabled => (
	is      => 'rw',
	isa     => 'Bool',
	default => 1,
	writer  => '_setCacheEnabled',
);

=head2 cacheExpireSecs

Controls how long to hold onto cached data.

=over

=item type: Int

=item required: no

=item default: 10 min

=back

=cut

has cacheExpireSecs => (
	is      => 'rw',
	isa     => 'Int',
	default => sub { DEFAULT_CACHE_EXPIRE_SECS() },
);

=head2 hosts

Choose which managed nodes or groups you want to execute against.  This format
of this is exactly the same as defined in "Patterns: targeting hosts and groups" 
by the Ansible documentation.

=over

=item type: Str

=item required: no

=item default: localhost

=back

=cut

has hosts => (
	is      => 'rw',
	isa     => 'Str',
	default => 'localhost',
);

=head2 keepTempFiles

Keeps the generated tempfiles for debugging/troubleshooting.  The tempfiles 
used are a playbook, template, and json output.

=over

=item type: Bool

=item required: no

=item default: 0

=back

=cut

has keepTempFiles => (
	is      => 'rw',
	isa     => 'Bool',
	default => 0,
);

=head2 keepTempFilesOnError

This is a toggle to keep the generated tempfiles when Ansible exits with an
error.  

=over

=item type: Bool

=item required: no

=item default: 0

=back

=cut

has keepTempFilesOnError => (
	is      => 'rw',
	isa     => 'Bool',
	default => 1,
);

##############################################################################
# PRIVATE_ATTRIBUTES
##############################################################################

has _exitDueToAnsibleError => (
	is      => 'rw',
	isa     => 'Bool',
	default => 0,
);

has _tempDir => (
	is        => 'rw',
	isa       => 'Str',
	lazy      => 1,
	builder   => '_buildTempDir',
	predicate => '_hasTempDir',
	clearer   => '_clearTempDir',
);

has _tempFiles => (
	is      => 'rw',
	isa     => 'ArrayRef',
	default => sub { [] },
);

##############################################################################
# CONSTRUCTOR
##############################################################################

# uncoverable branch false count:1
method BUILD {

	$self->Cache->ns( CACHE_NS_VARS() );
	$self->Cache->expireSecs( $self->cacheExpireSecs );
	$self->Cache->enabled( $self->cacheEnabled );
}

##############################################################################
# DESTRUCTOR
##############################################################################

# uncoverable branch false count:1
method DEMOLISH {

	if ( $self->keepTempFiles ) {

		# do nothing
	}
	elsif ( $self->_exitDueToAnsibleError and $self->keepTempFilesOnError ) {

		# do nothing
	}
	else {
		$self->_cleanupTempFiles;
	}
}

##############################################################################
# PUBLIC METHODS
##############################################################################

=head1 METHODS

All methods confess on error unless otherwise specified.

=head2 clearCache()

Clears any cached vars.

=head3 usage:

  $vars->clearCache;

=head3 args:

none

=cut

# uncoverable branch false count:1
method clearCache {

	$self->Cache->clear;

	return 1;
}

=head2 disableCache()

Disables caching.

=head3 usage:

  $vars->disableCache;

=head3 returns:

The previous value of the attribute 'cacheEnabled'.

=head3 args:

none

=cut

# uncoverable branch false count:1
method disableCache {

	my $orig = $self->cacheEnabled;
	
	$self->_setCacheEnabled(0);
	$self->Cache->enabled( $self->cacheEnabled );

	return $orig;
}

=head2 enableCache()

Enables caching.

=head3 usage:

  $vars->enableCache;

=head3 returns:

The previous value of the attribute 'cacheEnabled'.

=head3 args:

none

=cut

# uncoverable branch false count:1
method enableCache {

	my $orig = $self->cacheEnabled;

	$self->_setCacheEnabled(1);
	$self->Cache->enabled( $self->cacheEnabled );

	return $orig;
}

=head2 getValue()

Fetches the value of the specified var.

=head3 usage:

  $val = $vars->getValue($path);
  
=head3 returns:

The value found at the specified path.
                        
=head3 args:

=over

=item path

The path to the variable in dot notation.  See L<Hash::DotPath> for more info.

=over

=item type: Str

=item required: yes

=back

=back

=cut

method getValue (Str $path!) {

	my $href    = $self->getVar(@_);
	my $dotResp = Hash::DotPath->new($href);

	# --> Any (value @ path)
	return $dotResp->get($path);
}

=head2 getVar($path)

Fetches the variable found at the specified path. 

=head3 usage:

  $href = $vars->getVar($path);
  
=head3 returns:

A hash reference containing the requested var.  Note that this also includes
each of the elements in the path.  Examples:

  $href = $vars->getVar('foo.bar');
  Data::Printer::p($href);
  \ {
    foo   {
        bar   "somevalue"
    }
  }
  
  $href = $vars->getVar('biz.0.baz');
  Data::Printer::p($href);
  \ {
    biz   [
        [0] {
            baz   "anothervalue"
        }
    ]
}
                        
=head3 args:

=over

=item path

The path to the variable in dot notation.  See L<Hash::DotPath> for more info.

=over

=item type: Str

=item required: yes

=back

=back

=cut

method getVar (Str $path!) {

	return $self->getVars( [$path] );
}

=head2 getVars([$paths])

Fetches the variables found at the specified path. 

=head3 usage:

  $href = $vars->getVars(['foo.0.bar', 'biz']);
  
=head3 returns:

A hash reference containing the requested vars.  The characteristics 
are the same as described in L</getVar> except that the vars are merged into
a single hash ref.

=head3 args:

=over

=item path

The path to the variable in dot notation.  See L<Hash::DotPath> for more info.

=over

=item type: ArrayRef[Str]

=item required: yes

=back

=back

=cut

method getVars (ArrayRef $paths!) {

	my @missing;
	my $cached = Hash::DotPath->new( $self->_getCache );

	foreach my $path (@$paths) {
		if ( !$cached->exists($path) ) {
			push @missing, $path;
		}
	}

	my $href   = $self->_getVars( \@missing );
	my $merged = $cached->merge($href);
	$self->_setCache( $merged->toHashRef );

	#
	# now extract just the requested paths because the cache might
	# have a superset of what was requested.
	#
	my $result = Hash::DotPath->new;
	foreach my $path (@$paths) {
		$result->set( $path, $merged->get($path) );
	}

	return $result->toHashRef;
}

##############################################################################
# PRIVATE METHODS
##############################################################################

method _getTempFile (Str $suffix!) {

	my $dir = $self->_tempDir;

	my ( $tempFh, $tempFilename ) =
	  File::Temp::tempfile( DIR => $dir, SUFFIX => $suffix );
	close($tempFh);

	$tempFilename = sprintf '%s/%s', $dir, $self->File->basename($tempFilename);
	push @{ $self->_tempFiles }, $tempFilename;

	return $tempFilename;
}

method _getVars (ArrayRef $vars!) {

	return {} if @$vars < 1;

	#
	# save template j2 file
	#
	my $templateFilename = $self->_getTempFile('-template.j2');

	my @content;
	foreach my $var (@$vars) {
		push @content, "{{ my_vars | to_nice_json }} ";
	}

	$self->File->write( $templateFilename, join( "\n", @content ) );

	#
	# create a placeholder for the template output
	#
	my $outputFilename = $self->_getTempFile('-output.json');

	#
	# create the playbook
	#
	my $pbFilename = $self->_getTempFile('-playbook.yml');

	my $content =
	  $self->_buildPlaybook( $vars, $templateFilename, $outputFilename );

	$self->File->write( $pbFilename, $content );

	#
	# execute
	#
	my $run = Ansible::Util::Run->new(
		vaultPasswordFiles => $self->vaultPasswordFiles );

	my ( $stdout, $stderr, $exit ) =
	  $run->ansiblePlaybook( playbook => $pbFilename, confessOnError => 0 );

	if ($exit) {
		$self->_exitDueToAnsibleError(1);
		$self->Logger->warn( "keeping tempfiles located at "
			  . $self->_tempDir
			  . " for troubleshooting" );
		confess $stderr if $exit;
	}

	#
	# read the output json and put into perl var
	#
	my $json_text = $self->File->read($outputFilename);
	my $json      = JSON->new;
	my $answer    = $json->decode($json_text);

	# return answer
	return $answer;
}

method _buildPlaybookVars (ArrayRef $vars!) {

	my $dot = Hash::DotPath->new;

	foreach my $var (@$vars) {
		$dot->set( $var, sprintf '{{ %s }}', $var );
	}

	my $my_vars_yaml = YAML::Dump( $dot->toHashRef );

	my @indented;
	foreach my $line ( split /\n/, $my_vars_yaml ) {
		next if $line eq '---';    # remove new document syntax
		push @indented, sprintf '%s%s', ' ' x 6, $line;
	}

	return join "\n", @indented;
}

method _buildPlaybook (ArrayRef $vars!,
                       Str      $template_src!,
                       Str      $template_dest!) {

	my $hosts = $self->hosts;

	my @content;
	push @content, "- hosts: $hosts";

	if ( $hosts eq 'localhost' or $hosts eq '127.0.0.1' ) {
		push @content, '  connection: local';
	}

	push @content, '  gather_facts: yes';
	push @content, '  vars:';
	push @content, '    my_vars:';
	push @content, $self->_buildPlaybookVars($vars);
	push @content, '  tasks:';
	push @content, '    - template:';
	push @content, "        src:  $template_src";
	push @content, "        dest: $template_dest";
	push @content, "\n";

	return join "\n", @content;
}

method _getCache {

	my $vars = $self->Cache->get( key => CACHE_KEY() );
	if ( !$vars ) {
		return {};
	}

	return $vars;
}

method _setCache (HashRef $href!) {

	$self->Cache->set(
		key  => CACHE_KEY(),
		data => $href,
	);

	return $href;
}

method _cleanupTempFiles {

	#
	# cleanup the files
	#
	foreach my $tempFile ( @{ $self->_tempFiles } ) {
		$self->File->unlink($tempFile);
	}

	$self->_tempFiles( [] );

	#
	# cleanup the dir
	#
	$self->File->rmdir( $self->_tempDir );
	$self->_clearTempDir;
}

method _buildTempDir {

	return tempdir( CLEANUP => 0 );
}

1;
