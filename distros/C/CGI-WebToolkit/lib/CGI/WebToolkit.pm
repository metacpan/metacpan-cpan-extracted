package CGI::WebToolkit;

use 5.008006;
use strict;
use warnings;

use CGI qw(param header);
use CGI::Carp qw(fatalsToBrowser);
use Data::Dump qw(dump);
use DBI;
use Digest::MD5 qw(md5_hex);

our $VERSION = '0.08';

our $WTK = undef;

our @XHTML_TAGS
	= qw(a abbr acronym address applet area b base bdo big blockquote
		 body br button caption cite code col colgroup dd del dfn div
		 dl DOCTYPE dt em fieldset form frame frameset h1 h2 h3 h4 h5
		 h6 head hr html i iframe img input ins kbd label legend li
		 link map meta noframes noscript object ol optgroup option p
		 param pre q samp script select small span strong style sub sup
		 table tbody td textarea tfoot th thead title tr tt ul var marquee
		 section header footer nav article
		 emph);

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# constructor

sub new
{
	my ($class, @args) = @_;
	my $self = bless {}, $class;
	return $self->__init( @args );
}

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# methods

sub handle
{
	my ($self) = __parse_args(@_);
	
	# clear cache
	$self->__clear_cache()
		if $self->{'allowclearcache'} == 1
			&& defined param($self->{'clearcacheparam'});
	
	# determine name of workflow function
	my $workflow_function_name = param($self->{'workflowparam'});
	   $workflow_function_name = $self->{'entryaction'}
	   		unless defined $workflow_function_name;
	
	my $mimetype = '';
	my $message = '';
	my $function_name = $workflow_function_name;
	my $args = [];
	while (1) {
		
		my $result = $self->call( $function_name, @{$args} );
		
		__die("function '$function_name' returned invalid result.".
			 " Use the methods output() or followup() to generate a valid result.")
			if ref $result ne 'HASH' || !exists $result->{'type'};
		
		if ($result->{'type'} eq 'output') {
			if (exists $result->{'status'} && $result->{'status'} == 1) {
				
				__die("missing mimetype in result from function '$function_name'")
					unless exists $result->{'mimetype'};			
				__die("missing content in result from function '$function_name'")
					unless exists $result->{'content'};
					
				$mimetype = $result->{'mimetype'};
				$message  = $result->{'content'};

				if ($mimetype eq 'text/html') {
					# replace any {...:...} placeholders with their default values
					$message =~ s/\{[a-zA-Z0-9\.\_]+\:([^\}]*)\}/$1/mg;

					# replace any {...} placeholders with empty string
					$message =~ s/\{[a-zA-Z0-9\.\_]+\}//mg;
				}

				last;				
			}
			else {
				$function_name = 'core.error';
			}
		}
		elsif ($result->{'type'} eq 'followup') {
			
			__die("missing followup function name in result from function '$function_name'")
				unless exists $result->{'function_name'};

			$function_name = $result->{'function_name'};
			$args = $result->{'arguments'} if exists $result->{'arguments'};
		}
		else {
			__die("function '$function_name' returned unknown type of result.".
			     " Use the methods output() or followup() to generate a valid result.");
		}
	}
	
	$| = 1;
	
	# add session to every link that points to the cgi script
	if (exists $ENV{'SCRIPT_NAME'}) {
		my $script = quotemeta $ENV{'SCRIPT_NAME'};
		my $url_addon  = $self->{'idparam'}.'='.$self->{'session_id'}.'&';
		my $form_addon =
			'<input type="hidden" name="'.$self->{'idparam'}
				.'" value="'.$self->{'session_id'}.'"/>'.
			'<input type="hidden" name="'.$self->{'clearcacheparam'}
				.'" value="1"/>';
		
		if ($mimetype eq 'text/html') {
			# add session id to internal links
			$message =~ s/(href=[\"\']($script)?\?)/$1$url_addon/mig;
			$message =~ s/(href=[\"\']$script)/$1?$url_addon/mig;
			
			# add session id as hidden field to internal forms
			$message =~ s/(<form[^\>]*action=[\"\']$script[^\>]*>)/$1$form_addon/mig;
		}
	}

	$self->__cleanup();
	
	return header( -type => $mimetype ).$message;
}

sub call
{
	my ($self, $function_name, @args) = __parse_args(@_);

	# check if user is allowed to execute workflow function
	$function_name = $self->{'entryaction'}
		if $self->{'checkrights'} == 1 && !$self->allowed($function_name);

	# check for cache entry
	my $cachehash;
	if ($self->{'cachetable'} ne '') {
		$cachehash = $self->__get_cache_hash($function_name, @args);
		my $result = $self->__load_cache($cachehash);
		return $result if defined $result;
	}
		
	unless (exists $self->{"workflow_function_cache"}->{$function_name}) {
	
		my $function_filename 
			= $self->__get_external_function_filename('workflows', $function_name);
		
		if (defined $function_filename) {
			# load function ref. into cache
			$self->{"workflow_function_cache"}->{$function_name}
				= __load_file_as_subref($function_filename)
					unless exists $self->{'workflow_function_cache'}->{$function_name};
		}
		else {
			# define error function
			$self->{"workflow_function_cache"}->{$function_name}
				= sub { __die("failed to load function '$function_name'") };
		}
	}

	# load library path for modules
	my $libpath = $self->{'privatepath'}.'/modules';
	eval('use lib "'.$libpath.'"');
	__die("loading of library path '$libpath' failed: $@") if $@;

	# load all modules for workflow function
	foreach my $module (@{$self->{'modules'}}) {
		eval('use '.$module);
		__die("loading of module '$module' failed: $@") if $@;
	}
	
	# call workflow function
	$self->{'current_workflow_function'} = $function_name;
	my $result =
		$self->{"workflow_function_cache"}->{$function_name}->(
			$self, @args );
	$self->{'current_workflow_function'} = undef;
	
	# save result to cache
	if ($self->{'cachetable'} ne '') {
		$self->__save_cache($cachehash, $result);
	}
	
	return $result;
}

sub output
{
	my ($self, $status, $info, $content, $mimetype) = __parse_args(@_);
	$status   = 1 			unless defined $status;
	$info     = 'ok' 		unless defined $info;
	$content  = '' 			unless defined $content;
	$mimetype = 'text/html' unless defined $mimetype;
	return {
		'type'     => 'output',
		'status'   => $status,
		'info'     => $info,
		'content'  => $content,
		'mimetype' => $mimetype,
	};
}

sub followup
{
	my ($self, $function_name, @args) = __parse_args(@_);
	return {
		'type'          => 'followup',
		'function_name' => $function_name,
		'arguments'     => [ @args ],
	};
}

# ------------------------------------------------------------------------------

sub get
{
	my ($self, $varname) = __parse_args(@_);
	return 1 if $self->{'sessiontable'} eq '';
	
	if (exists $self->{'session'}->{$varname}) {
		return $self->{'session'}->{$varname};
	} else {
		return undef;
	}
}

sub set
{
	my ($self, $varname, $value) = __parse_args(@_);
	return 1 if $self->{'sessiontable'} eq '';
	
	$self->{'session'}->{$varname} = (defined $value ? $value : '');
	return 1;
}

sub unset
{
	my ($self, $name) = __parse_args(@_);
	return 1 if $self->{'sessiontable'} eq '';
	
	delete $self->{'session'}->{$name}
		if exists $self->{'session'}->{$name};
		
	return 1;
}

# ------------------------------------------------------------------------------

sub fill
{
	my ($self, $template_name, $data) = __parse_args(@_);
	my @data = (ref($data) eq 'ARRAY' ? @{$data} : ($data));

	my $filename1 = $self->__get_external_function_filename( 'generators', $template_name );
	my $filename2 = $self->__get_external_function_filename( 'generators', 'core.'.$template_name );

	if (defined $filename1) {
		# load function ref. into cache
		$self->{"template_function_cache"}->{$template_name}
			= __load_file_as_subref($filename1)
				unless exists $self->{'template_function_cache'}->{$template_name};
	}
	elsif (defined $filename2) {
		# load function ref. into cache
		$self->{"template_function_cache"}->{$template_name}
			= __load_file_as_subref($filename2)
				unless exists $self->{'template_function_cache'}->{$template_name};
	}
	else {
		# load static template file from theme
		
		my @fallback_themes = @{$self->{'templatefallbacks'}};
		
		# check for specific theme
		if ($template_name =~ /^([^\:]+)\:(.*)$/) {
			my ($theme, $name) = $template_name =~ /^([^\:]+)\:(.*)$/;
			@fallback_themes = ($theme);
			$template_name = $name;
		}
		
		# look into themes for file
		my $filename;
		foreach my $theme (@fallback_themes) {
			$filename = __identifier_to_filename(
							$self->{'privatepath'}.'/templates/'.$theme.'/',
							$template_name, '.html');
			last if -f $filename;
		}

		# load file
		open TMPLFILE, '<'.$filename or __die("failed to open file '$filename': $!");
		my $content = join '', <TMPLFILE>;
		close TMPLFILE;
		
		# create generic function to parse the content
		$self->{"template_function_cache"}->{$template_name} =
			sub {
				my ($self, @data) = @_;
				my $result = '';
				foreach my $data (@data) {
					my $tmpl = $content;					
					# expand macros
					$self->__expand_macros(\$tmpl) if $self->{'allowmacros'} == 1;
					# replace variables
					__replace_placeholders(\$tmpl, $data);
					# replace common variables
					__replace_placeholders(\$tmpl, $self->{'common_placeholders'});
					$result .= $tmpl;
				}
				return $result;
			}
	}

	# call template function
	return
		$self->{"template_function_cache"}->{$template_name}->(
			$self, @data );	
}

# ------------------------------------------------------------------------------

sub _
{
	my ($self, $phrase, $language) = __parse_args(@_);
	return '' unless defined $phrase;

	return $phrase
		if $self->{'phrasetable'} eq '';

	$language = $self->get('language') unless defined $language;
	$language = $self->{'defaultlanguage'} unless defined $language;
	
	# query db for phrase
	my $query
		= $self->find(
			-tables => [$self->{'phrasetable'}],
			-where  => {'name' => $phrase},
		);
		
	if (my $row = $query->fetchrow_hashref()) {
		if ($row->{'language'} eq $language) {
			return $phrase;
		}
		else {
			# look for translation
			my $translation = __find_translation($row->{'translations'}, $language);
			return (defined $translation ? $translation : $phrase);
		}
	}
	else {
		return $phrase;
	}
}

# ------------------------------------------------------------------------------

sub lang
{
	my ($self, $language) = __parse_args(@_);
	if (defined $language) {
		# set
		$self->set($language);
	}
	# get
	my $lang = $self->get('language');
	return (defined $lang ? $lang : $self->{'defaultlanguage'});
}

# ------------------------------------------------------------------------------

sub translate
{
	my ($self, @pairs) = __parse_args(@_);
	return 0
		if $self->{'phrasetable'} eq '';
	
	__die("translate() expects language/phrase pairs as parameters")
		if scalar(@pairs) % 2 == 1 || scalar(@pairs) < 4;

	# erease any bad characters
	foreach my $p (0..$#pairs) {
		$pairs[$p] =~ s/[\n\r\:]//g;
	}
	
	# create real tuples
	my ($key_language, $key_phrase) = (shift(@pairs), shift(@pairs));
	my %phrases;
	for (my $i = 0; $i < scalar @pairs; $i += 2) {
		$phrases{$pairs[$i]} = $pairs[$i + 1];
	}

	# query db for phrase entry
	my $query 
		= $self->find(
			-tables => [$self->{'phrasetable'}],
			-where  => {'name' => $key_phrase, 'language' => $key_language},
		);

	if (my $row = $query->fetchrow_hashref()) {
		# update
		my $translations = __find_translation($row->{'translations'});
		foreach my $lang (keys %phrases) {
			$translations->{$lang} = $phrases{$lang};
		}
		$self->update(
			-table => $self->{'phrasetable'},
			-set => {
				'name' => $key_phrase,
				'language' => $key_language,
				'translations' => join("\n", map { $_.':'.$translations->{$_} } keys %{$translations}),
			},
			-where => {'name' => $key_phrase, 'language' => $key_language},
		);	
	}
	else {
		# insert
		$self->create(
			-table => $self->{'phrasetable'},
			-row => {
				'name' => $key_phrase,
				'language' => $key_language,
				'translations' => join("\n", map { $_.':'.$phrases{$_} } keys %phrases),
			},
		);
	}
}

# ------------------------------------------------------------------------------

sub find
{
	my ($self, %options) = __parse_args(@_);
	my $opts = __parse_params( \%options,
		{
			tables 		=> [],
			where 		=> {},
			wherelike 	=> {},
			group 		=> [],
			order 		=> [],
			limit 		=> 0,
			distinct 	=> 0,
			columns		=> [],
			joins		=> {},
			sortdir		=> 'asc', # 'asc' or 'desc'
		});

	my @tables = map { $self->__quotename($_) } @{$opts->{'tables'}};

	my @columns = map { $self->__quotename($_) } @{$opts->{'columns'}};

	my @joins =
		map {
			$self->__quotename($_).' = '.$self->__quotename($opts->{'joins'}->{$_});
		}
		keys %{$opts->{'joins'}};

	my @group = map { $self->__quotename($_) } @{$opts->{'group'}};

	my @order = map { $self->__quotename($_) } @{$opts->{'order'}};
	
	my $sql
		= 'SELECT'
		.(defined $opts->{'distinct'} ? ' DISTINCT' : '')
		.' '.(scalar @columns ? join(', ', @columns) : '*')
		.' FROM '.join(', ', @tables)
		.' WHERE '
		.(scalar keys %{$opts->{'where'}} ?
			$self->__make_sql_where_clause($opts->{'where'})
			: '1')
		.(scalar keys %{$opts->{'wherelike'}} ?
			' AND '.$self->__make_sql_where_clause($opts->{'wherelike'}, 1)
			: '')
		.(scalar @joins ? ' AND '.join(' AND ', @joins) : '')
		.(scalar @group ? ' GROUP BY '.join(', ', @group) : '')
		.(scalar @order ? ' ORDER BY '.join(', ', @order).' '.uc($opts->{'sortdir'}) : '')
		.($opts->{'limit'} > 0 ? ' LIMIT '.$opts->{'limit'} : '');
	
	return $self->query($sql);
}

sub create
{
	my ($self, %options) = __parse_args(@_);
	my $opts = __parse_params( \%options,
		{
			table => undef,
			row => {},
		});

	my @columns;
	my @values;
	map {
		push @columns, $self->__quotename($_);
		push @values,  $self->__quote($opts->{'row'}->{$_});
	}
	keys %{$opts->{'row'}};

	my $sql
		= 'INSERT'
			.' INTO '.$self->__quotename($opts->{'table'})
			.' ('.join(', ', @columns).')'
			.' VALUES ('.join(', ', @values).')';

	$self->query($sql);
	return $self->{'dbh'}->last_insert_id(undef, undef, $opts->{'table'}, 'id');
}

sub update
{
	my ($self, %options) = __parse_args(@_);
	my $opts = __parse_params( \%options,
		{
			table => '',
			set => {},
			where => {},
			wherelike => {},
		});

	my @sets =
		map {
			$self->__quotename($_).' = '.$self->__quote($opts->{'set'}->{$_});
		}
		keys %{$opts->{'set'}};

	my $sql
		= 'UPDATE'
			.' '.$self->__quotename($opts->{'table'})
			.' SET '.join(', ', @sets)
			.' WHERE '
			.(scalar keys %{$opts->{'where'}} ?
				$self->__make_sql_where_clause($opts->{'where'})
				: '1')
			.(scalar keys %{$opts->{'wherelike'}} ?
				' AND '.$self->__make_sql_where_clause($opts->{'wherelike'}, 1)
				: '');

	return $self->query($sql);
}

sub remove
{
	my ($self, %options) = __parse_args(@_);
	my $opts = __parse_params( \%options,
		{
			table => '',
			where => {},
			wherelike => {},
		});

	my $sql
		= 'DELETE'
			.' FROM '.$self->__quotename($opts->{'table'})
			.' WHERE '
			.(scalar keys %{$opts->{'where'}} ?
				$self->__make_sql_where_clause($opts->{'where'})
				: '1')
			.(scalar keys %{$opts->{'wherelike'}} ?
				' AND '.$self->__make_sql_where_clause($opts->{'wherelike'}, 1)
				: '');

	return $self->query($sql);
}

sub load
{
	my ($self, $group, $recordset, $tablename) = __parse_args(@_);
	
	my $records	= __load_data_file($self->{'privatepath'}.'/data/'.$group.'/'.$recordset.'.txt');
	
	my $inserted = 0;
	foreach my $record (@{$records}) {
		__die("record does not have an id field, in data file '$group/$recordset'")
			unless exists $record->{'id'};
		
		my $query
			= $self->find(
				-tables => [$tablename],
				-where  => {'id' => $record->{'id'}},
				-limit  => 1,
			);
			
		if (my $row = $query->fetchrow_hashref()) {
			# do nothing
		}
		else {
			# insert
			$self->create(
				-table => $tablename,
				-row   => $record,
			);
			$inserted ++;	
		}
	}
	return (scalar @{$records}, $inserted);
}

sub query
{
	my ($self, $sql) = __parse_args(@_);
	$self->__connect_to_db();
	my $query = $self->{'dbh'}->prepare($sql);
	$query->execute()
		or __die('the query ['.$sql.'] failed: '.DBI->errstr());
	return $query;
}

# ------------------------------------------------------------------------------

sub getparam
{
	my ($self, $name, $default, $regex) = __parse_args(@_);
	$regex = '.*' unless defined $regex;
	my $value = param($name);
	return (defined $value && $value =~ /$regex/ ? $value : $default);
}

# ------------------------------------------------------------------------------

sub login
{
	my ($self, $loginname, $password) = __parse_args(@_);
	return 1 if $self->{'usertable'} eq '';

	return 0 unless defined $loginname;
	return 0 unless defined $password;

	return 0 if $self->{'usertable'} eq '';

	my $query
		= find(
			-tables => [$self->{'usertable'}],
			-where  => { 
				'loginname' => $loginname,
				'password' => md5_hex($password),
			},
			-limit  => 1,
		);

	if (my $user = $query->fetchrow_hashref()) {
		return 0 if $user->{'active'} == 0;
		
		# associate session with user id
		set('user', $user);
		
		# set language
		$self->set('language', $user->{'ui_language'})
			if $user->{'ui_language'} ne '';
	}
	else {
		return 0;
	}
}

# ------------------------------------------------------------------------------

sub logout
{
	my ($self) = __parse_args(@_);
	return 1 if $self->{'usertable'} eq '';

	$self->unset('user');
	return 1;
}

# ------------------------------------------------------------------------------

sub allowed
{
	my ($self,
		$function_name,	# workflow function name
		$loginname,		# loginname of user
		) = __parse_args(@_);

	return 1 if $self->{'accessconfig'} eq '';

	# load access config from <privatepath>/accessconfigs/<name>.txt
	# $mappings = { <regex> => <functionname>, ... }
	my $mappings
		= __load_config_file(
			$self->{'privatepath'}.'/accessconfigs/'.$self->{'accessconfig'}.'.txt');

	# determine and call appropriate access check function(s)
	my $has_access = 0;
	foreach my $rgx (keys %{$mappings}) {
		if ($function_name =~ /$rgx/) {
			my $check_function_name = $mappings->{$rgx};
			my $filename =
				$self->__get_external_function_filename(
					'accesschecks', $check_function_name);

			# load function as subroutine
			$self->{"access_function_cache"}->{$check_function_name}
				= __load_file_as_subref($filename)
					unless exists $self->{"access_function_cache"}->{$check_function_name};

			my $check_function = $self->{"access_function_cache"}->{$check_function_name};

			$has_access = $has_access && $check_function->( $self, $function_name, $loginname );
		}
	}
	
	return $has_access;
}

# ------------------------------------------------------------------------------

sub logmsg
{
	my ($self, $msg, $priority) = __parse_args(@_);
	
	$msg .= "\r\n" if $msg !~ /\r?\n$/;
	
	$priority = 'DEBUG'
		if !defined $priority
		|| !scalar
				grep { $_ eq uc($priority) }
					qw(DEBUG INFO WARNING ERROR FATAL);
	
	# log to priority-logfile
	my $logfile = $self->{'privatepath'}.'/logs/'.uc($priority).'.txt';
	__file_append($logfile, $msg);
	
	if (defined $self->{'current_workflow_function'}) {
		# log to workflow-function-specific logfile as well
		my $logfile2 = $self->{'privatepath'}.'/logs/'.uc($self->{'current_workflow_function'}).'.txt';
		__file_append($logfile2, $msg);
	}
}

# ------------------------------------------------------------------------------

sub fail
{
	my ($self, $msg) = __parse_args(@_);
	__die($msg);
}

# ------------------------------------------------------------------------------

sub upload
{
	my ($self, $paramname, $groupname) = __parse_args(@_);
	
	# retrieve file from parameters
	my $file = $self->getparam($paramname, undef);

	__die("cannot retrieve upload via unknown parameter '$paramname'")
		unless defined $file;

	my $now = time();

	my $upload_info = CGI::uploadInfo($file);
	my $ending = $upload_info->{'Content-Disposition'};
	   $ending =~ s/^.*\.//;
	   $ending =~ s/\"$//;

	# generate filename
	my $filepath = $self->{'publicpath'}.'/uploads/'.$groupname.'/'; 
	my $filename = $self->{'session_id'}.'_'.$now.'.'.$ending;

	# write data to file
	open UPLOAD, '>'.$filepath.$filename
		or __die("failed to write upload to file '$filepath$filename': $!");

	# Dateien in den Binaer-Modus schalten
	binmode $file;
	binmode UPLOAD;

	my $info = {
		'status' => 1,
		'info'   => 'The file has been successfully saved.',
	};

	my $data;
	my $bytes_written = 0;
	while (read $file, $data, 1024) {
		print UPLOAD $data;
		$bytes_written += 1024;
		if ($bytes_written > $self->{'uploadmaxsize'}) {
			$info->{'status'} = 0;
			$info->{'info'} =
				'The filesize exceeded the maximum upload size. '.
				'Aborted after '.$bytes_written.' Bytes.';
			last;
		}
	}
	close UPLOAD;
	
	my $mimetype = $upload_info->{'Content-Type'};
	my $original_filename = $upload_info->{'Content-Disposition'};
	   $original_filename =~ s/^.*filename\=\"(.*)\"$/$1/;

	# success
	if ($info->{'status'} == 1) {
		$info->{'path'}     = $filepath;
		$info->{'filename'} = $filename;
		$info->{'created'}  = $now;
		$info->{'mimetype'} = $mimetype;
		$info->{'original_filename'} = $original_filename;
	}
	
	# save info in session
	push @{$self->{'session'}->{'uploads'}}, $info;
	
	return $info->{'status'};
}

# ------------------------------------------------------------------------------

sub AUTOLOAD
{
	my ($self, @args) = __parse_args(@_);
	
	my $function_name = $CGI::WebToolkit::AUTOLOAD;
	   $function_name =~ s/.*\://g;
	
	if ($function_name eq 'DESTROY') {
		return SUPER::DESTROY(@args);
	}
	elsif ($function_name =~ /^\_[^\_]/) {
		# module function execution call
		
		# try to find subroutine in
		$function_name =~ s/^\_//;		
		foreach my $module (@{$self->{'modules'}}) {
			my $is_sub = 0;
			eval('$is_sub = (defined &CGI::WebToolkit::Modules::'.ucfirst($module).'::'.$function_name.')');
			__die("eval failed: $@") if $@;
			if ($is_sub) {
				# call subroutine
				my @result;
				eval('@result = CGI::WebToolkit::Modules::'.ucfirst($module).'::'.$function_name.'($self, @args)');
				__die("eval for subroutine call failed: $@") if $@;
				return (wantarray ? @result : (scalar @result ? $result[0] : undef));
			}
		}
		__die("could not find subroutine named 'CGI::WebToolkit::Modules::*::".$function_name."'");
	}
	elsif ($function_name =~ /^[A-Z]/) {
		# template loading call
		
		my ($theme, $template_name) = split /\_/, $function_name;
		unless (defined $template_name) {
			$template_name = $theme;	
			$theme = '';
		}
		$theme = lc $theme;
		
		# create template name
	    $template_name =~ s/([A-Z])/_$1/g;
	    $template_name =~ s/^\_//g;
	    $template_name =~ s/\_/./g;
	    $template_name = lc $template_name;
		
		return
			$self->fill(
				(length $theme ? $theme.':' : '').$template_name,
				{ @args },
			);
	}
	else {
		__die("Unknown function/method called '$function_name'.");
	}
}

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# cleanup

sub __cleanup
{
	my ($self) = @_;
	
	$self->__save_session();
	$self->__disconnect_from_db();
}

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# internal helper functions/methods

sub __expand_macros
{
	my ($self, $stringref) = @_;
	my $string = ${$stringref};
	
	my $tokens = __tokenize_xml($string);
	
	# the generated tokens are now beeing expanded

	my $parsed = '';
	my $t = 0; # offset of current token
	my $abort = 0;
	while (1) {
		last if $t >= scalar @{$tokens};

		my $token = $tokens->[$t];
	
		if (!ref $token) {
			$parsed .= $token;
			$t ++;
		}
		else {
			my ($type, $name, $attribs) = @{$token};
			if ($type eq 'start' || $type eq 'single') {
				
				my $data = __attribs_to_hash($attribs);
				$data->{'content'} = '';
				
				my $t_span = 1; # assume a "single" tag
				if ($type eq 'start') {
					# find end tag
					$t_span = __get_token_span($tokens, $t);
					unless (defined $t_span) {
						# if no end tag: tag end is end of tokens
						$t_span = scalar(@{$tokens}) - $t;
					}

					# get tokens from start tag till end tag
					my @subtokens = splice @{$tokens}, $t, $t_span;
					shift @subtokens;
					pop @subtokens;

					# convert sub-tokenlist back to xml
					$data->{'content'} = __render_tokens(\@subtokens);
				}
				elsif ($type eq 'single') {
					splice @{$tokens}, $t, 1;
				}
				
				# fill template
				my $filled = $self->fill($name, $data);
				
				# tokenize template
				my $sub_tokens = __tokenize_xml($filled);

				# replace tag with sub-tokenlist
				splice @{$tokens}, $t, 0, @{$sub_tokens};
				
				# restart expanding at previous token
			}
			elsif ($type eq 'end') {
				# this end tag actually belongs to a start tag
				# which is out of the scope of this token list
				# -> ignore this end tag
				$t ++;
			}
		}
		$abort ++;
		__die("macro expansion ran into endless loop.") if $abort == 100;
	}

	${$stringref} = $parsed;
	return 1;	
}

sub __render_tokens
{
	my ($tokens) = @_;
	my $string = '';
	foreach my $token (@{$tokens}) {
		if (ref $token) {
			$string .=
				'<'.($token->[0] eq 'end' ? '/' : '').
				$token->[1].($token->[0] eq 'end' ? '' : ' '.$token->[2]).
				($token->[0] eq 'single' ? '/' : '').'>';
		}
		else {
			$string .= $token;
		}
	}
	return $string;
}

sub __attribs_to_hash
{
	my ($attribs) = @_;
	my %hash;
	my @pairs = split /[\s\t]+/, $attribs;
	foreach my $pair (@pairs) {
		my ($key, $value) = split /\=/, $pair;
		$value =~ s/^[\"\']?//;
		$value =~ s/[\"\']?$//;
		$hash{$key} = $value;
	}
	return \%hash;
}

sub __get_token_span
{
	my ($tokens, $t) = @_;
	my $found = 0;
	my $open = 0; # open tags with same name as token at position $t
	my $s;
	foreach my $i ($t+1..scalar(@{$tokens})-1) {
		$s = $i;
		next unless ref $tokens->[$s];
		if ($tokens->[$s]->[1] eq $tokens->[$t]->[1]) {
			if ($tokens->[$s]->[0] eq 'start') {
				$open ++;
			}
			elsif ($tokens->[$s]->[0] eq 'end') {
				if ($open <= 0) {
					$found = 1;
					last;
				}
				else {
					$open --;
				}
			}
		}
	}
	my $span = ($found ? ($s - $t + 1) : undef);
	return $span;
}

sub __dump_tokens
{
	my ($tokens) = @_;
	my $s = "[\n";
	my $i = 0;
	map {
		if (!ref $_) {
			$s .= "  [".sprintf('%0d',$i)."] ...\n";			
		}
		elsif ($_->[0] eq 'start') {
			$s .= "  [".sprintf('%0d',$i)."] <".$_->[1].">\n";
		}
		elsif ($_->[0] eq 'end') {
			$s .= "  [".sprintf('%0d',$i)."] </".$_->[1].">\n";
		}
		elsif ($_->[0] eq 'single') {
			$s .= "  [".sprintf('%0d',$i)."] <".$_->[1]."/>\n";
		}
		$i ++;
	} @{$tokens};
	return $s."]\n";
}

sub __tokenize_xml
{
	my ($string) = @_;
	
	# remove comments
	$string =~ s/<!(?:--(?:[^-]*|-[^-]+)*--\s*)>//sg;
	
	# this regex parses an xml tag (sloppy...)
	my $tagregex = '^(\/?)([a-zA-Z0-9\:\_\.]+)([\s\t\n\r]*)([^\>]*[^\/])?(\/?)>(.*)$';
	
	# what follows is actually a very rudimentary tokenizer
	# that splits the source into an array of tokens, either
	# tag (start-tag, end-tag or single-tag) and strings

	my @tokens = ('');
	foreach my $tag (split /</s, $string) {
		
		if ($tag =~ /$tagregex/s) {
			my ($is_end, $tagname, $space, $attribs, $is_single, $rest)
				= $tag =~ /$tagregex/s;
		
			$space     = '' unless defined $space;
			$attribs   = '' unless defined $attribs;
			$is_single = '' unless defined $is_single;
			$rest      = '' unless defined $rest;
		
			if (scalar grep { $tagname eq $_ } @XHTML_TAGS) {
				# normal html tag
				ref $tokens[-1] ? push(@tokens,'<'.$tag) : ($tokens[-1] .= '<'.$tag);
			}
			else {
				# macro
				if (length $is_end) {
					# end tag
					push @tokens, ['end', $tagname];
				}
				elsif (length $is_single) {
					# single tag
					push @tokens, ['single', $tagname, $attribs];
				}
				else {
					# start tag
					push @tokens, ['start', $tagname, $attribs];
				}
				ref $tokens[-1] ? push(@tokens,$rest) : ($tokens[-1] .= $rest);
			}
		}
		else {
			ref $tokens[-1] ? push(@tokens,$tag) : ($tokens[-1] .= $tag);
		}
	}

	return \@tokens;
}

sub __load_data_file
{
	my ($datafilename) = @_;
	
	if (-f $datafilename && -r $datafilename) {
		open DATAFILE, '<'.$datafilename
			or _die("failed to open file '$datafilename': $!");
			
		my @records;
		my $current_id     = undef;
		my $current_field  = undef;
		my $current_record = {};
		foreach my $line (<DATAFILE>) {
					
			if (defined $current_id && defined $current_field && $line =~ /^[\s\t]/) {
				# possibly field value line
				$line =~ s/^[\s\t]//;
				$current_record->{$current_field} .= $line;
			}
			else {
				if ($line =~ /^\[(\d+)\][\s\t\n\r]*$/) {
					# id line
					if (defined $current_id) {
						# save previous record
						push @records, $current_record;
					}
					# reset
					$current_id = $line;
					$current_id =~ s/^\[(\d+)\][\s\t\n\r]*$/$1/;
					$current_record = { 'id' => $current_id };
				}
				elsif ($line =~ /^(\w+)[\s\t]*([\:\.])(.*)\n\r?$/) {
					# field line
					my ($fieldname, $type, $value)
						= $line =~ /^(\w+)[\s\t]*([\:\.])(.*)\n\r?$/;
					if ($type eq ':') {
						$current_record->{$fieldname} = $value;
						$current_field = undef;
					}
					else {
						$current_record->{$fieldname} = '';
						$current_field = $fieldname;
					}
				}
			}
		}
		if (defined $current_id) {
			# save last record
			push @records, $current_record;
		}		
		return \@records;
	}
	else {
		__die("failed to open file '$datafilename': no file or not readable");
	}
}

sub __parse_translations
{
	my ($translations) = @_;
	my %phrases;
	foreach my $translation (split /\n/, @{$translations}) {
		my ($language, $phrase) =~ /^([^\:]+)\:(.*)$/;
		$phrases{$language} = $phrase;
	}
	return \%phrases;
}

sub __find_translation
{
	my ($translations, $find_language) = @_;
	foreach my $translation (split /\n\r?/, $translations) {
		my ($language, $phrase) = $translation =~ /^([^\:]+)\:(.*)$/;
		return $phrase
			if $language eq $find_language;
	}
	return undef;
}

sub __get_cache_hash
{
	my ($self, $function_name, @args) = @_;

	# string of which hash is computed
	my $string = '';
	
	my $cfgfile = $self->{'privatepath'}.'/cacheconfigs/'.$function_name.'.txt';	
	if (-f $cfgfile) {
		# open cache config
		my $cfg
			= __read_config_file($cfgfile, {
					'session'  => [],
					'params'   => [],
					'lifetime' => 3600,
				});
				
		map { $string .= __serialize($self->get($_)) } @{$cfg->{'session'}};
		map { $string .= __serialize(param($_))      } @{$cfg->{'params'}};
		$string .= __serialize(\@args);
	}
	else {
		# hash is created out of complete session, post/get and arguments
		
		# commented, because makes cache renew too often...
		#map { $string .= __serialize($self->get($_)) } keys %{$self->{'session'}};
		
		map {
			$string .=
				($_ eq $self->{'idparam'} || $_ eq $self->{'clearcacheparam'} ?
					'' : __serialize(param($_)));
		} param();
		$string .= __serialize(\@args);
	}
	
	return md5_hex($string);
}

sub __load_cache
{
	my ($self, $cachehash) = @_;
	my $query
		= $self->find(
			-tables => [$self->{'cachetable'}],
			-where  => {'hash' => $cachehash},
			-limit  => 1,
		);
		
	if (my $entry = $query->fetchrow_hashref()) {
		return __deserialize($entry->{'content'});
	}
	else {
		return undef;
	}
}

sub __save_cache
{
	my ($self, $cachehash, $data) = @_;
	
	$self->create(
		-table => $self->{'cachetable'},
		-row   => {
			'content' 	  => __serialize($data),
			'hash' 		  => $cachehash,
			'last_update' => time(),
		},
	);
	
	return 1;
}

sub __clear_cache
{
	my ($self) = @_;
	return 1 if $self->{'cachetable'} eq '';
	$self->remove( -table => $self->{'cachetable'} );
}

sub __file_append
{
	my ($filename, $text) = @_;
	open OUTFILE, '>>'.$filename or __die("failed to open file '$filename': $!");
	print OUTFILE $text;
	close OUTFILE;
	return 1;
}

# returns the args array with the
# current CGI::WebToolkit instance as first argument
sub __parse_args
{
	if (scalar @_ && ref($_[0]) eq 'CGI::WebToolkit') {
		return @_;
	} else {
		return ($WTK, @_);
	}
}

sub __replace_placeholders
{
	my ($stringref, $hash) = @_;
	foreach my $key (keys %{$hash}) {
		my $cleankey = $key;
		   $cleankey =~ s/[^a-zA-Z0-9\_]//g;
		${$stringref} =~ s/\{$cleankey[^\}]*\}/$hash->{$key}/mig;
	}
	return undef;
}

sub __make_sql_where_clause
{
	my ($self, $where, $use_like) = @_;
	$use_like = 0 unless defined $use_like;
	
	my @parts =
		map {
			my $fieldname  = $self->__quotename($_);
			my $fieldvalue = $self->__quote($where->{$_});
			
			my $s  = $fieldname;
			   $s .= ($use_like == 1 ? ' LIKE ' : ' = ');
			   $s .= ''.$fieldvalue;
			$s;
		}
		keys %{$where};
	
	return join(' AND ', @parts);
}

sub __quote
{
	my ($self, @args) = @_;
	$self->__connect_to_db();
	
	return $self->{'dbh'}->quote(@args)
		or __die('quote failed: '.DBI->errstr());
}

# escapes a CGI::WebToolkit field identifier, e.g. "mytable.myfield" or "myfield" etc.
sub __quotename
{
	my ($self, $fieldname) = @_;
	$self->__connect_to_db();

	my @parts = split /\./, $fieldname;
	
	my $quoted;
	if (scalar @parts == 1) {
		#$quoted = $self->{'dbh'}->quote_identifier(undef, undef, $parts[0])
		#	or _die("quote_identifier() failed: ".DBI->errstr());
		$quoted = '`'.$parts[0].'`';
	}
	else {
		#$quoted = $self->{'dbh'}->quote_identifier(undef, $parts[0], $parts[1])
		#	or _die("quote_identifier() failed: ".DBI->errstr());
		$quoted = '`'.$parts[0].'`'.'.'.'`'.$parts[1].'`';
	}
	return $quoted;
}

sub __get_external_function_filename
{
	my ($self,
		$type,	# "functions" or "templates" or other subdirectory in <privatepath>
		$name,	# name of function in dot-syntax, e.g. "page.home.default"
		)
		= @_;
	
	# untaint name
	$name =~ s/^(([a-z\_]+)(\.([a-z\_]+))*).*$/$1/;

	my $filename = __identifier_to_filename(
						$self->{'privatepath'}.'/'.$type.'/', $name, '.pl');

	if (-f $filename) {
		return $filename;
	} else {
		return undef;
	}
}

# bla.bla.bla -> bla/bla/bla
sub __identifier_to_filename
{
	my ($prefix, $identifier, $suffix) = @_;
	$suffix = '' unless defined $suffix;
	
	my $filename = $identifier;
	   $filename =~ s#\.#/#g;
	   
	return $prefix.$filename.$suffix;
}

# loads an external file into an anonymous perl function ref.
# and returns this ref.
sub __load_file_as_subref
{
	my ($filename) = @_;
	
	__die("cannot load file '$filename': does not exist.")  unless -f $filename;
	__die("cannot load file '$filename': is not readable.") unless -r $filename;
	
	my $subref = undef;
	open PERLFILE, '<'.$filename or __die("failed to open file '$filename': $!");
	my $code = join '', <PERLFILE>;
	   $code =~ /^(.*).*$/sm; # untaint
	   $code = "$1";
	   $code = '$subref = sub { my ($wtk, @args) = @_;'."\n".$code."\n".'}';
	close PERLFILE;
	eval($code);
	__die("function (file '$filename') failed to load with error: $@") if $@;
	
	return $subref;
}

sub __load_session
{
	my ($self) = @_;
	return 1 if $self->{'sessiontable'} eq '';
	
	# determine session id
	$self->{'session_id'} =
		$self->getparam( $self->{'idparam'}, undef, '^[a-zA-Z0-9]{32}$' );

	$self->{'session_id'} = md5_hex( time() )
		unless defined $self->{'session_id'};

	# try to find it in db
	my $query =
		$self->find(
			-tables => [ $self->{'sessiontable'} ],
			-where => { 'session_id' => $self->{'session_id'} },
		);
	
	my $sessionstart = 0;
	if (my $session = $query->fetchrow_hashref()) {
		if (time() - $session->{'last_update'} < $self->{'sessiontimeout'}) {
			$self->{'session'} = __deserialize($session->{'content'});
		} else {
			# session timed out
			$self->{'session_id'} = md5_hex( time() ); # gets new session id!
			$self->{'session'} = {};
			
			$self->set('session_timed_out', 1);
			
			$sessionstart = 1;
		}
	}
	else {
		# create empty session
		$self->{'session'} = {};
		
		$sessionstart = 1;
	}
	
	# trigger callback
	$self->call($self->{'onsessionstart'})
		if $sessionstart && $self->{'onsessionstart'} ne '';
}

sub __save_session
{
	my ($self) = @_;
	return 1 if $self->{'sessiontable'} eq '';
	
	# check if session row exists in database
	my $query =
		$self->find(
			-tables => [ $self->{'sessiontable'} ],
			-where => { 'session_id' => $self->{'session_id'} },
		);
		
	if (my $session = $query->fetchrow_hashref()) {
		# update
		$self->update(
			-table => $self->{'sessiontable'},
			-set => {
				'content' => __serialize($self->{'session'}),
				'last_update' => time(),
			},
			-where => {	'session_id' => $self->{'session_id'} },
		);
	}
	else {
		# insert
		$self->create(
			-table => $self->{'sessiontable'},
			-row => { 
				'session_id' => $self->{'session_id'},
				'content' => __serialize($self->{'session'}),
				'last_update' => time(),
			},
		);
	}
}

sub __serialize
{
	my ($structure) = @_;
	return dump($structure);
}

sub __deserialize
{
	my ($string) = @_;
	return {} unless length $string;
	my $structure = undef;
	eval('$structure = '.$string);
	__die("deserialization of string failed: $@") if $@;
	return $structure;
}

sub __connect_to_db
{
    my ($self) = @_;
	return 1 if defined $self->{'dbh'}; # && ref($self->{'dbh'}) eq 'DBI';
    
    $self->{'dbh'}
        = DBI->connect(
            "DBI:".$self->{'engine'}.":".$self->{'name'}.":".$self->{'host'},
            $self->{'user'}, $self->{'password'},
            {
				#PrintError => 1,
				#RaiseError => 1,
				#AutoCommit => 1,
				#PrintWarn  => 1,
			})
	    or __die("Could not connect to database");
    
    return 1;
}

sub __disconnect_from_db
{
	my ($self) = @_;
	
	return $self->{'dbh'}->disconnect();
}

sub __init
{
	my ($self, %options) = @_;
	
	my $optdefaults =
		{
			# path parameters
			publicpath => '',
			publicurl => '',
			privatepath => '',
			cgipath => '',
			cgiurl => '',

			# configuration parameters
			config => "",
		
			# database parameters
			engine => "mysql",
			user => "guest",
			name => "",
			password => "",
			host => "localhost",
			port => "",
		
			# template parameters
			templatefallbacks => ['core'],
			allowmacros => 1,
			
			# form creation parameters
			# ...
		
			# session parameters
			idparam => 'sid',
			sessiontable => '',
			sessiontimeout => 1800,
			
			# user/rights management
			usertable => '',
			checkrights => 0,
			
			# caching
			cachetable => '',
			allowclearcache => 1,
			clearcacheparam => 'clearcache',
			
			# locale
			phrasetable =>'',
			defaultlanguage => 'en_GB',
			
			# workflow parameters
			workflowparam => 'to',
			entryaction => 'core.default',
			modules => [],
			
			# combinable files
			cssfiles => [],
			jsfiles => [],
			
			# triggers
			onsessionstart => '',
			onsessionoutofdate => '',
			
			# uploads
			uploadmaxsize => (1024 * 1024 * 6), # 6MB
		};

	# check if config filename is given -> if so, load it first
	# (so that it can be overwritten by settings from %options later!)
	my $cfgopts = $optdefaults;
	foreach my $key (keys %options) {
		my $name = lc $key;
		   $name =~ s/^\-*//;
		if ($name eq 'config') {
			$cfgopts = __load_config_file( $options{$key}, $optdefaults );
		}
	}
	
	my $opts = __parse_params( \%options, $cfgopts );
	map { $self->{$_} = $opts->{$_} } keys %{$opts};
	
	# add 'default' theme as last fallback if not already added
	push @{$self->{'templatefallbacks'}}, 'core'
		if !scalar @{$self->{'templatefallbacks'}}
			|| $self->{'templatefallbacks'}->[-1] ne 'core';
	
	$self->{'dbh'} = undef;
	$self->{'session'} = undef;
	$self->{'session_id'} = undef;
	
	# caches for function refs.
	$self->{'workflow_function_cache'} = {};
	$self->{"template_function_cache"} = {};
	$self->{"access_function_cache"}   = {};
	
	$self->__load_session();
	
	# common placeholders
	$self->{'common_placeholders'} = {
		'script_url' 	 => (exists $ENV{'SCRIPT_NAME'} ? $ENV{'SCRIPT_NAME'} : '?'),
		'public_url' 	 => $self->{'publicurl'},
		'clear'			 => '<div class="clear"></div>',
		'session_id'	 => $self->{'session_id'},
		'do_nothing_url' => 'javascript:void(1);',
		'javascript_url' => (exists $ENV{'SCRIPT_NAME'} ? $ENV{'SCRIPT_NAME'} : '').'?to=core.combine.javascript',
		'css_url' 		 => (exists $ENV{'SCRIPT_NAME'} ? $ENV{'SCRIPT_NAME'} : '').'?to=core.combine.css',
	};
	
	# name of workflow function that is currently executed
	$self->{'current_workflow_function'} = undef;
	
	# set current language
	$self->set('language', $self->{'defaultlanguage'});
	
	# uploads info
	$self->{'session'}->{'uploads'} = [];
	
	# save global CGI::WebToolkit instance
	$WTK = $self;
	
	return $self;
}

sub __load_config_file
{
	my ($filename, $defaults) = @_;
	
	open CFGFILE, '<'.$filename
		or _die("failed to load config file '$filename': $!");
	my $options = {};
	if (defined $defaults) {
		# copy defaults
		map { $options->{$_} = $defaults->{$_} } keys %{$defaults};
	}
	while (<CFGFILE>) {
		chomp;
		s/^(.*)\#.*$/$1/g;
		next if /^[\s\t\n\r]*$/;
		s/^[\s\t\n\r]*//g;
		s/[\s\t\n\r]*$//g;
		my $rgx =
			(defined $defaults ?
				'^([a-zA-Z0-9\_]+)[\s\t]*\:[\s\t]*(.*)$' :
				'^([^\:]+)[\s\t]*\:[\s\t]*(.*)$');
		if (/$rgx/) {
			my ($key, $value) = $_ =~ /$rgx/;
			$key = lc $key;
			$key =~ s/^\-*//g;
			
			if (defined $defaults) {
				if (ref $defaults->{$key} eq 'ARRAY') {
					# array variable
					$options->{$key} = [ split(/\s*\,\s*/, $value) ]
						if exists $defaults->{$key};
				}
				else {
					# string variable
					$options->{$key} = $value
						if exists $defaults->{$key};
				}
			}
			else {
				$options->{$key} = $value;
			}
		}
	}
	close CFGFILE;
	return $options;
}

# dumps data to browser
sub __dd
{
	print header();
	print '<pre>'.dump($_[0]).'</pre><br/>';
}

sub __parse_params
{
	my ($params, $defaults) = @_;
	my $values = {};
	foreach my $key (keys %{$defaults}) {
		$values->{$key} = $defaults->{$key};
	}
	foreach my $key (keys %{$params}) {
		my $cleankey = lc $key;
		   $cleankey =~ s/^\-//;
		$values->{$cleankey} = $params->{$key}
			if exists $defaults->{$cleankey};
	}
	return $values;
}

sub __die
{
	my ($msg) = @_;
	print header();
	print
		'<html></head><title>Lowlevel Error</title></head><body>'.
			'<span style="color:red">Lowlevel Error: <b>'.$msg.'</b></span>'.
		'</body></html>';
	exit;
}

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
1;
__END__

=head1 NAME

CGI::WebToolkit - Website Toolkit

=head1 SYNOPSIS

	use CGI::WebToolkit;
	my $wtk = CGI::WebToolkit->new( %options );
	print $wtk->handle();

=head1 DESCRIPTION

CGI::WebToolkit tries to simplify the common tasks when creating dynamic
websites. The use of CGI::WebToolkit should lead to the development of easy
to understand, relieable and fast dynamic web applications that
are easy to adjust and maintain.

CGI::WebToolkit itself is designed to be as simple and straight
forward as possible. The basic philosophy behind the module is
best described as "Do not repeat yourself." (DNRY). The experience
gained while developing a number of websites has led to certain
common recipes that are packaged as a single module for reusability.

CGI::WebToolkit was writted to provide abstractions and functionality for the
following common tasks in web application development:

=over 1

=item 1 Configuration

=item 2 Workflow abstraction (aka runlevel, modes, actions, ...)

=item 3 Sessions

=item 4 Templates (incl. form creation etc.)

=item 5 Datenbase abstraction

=item 6 User and rights management

=item 7 Internationalization

=item 8 Caching

=back

There is a tutorial: CGI::WebToolkit::Tutorial.


=head2 Directory structure

CGI::WebToolkit relies on a common directory structure. This structure makes it
possible to simplify the configuration of the application to a level
where only the minimal information needed must be given. This makes
development more relieble, faster and other tools may work on many
websites.

The directory structure of the B<public directory> as required
by CGI::WebToolkit, usually this would go somewhere in the htdocs directory
on the server:

	core/
	themes/
	  <themename>/
	uploads/

The directory structure of the B<private directory> as required by
CGI::WebToolkit, usually this would go B<outside> of the web-accessable area
on the server:

	accesschecks/
	accessconfigs/
	cacheconfigs/
	configs/
	generators/
	javascripts/
	logs/
	modules/
	schemas/
	styles/	
	templates/
	  <themename>/
	workflows/

The directory structure of the B<cgi directory> can have any form.
Usually this resembles the cgi directory on the server. The actual
application scripts go there.



=head2 Constructor new()

The constructor takes only named parameters, of which some are optional.
These options are given in a shell-like syntax, e.g I<-optname>.
The case of the parameter name does not matter, so you can either write
I<-OptName>, I<-optName>, I<optname> or any kind of other case variation.

	use CGI::WebToolkit;
	my $wtk = CGI::WebToolkit->new(
	  # required
	  -publicpath  => '...',
	  -publicurl   => '...',
	  -privatepath => '...',
	  -cgipath     => '...',
	  -cgiurl      => '...',	
	  # optional
	  # ...
	);


=head3 Required settings

=head4 -publicpath => I<path>

The path to the B<public directory> of the web application.

=head4 -publicurl => I<url>

The url to the B<public directory> of the web application.

=head4 -privatepath => I<path>

The path to the B<private directory> of the web application.

=head4 -cgipath => I<path>

The path to the B<cgi directory> of the web application.

=head4 -cgiurl => I<url>

The url to the B<cgi directory> of the web application.



=head3 Optional settings

=head4 -config => I<filename>

This is the name of a configuration file to load. The file should
exist in the I<config> directory. Values from configuration
files have low priority, any parameter that is set directly within
the new() call overwrites the config value.

=head4 -engine => I<database-type>

The name of the database engine, default is I<mysql>.

=head4 -user => I<name>

The name of the database user, default is I<guest>.

=head4 -name => I<database-name>

The name of the database to use, default is empty.

=head4 -password => I<password>

The password of the database user, default is empty.

=head4 -host => I<host>

The host name for the database server, default is I<localhost>.

=head4 -port => I<port>

The port number for the database server, default is empty.

=head4 -templatefallbacks => [ I<name>, ... ]

The fallback directories that are searched for the template files.
The first one is searched first, then the second etc. until
the template file is found. If no template file could be found,
the template I<core.error> is used.

=head4 -idparam => I<name>

The name of the POST/GET parameter that holds the session id,
default is I<sid>.

=head4 -sessiontable => I<name>

The name of the database table that holds the session data.
The table must contain these columns: I<id>, I<session_id>, I<content>
and I<last_update>. The default table name is I<session>.

An example SQL statement (for MySQL) that will create an appropriate
database session table:

	create table `session` (
	  `id` int(11) not null auto_increment primary key,
	  `session_id` varchar(32) not null,
	  `content` text not null,
	  `last_update` int(16) not null
	);

To deactivate sessions, leave this option empty, which is also
the default.

=head4 -sessiontimeout => I<seconds>

The number of seconds after which a session is regarded as trash
and not available anymore. Default timeout is I<1800 seconds> (I<30 minutes>).

=head4 -usertable => I<name>

Name of the database table to store user info in.
An example SQL statement (for MySQL) that will create an appropriate
database user table:

	create table `user` (
	  `id` int(11) not null auto_increment primary key,
	  `loginname` varchar(255) not null,
	  `password` varchar(32) not null,
	  `language` varchar(5) not null
	);

If you do not need this feature, just leave the tablename empty,
which is also the default.

=head4 -accessconfig => I<name>

This option defined what access configuration file is used.
The default is empty, which means that no access check will be
performed.

=head4 -cachetable => I<name>

The name of the database table that is used to store cached
results from workflow functions. In order to make the cache work
properly you have to define cache parameters (see I<Caching>).

An example SQL statement (for MySQL) that will create an appropriate
database cache table:

	create table `cache` (
	  `id` int(11) not null auto_increment primary key,
	  `hash` varchar(32) not null,
	  `content` text not null,
	  `last_update` int(16) not null
	);

To deactivate caching, leave the tablename empty, which is also
the default.

=head4 -allowclearcache => 1/0

Caching is activated, as soon as you define a cachetable inside
the configuration variables, s.a. But how do you delete the cache,
e.g. for testing purposes? If this option is set to 1 (the default),
you only have to attach an additional parameter to the url named
"clearcache" and the whole cache will be removed from the database.

This method clears all cache entries in the configured cache
table. It is currently impossible to selectively remove only
certain cache entries, because the cache entry's name (a hash
value) cannot be used to determine any details, about where
this entry is from, e.g. the name of the workflow function etc.

=head4 -clearcacheparam => I<name>

The name of the POST/GET parameter that triggers the removal
of the cache, if activated, see -allowclearcache.

=head4 -workflowparam => I<name>

The name of the POST/GET parameter that holds the name of the
workflow function, default is I<do>.

=head4 -entryaction => I<name>

The name of the workflow function that is called if no workflow
function name could be determined, default is I<core.default>.

=head4 -modules => [ I<name>, ... ]

The names of modules to load. These modules will be available
from inside the workflow functions. Modules such as these usually
contain general functions that return arbitrary data in order
to calculate, deliver or store other data. The modules must exist
somewhere in @INC or inside the I<modules> directory.

=head4 -cssfiles => [ I<name>, ... ]

The names of css files that are all combined into one single css.
The final css can be retrieved via the special url I<...?to=core.combine.css>
The css files must exist inside the I<styles> directory.

=head4 -jsfiles => [ I<name>, ... ]

The names of javascript files that are all combined into one single javascript.
The final javascript can be retrieved via the special url I<...?to=core.combine.js>
The javascript files must exist inside the I<javascript> directory.

=head4 -phrasetable => <name>

The name of the database table to use for the translation dictionary.

An example SQL statement (for MySQL) that will create an appropriate
database dictionary table:

	create table `phrase` (
	  `id` int(11) not null auto_increment primary key,
  	  `language` varchar(5) not null,
	  `name` varchar(32) not null,
	  `translations` text not null
	);

To deactivate the translation feature, just leave the tablename empty,
which is also the default.

=head4 -defaultlanguage => I<language>

The language used for guests that come to the website for
the first time and are not currenlty logged in.

=head4 -onsessionstart => I<functionname>

The name of the workflow function that is called when the session
is started. This may be useful to initialize some session variables.
The result of that workflow function is then ignored.

=head4 -allowmacros => 1/0

If this option is set to 1 (default), the templates that are
loaded, are filtered through a macro processor. It is basicly
a processor that allows the loading of templates from within
(xml-based) templates. Disabling this feature makes processing
of template a bit faster.

See separate section I<macros> below for details on macros.

=head4 -uploadmaxsize => I<bytes>

Maximum allowed upload size. This is the internal limit, there
is usually a server limit for uploads, which probably has
to be adjusted as well. The default size is 6MB.






=head2 Objectoriented and functional style

The methods of CGI::WebToolkit can be invoced in two different styles:
in the object oriented manner using standard syntax:

	$wtk->methodname();

and in a functional manner:

	methodname();

When called as usual functions, the CGI::WebToolkit instance the call works on
is a singleton and refers to the last instance of CGI::WebToolkit that was
created via the new() constructor.

The functional way of invocation has the advantage of beeing
visually more obvious. Usually there is only one instance of CGI::WebToolkit
anyway, so conflicts hardly happen.






=head2 Methods for workflow abstraction

In CGI::WebToolkit, each time a webpage is requested, the workflow engine tries
to determine, which workflow function should be executed. Then this
function is executed. Workflow functions are ordinary Perl functions
that get certain parameters and return an array of values. Each
workflow function has a unique name and can be sorted into categories
and/or subcategories etc.


=head3 handle()

This method is used to handle the current request. It will determine
the workflow function to be called, call it, analyse its result
and call other workflow functions if nessessary. Finally, it will
return a string - the webpage requested, a part of a webpage
or a valid replacement, such as an error page.

handle() will analyse the workflow parameters that were
given to the request from the client and based on that call a certain
workflow function. If this function does return a I<followup>, it
will be called directly afterwards, if not, the message returned by
the workflow function is returned. A <followup> is a special return
value that tells CGI::WebToolkit to forward control flow directly to another
workflow function.

Inside a workflow function the CGI::WebToolkit instance is magically
available as the variable $wtk and the additional arguments
are stored in @args.


Examples for workflow functions:

	# ...
	return $wtk->output(1, 'ok', "<h1>Hello, World!</h1>");

	# ...
	return $wtk->followup("core.error");

	# ...
	return $wtk->output(1, 'ok', "...", 'image/png');


The bodies of workflow functions are stored in Perl files, one for
each function inside a directory (or subdirectory etc.) in the I<workflows>
directory.


=head3 call()

This method is used to call a workflow function directly and
return its result unmodified and unanalysed.

	my $result = $wtk->call( $name, @args );


=head3 output()

This method returns a valid CGI::WebToolkit result that can be returned from
a workflow function. This result is used, when the workflow 
function wants to return a complete page or a part of a page.
It gets the following options:

	# ...
	return $wtk->output(1, 'info...', $html, 'text/html');

If the mimetype is not explicitly given, I<text/html> is used.


=head3 followup()

This method returns a valid CGI::WebToolkit result that can be returned from
a workflow function. Its used when a workflow function wants
to silently hand over control flow to another workflow function.
It gets the following options:

	# ...
	return $wtk->followup('group.function', @args);




=head3 getparam()

The getparam() method is used to return a parameter, match it
against a regular expression or return a default value if no
parameter was set in neither POST nor GET vars.

Parameters:

=over 1

=item 1 $name = The name of the parameter.

=item 2 $default = The default value.

=item 3 $regex = The regular expression used to check the parameter value.

=back





=head3 fail()

fail() dies hard with a short message. All control flow comes
to an end immedietly. This method can be used when some error occurs
and there is no hope of recovery. Since only the raw message will
be shown to the user, you should consider creating a complete
error page, if that is possible.

Example:

	fail("cannot open file 'xyz'");



=head3 Shortcut Syntax for calling module functions

Businesss logic usually goes into modules that are loaded using
the -modules switch, s.a. But when you call a subroutine from
such a module, e.g. inside a workflow function, its usually
a unhandy, for example:

	CGI::WebToolkit::Modules::MyProjectModule::my_tiny_function($wtk, @args);

Plus, in  most cases, you have to pass the CGI::WebToolkit instance to the
subroutine, because you somehow need it in there.

To make life easier, there is an alternative, shorter way
of calling a module subroutine:

	_my_tiny_function(@args);

That means exactly the same as the call above. To be honest, it
means I<almost> the same. Whereas with the long syntax, you
exactly know which module is used, whereas with the short syntax,
CGI::WebToolkit will try one module after another until it has found the
subroutine named I<my_tiny_function> and then calls it.











=head2 Methods for session management

Session data is data that is stored on the server side and can be accessed
throughout several webpage requests. In the CGI::WebToolkit the session is a flat hash
of arbitrary data that is stored in the database or a flat file.

In order to identify the session, a session id is used. This session id
has to be submitted by the client for each request, either through a 
cookie, a POST variable or a GET variable. The name of this variable
is usually I<sid>, but can be configured. CGI::WebToolkit takes automaticly care of
that the session id is submitted via links and form submits to
the application script.

To group certain session data entries, usually a dot-based notation is used,
e.g. I<my_workflow.my_name>. This method is stronlgy recommended as well
as limiting the amount of session entries to the absolute minimum.

When the CGI::WebToolkit instance is created, the session is loaded automaticly and
can be accessed through the following methods:

=head3 get()

	my $value = $wtk->get( "my_name" );

=head3 set()

	$wtk->set( "my_name", "value" );

=head3 unset()

This method removes the entry from the session. When you try to
retrieve the entry's value afterwards, you will get an undefined
value.

	$wtk->set( "my_name" );







=head2 Methods for template management

By definition a template is something that contains placeholders that
are replaced by actual values when the template is I<filled>. In CGI::WebToolkit
a template is a function that returns any kind of string, usually
that would be XHTML or XML.

=head3 fill()

The fill() method fills a hash of data into a template by replacing
the placeholders inside the template with actual values. Here are
some examples for fill() calls:

	my $name1 = 'group.subgroup.name';
	my $name2 = 'othername';
	
	my $hash = { 'title' => "...", -info => "..." };
	
	my $string1 = $wtk->fill( $name1,   $hash );
	my $string2 = $wtk->fill( $name2, [ $hash, $hash ] );

The first parameter to the fill() method is
the name of the template. See below for details on template names.

The second parameter to the fill() method is the hash with
the actual information. The values inside the hash are (usually)
all strings. If an array (reference) of multiple hashs is supplied,
the template is loaded for each hash and the final result is the
concatenation of the filled templates.

When the information is filled into the template, each placeholder
is replaced with the value of the key of the same name, e.g.
the hash key I<info> provides the value for the placeholder I<info>.
Inside the template the placeholders are usually noted inside
curly brackets. Here is an example of a template:

	<h1>{title}</h1>
	<p>{info}</p>

The hash keys can be noted in any case with an optional dash at
the beginning in order to allow easy notation, e.g. the hash
keys I<Info>, I<-info>, I<-InFO> etc. refer to the same
placeholder I<info>.


=head3 Template names and themes

In CGI::WebToolkit Themes are sets of templates. Each theme has its own subdirectory
inside the I<templates> directory. These theme directories can
contain more subdirectories to group templates semantically.

Here some examples fof valid names and the corresponding
template files, assuming the template fallback is set to
I<myproject> as the first theme and I<core> as the second theme:

	my $name1 = 'page';      # "<private-path>/templates/myproject/page.html"
	my $name2 = 'form.text'; # "<private-path>/templates/core/form/text.html"

Each dot in the name is converted to a slash to form the
final template filename. Then the fallback theme directories are
sequentially checked for a file with that name and the first
match is used as the template file.

If you want to load the template from a specific theme, you
can use the following syntax:

	# This will load from the "core" theme
	my $string1 = $wtk->fill( 'core:form.date', @data );
	
	# This will load from the theme that is first
	# defined inside the fallback hierarchy of themes
	my $string2 = $wtk->fill( 'form.date', @data );


=head3 Generator functions

If no template could be found using the theme fallbacks declared
in the configuration (s.a.), then a generator function of that
name is called.

[...]


=head3 Common template placeholders

The following placeholders are always available and can therefor
be used in any template loaded with the fill() method:

B<{script_url}>

The URL of the script executable, including the script name.

B<{public_url}>

The URL of the public directory.

B<{clear}>

The special XHTML snippet <div class="clear"></div>

B<{do_nothing_url}>

This URL can be used in Links that should do nothing.
It containts the Javascript snippet javascript:void(1);

B<{javascript_url}>

This URL points to the special core workflow function I<core.combine.javascript>
and therefor points to a combined javascript.

B<{css_url}>

This URL points to the special core workflow function I<core.combine.css>
and therefor points to a combined stylesheet.


=head3 Default placeholder values

Any placeholders in a template that have not been filled, are
by default replaced with an empty string. Sometimes you want to
have a special default value instead of the empty string.
Example:

	<b>{title:This is the default title}</b>


=head3 Simplified calling of fill()

To make it visually clearer what template is filled, there is an
alternative way of calling the fill() method. The following
statements mean the same:

	my $string = $wtk->fill('form.date', {-month => '...', -year => '...'});
	
	my $string = $wtk->FormDate(-month => '...', -year => '...');

Using the general method of using the functional style of
invocation, this even gets shorter:

	my $string = FormDate(-month => '...', -year => '...');

In case you want the template from a specific theme, use this
syntax for the functional invocation:

	my $string = Core_FormDate(-month => '...', -year => '...');


=head3 Template Macros

Template macros are a way of loading templates from within
templates.

For example, if you want to create a general piece of markup
that is considered "a box", you wish you were able to
keep this markup in one place and use it from anywhere else
in other templates. That is what these macros are for.

Example of a box markup:

     <div class="box">
     	<h1>{title}</h1>
     	<p>{content}</p>
     </div>

This markup goes in a file called I<templates/my_project/box.html>
(in our example).

And here is how to use the box markup inside another template:

	<h1>Hallo!</h2>
	<box title="My Box">In the box.</box>

The macro processor allows recursive notation of macros,
so that the following works as expected:

	<box>In the <box>other box</box> box.</box>






=head2 Methods for database access

To access the data that is stored inside the attached (relational) database, CGI::WebToolkit
offers some handy functions.
When the CGI::WebToolkit instance is created, all information regarding the database
connection is given and CGI::WebToolkit will try to establish a connection.

Internally, a DBI instance is created, so any kind of database can be
used for which a DBI driver is provided.

Any fieldname noted below can consist of the field's name only or addiontally
the tablename, e.g. I<myfield> and I<mytable.myfield> are both valid
field names.

=head3 find()

To retrieve records from the database, use the select() method:

	my $query = $wtk->find(
	  -tables 	=> [qw(mytable1 mytable2 ...)],
	  -where 		=> { name => "...", ... },
	  -wherelike 	=> {...},
	  -group 		=> [qw(id name ...)],
	  -order 		=> [qw(id name ...)],
	  -limit 		=> 10,
	  -distinct 	=> 1,
	  -columns		=> [qw(id name ...)],
	  -joins		=> { name => name, ... },
	  -sortdir		=> 'asc', # or 'desc'
	);

To access the records of the result set, use the normal DBI methods:

	my $array = $query->fetchrow_arrayref();
	my $hash = $query->fetchrow_hashref();
	while (my $record = $query->fetchrow_arrayref()) {
		# ...
	}
	# ...

=head3 create()

To insert a record, use the create() method:

	my $id = $wtk->create(
	  -table => "...",
	  -row => { name => "...", ... },
	);

=head3 update()

To update fields in a record, use the update() method:

	my $success = $wtk->update(
	  -table => "...",
	  -set => { name => "...", ... },
	  -where => { ... },
	  -wherelike => { ... },
	);

=head3 remove()

To delete records, use the remove() method:

	my $query = $wtk->remove(
	  -table => "...",
	  -where => { ... },
	  -wherelike => { ... },			
	);

=head3 query()

Any kind of other query can be executed using the query() method:

	my $query = $wtk->query( $sql );

=head3 load()

This method is used to import a text file that contains a number of
records into a certain table in the database. This is nice, if you
set up many databases for an application and want to insert some
default data all at once.

Example:

	load( 'my_project', 'default_data', 'my_table' );

This example will load the file I<data/my_project/default_data.txt>
from the configured I<private> directory into the database
table named "my_table" (in the configured database).

The data file must be in a certain format. Here is an example:

	[1]
	name:Mr.X
	age:23

	[2]
	name:Mr.Y
	age:56
	bio.
		Born in 1980, Mr.Y
		was the first to invent
		the toaster.

	[3]
	name:Mrs.Y
	age:25

Each data file can contain zero or more records, each of which
starts with a line containing the id of the record in brackets.
Each line after that contains a field value, which starts with the
field name followed by a colon (":"), followed by the field value
up to the end of line (without the newline).

If a field value contains newlines, the fieldname must be followed
by a dot (instead of a colon) and the following lines are considered
the value of the field. The field value lines must contain a
space character (space or horizontal tab) at the line start,
which identifies them as field value lines but is ignored.

Due to the format, certain restrictions apply to data that
is stored in data files:

=over 1

=item 1 The table must have a column named I<id>.

=item 2 Field names are not allowed to contain colons, dots
or newline characters.

=back

When inserted in the database, CGI::WebToolkit checks first, if a certain row
with that id already exists. If so, nothing happens. In almost all
cases you do not want to have your data in the database be overwritten
by data from data files.

Empty lines in data files and space characters before the colon
are completely ignored.






=head2 Methods for user and rights management

=head3 login()

The login() method associates the current session with a user,
aka it logs the user in. The method takes two parameters,
the username and the password:

	$wtk->login( $username, $password );

To work, the -usertable option has to be configured (s.a.).

After logging in, the user's data is available in the session
under the name I<user>.

The method returns 1 on success and 0 on failure.

=head3 logout()

This method removes any associated user from the current session,
aka logt the user out.

=head3 allowed()

This method checks for a given workflow function name if the given
user (or the current session user) is allowed to execute the
workflow function.

It gets two parameter, first the workflow function name and
second optionally the user name, which defaults to the currently
logged in user, if any. If no user is logged in and no username
is given as second parameter, then the special username I<guest>
is used. allowed() returns 1 if the user is allowed to execute the
workflow function, 0 therwise.

In order to determine, if the user has access, the access configuration
file is loaded from I<accessconfigs/> in the I<private> directory.
This file maps workflow function names to access function names.
The appropriate access function is then executed and tells CGI::WebToolkit
if the user should be given access.

The access functions are stored in I<accesschecks/> in the
I<private> directory and are raw subroutine bodies. When called,
the special variable $wtk is magically available, which is the
CGI::WebToolkit instance. The subroutine body should return either 1 or 0.
Additionally the workflow function name and the username
that are beeing checked are passed to the subroutine body
as first and second parameter in the array @args.

Here is an example of such
an access check subroutine body that would go inside a file
in I<accesschecks> in the I<private> directory:

	my ($wf, $username) = @args;
	if ($username eq 'root') {
	  return 1;
	}
	elsif ($wf eq 'my_project.public.home') {
	  return 1;
	}
	else {
	  return 0;
	}

The format of an access configuration file is the same as
of a normal config file. Here is an example:

	.*: my_project.general_rights
	admin\..*: my_project.admin_rights

This file says in the first line that for all workflow functions
matching ".*" the access check function named I<my_project.general_rights>
will be consulted. For all workflow functions matching "admin\..*"
(means literally: in the group of "admin") the access check function
named I<my_project.admin_rights> should be consulted.

If a workflow function name is matching more than one entry
in an access configuration file, I<all> of the matching entries
are processed and I<all> of them have to grant the user access,
to finally grant access.






=head2 Methods for Internationalization

=head3 _()

The _() (underscore-method) is used to translate a phrase into
the current or any other language. It will consult the dictionary
and return the translated string. If no translation could be found,
the phrase itself is returned.

The _() takes two parameters: the phrase (string) and optionally
a language name, e.g. I<en> or I<en_GB> etc. The language names
should conform to the international naming conventions though this
is not required.

Example:

	my $text_de = _('I like to walk around the block', 'de');
	my $text_in_current_language =
		_('Hello, World!');

If you need to call the _() method from within a template, just
use the core generator I<t>, as in this example:

	<t>Hello</t>, dude!
	<t lang="de_DE">Hello</t>, dude!

This is equivalent to the following calls within perl:

	_('Hello');
	_('Hello', 'de_DE');

=head3 lang()

The lang() method is used to set and retrieve the language
of the current session. If passed a parameter, this will be the
new current session language. The current session language is
always returned.

=head3 translate()

translate() is used to translate a phrase to another language.
The most common syntax is that of a sequence of pairs, with
the language identifier as the key and the phrase as value.
The first pair is used as the key phrase to be stored in the
database phrase table.

	translate( <language> => <phrase>, ... );

Example:

	translate(
	  'en_GB' => 'Hello!',
	  'de_DE' => 'Hallo!',
	  # you can add even more pairs
	);






=head2 Methods for form file upload

=head3 upload()

This method will save a file that was transferred via a normal
form submit inside a normal file form field:

	upload('attachment','my_project_uploads');

To make this example work, the form beeing submitted must 
contain a file field named I<attachment> and there must be
a writeable directory I<uploads/my_project_uploads/> in the
I<public> directory.

The file is loaded from the parameter, saved inside the
directory I<uploads/my_project_uploads/> in the I<public> directory
and if everything goes well, a new entry like the following
is added to the session variable array named I<uploads>, s.a.:

	{
		'success'  => 1/0,
		'info'     => '...',
		
		# optional fields if upload save was successful
		'path'     => '...',
		'filename' => '...',
		'created'  => '...',
		'mimetype' => '',
		
		'original_filename' => '',
	}

The field I<info> contains all the information from the
method CGI::uploadInfo(), including the actual filename
that was selected in the form field and the content type.

To retrieve this information about the latest upload, you can
simply do the following:

	my $info = $wtk->get()->[-1];



=head2 Other methods

=head3 logmsg()

logmsg() writes a text message to a logfile. It takes the message
as first parameter and optionally a priority, which can be one
of I<DEBUG> (default), I<INFO>, I<WARNING>, I<ERROR> or I<FATAL>. 

The logfiles are kept in the private path under I<logs>.
For each priority and workflow function there is a separate logfile
that can then be inspected for debugging or other reasons.






=head2 Predefined template functions

There are a lot of predefined generator functions, which are
located in the I<core> subdirectory of the I<generators> directory.


=head2 Fileformats

=head3 Configuration file format

The configuration files have a format that allows for grouping
configuration values into separate namespaces. An example configuration
file that can be parsed is:

	# comment
	name: value
	name2 : value

=head3 Template file format

An example template file:

	<h1>{title}</h1>
	<p>{content}</p>
	<i>{author:Default Value}</i>


=head1 EXPORT

None by default.



=head1 SEE ALSO

CGI::WebToolkit::Tutorial

Other modules are worth a look, including CGI, CGI::App and many more.
Use the search on cpan.org to find alternatives to the CGI::WebToolkit.

There is no website for this module.

If you have any questions, hints or something else to say,
please mail to tokirc@gmx.net or post in the comp.lang.perl.modules
mailing list- thank you for helping make CGI::WebToolkit better!

=head1 AUTHOR

Tom Kirchner, tokirc@gmx.net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Tom Kirchner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
