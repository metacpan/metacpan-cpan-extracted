#=Copyright Infomation
#==========================================================
#Module Name       : Config::IniMan
#Program Author   : Dr. Ahmed Amin Elsheshtawy, Ph.D. Physics, E.E.
#Home Page           : http://www.mewsoft.com
#Contact Email      : support@mewsoft.com
#Copyrights © 2014 Mewsoft. All rights reserved.
#==========================================================
package Config::IniMan;

use strict;
use warnings;
use Tie::IxHash;
use utf8;

our $VERSION = '1.20';
#=========================================================#
=encoding utf-8

=head1 NAME

Config::IniMan - INI file manager object style preserved format and sort order.

=head1 SYNOPSIS

	use Config::IniMan;
	
	# Create the config object and load it from a file
	my $config = Config::IniMan->new("sample.ini");
	
	# Create the config object and load it from a file with specific encoding
	my $config = Config::IniMan->new("sample.ini", "utf8");
	
	# Create empty config object
	my $config = Config::IniMan->new();
	
	# then load the config file
	$config->read("sample.ini");
	
	#read file in specific encoding
	$config->read("sample.ini", "utf8");
	
	# parameters values can be obtained as object methods. getter/setter style.
	# get the parameter 'website' value from current or default section.
	my $value = $config->website; 
	# same as
	my $value = $config->get("website"); 
	# set parameter 'website' value as a setter object method
	$config->website("http://mewsoft.com"); 
	
	# get parameter value from default or current section
	my $value = $config->get("name"); 
	# get parameter value from a section
	my $value = $config->get("section", "name");
	# get parameter value from a section and return default value if it does not exist
	my $value = $config->get("section", "name", "default");
	
	# change parameter value in the current or default section
	$config->set("name", "value");
	# change parameter value in a section
	$config->set("section", "name", "value");

	# add a new section at the end of the file
	$config->add_section("section");
	
	#set current active section
	$config->section(); # set current section to default section
	$config->section("section");
	# set current section and get a parameter value from it.
	$value = $config->section("section")->get("name");
	
	# get entire section as a hash reference
	$section = $config->get_section();# default section
	$section = $config->get_section("section");
	print $section->{"merchant"};
	
	# get all sections names
	@sections = $config->sections();
	
	# get all section params
	@params = $config->section_params("section");

	# get all section values
	@params = $config->section_values("section");

	#delete section params
	$config->delete("section", @name);
	
	#delete entire section
	$config->delete_section("section");
	
	#check if parameter exists
	$found  = $config->exists("name"); # check parameter name exists in the current section.
	$found  = $config->exists("section", "name");
	
	#check if section exists
	$found  = $config->section_exists("section");
	
	#Returns entire ini file contents in memory as single string with format preserved.
	$ini_data = $config->as_string();
	
	#writes entire ini contents in memory to a file.
	$config->write(); # save changes to the currently loaded file.
	$config->write("newfile"); # save as a new file.
	$config->write("newfile", "utf8"); # save as a new file in different encoding.


=head1 DESCRIPTION

This module reads and writes INI files in object style and preserves original files sort order, comments, empty lines, and multi lines parameters.

It is basically built on the top of using the L<Tie::IxHash> module which implements Perl hashes that preserve the order in which the hash 
elements were added. The order is not affected when values corresponding to existing sections or parameters are changed.

New sections will be added to the end of the current file contents and new parameters will be added to the end of the current section.

=head2 INI Format Sample

	;default section without name. this line is a comment
	#this line also is another comment
	title=Hellow world
	name=Ahmed Amin Elsheshtawy
	email=support@mewsoft.com
	website=http://www.mewsoft.com
	;
	;line below is empty line and is allowed

	;database settings
	[database]
	name=blog
	user=user1234
	password=blog1234

	;admin login
	[admin]
	username=admin
	password=admin123

	# paypal account setting
	[payment]
	merchant=paypal
	email=support@mewsoft.com

	[multil-line-data]
	ftp_msg=This is the ftp address of the domain where\
	the software will be installed. Either use domain name\
	or IP address, for example ftp.yourdomain.com is the \
	ftp address and 234.453.213.32 is the IP number.
	;
	[lastlogin]
	time=5/9/2014=Friday
	;
	# utf8 Arabic section
	[عربى]
	الأسم=أحمد امين الششتاوى

