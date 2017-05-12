package Basset::Template;

#Basset::Template, copyright and (c) 2002, 2003, 2004, 2005, 2006 James A Thomason III
#Basset::Template is distributed under the terms of the Perl Artistic License.

=pod

=head1 NAME

Basset::Template - my templating system

=head1 AUTHOR

Jim Thomason, jim@jimandkoka.com

=head1 DESCRIPTION

Yes yes, I am horribly horribly villified for even considering doing such a thing. But this is actually a pretty damn
powerful AND flexible templating system. It embeds perl into the template and doesn't worry about extra syntax or tokens
or such of its own. Theoretically, it'd be really easy to subclass the thing and actually create your own template syntax,
if you so desire. Personally, I don't. At least, not yet...

Templates live in their own namespaces, so you won't need to worry about things colliding. At all. Ever. Magic!
The only variable that's imported into a template's namespace is '$self', the template object being processed.

=head1 QUICK START

Okay, so you want to write a template. It's going to need a few things. Code, values, and passed variables. Try this example:

 in: /path/to/template.tpl

 %% foreach my $age (1..5) {
 	<% $name %> is now <% $age %><% "\n" %>
 %% };

Then, your code can be:

 use Basset::Template;
 my $template = Basset::Template->new(
 	'template' => '/path/to/template.tpl'
 ) || die Basset::Template->error();

 print $template->process(
 	{
 		'name' => \'Jim'
 	}
 ) || $template->error;

Voila. All done. Note that %% starts a code line which goes to the end. <% %> delimits a variable to
be inserted. Also be aware that any white space between code blocks or variable insertion blocks will be stripped.
That's why we have that "\n" in a variable insertion block - it puts in a new line. We don't end up with 2 newlines
because the actual newline is stripped.

The process method returns the processed template. You may pass in a hashref containing the values to be inserted.
Note that values should be passed by reference. In this case, we pass in 'name', which is a scalar containing 'Jim'.
If you don't pass a value by reference, it will be assumed that you meant to pass in a scalar reference and be alterred
as such. Note that this has no effect on you.

 {'name' => \'Jim'} == {'name' => 'Jim'}

And that includes the read-only nature of the ref to the literal. Both values are accessed in your template via '$name'

You can also skip creating an object, if you'd prefer:

 print Basset::Template->process('/path/to/template.tpl', {'name' => \'Jim'}) || die Basset::Template->error;

Damn near everything is configurable. Read on for more information.

=cut

our $VERSION = '1.04';

use Cwd ();

use Basset::Object;
our @ISA = Basset::Object->pkg_for_type('object');

use strict;
use warnings;

=pod

=head1 ATTRIBUTES

B<Note that all attributes should be set in the conf file>

=over

=item open_return_tag, close_return_tag

In a template, the simplest thing that you're going to want to do is embed a value. Say you have $x = 7 and want to display
that. Your template could be:

 $x = <% $x %>

Which, when processed, would print:

 $x = 7

