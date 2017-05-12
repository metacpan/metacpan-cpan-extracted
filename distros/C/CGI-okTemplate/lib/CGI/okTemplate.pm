package CGI::okTemplate;

use 5.008004;
use strict;
use Carp;
use English;
use warnings;
use File::Spec;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::okTemplate ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.03';

our $debug=0;

# Preloaded methods go here.

sub new {
	my $class = shift;
	my $self = {};

	bless($self,$class);
	$self->{___params} = {@_};
	$debug = 1 if $self->{___params}->{Debug};
	$self->{___params}->{BlockTag} = 'TemplateBlock' unless $self->{___params}->{BlockTag};
	if($self->{___params}->{RootDir}) {
		$self->{___params}->{RootDir} = File::Spec->rel2abs($self->{___params}->{RootDir});
	} else {
		$self->{___params}->{RootDir} = File::Spec->rel2abs(File::Spec->curdir());
	}
	$self->{___params}->{RootDir} = ___clean_up_dirs(File::Spec->canonpath($self->{___params}->{RootDir}));
	confess "Root Dir '$self->{___params}->{RootDir}' does not exists\n" unless (-d $self->{___params}->{RootDir});
	$self->read_template($self->{___params}->{File}) if($self->{___params}->{File});

	return $self;
}

sub read_template {
	my $self = shift;
	my $file = shift;

	unless($file) {
		confess "Parameter 'File' undefined in function 'read_template.'\n";
	}

	unless(File::Spec->file_name_is_absolute( $file )) { # make absolute path to file
		$file = File::Spec->catfile($self->{___params}->{RootDir},$file);
	}

	$file = ___clean_up_dirs(File::Spec->canonpath($file)); # delete up dirs from path
	confess "File '$file' does not exists\n" unless (-r $file);

	unless(___under_root($self->{___params}->{RootDir},$file)) {
		confess "File '$file' does not under root dir '$self->{___params}->{RootDir}'\n";
	}
	
	$self->{___params}->{File} = $file;

	local($/) = undef;
	open IN, $file;
	my $in = <IN>;
	close IN;

	my $cur_path = ___get_dir($file);
	$in = ___read_includes($in,$cur_path,$self->{___params}->{RootDir});

	$self->{___template___} = ___parse_template($in,$self->{___params}->{BlockTag},$cur_path,$self->{___params}->{RootDir});
}

sub ___read_includes {
	my $text = shift;
	my $cur_path = shift;
	my $root_path = shift;
	while($text =~ m/<!--Include\s+(.+?)-->/) {
		my $pre_inc = $PREMATCH; # text before include
		my $post_inc = $POSTMATCH; # text after include
		my $include_filename = $1; # got include filename
		unless(File::Spec->file_name_is_absolute( $include_filename )) {
			$include_filename = File::Spec->catfile($cur_path,$include_filename);
		}
		$include_filename = ___clean_up_dirs(File::Spec->canonpath($include_filename)); # delete up dirs from path
		unless(___under_root($root_path,$include_filename) && (-r $include_filename)) {
			$text = $pre_inc;
			if($debug) {
				$text .=
				"File '$include_filename' can't be included" .
				" in this document because of wrong file path";
			}
			$text .= $post_inc;
		} else {
			my $in = '';
			local($/) = undef;
			open IN, "< $include_filename";
			$in = <IN>;
			close IN;
			my $new_cur_path = ___get_dir($include_filename);
			$text = $pre_inc . ___read_includes($in,$new_cur_path,$root_path) . $post_inc;
		}
	}
	return $text;
}

sub ___clean_up_dirs {
	my $path = shift;
	my ($vol, $dirs, $file) = File::Spec->splitpath( $path, 1 );
	my @path = File::Spec->splitdir( $dirs );
	my $i;

	for($i = 0; $i<$#path; $i++) {
		if($path[$i] eq File::Spec->updir()) {
			if($i) { # not first folder
				$i--; # go 1 step up
			} else { # first folder
				shift @path;
			}
			redo;
		}
		if($path[$i+1] eq File::Spec->updir()) {
			splice @path, $i, 2;
			redo;
		}
	}

	return File::Spec->catpath($vol,File::Spec->catdir(@path),$file);
}


sub ___under_root {
	my $root = shift;
	my $file = shift;

	return $file =~ /^($root)/;
}

sub ___get_dir {
	my $path = shift;
	my ($vol, $dirs, $file) = File::Spec->splitpath( $path );

	return File::Spec->catpath($vol,$dirs,''); # remove file
}



sub parse {
	my $self = shift;
	my $data = shift || {};
	my $res;

	$res = ___parse_data($self->{___template___},$data,$self->{___params}->{BlockTag});
	$res =~ s/<%.*?%>//g unless $self->{___params}->{NoClean};

	return $res;
}

sub ___parse_template {
	my $text = shift;
	my $block_tag = shift;
	my $cur_path = shift;
	my $root_path = shift;
	my $tmp = {___text___=>'',___blocks___=>{}};
	while($text) {
		if($text =~ m/<!--($block_tag)\s+(.+?)-->(.*?)<!--\/\1\s+?\2-->/s) {
			my $block_name = $2;
			my $block_text = $3;
			$tmp->{___text___} .= $PREMATCH;
			$text = $POSTMATCH;
			$tmp->{___text___} .= "<!--${block_tag}_parsed $block_name-->";
			$tmp->{___blocks___}->{$block_name} = ___parse_template($block_text,$block_tag);
		} else {
			$tmp->{___text___} .= $text;
			$text = undef;
		}
	}
	return $tmp;
}