=cut
#=========================================================#
sub AUTOLOAD {
my ($self) = shift;

    my ($class, $method) = our $AUTOLOAD =~ /^(.*)::(\w+)$/;

    if ($self->can($method)) {
		return $self->$method(@_);
    }

	if (@_) {
		# set parameter value in the current section
		$self->{data}->{$self->{section}}->{$method} = $_[0];
		return $self;
	}
	else {
		# return parameter value from current section
		return $self->{data}->{$self->{section}}->{$method};
	}
}
#=========================================================#
=head2 new()

	use Config::IniMan;

	# Create the config object and load it from a file
	my $config = Config::IniMan->new("sample.ini");

	# Create the config object and load it from a file with specific encoding
	my $config = Config::IniMan->new("sample.ini", "utf8");

	# Create empty config object
	my $config = Config::IniMan->new();

	# then load the config file
	$config->read("sample.ini");

	#read file in specific encoding
	$config->read("sample.ini", "utf8");

Create the config object and load it from a file if provided with specific encoding.

=cut
sub new {
my ($self, $file, $encoding) = @_;
    
	$self = bless {}, $self;
	
	$self->{encoding} = $encoding;
	$self->{file} = $file;
	$self->{section} = "_"; # default section name
	$self->{data} = {};
	$self->{counter} = 0;

	$self->read($self->{file}) if ($self->{file});

    return $self;
}
#=========================================================#
=head2 read()

	use Config::IniMan;

	# Create empty config object
	my $config = Config::IniMan->new();

	# then load the config file
	$config->read("sample.ini");

	#read file in specific encoding
	$config->read("sample.ini", "utf8");

Read and parse ini file contents in specific encoding.

