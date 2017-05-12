package Asterisk::config;
#--------------------------------------------------------------
#
#	Asterisk::config - asterisk config files read and write
#
#	Copyright (C) 2005 - 2008, Sun bing.
#
#	Sun bing <hoowa.sun@gmail.com>
#
#
#   LICENSE
#   The Asterisk::config is licensed under the GNU 2.0 GPL. 
#   Asterisk::config carries no restrictions on re-branding
#   and people are free to commercially re-distribute it.
#
#
#--------------------------------------------------------------
$Asterisk::config::VERSION='0.97';

use strict;
use Fcntl ':flock';

##############################
#  CLASS METHOD
sub new {
my	$class = shift;
my	%args = @_;
my	(@resource_list,$resource_list,$parsed_conf,$parsed_section_chunk,$comment_flag);

	#try read
	return(0) if (!defined $args{file});
	return(0) if (!-e $args{file});
	if (defined $args{'stream_data'}) {
		@resource_list = split(/\n/,$args{'stream_data'});
	} else {
		open(DATA,"<$args{'file'}") or die "Asterisk-config Can't Open file : $!";
		@resource_list = <DATA>;
		close(DATA);
	}
	chomp(@resource_list);
	#try parse
	$comment_flag = '\;|\#';
	($parsed_conf,$parsed_section_chunk) = &_parse(\@resource_list,$comment_flag,$args{'section_chunk'});

	#try define default variable
	$args{'keep_resource_array'} = 1 if (!defined $args{'keep_resource_array'});
	if (defined $args{'keep_resource_array'} && $args{'keep_resource_array'}) {
		$resource_list = \@resource_list;
	}
	if (!defined $args{'clean_when_reload'}) {
		$args{'clean_when_reload'} = 1;
	}
	if (!defined $args{'reload_when_save'}) {
		$args{'reload_when_save'} = 1;
	}

my	$self = {
		#user input
		file=> $args{'file'},
		keep_resource_array=> $args{'keep_resource_array'},
		clean_when_reload=> $args{'clean_when_reload'},
		reload_when_save=> $args{'reload_when_save'},

		#internal
		commit_list => [],
		parsed_conf=> $parsed_conf,
		parsed_section_chunk=> $parsed_section_chunk,
		resource_list=> $resource_list,
		comment_flag=> $comment_flag,
	};
	bless $self,$class;
	return $self;
}

##############################
#  INTERNAL SUBROUTE _parse
# parse conf
sub _parse {
my	$resource_list = $_[0];
my	$comment_flag = $_[1];
my	$section_chunk = $_[2];

my (%DATA,$last_section_name,%DATA_CHUNK);
	$DATA{'[unsection]'}={};	$DATA_CHUNK{'[unsection]'}={} if ($section_chunk);
	foreach my $one_line (@$resource_list) {
	my	$line_sp=&_clean_string($one_line,$comment_flag);

		#format : Find New Section ???
		if ($line_sp =~ /^\[(.+)\]/) {
			$DATA{$1}={};			$last_section_name = $1;
			$DATA_CHUNK{$1}=[] if ($section_chunk);
			next;

		#save source chunk to data_chunk
		} elsif ($section_chunk) {
			next if ($one_line eq '');
		my	$section_name = $last_section_name;
			$section_name = '[unsection]' if (!$section_name);
			#copying source chunk to data_chunk
			push(@{$DATA_CHUNK{$section_name}},$one_line);
		}

		next if ($line_sp eq '');#next if just comment

		#fromat : Include "#" ???
		if ($line_sp =~ /^\#/) {
		my	$section_name = $last_section_name;
			$section_name = '[unsection]' if (!$section_name);
			$DATA{$section_name}{$line_sp}=[] if (!$DATA{$section_name}{$line_sp});
			push(@{$DATA{$section_name}{$line_sp}},$line_sp);
			next;
		}

		#format : Key=Value ???
		if ($line_sp =~ /\=/) {
			#split data and key
		my	($key,$value)=&_clean_keyvalue($line_sp);

		my	$section_name = $last_section_name;
			$section_name = '[unsection]' if (!$section_name);
			$DATA{$section_name}{$key}=[] if (!$DATA{$section_name}{$key});
			push(@{$DATA{$section_name}{$key}},$value);
			next;
		}
	}

return(\%DATA,\%DATA_CHUNK);
}