sub ___parse_data {
	my $template = shift || {};
	my $data = shift || {};
	my $block_tag = shift;
	my $text_level = $template->{___text___};
	my $text_result = '';
	my %data = ();
	my %blocks = ();
	my $key;
	foreach $key (keys %$data) {
		if(ref $data->{$key}) {
			$blocks{$key} = $data->{$key};
		} else {
			$data{$key} = $data->{$key};
		}
	}
	while($text_level) {
		if($text_level =~ m/<!--(${block_tag}_parsed) (.+?)-->/s) {
			my $block_name = $2;
			my $block;
			$text_result .= $PREMATCH;
			$text_level = $POSTMATCH;
			foreach $block (@{$blocks{$block_name}}) {
				$text_result .= "<!--BlockParsed $block_name-->" if $debug;
				$text_result .= ___parse_data($template->{___blocks___}->{$block_name},$block,$block_tag);
				$text_result .= "<!--/BlockParsed $block_name-->" if $debug;
			}
		} else {
			$text_result .= $text_level;
			$text_level = undef;
		}
	}

	# put local macro value or leave for global value changes
	$text_result =~ s/<%\s*(.+?)\s*%>/(exists $data{$1}) ?  $data{$1} : "<% $1 %>"/ge;
	return $text_result;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

CGI::okTemplate - Perl extension for easy creating websites with using templates

=head1 SYNOPSIS

  use CGI::okTemplate;
  my $tmp = new CGI::okTemplate();
  $tmp->read_template('t/test.tpl');
  print $tmp->parse($data);

or

  use CGI::okTemplate;
  my $tmp = new CGI::okTemplate(File=>'t/test.tpl');
  print $tmp->parse($data);

=head1 DESCRIPTION

This is an object oriented template module which parses template files
and puts data instead of macros.

Template document can have 3 types of special TAGs:

=item <% {macroname} %>

	{macroname} - name of variable which will be changed to its value

	if {macroname} undefined in currect block
	it will be changed in outer block.
	if {macroname} undefined in outer block also 
	then this tag will be erased from document 
	if function 'new' not receives parameter 'NoClean' 
	or leave as is if parameter 'NoClean' not used

	you can put spaces between '<%' and '{macroname}' and '%>'

=item <!--Include {filename}-->

	this tag includes file named {filename} into current
	template file.

	{filename} can be relative (to current template path) 
	or absolute path to the file

=item <!--{BlockTag} {blockname}-->...<!--/{BlockTag} {blockname}-->

	this tag defines the start and end of the block
	{BlockTag} can be defined in function 'new' by parameter 'BlockTag'
	default {BlockTag} is 'TemplateBlock'

	{blockname} is the name of block.


=head1 FUNCTIONS

=item new

	creates new template object

	use CGI::okTemplate;
	my $tmp = new CGI::okTemplate();

	Possible parameters:
		BlockTag - defines the key work for block tags
		File - path to template file (relative or absolute)
		RootDir - dir where all templates have to be under (default is current dir)
		NoClean - says to not clean tags for undefined variables
		Debug - says to put an info into parsed document


=head1 OBJECT FUNCTIONS

=item read_template($filename)

	defines template file named $filename to he template object
	this function will overwrite the template data defined in 'new' function
	if that function received 'File' parameter

=item parse($data)

	parses template with data sctructure $data

	$data is the hash reference (see the section DATA STRUCTURE)

=head1 DATA STRUCTURE

Data for template is the hash reference.

Hash can have 2 types of value for each key.

	1) string value - it means that this element
has value for {macroname} of current (or inner) block;

	2) array reference - it means that this element
has array of data for block named my key name;

Example :

 Perl Code (example1.pl): 
 -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 #!/usr/bin/perl
 use CGI::okTemplate;
 my $tmpl = new CGI::Template(	File=>'templates/example1.tpl',
				BlockTag=>'Block');

 $data = {
	header => 'value for "header" macro',
	footer => 'value for "footer" macro',
	row => [
		{value => 'value1',},
		{value => 'value2',},
		{value => 'value3',},
	],
 };
 -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

Template File (templates/example1.tpl):
 -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 <%header%>
 <!--Block row--><%value%><!--/Block row-->
 <%footer%>
 -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

The result have to be:
 -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 value for "header" macro
 value1
 value2
 value3
 value for "footer" macro
 -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

As we can see row has reference to the array of simple data structures for block named 'row'
This array has 3 elemens. So this block will be parsed 3 times.

See example folder for examples.

=head2 EXPORT

None by default.



=head1 SEE ALSO

examples/*.pl - for scripts

examples/templates/* - for templates



A mailing list for this module not opened yet.

A web site for this and other my modules is under construction.

=head1 AUTHOR

Oleg Kobyakovskiy, E<lt>ok.perl &at; gmail &dot; comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Oleg Kobyakovskiy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