=cut
sub read {
	my $self = shift;
	my $file = shift;
	if (@_) {
		$self->encoding(shift);
	}

	my $encoding  = $self->encoding? "<:".$self->encoding : '<';
	local $/= undef;
	
	open (my $fh, $encoding, $file) or return ("Error reading file $file: $!");
	my $content = <$fh>;
	close ($fh);

	$self->parse($content);
	$self->{file} = $file;
}
#=========================================================#
sub parse {
my ($self, $content) = @_;
	
	my @lines =  split (/(?:\015{1,2}\012|\015|\012)/, $content);
	
	my $section = "_"; # default section name, not written to file
	
	$self->{counter} = 0;

	no strict 'subs';
	
	# sections sorted hash
	tie %{$self->{data}}, Tie::IxHash;
	
	# default section variables sorted hash
	tie %{$self->{data}->{$section}}, Tie::IxHash;
	
	my ($name, $value, $multiline);

	$multiline = 0;

	# process data
	foreach my $line (@lines) {
		
		$self->{counter}++;
		# keep comments and empty lines
		if ($line =~ /^\s*(?:\#|\;|$)/ ) {
			$self->{data}->{$section}->{"__SKIP__$self->{counter}"} = $line;
			next;
		}

		# sections names
		if ($line =~ /^\s*\[\s*(.+?)\s*\]\s*$/) {
			$section = $1;
			# add new section variables sorted hash
			tie %{$self->{data}->{$section}}, Tie::IxHash;
			next;
		}

		# section variables key, value pairs key=value
		if ($multiline) {
			$multiline = 0;
			if ($line =~ /\\$/) {
				$multiline = 1;
				$line =~ s/\\$//;
			}
			$self->{data}->{$section}->{$name} .= $line;
			next;
		}
		elsif ($line =~ /^\s*([^=]+?)\s*=\s*(.*?)\s*$/) {
			($name, $value) = ($1, $2);
			$multiline = 0;
			if ($value =~ /\\$/) {
				$multiline = 1;
				$value =~ s/\\$//;
			}
			$self->{data}->{$section}->{$name} = $value;
			next;
		}
		
		# TODO error formated line here, heredocs if needed etc
	}# @lines
}
#=========================================================#
=head2 encoding()
	
	$encoding = $config->encoding();
	$config->encoding("utf8"); # set encoding

Gets and sets the default file read and write encoding.

=cut
sub encoding {
	my $self = shift;
	$self->{encoding} = shift if (@_);
	$self->{encoding};
}
#=========================================================#
=head2 clear()
	
	$config->clear();

Deletes entire file contents from memory. Does not save to the file.

=cut
sub clear {
my ($self) = @_;
	$self->{data} = {};
	$self->{file} = "";
	$self->{section} = "_";
	$self->{counter} = 0;
}
#=========================================================#
=head2 get()

	$value = $config->get("name"); # get parameter value from default or current section
	$value = $config->get("section", "name");
	$value = $config->get("section", "name", "default");

	# parameters values can be obtained as object methods. getter/setter style.
	# get the parameter 'website' value from current or default section.
	my $value = $config->website; 
	# same as
	my $value = $config->get("website"); 
	# set parameter 'website' value as a setter object method
	$config->website("http://mewsoft.com"); 

Gets parameter value. Returns the value of a parameter by its name. If you pass only the parameter name, it will search within the 
current section or the default section. You can pass also a default value to be returned if parameter does not exist.

=cut
sub get {
	my $self = shift;
	my ($section, $name, $default) = "";
	if (@_ == 1) {
		$name = shift;
		$section = $self->{section};
	}
	elsif (@_ == 2) {
		($section, $name) = @_;
	}
	else {
		($section, $name, $default) = @_;
	}
	
	$section ||= $self->{section};
	
	if (exists $self->{data}->{$section}->{$name}) {
		return $self->{data}->{$section}->{$name};
	}

	return $default;
}
#=========================================================#
=head2 set()
	
	$config->set("name", "value"); # sets parameter value in the current or default section
	$config->set("section", "name", "value");

	# set parameter 'website' value as a setter object method
	$config->website("http://mewsoft.com");

Sets parameter value. Adds new section if section does not exist. This method is chained.

=cut
sub set {
	my $self = shift;
	my ($section, $name, $value) = "";
	if (@_ == 2) {
		($name, $value) = @_;
		$section = $self->{section};
	}
	else {
		($section, $name, $value) = @_;
	}

	$section ||= "_";

	if (!$self->section_exists($section)) {
		$self->add_section($section);
	}

	$self->{data}->{$section}->{$name} = $value;
	$self;
}
#=========================================================#
=head2 add_section()
	
	$config->add_section("section");

Adds new section to the end of the file if it does not exist. This method is chained.

=cut
sub add_section {
my ($self, $section) = @_;

	$section ||= "_";
	no strict 'subs';
	if (!$self->section_exists($section)) {
		tie %{$self->{data}->{$section}}, Tie::IxHash;
	}
	
	$self;
}
#=========================================================#
=head2 section()
	
	$config->section(); # set current section to default section
	$config->section("section");
	# set current section and get a parameter value from it.
	$value = $config->section("section")->get("name");

Sets current active section. If empty section name is passed, will set the default section as current one. This method is chained.

=cut
sub section {
my ($self, $section) = @_;
	$section ||= "_";
	if ($self->section_exists($section)) {
		$self->{section} = $section;
		return $self->{data}->{$section};
	}
}
#=========================================================#
=head2 get_section()
	
	$section = $config->get_section();# default section
	$section = $config->get_section("section");
	print $section->{"email"};

Returns entire section as a hash ref if exists.

=cut
sub get_section {
my ($self, $section) = @_;
	$section ||= "_";
	if ($self->section_exists($section)) {
		return $self->{data}->{$section};
	}
}
#=========================================================#
=head2 sections()
	
	@sections = $config->sections();

Returns array of sections names in the same sorted order in the file.

=cut
sub sections {
my ($self) = @_;
	(keys %{$self->{data}});
}
#=========================================================#
=head2 section_params()
	
	@params = $config->section_params("section");

Returns array of section parameters names in the same sorted order in the file.

=cut
sub section_params {
my ($self, $section) = @_;
	
	$section ||= $self->{section};
	(keys %{$self->{data}->{$section}});
}
#=========================================================#
=head2 section_values()
	
	@values = $config->section_values(); # get current or default section values
	@values = $config->section_values("section");

Returns array of section parameters values in the same sorted order in the file.

=cut
sub section_values {
my ($self, $section) = @_;
	(values %{$self->{data}->{$section}});
}
#=========================================================#
=head2 delete()
	
	$config->delete("section", @name);

Delete section parameters. This method is chained.

=cut
sub delete {
my ($self, $section, @name) = @_;
	$section ||= "_";
	delete $self->{data}->{$section}->{$_} for @name;
	$self;
}
#=========================================================#
=head2 delete_section()
	
	$config->delete_section();# delete default section
	$config->delete_section("section");

Delete entire section if it exist. This method is chained.

=cut
sub delete_section {
my ($self, $section) = @_;
	$section ||= "_";
	delete $self->{data}->{$section};
	$self;
}
#=========================================================#
=head2 exists()
	
	$found  = $config->exists("name"); # check parameter name exists in the current section.
	$found  = $config->exists("section", "name");

Checks if parameter exists. If no section passed, it will check in the current of default section.

=cut
sub exists {
	my $self = shift;
	my ($section, $name);
	if (@_ == 1) {
		$name = shift;
		$section = $self->{section};
	}
	else {
		($section, $name) = @_;
	}
	$section ||= "_";
	exists $self->{data}->{$section}->{$name};
}
#=========================================================#
=head2 section_exists()
	
	$found  = $config->section_exists("section");

Checks if section exists.

=cut
sub section_exists {
my ($self, $section) = @_;
	$section ||= "_";
	exists $self->{data}->{$section};
}
#=========================================================#
=head2 as_string()
	
	$ini_data = $config->as_string();

Returns entire ini file contents in memory as single string with format preserved.

=cut
sub as_string {
my ($self) = @_;
	
	my $content = "";
	
	my $v;
	foreach my $section (keys %{$self->{data}}) {
		$content .= "[$section]\n" unless ($section eq "_");

		foreach my $k (keys %{$self->{data}->{$section}}) {
			$v =$self->{data}->{$section}->{$k};
			if ($k =~ /^__SKIP__\d+$/) {
				$content .= "$v\n";
				next;
			}
			else {
				$content .= "$k=$v\n";
			}
		}
	}
	
	return $content;
}
#=========================================================#
=head2 write()
	
	$config->write(); # save changes to the currently loaded file.
	$config->write("newfile"); # save as a new file.
	$config->write("newfile", "utf8"); # save as a new file in different encoding.

Writes entire ini file contents in memory to file.

=cut
sub write {
	my $self= shift;
	my $file = shift if (@_);
	$self->encoding(shift) if (@_);
	
	$file or return ("Empty file name during writing file: $!");

	my $encoding  = $self->encoding? ">:".$self->encoding : '>';
	local $/= undef;
	
	open(my $fh, $encoding, $file) or return ("Error writing file $file: $!");
	print $fh $self->as_string;
	close($fh);
}
#=========================================================#
#TODO
#sub rename {
#my ($self, $section, $key, $newkey) = @_;
#}
#=========================================================#
#TODO
#sub rename_section {
#my ($self, $section, $newsection) = @_;
#}
#=========================================================#
#TODO
#sub set_section_comment {
#my ($self, $section, @comment) = @_;
#}
#=========================================================#
#TODO
#sub get_section_comment {
#my ($self, $section, @comment) = @_;
#}
#=========================================================#
#TODO
#sub del_section_comment {
#my ($self, $section, @comment) = @_;
#}
#=========================================================#
sub DESTROY {
}
#=========================================================#
#=========================================================#
1;


=head1 Bugs

This project is available on github at L<https://github.com/mewsoft> .

=head1 SEE ALSO

L<Config::Tiny>
L<Config::IniFiles>
L<Config::INI>
L<Config::INIPlus>
L<Config::Any>
L<Config::General>

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  احمد امين الششتاوى <support@mewsoft.com>
Website: http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Dr. Ahmed Amin Elsheshtawy support@mewsoft.com,
L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