##############################
#  INTERNAL SUBROUTE _clean_string
# clean strings
sub _clean_string {
my	$string = shift;
my	$comment_flag = shift;
	return '' unless $string;
	if ($string !~ /^\#/) {
		($string,undef)=split(/$comment_flag/,$string);
	}
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
return($string);
}

##############################
#  INTERNAL SUBROUTE _clean_string
# split key value of data
sub _clean_keyvalue {
my	$string = shift;
my	($key,$value)=split(/\=(.*)/,$string);
	$key =~ s/^(\s+)//;		$key =~ s/(\s+)$//;
	if ($value) {
		$value=~ s/^\>//g;		$value =~ s/^(\s+)//;	$value =~ s/(\s+)$//;
	}

return($key,$value);
}

##############################
#  READ METHOD
sub get_objvar
{
my	$self = shift;
my	$varname = shift;
	if (defined $self->{$varname}) {
		return($self->{$varname});
	} else {
		return(0);
	}
}

sub fetch_sections_list
{
my	$self = shift;
my	@sections_list = grep(!/^\[unsection\]/, keys %{$self->{parsed_conf}});
return(\@sections_list);
}

sub fetch_sections_hashref
{
my	$self = shift;
return($self->{parsed_conf});
}

sub fetch_keys_list
{
my	$self = shift;
my	%args = @_;
	return(0) if (!defined $args{section});
	return(0) if (!defined $self->{parsed_conf}{$args{section}});

my	@keys_list = grep(!/^\[unsection\]/, keys %{$self->{parsed_conf}{$args{section}}});
return(\@keys_list);
}

sub fetch_keys_hashref
{
my	$self = shift;
my	%args = @_;
	return(0) if (!defined $args{section});
	return(0) if (!defined $self->{parsed_conf}{$args{section}});

return($self->{parsed_conf}{$args{section}});
}

sub fetch_values_arrayref
{
my	$self = shift;
my	%args = @_;
	return(0) if (!defined $args{section});
	return(0) if (!defined $self->{parsed_conf}{$args{section}});
	return(0) if (!defined $args{key});
	return(0) if (!defined $self->{parsed_conf}{$args{section}}{$args{key}});

return($self->{parsed_conf}{$args{section}}{$args{key}});
}

sub reload
{
my	$self = shift;

	#try read
	return(0) if (!defined $self->{file});
	return(0) if (!-e $self->{file});
	open(DATA,"<$self->{'file'}") or die "Asterisk-config Can't Open file : $!";
my	@resource_list = <DATA>;
	close(DATA);
	chomp(@resource_list);

	# save to parsed_conf
my	($parsed_conf,$conf_chunk_ignored) = &_parse(\@resource_list,$self->{comment_flag});
	$self->{parsed_conf} = $parsed_conf;

	# save to resource_list
my	$resource_list;
	if (defined $self->{'keep_resource_array'} && $self->{'keep_resource_array'}) {
		$resource_list = \@resource_list;
	}
	$self->{resource_list} = $resource_list;

	# save to commit_list / do clean_when_reload ?
	if (defined $self->{'clean_when_reload'} && $self->{'clean_when_reload'}) {
		&clean_assign($self);
	}


return(1);
}

##############################
#  WRITE METHOD

sub clean_assign
{
my	$self = shift;
#	undef($self->{commit_list});
	$self->{commit_list}=[];
return(1);
}

sub set_objvar
{
my	$self = shift;
my	$key = shift;
my	$value = shift;

	return(0) if (!defined $value);
	return(0) if (!exists $self->{$key});
	$self->{$key} = $value;

return(1);
}

#-----------------------------------------------------------
#  assign method to commit_list
sub assign_cleanfile
{
my	$self = shift;
my	%hash = @_;
	$hash{'action'}='cleanfile';
	push(@{$self->{commit_list}},\%hash);
}

sub assign_matchreplace
{
my	$self = shift;
my	%hash = @_;
	$hash{'action'}='matchreplace';
	push(@{$self->{commit_list}},\%hash);
}

sub assign_append
{
my	$self = shift;
my	%hash = @_;
	$hash{'action'}='append';
	push(@{$self->{commit_list}},\%hash);
}

sub assign_replacesection
{
my	$self = shift;
my	%hash = @_;
	$hash{'action'}='replacesection';
	push(@{$self->{commit_list}},\%hash);
}

sub assign_delsection
{
my	$self = shift;
my	%hash = @_;
	$hash{'action'}='delsection';
	push(@{$self->{commit_list}},\%hash);
}

sub assign_addsection
{
my	$self = shift;
my	%hash = @_;
	$hash{action} = 'addsection';
	push(@{$self->{commit_list}}, \%hash);
}