In this case, <% is your open_return_tag and %> is your close_return_tag. These should be specified in your
conf file, but may be alterred on a per-object basis (if you're a real masochist).

Also note that side effects are handled correctly:

 $x is now : <% ++$x %>, and is still <% $x %>;

 evaluates to :
 $x is now : 8, and is still 8

And that you may do extra processing here, if you'd like. The final value is the one returned.

 <% $x++; $x = 18; $x %>

 evaluates to :
 18

Defaults are <% and %>

=cut

__PACKAGE__->add_attr('open_return_tag');
__PACKAGE__->add_attr('close_return_tag');

=item open_eval_tag, close_eval_tag

Sometimes, though, it gets a little more complicated, and you actually want to put code in your template. That's where
the eval tags come into play. The defaults are "%%" and "\n".

For example:

 %% foreach my $x (1..5) {
 	<% $x %>
 %% };

evalutes to:

 12345

(recall that the whitespace is stripped)

Voila. You may insert any perl code you'd like in there, as long as it's valid. If you want to output something into the 
template instead of using the eval tags, use the special filehandle OUT.

 %% foreach my $x (1..5) {
 	%% print OUT $x;
 %% };

is the same thing.

Note that you may put comments in this way.

%% # this is a comment.

Comments will be stripped before the template is displayed. See also open_comment_tag and close_comment_tag

=cut

__PACKAGE__->add_attr('open_eval_tag');
__PACKAGE__->add_attr('close_eval_tag');

=pod

=item big_open_eval_tag, big_close_eval_tag

By default, our code is line delimited. That's nice for not needing closing tags for one-liner things, like if statements
or for loops. But sometimes you need to do a lot of processing. That's a mess.

 %% my $x = some_function();
 %% $x + 1;
 %% if ($x > 18) {
 %%		$x = other_function;
 %% } elsif ($x > 14) {
 	$x = 12;
 %% };
 %% $x = process($x);
 %% # etc.

So, we have our big tags, defaulting to <code> and </code>, which are a synonym, just with a closing tag.

 <code>
	  my $x = some_function();
	  $x + 1;
	  if ($x > 18) {
			$x = other_function;
	  } elsif ($x > 14) {
		$x = 12;
	  };
	  $x = process($x);
	  # etc.
 </code>

Much cleaner.

=cut

__PACKAGE__->add_attr('big_open_eval_tag');
__PACKAGE__->add_attr('big_close_eval_tag');

=pod

=item open_comment_tag, close_comment_tag

You're a bad, bad developer if you're not commenting your code. And your templates are no exception. While you can
embed comments via the eval_tags, it's less than ideal.

 %% # this is a comment
 <code> #this is a comment </code>

So we have our comment tags, which default to <# and #>

 <# this is a comment that will be stripped out well before you see the processed template #>

=cut

__PACKAGE__->add_attr('open_comment_tag');
__PACKAGE__->add_attr('close_comment_tag');

=pod

=item open_include_tag, close_include_tag

You may want to include another template inside your current template. That's accomplished with include tags,
which default to <& and &>

 This is my template.
 Here is a subtemplate : <& /path/to/subtemplate.tpl &>

There are two ways to include a subtemplate - with passed variables and without. Passing without variables is easy -
we just did that up above.

 <& /path/to/subtemplate.tpl &>

Passing with variables is also easy, just give it a hashref.

<& /path/to/subtemplate.tpl {'var1' => \$var1, 'var2' => \$var2, 'var3' => \$var3} &>

And voila. All set. Same rules apply for passing in variables as applies for the process method. You may break the include
statement over multiple lines, if so desired.

The major difference between the two is that if a subtemplate is included without variables, then it is evaluted in
the B<template's> package. So it has access to all variables, etc. within the template and vice-versa. If a subtemplate
is included with variables, then it is evaluated in it's B<own> package. So it does not have access to any variables of
the supertemplate, nor does the supertemplate have access to the subtemplate's values.

=cut

__PACKAGE__->add_attr('open_include_tag');
__PACKAGE__->add_attr('close_include_tag');

__PACKAGE__->add_attr('open_cached_include_tag');
__PACKAGE__->add_attr('close_cached_include_tag');

__PACKAGE__->add_attr('cache_all_inserts');

=pod

=item document_root

For included files, this is the document root. Say you're running a webserver, and you want to include a file. Your
webserver doc root is: /home/users/me/public_html/mysite.com/

Now, when you include files, you don't want to have to do:

 <& /home/users/me/public_html/mysite.com/someplace/mysubtemplate.tpl &>

because that's messy and very non-portable. So just set a document_root.

 $tpl->document_root('/home/users/me/public_html/mysite.com/');

and voila:

 <& /someplace/mysubtemplate.tpl &>

Note that this only affects subtemplates set with an absolute path. So even with that doc root, these includes are
unaffected:

 <& someplace/mysubtemplate.tpl &>
 <& ~/someplace/mysubtemplate.tpl &>

=cut

__PACKAGE__->add_attr('document_root');

=pod

=item allows_debugging

Boolean flag. 1/0. If 1, then the debug tags will execute, if 0, then they won't.

=cut

__PACKAGE__->add_attr('allows_debugging');

=pod

=item open_debug_tag, close_debug_tag

Debugging information can be a very good thing. The debug tags are the equivalent of return tags, but they go
to STDERR. You may do additional processing, manipulation, etc., but the last value always go to STDERR.

 <debug>
	"Now at line 15, and x is $x"
 </debug>

 <debug>
 	my $z = $x;
 	$z *= 2;
 	"Now at line 15, and twice x is $z";
 </debug>

Debug tags will only be executed if allows_debugging is 1.

=cut

__PACKAGE__->add_attr('open_debug_tag');
__PACKAGE__->add_attr('close_debug_tag');

=pod

=item pipe_flags

This is a trickled class attribute hashref.

The pipe_flags allow you to deviate from standard perl and send the output of your value to a processor before displaying.

Built in flags include 'h' to escape the output for HTML and 'u' to escape the output for URLs.

New flags should have the flag as the key and the processor as the value.

 Some::Template::Subclass->pipe_flags->{'blogger_flag'} = 'blogger_processor';

Will get one argument - the value to be processed.

=cut

__PACKAGE__->add_trickle_class_attr('pipe_flags',
	{
		'h' => 'escape_for_html',
		'u' => 'escape_for_url',
	}
);

=pod

=item template

This is the actual template on which you are operating.

 $tpl->template('/path/to/template');	#for a file
 $tpl->template(\$template);			#for a value in memory

 my $tpl = Basset::Template->new('template' => '/path/to/template');

Hand in a literal string for a file to open, or a scalarref if it's already in memory.

Note that if you had in a template with an absolute path starting with /, the template will automatically
be assumed to be sitting off of the document root. Relative paths are unaffected.

=cut

__PACKAGE__->add_attr('_template');

sub template {
	my $self = shift;

	my $tpl = $self->_template(@_);
	my $root = $self->document_root;

	if (defined $tpl && defined $root && $tpl =~ m!^/! && $tpl !~ m!^$root!) {
		my $full_path_to_tpl = $root . $tpl;
		$full_path_to_tpl =~ s!//+!/!g;
		return $full_path_to_tpl;
	}
	else {
		return $tpl;
	};

}

=pod

=item preprocessed_template

This stores the value of the template after it's been run through the preprocessor. You probably don't
want to touch this unless you B<really> know what you're doing.

Still, it's sometimes useful to look at for debugging purposes, if your template isn't displaying properly.
Be warned - it's a bitch to read.

=cut

__PACKAGE__->add_attr('preprocessed_template');

#This is the template we're currently operating on. Internal attribute. Don't touch it.

__PACKAGE__->add_attr('_current_template');

#internal method. All templates evaluate in their own distinct package. This is it.
#This value is set by gen_package

__PACKAGE__->add_attr('package');

#internal method. As a template evaluates, its output gets tacked onto a scalar. This is it.
#This value is set by gen_file

__PACKAGE__->add_attr('file');

__PACKAGE__->add_attr('_preprocessed_inserted_file_cache');

=pod

=item caching

Boolean flag. 1/0.

templates are obviously not executable code. Nothing can be done with them, they're nonsensical. So, before they can
be used, they must be preprocessed into something useful. That preprocessing step is reasonably fast, but it's still
effectively overhead. You don't care about the transformations happening, you just want it to work!

Besides most templates are modified very rarely - it's normally the same thing being re-displayed. So constantly re-preprocessing
it is inefficient. So, you may turn on caching.

If caching is on, during preprocessing the template looks in your cache_dir. If it finds a preprocessed version that is
current, it grabs that version and returns it. No more additional processing. If it finds a preprocessed version that is
out of date (i.e., the actual template was modified after the cached version was created) then it looks to the new
template and re-caches it. If no cached value is found, then one is cached for future use.

=cut

__PACKAGE__->add_attr('caching');

=pod

=item cache_dir

This is your cache directory, used if caching is on.

 $template->cache_dir('/path/to/my/cache/dir/');

=cut

__PACKAGE__->add_attr('cache_dir');

=pod

=item compress_whitespace

Boolean flag. 1/0.

Sometimes whitespace in your template doesn't matter. an HTML file, for example. So, you can compress it. That way
you're sending less data to a web browser, for instance.

compress_whitespace turns runs of spaces or tabs into a single space, and runs of newlines into a single newline.

=cut

__PACKAGE__->add_attr('compress_whitespace');

sub init {
	return shift->SUPER::init(
		{
			'open_return_tag'			=> '<%',
			'close_return_tag'			=> '%>',
			'open_eval_tag'				=> '%%',
			'close_eval_tag'			=> "\n",
			'big_open_eval_tag'			=> '<code>',
			'big_close_eval_tag'		=> "</code>",
			'open_comment_tag'			=> '<#',
			'close_comment_tag'			=> '#>',
			'open_include_tag'			=> '<&',
			'close_include_tag'			=> '&>',
			'open_cached_include_tag'	=> '<&+',
			'close_cached_include_tag'	=> '+&>',
			'open_debug_tag'			=> '<debug>',
			'close_debug_tag'			=> '</debug>',
			'cache_all_inserts'			=> 0,
			
			'caching'					=> 1,
			'compress_whitespace'		=> 1,
			'allows_debugging'			=> 1,
			
			'_full_file_path_cache'	=> {},
			'_preprocessed_inserted_file_cache' => {},
		},
		@_
	);
}

{
	my $package = 0;
	my $file = 0;


	#internal method, generates a new package for the template to be processed in

	sub gen_package {
		my $self = shift;

		my $template = shift || $self->template;

		#if it's the template itself was handed in as a ref, then create an internal package
		if (ref $template) {
			return __PACKAGE__ . "::package::ipackage" . $package++;
		}
		#otherwise, it's a file, then create the special package
		else {
			my $full_file = $self->full_file_path($template);
			$full_file =~ s/(\W)/'::p' . ord($1)/ge;
			return __PACKAGE__ . "::package::fpackage" . $full_file;
		};
	};

	#internal method, generates a new scalar for the processed template to be tacked on to.

	sub gen_file {
		my $self = shift;

		my $template = shift || $self->template;

		#if we've been given two values, then it's a template to be incremented
		if (@_){
			$template =~ s/[if]file/subfile/g;
			return $template . $file++;
		}
		#if it's the template itself was handed in as a ref, then create an internal package
		if (ref $template) {
			return '$' . __PACKAGE__ . "::file::ifile" . $file++;
		}
		#otherwise, it's a file, then create the special package
		else {
			my $full_file = $self->full_file_path($template);
			$full_file =~ s/(\W)/'::p' . ord($1)/ge;
			return '$' . __PACKAGE__ . "::file::ffile" . $full_file;
		};
	};

};

# very very very internal method. Takes any template information inside of a return tag, and translates
# it into an eval tag

sub return_to_eval {
	my $self	= shift;
	my $val		= shift;

	my $bein	= $self->big_open_eval_tag;
	my $beout	= $self->big_close_eval_tag;

	my $file	= $self->file;

	my $subval	= $self->gen_file($file,1);

	$val =~ /^(.+?)									# first of all match, well, anything.
				(									# finally, our optional pipe flags. A pipe, followed by an arbitrary word
					(?:									
						\|
						\s*
						\w+
						(?:
							\s*[\$%@&*\\]?\w+		# and an optional string of arguments, which may be words or variables
						)*
						\s*
					)*
				)
			$/sx;
	
	my ($code, $pipes) = ($1, $2);
	
	my $pipe;
	
	if (defined $pipes) {
		$pipe = $subval;
		while ($pipes =~ /\|\s*(\w+)((?:\s*[\$%@&*\\]?\w+)*)/g) {
			if (my $method = $self->pipe_flags->{$1}) {
				my $args = '';
				if (defined $2) {
					my @params = split ' ', $2;
					my @args = ();
				
					foreach my $param (@params) {
						push @args, $param =~ /^\W/
							? $param
							: "q{$param}";
					}
				
					$args = ', ' . join(', ', @args);
				}
				$pipe = "\$self->$method($pipe $args)";
			}
		}
	}

	$val = $bein . " $subval = do { $code }; $file .= defined ($subval) ? $pipe : ''; " . $beout;
	
	return $val;
};

# very very very internal method. Takes any template information inside of a debug tag, and translates
# it into an eval tag

sub debug_to_eval {
	my $self	= shift;
	my $val		= shift;

	return '' unless $self->allows_debugging;

	my $bein	= $self->big_open_eval_tag;
	my $beout	= $self->big_close_eval_tag;

	$val = $bein . "{ my \@debug_val = do { $val }; print STDERR (\@debug_val ? \@debug_val : ''), \"\\n\"; };" . $beout;
	
	return $val;
};

# internal method. The tokenizer breaks up the template into eval components and non eval components

sub tokenize {
	my $self		= shift;

	my $template	= shift || $self->template
		or return $self->error("Cannot tokenize without template", "BT-01");

	my $rin		= $self->open_return_tag;
	my $rout	= $self->close_return_tag;

	my $ein		= $self->open_eval_tag;
	my $eout	= $self->close_eval_tag;

	my $bein	= $self->big_open_eval_tag;
	my $beout	= $self->big_close_eval_tag;

	return 
		grep {defined $_ && length $_ > 0}
		split(/(\Q$rin\E(?:.*?)\Q$rout\E)|(\Q$ein\E(?:.*?)\Q$eout\E)|(\Q$bein\E(?:.*?)\Q$beout\E)/s, $template);
};

=pod

=item full_file_path

given a file (usually a template), full_file_path returns the absolute path of the file,
relative to the file system root

=cut

__PACKAGE__->add_attr('_full_file_path_cache');

sub full_file_path {
	my $self = shift;
	my $file = shift or return $self->error("Cannot get file path w/o file", "BT-14");

	return $self->_full_file_path_cache->{$file} if defined $self->_full_file_path_cache->{$file};


	if ($file =~ /^\//){
		#do nothing, it's fine
	}
	elsif ($file =~ /^~/){
		my $home = $ENV{HOME} or return $self->error("Cannot get home", "BT-10");
		$home .= '/' unless $home =~ /\/$/;
		$file =~ s/^~\//$home/;
	}
	elsif ($file =~ /^\.[^.]/){
	
		my $cwd = Cwd::getcwd() or return $self->error("Cannot getcwd", "BT-09");
		$cwd .= '/' unless $cwd =~ /\/$/;
	
		$file =~ s/^\.\//$cwd/;
		#return $file;
	}
	elsif ($file =~ /[a-zA-Z0-9_]/) {
	
		my $cwd = Cwd::getcwd() or return $self->error("Cannot getcwd", "BT-09");
		$cwd .= '/' unless $cwd =~ /\/$/;
	
		$file = $cwd . $file;
		#return $file;
	}
	else {
		return $self->error("Cannot get full path to file '$file'", "BT-11");
	}
	
	if ($file =~ /\.\./){
		my @file = split(/\//, $file);
		my @new = ();
		foreach (@file){
			if ($_ eq '..'){
				pop @new;
			}
			else {
				push @new, $_;
			};
		};
		$file = join('/', @new);
	};

	$self->_full_file_path_cache->{$file} = $file;

	return $file;
};

# internal method. Names the cached file that will be written to the cache_dir.
# currently filename . '-,' debuglevel . '.' . package name . '.cache'

sub cache_file {
	my $self = shift;
	my $file = shift or return $self->error("Cannot create cache_file w/o file", "BT-12");

	my $dir = $self->cache_dir or return $self->error("Cannot create cache_file w/o cache_dir", "BT-19");
	$dir =~ s/\/$//;

	(my $pkg = __PACKAGE__) =~ s/::/,/g;

	my $debug = $self->allows_debugging;

	my $cache_file = $dir . $self->full_file_path("$file-,$debug.$pkg.cache");	#name our preprocessed cache file

	return $cache_file;

};

#internal method. handles converting a subtemplate include tag into the necessary eval tag equivalent.

sub insert_file {
	my $self	= shift;
	my $file	= shift or return $self->error("Cannot insert w/o file", "BT-13");
	my $cached	= shift || 0;

	my $pkg		= $self->pkg;

	my $bein	= $self->big_open_eval_tag;
	my $beout	= $self->big_close_eval_tag;

	my $f = $self->file;
	
	if ($file =~ s/\s+>>\s*(\$\w+)//) {
		$f = $1;
	}

	$file =~ s/^\s+|\s+$//g;

	my $args = undef;

	if ($file =~ /\s/){
		($file, $args) = split(/\s+/, $file, 2);
		$args =~ s/\\/\\\\/g;
		$args =~ s/([{}])/\\$1/g;
	};

	my $return = undef;
	if ($cached) {

		my $tpl = $pkg->new(
			'template' => $file,
			'caching' => 0,
			'compress_whitespace' => $self->compress_whitespace
		);
		
		my $file = $tpl->template;
		my $embedded;
		{
			local $/ = undef;
			my $filehandle = $self->gen_handle;
			open ($filehandle, '<', $file) or return $self->error("Cannot open embedded templated $file : $!", "BT-06");
			$embedded = <$filehandle>;
			close $filehandle or return $self->error("Cannot close embedded template $file : $!", "BT-07");
		}
		
		$return = "$bein { $beout" . $embedded . "$bein } $beout";
		
	}
	elsif ($args){
		$return	 = qq[$bein { local \$@ = undef; my \$tpl = \$self->_preprocessed_inserted_file_cache->{"$file"} || $pkg->new('template' => "$file", caching => ] . $self->caching . ', compress_whitespace => ' . $self->compress_whitespace . ');';
		$return .= qq[\$self->_preprocessed_inserted_file_cache->{"$file"} = \$tpl;];
		$return	.= qq[my \$hash = eval q{$args}; if (\$@) { $f .= '[' . \$@ . ' in subtemplate $file]' } else {$f .= \$tpl->process(\$hash) || '[' . \$tpl->errstring . ' in subtemplate $file]'; } }; $beout];
	}
	else {
		$return	 = qq[$bein { local \$@ = undef; my \$tpl = \$self->_preprocessed_inserted_file_cache->{"$file"} || $pkg->new('template' => "$file", caching => ] . $self->caching . ', compress_whitespace => ' . $self->compress_whitespace . ');';
		$return .= qq[\$self->_preprocessed_inserted_file_cache->{"$file"} = \$tpl;];
		$return	.= qq[$f .= eval (\$tpl->preprocess) || '[' . \$tpl->errstring . ':(' . \$@ . ') in subtemplate $file]'; }; $beout];
	};

	return $return;

};

=pod

=back

=head1 METHODS

=over

=item preprocess

preprocess is called internally, so you'll never need to worry about it. It takes the template and translates it into
an executable form. Only call preprocess if you really know what you're doing (for example, if you want to look at the
preprocessed_template without actually calling process).

=cut

sub preprocess {
	my $self		= shift;

	my $template	= shift || $self->template
		or return $self->error("Cannot preprocess without template", "BT-02");
	my $raw			= shift || 0;

	$self->file($self->gen_file($template)) unless $self->file;
	$self->package($self->gen_package($template)) unless $self->package;

	# first things first - nuke the template itself, this will allow us to use the standardized names
	# based upon the template file name, AND run that template more than once in the
	# same script
	if ($self->file) {
		no strict 'refs';
		my $stringy_file = $self->file;
		$stringy_file =~ s/^\$//;
		${$stringy_file} = undef;
	};

	# okay, if we have a preprocessed_template AND the template that we're preprocessing
	# is the one that we've cached (_current_template), then we can return the preprocessed_template
	# otherwise, we need to preprocess it
	if ($self->preprocessed_template && $self->_current_template eq $template){
		return $self->preprocessed_template;
	};

	# keep track of the original value that was passed, so we can hand that into _cached_template
	# if desired 
	my $passed_template = scalar $template;

	my $cache_file = undef;	#so we can cache the preprocessed template to disk, if desired

	#okay, if we're given a string reference, use that as our template. Otherwise, 
	#we're going to assume that it's a file to open
	if (ref $template){
		#for now, just de-reference it. Memory management be damned!
		#I may pass by ref later, but for now I don't want to mess w/the original
		$template = $$template;
	}
	#otherwise, we're going to assume that it's the path to a hard file on disk
	else {
		my $filename	= $template;

		$cache_file = $self->cache_file($filename);	#turn it into the full name

		if ($cache_file) {

			my $using_cache = 0;

			#check to see if we have a cached preprocessed file
			if (-e $cache_file && (-M $filename >= -M $cache_file)){
				$filename = $cache_file;
				$using_cache = 1;
			};

			# load up the file. We'll either be loading the template from the cache
			# if the check up there succeeded, or we'll be loading the original template
			my $filehandle = $self->gen_handle;
			open ($filehandle, '<', $filename) or return $self->error("Cannot open template $template : $!", "BT-06");
			local $/ = undef;
			$template = <$filehandle>;
			close $filehandle or return $self->error("Cannot close template $template : $!", "BT-07");

			#return now if we loaded this thing out of the cache
			$self->_current_template($passed_template);
			return $self->preprocessed_template($template) if $using_cache;
		};
	};

	my $rin		= $self->open_return_tag;
	my $rout	= $self->close_return_tag;

	my $ein		= $self->open_eval_tag;
	my $eout	= $self->close_eval_tag;

	my $bein	= $self->big_open_eval_tag;
	my $beout	= $self->big_close_eval_tag;

	my $cin		= $self->open_comment_tag;
	my $cout	= $self->close_comment_tag;

	my $ciin	= $self->open_cached_include_tag;
	my $ciout	= $self->close_cached_include_tag;

	my $iin		= $self->open_include_tag;
	my $iout	= $self->close_include_tag;

	my $din		= $self->open_debug_tag;
	my $dout	= $self->close_debug_tag;

	my $pkg		= $self->package;
	my $file	= $self->file;

	#we need the special extra case of the while loop here to handled nested cached embedded templates.
	$template =~ s/\Q$ciin\E(.*?)\Q$ciout\E/$self->insert_file($1, 'cached')/ges while $template =~ /\Q$ciin\E(.*?)\Q$ciout\E/s;
	$template =~ s/\Q$iin\E(.*?)\Q$iout\E/$self->insert_file($1, $self->cache_all_inserts)/ges while $template =~ /\Q$iin\E(.*?)\Q$iout\E/s;

	if (defined $template) {
		$template =~ s/\Q$cin\E(.*?)\Q$cout\E//gs;

		$template =~ s/\Q$rin\E(.*?)\Q$rout\E/$self->return_to_eval($1)/gse;

		$template =~ s/\Q$din\E(.*?)\Q$dout\E/$self->debug_to_eval($1)/gse;

		$template =~ s/\Q$eout\E(\s+)\Q$ein\E/$eout$ein/g;
		$template =~ s/\Q$beout\E(\s+)\Q$bein\E/$beout$bein/g;
	}



	my @tokens = $self->tokenize($template) or return;

	my $stack = 0;
	my @idx = ();

	my $block = 0;

	foreach (@tokens){
		if ($_ =~ /$ein(.*?)$eout/s){
			$_ =~ s/$ein(.*?)$eout/$1\n/gs;
			$_ =~ s/([^;{}\s]\s*)$/$1;/;		#add semicolons, if needed
			$block++ if $_ =~ /{\s*$/;
			$block-- if $_ =~ /^\s*}/;
		}
		elsif ($_ =~ /$bein(.*?)$beout/s){
			$_ =~ s/$bein(.*?)$beout/$1\n/gs;
			$_ =~ s/([^;{}\s]\s*)$/$1;/;		#add semicolons, if needed
			$block++ if $_ =~ /{\s*$/;
			$block-- if $_ =~ /^\s*}/;
		}
		else {
			$_ =~ s/([{}])/\\$1/g;
			if ($block && /^\s+$/){
				$_ = '';
				next;
			}; 
			unless (/$file/){
				$_ =~ s/[^\S\n]+/ /g if $self->compress_whitespace;
				$_ =~ s/[^\S ]+/\n/g if $self->compress_whitespace;
				$_ = "$file .= (q{$_});\n";
			};
		};
	};

	#$template = join('', "use strict;\n", "use warnings;\n", @tokens);
	$template = join('', @tokens);
	$template =~ s/print OUT/$file .=/g;
	$template .= ";\nreturn $file;\n";

	if ($self->caching && $cache_file){

		if (my $cache_dir = $self->cache_dir){
			#print "C $cache_dir\n";
			$cache_dir =~ s/\/$//;

			unless (-d $cache_dir){
				mkdir($cache_dir, 0777) or return $self->error("Cannot make directory $cache_dir - ($!)", "BT-15");
			};

			(my $filedir = $cache_file) =~ s/^$cache_dir//;

			my @file = split(/\//, $filedir);
			pop @file;	#thats my filename, not the path.
			#print "F @file\n";

			foreach my $dir (@file) {
				next if $dir =~ /^\s*$/;
				$cache_dir .= "/$dir";
				#print "CACHE DIR : $cache_dir ($dir)\n";
				unless (-d $cache_dir){
					mkdir($cache_dir, 0777) or return $self->error("Cannot make directory $cache_dir - ($!)", "BT-15");
				};
			};
			my $cachehandle = $self->gen_handle;
			if (open ($cachehandle, '>', $cache_file)) {
				print $cachehandle $template;
				close ($cachehandle) or return $self->error("Cannot close cache file ($cache_file) - ($!)", "BT-16");
			}
			else {
				return $self->error("Cannot open cache file ($cache_file) - ($!)", "BT-17");
			};
		};
	};


	$self->_current_template($passed_template);
	return $self->preprocessed_template($template);
};

=pod

=item process

Ahh, the magic method that finally does what we want - turns our template into the populated thing we want to work with.

Takes 0, 1, or 2 arguments, and may be called as a class or an object method. If called as an class method, a new template
object is created internally.

With 0 arguments, you must call it as an object method. The 0 argument form is equivalent to:

 $tpl->process($tpl->template);

With 1 argument, you may either pass a template OR a hashref of values.

 $tpl->process($template);
 $tpl->process($hashref);

The second form is equivalent to:

 $tpl->process($tpl->template, $hashref);

With 2 arguments, you pass a template AND a hashref of values.

 $tpl->process($template, $hashref);

process returns the completed, processed, done template.

 my $page = $tpl->process($hashref) || die $tpl->error();
 print $page;

The hashref contains the values to be populated into the template. Assume your template is:

 Hello, <% $name %>

Then you may process it as:

 $tpl->process(); 						# prints "Hello, "
 $tpl->process({'name' => \'Billy'});	#prints "Hello, Billy"
 $name = 'Jack';
 $tpl->process({'name' => \$name});		#prints "Hello, Jack"
 $tpl->process({'$name' => \$name});	#prints "Hello, Jack"

You may pass different types of variables with the same name, if you specify their types.

 $tpl->process( {
 	'$name' => \$name,
 	'@name' => \@name,
 	'%name' => \%name
 } );

If no type is specified in the key, it is assumed to be a scalar. 

Also be warned that while you may pass in a reference to a constant, just like any other constant reference,
you may not then alter its value in your template. Even if you pass in the constant itself, it internally becomes
a reference and you can't change it.

=cut

sub process {
	my $self				= ref $_[0] ? shift : shift->new();

	my ($template, $vars)	= @_;

	#okay, if the template is not defined (meaning nothing was passed)
	#OR it's a hash reference (meaning it's actually the vars hash)
	#then we'll set the template to the object's template value or fail out
	#then we'll set the vars hash to the template. Not to worry if it's undefined,
	#since we'll initialize it later if need be.
	if (! defined $template || ref $template eq 'HASH'){
		$vars = $template;
		$template = $self->template
			or return $self->error("Cannot process without template", "BT-03");
	};

	#okay, now if we've been passed in a file (not a template reference), then
	#we can try to get away with using the cached version

	my $tplpath = ref $template ? 'Inline template' : $template;

	$template = $self->preprocess($template) or return;

	$vars ||= {};	#the vars will just be an empty hash if it's not defined

	my $pkg = $self->package;
	my $file = $self->file;

	{
		no strict 'refs';

		#make sure there's nothing lurking around inside the template
		%{$pkg . "::"} = ();

		# and nuke the template itself, this will allow us to use the standardized names
		# based upon the template file name, AND run that template more than once in the
		# same script
		my $stringy_file = $file;
		$stringy_file =~ s/^\$//;
		${$stringy_file} = undef;

		# finally, import our variables
		foreach my $key (keys %$vars){
			#if it's not a ref, we'll assume they wanted to pass in a scalar and make
			#it a reference.
			if (! ref $vars->{$key} || ref($vars->{$key}) !~ /^(REF|HASH|ARRAY|CODE|GLOB|SCALAR)$/) {
				my $val = $vars->{$key};
				$vars->{$key} = \$val;#\$vars->{$key};
			};
			#return $self->error("Please pass variables as references ($key)", "BT-08")
			#	unless ref $vars->{$key};

			#strip off leading variable type, if provided
			(my $pkgkey = $key) =~ s/^[\$@%&*]//;
			*{$pkg . "::$pkgkey"} = $vars->{$key};
		};
	};

	local $@ = undef;
	my $out = undef;
	my $ec = undef;

	eval qq{
		package $pkg;
		local \$@ = undef;
		\$out = eval \$template;
		\$ec = \$@ if \$@;
	};

	return $out || $self->error("Evaluation error in template $tplpath: $ec", "BT-05");

};

=pod

=item escape_for_html

class method, all it does is turn &, ", ', <, and > into their respective HTML entities. This is
here for simplicity of all the subclasses to display things in templates

=cut

=pod

=begin btest(escape_for_html)

$test->is(__PACKAGE__->escape_for_html('&'), '&#38;', 'escapes &');
$test->is(__PACKAGE__->escape_for_html('a&'), 'a&#38;', 'escapes &');
$test->is(__PACKAGE__->escape_for_html('&b'), '&#38;b', 'escapes &');
$test->is(__PACKAGE__->escape_for_html('a&b'), 'a&#38;b', 'escapes &');

$test->is(__PACKAGE__->escape_for_html('"'), '&#34;', 'escapes "');
$test->is(__PACKAGE__->escape_for_html('a"'), 'a&#34;', 'escapes "');
$test->is(__PACKAGE__->escape_for_html('"b'), '&#34;b', 'escapes "');
$test->is(__PACKAGE__->escape_for_html('a"b'), 'a&#34;b', 'escapes "');

$test->is(__PACKAGE__->escape_for_html("'"), '&#39;', "escapes '");
$test->is(__PACKAGE__->escape_for_html("a'"), 'a&#39;', "escapes '");
$test->is(__PACKAGE__->escape_for_html("'b"), '&#39;b', "escapes '");
$test->is(__PACKAGE__->escape_for_html("a'b"), 'a&#39;b', "escapes '");

$test->is(__PACKAGE__->escape_for_html('<'), '&#60;', 'escapes <');
$test->is(__PACKAGE__->escape_for_html('a<'), 'a&#60;', 'escapes <');
$test->is(__PACKAGE__->escape_for_html('<b'), '&#60;b', 'escapes <');
$test->is(__PACKAGE__->escape_for_html('a<b'), 'a&#60;b', 'escapes <');

$test->is(__PACKAGE__->escape_for_html('>'), '&#62;', 'escapes >');
$test->is(__PACKAGE__->escape_for_html('a>'), 'a&#62;', 'escapes >');
$test->is(__PACKAGE__->escape_for_html('>b'), '&#62;b', 'escapes >');
$test->is(__PACKAGE__->escape_for_html('a>b'), 'a&#62;b', 'escapes >');

$test->is(__PACKAGE__->escape_for_html('&>'), '&#38;&#62;', 'escapes &>');
$test->is(__PACKAGE__->escape_for_html('<">'), '&#60;&#34;&#62;', 'escapes <">');
$test->is(__PACKAGE__->escape_for_html("&&'"), '&#38;&#38;&#39;', "escapes &&'");
$test->is(__PACKAGE__->escape_for_html('<&'), '&#60;&#38;', 'escapes <&');
$test->is(__PACKAGE__->escape_for_html(q('"'')), '&#39;&#34;&#39;&#39;', q(escapes '"''));

$test->is(__PACKAGE__->escape_for_html(), undef, 'escaped nothing returns undef');
$test->is(__PACKAGE__->escape_for_html(undef), undef, 'escaped undef returns nothing');

=end btest(escape_for_html)

=cut

sub escape_for_html {
	my $self = shift;
	my $string = shift;

	if (defined $string) {
		$string =~ s/&/&#38;/g;
		$string =~ s/"/&#34;/g;
		$string =~ s/'/&#39;/g;
		$string =~ s/</&#60;/g;
		$string =~ s/>/&#62;/g;
	};

	return $string;
};


=pod

=item escape_for_url

URL escapes the key/value pair passed. This is here for simplicity of all the subclasses to display things in templates.

 my $escaped = $class->escape_for_url('foo', 'this&that'); #$escape is foo=this%26that

Also, you may pass an arrayref of values

 my $escaped = $class->escape_for_url('foo', ['this&that', 'me', '***'); #$escape is foo=this%26that&foo=me&foo=%2A%2A%2A

=cut

sub escape_for_url {
	my $class	= shift;
	my $key		= shift;
	my $value	= shift;
	
	$key =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
	
	if (defined $value && ref $value eq 'ARRAY'){
		my @q = undef;
		foreach my $v (@$value){
			$v = '' unless defined $v;
			 $v =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
			 push @q, "$key=$v";
		};
		return join("&", @q);
	}
	elsif (defined $value){
		$value =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
		return "$key=$value";	
	}
	else {
		return $key;
	};
};

1;

__END__

=pod

=back

=head1 EXAMPLES

 These are some example templates, with scripts to populate them.

 template
 --------

 %% my $old_age = 0;
 %% foreach my $age (1..5) {
 	I was <% $old_age %>, but now I am <% $age %>.
 	%% $old_age = $age;
 %% };

 script
 --------

 print Basset::Template->process('/path/to/template');

 result
 --------

 I was 0, but now I am 1.
 I was 1, but now I am 2.
 I was 2, but now I am 3.
 I was 3, but now I am 4.
 I was 4, but now I am 5.

 ========

 template
 --------

 Hello there, <% $name %>.
 I see that you are <% $admin ? '' : 'not' %> an admin.
 %% if ($admin) {
 	You may do administrative things.
 %% } else {
 	You may not do administrative things.
 %% }; 

 script
 --------

 my $template = Basset::Template->new('template' => '/path/to/template');
 print $template->process(
 	{
 		'name' => \'Jack',
 		'admin' => \'0'
 	}
 );

 result
 --------

 Hello there, Jack.
 I see that you are not an admin.
 You may not do administrative things.

 ========

 template
 --------

 <select name = "foo">
 	%% while (my ($key, $val) = each %foo) {
 		<option value = "<% $val %>"><% $key %></option>
 	%% };
 </select>

 script
 --------

 {
 	local $/ = undef;
 	$data = <DATA>;
 };

 my $template = Basset::Template->new();
 $template->template(\$data);
 print $template->process(
 	{
 		'foo' => {
 			'one' => '1',
 			'two' => '2',
 			'three' => '3'
 		}
 	}
 );

 __DATA__
 <select name = "foo">
 	%% while (my ($key, $val) = each %foo) {
 		<option value = "<% $val %>"><% $key %></option>
 	%% };
 </select>

 result
 --------

 <select name = "foo">
 	<option value = "1">one</option>
 	<option value = "3">three</option>
 	<option value = "2">two</option>
 </select>

=cut