sub assign_editkey
{
my	$self = shift;
my	%hash = @_;
	$hash{'action'}='editkey';
	push(@{$self->{commit_list}},\%hash);
}

sub assign_delkey
{
my	$self = shift;
my	%hash = @_;
	$hash{'action'}='delkey';
	push(@{$self->{commit_list}},\%hash);
}

#-----------------------------------------------------------
#  save method and save internal method
#  filename: run assign rules and save to file
#  save_file();
sub save_file
{
my	$self = shift;
my	%opts = @_;

	return if ($#{$self->{commit_list}} < 0);

my	$used_resource;
	#check to use resource_list?
	if (defined $self->{'keep_resource_array'} && $self->{'keep_resource_array'}) {
#		$used_resource = $self->{resource_list};
		$used_resource = [ @{ $self->{resource_list} } ];
	}

	if (!defined $used_resource) {
		open(DATA,"<$self->{'file'}") or die "Asterisk-config can't read from $self->{file} : $!";
	my	@DATA = <DATA>;
		close(DATA);
		chomp(@DATA);
		$used_resource = \@DATA;
	}

	foreach my $one_case (@{$self->{commit_list}}) {
		$used_resource = &_do_editkey($one_case,$used_resource,$self) if ($one_case->{'action'} eq 'editkey' || $one_case->{'action'} eq 'delkey');
		$used_resource = &_do_delsection($one_case,$used_resource,$self) if ($one_case->{'action'} eq 'delsection' || $one_case->{'action'} eq 'replacesection');
		$used_resource = &_do_addsection($one_case,$used_resource,$self) if ($one_case->{'action'} eq 'addsection');
		$used_resource = &_do_append($one_case,$used_resource,$self) if ($one_case->{'action'} eq 'append');
		$used_resource = &_do_matchreplace($one_case,$used_resource,$self) if ($one_case->{'action'} eq 'matchreplace');
		if ($one_case->{'action'} eq 'cleanfile') {
			undef($used_resource);
			last;
		}
	}


	#save file and check new_file
	if (defined $opts{'new_file'} && $opts{'new_file'} ne '') {
		open(SAVE,">$opts{'new_file'}") or die "Asterisk-config Save_file can't write : $!";
	} else {
		open(SAVE,">$self->{'file'}") or die "Asterisk-config Save_file can't write : $!";
	}
	flock(SAVE,LOCK_EX);
	print SAVE grep{$_.="\n"} @{$used_resource};
	flock(SAVE,LOCK_UN);
	close(SAVE);

	#reload when save
	if (defined $self->{'reload_when_save'} && $self->{'reload_when_save'}) {
		&reload($self);
	}

return();
}

sub _do_editkey
{
my	$one_case = shift;
my	$data = shift;
my	$class_self = shift;

my	@NEW;
my	$last_section_name='[unsection]';
my	$auto_save=0;

	foreach my $one_line (@$data) {

		#tune on auto save
		if ($auto_save) {			push(@NEW,$one_line);			next;		}

		my $line_sp=&_clean_string($one_line,$class_self->{comment_flag});

		#income new section
		if ($line_sp =~ /^\[(.+)\]/) {
			$last_section_name = $1;
		} elsif ($last_section_name eq $one_case->{section} && $line_sp =~ /\=/) {

			#split data and key
			my ($key,$value)=&_clean_keyvalue($line_sp);

			if ($key eq $one_case->{'key'} && $one_case->{'value_regexp'} && !$one_case->{'value'}) {
				$value =~ /(.+?)\,/;
				if ($one_case->{'action'} eq 'delkey' && $1 eq $one_case->{'value_regexp'}){	undef($one_line);	}

			} elsif ($key eq $one_case->{'key'} && !$one_case->{'value'}) {			#处理全部匹配的key的value值
				if ($one_case->{'action'} eq 'delkey') {	undef($one_line);	}
				else {	$one_line = "$key=".$one_case->{'new_value'};	}
#				$one_line = "$key=".$one_case->{'new_value'};
#				undef($one_line) if ($one_case->{'action'} eq 'delkey');
			} elsif ($key eq $one_case->{'key'} && $one_case->{'value'} eq $value) {	#处理唯一匹配的key的value值
				if ($one_case->{'action'} eq 'delkey') {	undef($one_line);	}
				else {	$one_line = "$key=".$one_case->{'new_value'};	}
#				$one_line = "$key=".$one_case->{'new_value'};
#				undef($one_line) if ($one_case->{'action'} eq 'delkey');
				$auto_save = 1;
			}
		}

		push(@NEW,$one_line) if (defined $one_line);
	}

return(\@NEW);
}

sub _do_delsection
{
my	$one_case = shift;
my	$data = shift;
my	$class_self = shift;

my	@NEW;
my	$last_section_name='[unsection]';
my	$auto_save=0;

	push(@NEW,&_format_convert($one_case->{'data'})) 
		if ($one_case->{'section'} eq '[unsection]' and $one_case->{'action'} eq 'replacesection');

	foreach my $one_line (@$data) {

		#tune on auto save
		if ($auto_save) {			push(@NEW,$one_line);			next;		}

		my $line_sp=&_clean_string($one_line,$class_self->{comment_flag});

		if ($last_section_name eq $one_case->{'section'} && $line_sp =~ /^\[(.+)\]/) {
			#when end of compared section and come new different section
			$auto_save = 1;
		} elsif ($last_section_name eq $one_case->{'section'}) {
			next;
		} elsif ($line_sp =~ /^\[(.+)\]/) {
			#is this new section?
			if ($one_case->{'section'} eq $1) {
				$last_section_name = $1;
				next if ($one_case->{'action'} eq 'delsection');
				push(@NEW,$one_line);
				$one_line=&_format_convert($one_case->{'data'});
			}
		}

		push(@NEW,$one_line);
	}

return(\@NEW);
}

sub _do_addsection
{
my	$one_case = shift;
my	$data = shift;
my	$class_self = shift;

my	$exists = 0;
my	$section = '[' . $one_case->{section} . ']';
	
	foreach my $one_line(@$data) {

		my $line_sp=&_clean_string($one_line,$class_self->{comment_flag});
		if($line_sp =~ /^\[.+\]/) {

			if ($section eq $line_sp) {
				$exists = 1;
				last;
			}
		}
	}
	unless($exists) {

		push(@$data, $section);
	}

return $data;
}

sub _do_append
{
my	$one_case = shift;
my	$data = shift;
my	$class_self = shift;
my	@NEW;

	if ((not exists $one_case->{'section'}) || ($one_case->{'section'} eq '')) {
	#Append data head of source data/foot of source data
		if ($one_case->{'point'} eq 'up') {
			push(@NEW,&_format_convert($one_case->{'data'}),@$data);
		} else {
			push(@NEW,@$data,&_format_convert($one_case->{'data'}));
		}

	} elsif (!defined $one_case->{'comkey'} || $one_case->{'comkey'} eq '') {
	#Append data head/foot of section_name
	my	$auto_save=0;
	my	$save_tmpmem=0;
	my	$offset=0;
		foreach my $one_line (@$data) {
			#tune on auto save
			if ($auto_save) {			push(@NEW,$one_line);			$offset++;	next;		}
			#check section
		my	$line_sp=&_clean_string($one_line,$class_self->{comment_flag});
		my	($section_name) = $line_sp =~ /^\[(.+)\]/;

			# for up / down
			if (defined $section_name && $one_case->{'section'} eq $section_name && $one_case->{'point'} eq 'up') {
				push(@NEW,&_format_convert($one_case->{'data'}));	$auto_save=1;
			} elsif (defined $section_name && $one_case->{'section'} eq $section_name && $one_case->{'point'} eq 'down') {
				push(@NEW,$one_line);	$one_line = join "\n", &_format_convert($one_case->{'data'});		$auto_save=1;
			# for foot matched section
			} elsif (defined $section_name && $one_case->{'section'} eq $section_name && $one_case->{'point'} eq 'foot') {
				$save_tmpmem=1;
			# for foot 发现要从匹配的section换成新section
			} elsif ($save_tmpmem == 1 && $section_name && $one_case->{'section'} ne $section_name) {
				push(@NEW,&_format_convert($one_case->{'data'}));	$auto_save=1;	$save_tmpmem=0;
			# for foot 发现匹配的section已经到达整个结尾
			} 
			if ($save_tmpmem == 1 && $offset==$#{$data}) {
				push(@NEW,$one_line);	$one_line = join "\n", &_format_convert($one_case->{'data'});
				$auto_save=1;	$save_tmpmem=0;
			}

			push(@NEW,$one_line);
			$offset++;
		}

	} else {

		my $last_section_name='[unsection]';
		my $auto_save=0;
		foreach my $one_line (@$data) {

			#tune on auto save
			if ($auto_save) {			push(@NEW,$one_line);			next;		}

			my $line_sp=&_clean_string($one_line,$class_self->{comment_flag});
			#income new section
			if ($line_sp =~ /^\[(.+)\]/) {
				$last_section_name = $1;
			} elsif ($last_section_name eq $one_case->{'section'} && $line_sp =~ /\=/) {
				#split data and key
				my ($key,$value)=&_clean_keyvalue($line_sp);
				if ($key eq $one_case->{comkey}[0] && $value eq $one_case->{comkey}[1] && $one_case->{'point'} eq 'up') {
					push(@NEW,&_format_convert($one_case->{'data'}));	$auto_save=1;
				} elsif ($key eq $one_case->{comkey}[0] && $value eq $one_case->{comkey}[1] && $one_case->{'point'} eq 'down') {
					push(@NEW,$one_line);	$one_line=&_format_convert($one_case->{'data'});
					$auto_save=1;
				} elsif ($key eq $one_case->{comkey}[0] && $value eq $one_case->{comkey}[1] && $one_case->{'point'} eq 'over') {
					$one_line=&_format_convert($one_case->{'data'});		$auto_save=1;
				}
			}
			push(@NEW,$one_line);
		}

	}

return(\@NEW);
}

# income scalar,array ref,hash ref output array data
sub _format_convert
{
my	$string = shift;
	if (ref($string) eq 'ARRAY') {
		return(@$string);
	} elsif (ref($string) eq 'HASH') {
		my @tmp;
		foreach  (keys(%$string)) {
			push(@tmp,"$_=".$string->{$_});
		}
		return(@tmp);
	} else {
		return($string);
	}
}

sub _do_matchreplace
{
my	$one_case = shift;
my	$data = shift;
my	$class_self = shift;
my	@NEW;

	foreach my $one_line (@$data) {
		if ($one_line =~ /$one_case->{'match'}/) {
			$one_line = $one_case->{'replace'};
		}
		push(@NEW,$one_line);
	}

return(\@NEW);
}

=head1 NAME

Asterisk::config - the Asterisk config read and write module.

=head1 SYNOPSIS

    use Asterisk::config;

    my $sip_conf = new Asterisk::config(file=>'/etc/asterisk/sip.conf');
    my $conference = new Asterisk::config(file=>'/etc/asterisk/meetme.conf',
                                              keep_resource_array=>0);

    $allow = $sip_conf->fetch_values_arrayref(section=>'general',key=>'allow');
    print $allow->[0];

    $sip_conf->assign_append(point=>'down',data=>"[userb]\ntype=friend\n");

    $sip_conf->save();


=head1 DESCRIPTION

Asterisk::config can parse and saving data with Asterisk config
files. this module support asterisk 1.0 1.2 1.4 1.6, and it also
support Zaptel config files.

=head1 Note

Version 0.9 syntax incompitable with 0.8.

=head1 CLASS METHOD

=head2 new

    $sip_conf = new Asterisk::config(file=>'file name',
                                     [stream_data=>$string],
                                     [object variable]);

Instantiates a new object of file. Reads data from stream_data or
file.


=head1 OBJECT VARIABLES

FIXME: should all of those be documented in the POD (rather than
in comments in the code?)

=head2 file

Config file name and path. Must be set.
If file does exists (exp. data from C<stream_data>), you will not
be able to save using L<save_file>.

=head2 keep_resource_array

use resource array when save make fast than open file, but need
more memory, default enabled. use set_objvar to change it.

=head2 reload_when_save

When save done, auto call .

Enabled by default. Use set_variable to change it.

FIXME: what is C<set_variable>?

=head2 clean_when_reload

When reload done, auto clean_assign with current object.

Enabled by default. Use L<set_objvar> to change it.

=head2 commit_list

Internal variable listed all command. 

=head2 parsed_conf

Internal variable of parsed. 


=head1 OBJECT READ METHOD

=head2 get_objvar

    $sip_conf->get_objvar(var_name);

Return defined object variables.

=head2 fetch_sections_list

    $sip_conf->fetch_sections_list();

List of sections (not including C<unsection>) in a file.

=head2 fetch_sections_hashref

    $sip_conf->fetch_sections_hashref();

Returns the config file parsed as a hash (section name -> section)
of lists (list of lines).

=head2 fetch_keys_list

    $sip_conf->fetch_keys_list(section=>[section name|unsection]);

Returns list of the kes in the keys in I<section name> (or
I<unsection>).

=head2 fetch_keys_hashref

    $sip_conf->fetch_keys_hashref(section=>[section name|unsection]);

Returns the section as a hash of key=>value pairs.

=head2 fetch_values_arrayref

    $sip_conf->fetch_values_arrayref(section=>[section name|unsection],
                                     key=>key name);

Returns a (reference to a) list of all the values a specific keys have
in a specific section. referenced value list, Returns 0 if section
was not found or key was not found in the section.

=head2 reload

    $sip_conf->reload();

Reloads and parses the config file.

If L<clean_when_reload> is true, will also do L<clean_assign>.

=head1 OBJECT WRITE METHOD

=head2 set_objvar

    $sip_conf->set_objvar('var_name'=>'value');

Set the object variables to new value.

=head2 assign_cleanfile

    $sip_conf->assign_cleanfile();

Resets all the non-saved changes (from other assign_* functions).

=head2 assign_matchreplace

    $sip_conf->assign_matchreplace(match=>[string],replace=>[string]);

replace new data when matched.

=over 2

=item * match -> string of matched data.

=item * replace -> new data string.

=back

=head2 assign_append

Used to add extra data to an existing section or to edit it.

    $sip_conf->assign_append(point=>['up'|'down'|'foot'],
                             section=>[section name],
                             data=>'key=value'|['key=value','key=value']|{key=>'value',key=>'value'});

This form is used to merely append new data.

=over 3

=item point 

Append data C<up> / C<down> / C<foot> with section.

=item section 

Matched section name, expect 'unsection'. If ommited, data will be
placed above first setcion, as in 'unsection', but then you cannot
use C<point=>"foot">.

=item data 

New replace data in string/array/hash.

=back

    $sip_conf->assign_append(point=>['up'|'down'|'over'],
                             section=>[section name],
                             comkey=>[key,value],
                             data=>'key=value'|['key=value','key=value']|{key=>'value',key=>'value'};

Appends data before, after or instead a given line. The line is
the first line in C<section> where the key is C<key> and the value
is C<value> (from C<comkey>.

=over 2

=item point 

C<over> will overwrite with key/value matched.

=item comkey 

Match key and value.

=back

=head2 assign_replacesection

    $sip_conf->assign_replacesection(section=>[section name|unsection],
                             data=>'key=value'|['key=value','key=value']|{key=>'value',key=>'value'});

replace the section body data.

=over 1

=item * section -> all section name and 'unsection'.

=back

=head2 assign_delsection

    $sip_conf->assign_delsection(section=>[section name|unsection]);

erase section name and section data.

=over 1

=item * section -> all section and 'unsection'.

=back

=head2 assign_addsection

    $sip_conf->assign_addsection(section=>[section]);

add section with name.

=over 1

=item * section -> name of new section.

=back

=head2 assign_editkey

    $sip_conf->assign_editkey(section=>[section name|unsection],key=>[keyname],value=>[value],new_value=>[new_value]);

modify value with matched section.if don't assign value=> will replace all matched key. 

warnning example script:

    $sip_conf->assign_editkey(section=>'990001',key=>'all',new_value=>'gsm');

data:

    all=g711
    all=ilbc

will convert to:

    all=gsm
    all=gsm


=head2 assign_delkey

    $sip_conf->assign_delkey(section=>[section name|unsection],key=>[keyname],value=>[value]);

erase all matched C<keyname> in section or in 'unsection'.

    $sip_conf->assign_delkey(section=>[section name|unsection],key=>[keyname],value_regexp=>[exten_number]);

erase when matched exten number.

	exten => 100,n,...
	exten => 102,n,...

=head2 save_file

    $sip_conf->save_file([new_file=>'filename']);

process commit list and save to file.
if reload_when_save true will do reload.
if no object variable file or file not exists or can't be 
save return failed.
if defined new_file will save to new file, default overwrite
objvar 'file'.

=head2 clean_assign

    $sip_conf->clean_assign();

clean all assign rules.

=head1 EXAMPLES

see example in source tree.

=head1 AUTHORS

Asterisk::config by Sun bing <hoowa.sun@gmail.com>

Version 0.7 patch by Liu Hailong.

=head1 COPYRIGHT

The Asterisk::config module is Copyright (c) Sun bing <hoowa.sun@gmail.com>
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 WARRANTY

The Asterisk::config is free Open Source software.

IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 SUPPORT

Sun bing <hoowa.sun@gmail.com>

The Asterisk::config be Part of FreeIris opensource Telephony Project
Access http://www.freeiris.org for more details.

=cut

1;
