#
#   Copyright (C) 1997, 1998
#   	Free Software Foundation, Inc.
#
#   This program is free software; you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the
#   Free Software Foundation; either version 2, or (at your option) any
#   later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, 675 Mass Ave, Cambridge, MA 02139, USA. 
#
package Catalog::tools::sqledit;
use vars qw($head %default_templates);
use strict;

use Carp;
use CGI ();
use Catalog::tools::cgi;
use Catalog::db;
use Catalog::tools::tools;

$head = "
<body bgcolor=#ffffff>
";

%default_templates
    = (
       'sqledit_search_form.html' => template_parse('inline sqledit_search_form', "$head
<title>Search form for _TABLE_</title>

<h3>Search form for _TABLE_</h3>

<form action=_SCRIPT_ method=POST>
<input type=submit value=search>
_HIDDEN_
<table>
_DEFAULT_
</table>

</form>
"),
       'sqledit_sinsert_form.html' => template_parse('inline sqledit_insert_form', "$head
<title>Insert form for _TABLE_</title>

<h3>Insert form for _TABLE_</h3>

<form action=_SCRIPT_ method=POST  enctype=multipart/form-data>
<input type=submit value=insert>
_HIDDEN_
<table>
_DEFAULT_
</table>

</form>
"),
       'sqledit_edit.html' => template_parse('inline sqledit_edit', "$head
<title>Edit form for _TABLE_</title>

_EDITCOMMENT_
<form action=_SCRIPT_ method=POST enctype=multipart/form-data>
<input type=submit name=update value=update>
_HIDDEN_
<table>
_DEFAULT_
</table>
</form>
"),
       'sqledit_search.html' => template_parse('inline sqledit_search', "$head
<title>Search _TABLE_</title>

<h3>_TABLE_</h3>

<table border=1>
<!-- start entry -->
<tr>_MARGINTABLE_ _DEFAULTTITLE_</tr>
<tr>_MARGIN_ _LINKS_</tr>
<tr>_MARGIN_ _DEFAULTROW_</tr>
<!-- end entry -->
</table>
<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
"),
       'sqledit_remove.html' => template_parse('inline sqledit_remove', "$head
<body bgcolor=#ffffff>

<center>

<h3>Confirm removal of record from  _TABLE_</h3>

<form action=_SCRIPT_ method=POST>
<input type=submit name=remove value=remove>
<input type=hidden name=context value=remove_confirm>
_HIDDEN_
</form>

</center>
"),
       'sqledit_remove_confirm.html' => template_parse('inline sqledit_remove_confirm', "$head
<body bgcolor=#ffffff>

<center>

<h3>Record removed from  _TABLE_</h3>

</center>
"),
       'hook_search.html' => template_parse('inline hook_search', "$head
<title>Search _TABLE_</title>

<h3>_TABLE_</h3>

<table border=1>
<!-- start entry -->
<tr>_DEFAULTROW_</tr>
<!-- end entry -->
</table>
<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
"),
       'error.html' => template_parse('inline error', "$head
<body bgcolor=#ffffff>
<title>Error</title>
<center><h3>
Error<p>
_MESSAGE_
</center></h3>
"),
       'edit.html' => template_parse('inline edit', "$head
<body bgcolor=#ffffff>
<title>Edit _FILE_</title>
<form action=_SCRIPT_ method=POST>
<input type=hidden name=context value=confedit>
<input type=hidden name=file value=_FILE_>
<input type=hidden name=rows value=_ROWS_>
<input type=hidden name=cols value=_COLS_>
<textarea name=text cols=_COLS_ rows=_ROWS_>_TEXT_</textarea>
<p>
<center>
<input type=submit name=action value=save>
<input type=submit name=action value=refresh>
</center>
<p>
_COMMENT_
</form>
"),
       'sqledit_requests.html' => template_parse('inline sqledit_requests', "$head
<title>Requests</title>

<h3>Requests</h3>

<table border=1>
<!-- start entry -->
<tr>
<td bgcolor=#c9c9c9>Search <a href='_SCRIPT_?context=search_form&table=_RTABLE_&limit=_RWHERE-CODED_&links_set=_RLINKS_&order=_RORDER-CODED_'>_LABEL_<a/></td>
<td><a href='_SCRIPT_?context=edit&table=sqledit_requests&primary=_ROWID_'>Edit<a/></td>
<td><a href='_SCRIPT_?context=remove&table=sqledit_requests&primary=_ROWID_'>Remove<a/></td>
</tr>
<!-- end entry -->
</table>
<p>
<a href='_SCRIPT_?context=insert_form&table=sqledit_requests'>Insert a request</a>
<br>
<a href='_SCRIPT_?context=search_form&table=sqledit_requests'>Search a request</a>
<br>

<!-- start pager -->
Number of pages _MAXPAGES_
<p>
_PAGES_
<!-- end pager -->
"),
       );

#sub DESTROY {}

sub new {
    my($type) = @_;

    my($self) = {};
    bless($self, $type);
    $self->initialize();
    return $self;
}

sub initialize {
    my($self) = @_;

    my($config) = config_load("sqledit.conf");
    if(exists($config->{'functions'})) {
	my($functions) = $config->{'functions'};
	if(!exists($functions->{'_evaled_'})) {
	    my($function);
	    foreach $function (keys(%$functions)) {
		my($string) = "\$functions->{\$function} = $functions->{$function} ";
		eval $string;
		if($@) {
		    my($error) = $@;
		    error($error);
		}
	    }
	    $functions->{'_evaled_'} = 1;
	}
    }
    %$self = (%$self, %$config) if(defined($config));

    $config = config_load("install.conf");
    %$self = (%$self, %$config) if(defined($config));
    
    $self->{'db'} = Catalog::db->new() if(!defined($self->{'db'}));
    my($db) = $self->{'db'};
    $db->resources_load('sqledit_schema', 'Catalog::tools::schema');
    $db->connect_error_handler(sub { $self->connect_error_handler(@_); });

    $self->{'params'} = [ 'table', 'links_set', 'stack', 'context', 'conf', 'order', 'style', 'limit', 'page_length' ];
    $self->{'templates'} = { %default_templates };

    $self->special_auth_initialize();
}

sub connect_error_handler {
    my($self, $db_type, $error) = @_;

    my($cgi) = $self->{'cgi'};
    my($url) = $cgi->url('-absolute' => 1);
    $self->serror("Could not connect to database because: <p><pre>%s</pre> Try <a href=$url?context=confedit&file=$db_type.conf>editing $db_type.conf</a> and check that the database server is running.", $error);
}

sub run {
    my($self, $function, $args, %args) = @_;
    my($close);
    if(!ref($self)) {
	$self = $self->new();
	$close = 1;
    }

    my($cgi) = Catalog::tools::cgi->new();
    $self->{'cgi'} = $cgi;

    my($key, $value);
    while(($key, $value) = each(%args)) {
	$cgi->param($key, $value);
    }
    $cgi->param('context', $function);

    my(@returned) = $self->${function}(@$args);

    $self->close() if($close);

    return @returned;
}

$Catalog::tools::sqledit::run = 0;

sub selector {
    my($self, $cgi) = @_;
    my($close);
    if(!ref($self)) {
	$self = $self->new();
	$close = 1;
    }

    if($Catalog::tools::sqledit::run++ > 0) {
	dbg("running in $$ : pass $Catalog::tools::sqledit::run\n", "sqledit");
    }

    $cgi = Catalog::tools::cgi->new() if(!defined($cgi));

    #
    # Unless explicitly specified otherwise, the script handling 
    # image display is the current script.
    #
    $self->{'imageutil'} = $cgi->script_name() if(!exists($self->{'imageutil'}));

    my($verbose) = $cgi->param('verbose');
    if(defined($verbose)) {
	# these are 'skicky', only changing when param verbose is given
	# verbose = 1 - minimal
	# verbose = 2 - enables opt_error_stack
	# verbose = 3 - spare
	# verbose>= 4 - sets DBI->trace to verbose-3
	$::opt_verbose = $verbose;
	$::opt_error_stack = ($::opt_verbose > 1);
	DBI->trace(($verbose-3<0) ? 0 : $verbose-3);
    }

    my($context) = '';
    if(defined($cgi->param('context'))) {
	$context = $cgi->param('context');
    } elsif(my $pathname = $cgi->path_info()) {
	$context = 'pathcontext';
	$pathname =~ s:([^/])$:$1/:;
	$cgi->param('pathname', $pathname);
    } else {
	# probably pathcontext to root but missing the trailing slash,
	# so that's where we'll redirect them:
	my $url = $cgi->url . "/";
        print join "",	"Status: 302 Moved\n",
			"Location: $url\n",
			"Content-Type: text/html\n\n";
	return "";
    }

    $| = 0; # Unbuffered output enabled per-request in gauge() if needed
    $cgi->nph(1) if(exists($self->{'nph'}) && $self->{'nph'} eq 'yes');

    my($content) = $cgi->param('content') || "text/html";
    print $cgi->header(-type => $content);

    if($context !~ /^[\w_]+$/io) {
	print "'$context' is not a valid context name";
	return "";
    }

    return "" if(!$self->special_auth($cgi));

    if(exists($self->{'context_allow'}) &&
       ( $self->{'context_allow'} eq '*' ||
	 $self->{'context_allow'} !~ /\b$context\b/)) {
	print istring("%s context is not allowed", $context);
	return "";
    }
    my($html);
    my($error);
    eval {
	local($SIG{__DIE__});
	$html = $self->${context}($cgi);
    };
    if($@) {
	$error = $@;
	if($error !~ /HTMLIZED/) {
	    croak($error);
	}
    }

    $self->close() if($close);

    if(defined($html)) {
	if(exists($self->{'status'}) &&
	   $self->{'status'} eq 'on') {
	    $html .= $self->process_status($context);
	}
#	warn($html);
	print $html;
    }

    $html = $error if($error);

    if(my $file = $cgi->param('dump')) {
	writefile($file, $html);
    }

    return $html;
}

#
# Undocumented feature specific to CFCE may be usefull for others but not sure
#
sub special_auth {
    my($self, $cgi) = @_;

    if(exists($self->{'special_auth'})) {
	my($spec) = $self->{'special_auth'};
	my($password) = $cgi->param($spec->{'param'});
	if(!defined($password)) {
	    print istring("special_auth: missing %s", $spec->{'param'});
	    return 0;
	}
	my($today) = $self->db()->date(time());
	my($row);
	eval {
	    $row = $self->db()->exec_select_one("select * from $spec->{'table'} where $spec->{'field_date'} = '$today' and $spec->{'field_password'} = '$password'");
	};
	if($@) {
	    my($error) = $@;
	    print istring("special_auth: cannot query table : %s", $error);
	    return 0;
	}
	if(!defined($row)) {
	    print istring("special_auth: permission denied");
	    return 0;
	}
    }
    return 1;
}

sub special_auth_initialize {
    my($self) = @_;

    if(exists($self->{'special_auth'})) {
	my($param) = $self->{'special_auth'}->{'param'};
	push(@{$self->{'params'}}, $param);
    }
}

#
# Output characters so that the Navigator shows activity during
# a lengthy process. This prevents timeout and provides feedback 
# to the user.
#
sub gauge {
    my($self) = @_;
    $| = 1;	# unbuffered output

    print " " if(exists($self->{'cgi'}));
}

#
# Only works on RedHat-5.2
#
sub process_size {
    my($statfile) = "/proc/$$/stat";
    return undef if(! -f $statfile);
    open(FILE, "<$statfile") or return undef;
    my($line) = <FILE>;
    close(FILE);
    return undef if(!$line);
    my(@values) = split(' ', $line);
    return $values[22];
}

sub process_status {
    my($self, $msg) = @_;

    my($html) = "<td>$msg</td><td>";

    my($size) = process_size();
    if(defined($size)) {
	$html .= "Process size = $size ";
    }
    $html .= "Process id = $$";

    my($file) = "/tmp/Catalog$$";
    open(FILE, ">>$file") or error("cannot open $file for append : $!");
    print FILE "<tr>$html</td></tr>\n";
    close(FILE);

    $html = readfile($file);

    return "\n<hr>\n<table>$html</table>\n<hr>\n";
}

#
# Callbacks for derived classes
#

#
# Enrich tag set for sqledit_entry_*.html template
#
sub search_entry_tags {
    my($self, $assoc, $info, $row, $table) = @_;
    return ();
}

sub requests_check {
    my($self) = @_;

    if(!$self->db()->table_exists('sqledit_requests')) {
	$self->db()->exec($self->db()->schema('sqledit_schema', 'sqledit_requests'));
    }
}

sub requests {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    $self->requests_check();

    my(%context) = (
		    'url' => $cgi->url('-absolute' => 1),
		    'page' => scalar($cgi->param('page')),
		    'page_length' => scalar($cgi->param('page_length')),
		    'template' => 'sqledit_requests',
		    'table' => 'sqledit_requests',
		    'order' => 'label',
		    'expand' => 'yes',
		    );
    return $self->searcher(\%context);
}

sub search_form {
    return blank_form(@_, 'search');
}

sub insert_form {
    return blank_form(@_, 'sinsert');
}

sub blank_form {
    my($self, $cgi, $type) = @_;
    $self->{'cgi'} = $cgi;
    
    my($table) = $cgi->param('table');
    my($template) = $self->template("sqledit_${type}_form");
    my($assoc) = $template->{'assoc'};

    template_set($assoc, '_COMMENT_', $cgi->param('comment'));

    $assoc->{'_TABLE_'} = $table;
    $assoc->{'_HIDDEN_'} = $self->hidden('context' => $type);
    my($row) = $self->args2row($table);
    if(exists($assoc->{'_DEFAULT_'})) {
	if($type eq 'search') {
	    $assoc->{'_DEFAULT_'} = $self->row2search($table, $row);
	} else {
	    $assoc->{'_DEFAULT_'} = $self->row2edit($table, $row);
	}
    } else {
	if($type eq 'search') {
	    $self->row2assoc_search($table, $assoc);
	} else {
	    $self->row2assoc($table, $row, $assoc);
	}
    }

    return $self->stemplate_build($template);
}

sub svalue_check {
    my($self, $table, $field, $info, $old_value, $new_value) = @_;

    my($spec) = $self->{'check'};
    return $new_value if(!defined($spec) || !exists($spec->{$table}));
    $spec = $spec->{$table};
    return $new_value if(!defined($spec) || !exists($spec->{$field}));
    $spec = $spec->{$field};

    if(defined($spec->{'mandatory'})) {
	#
	# If form field is empty or not specified and not set in base, bark
	#
	if((!defined($new_value) || $new_value eq '') &&
	   (!defined($old_value) || $old_value eq '')) {
	    $self->serror("table %s : field %s must be set", $table, $field);
	}
	#
	# If form field contains only spaces (reset field to empty), bark
	#
	if(defined($new_value) && $new_value =~ /^\s+$/) {
	    $self->serror("table %s : field %s must be set", $table, $field);
	}
    }
    return if(!defined($new_value));
    $_ = $new_value;

    #
    # Database dependent
    #
    my($type) = $info->{'type'};
    if($type eq 'char') {
	if(length($_) > $info->{'size'}) {
	    $self->serror("table %s : field %s : value %s is too long (max %s bytes)", $table, $field, $new_value, $info->{'size'})
	}
    } 
    my($functions) = $self->{'functions'};
    #
    # Default normalization
    #
    if(exists($functions->{'normalize_default'})) {
	my($func) = $functions->{'normalize_default'};
	&$func();
    }
    #
    # User specified
    #
    my($checker);
    foreach $checker (qw(normalize match)) {
	if(defined($spec->{$checker})) {
	    my($func) = $functions->{$spec->{$checker}};
	    error("$spec->{$checker} is not a known function") if(!defined($func));
	    my($status) = &$func($self, $field);
	    if($status ne '1') {
		my($message) = 
		$self->serror("table %s : field %s : value %s $checker failed %s", $table, $field, $_, $status);
	    }
	}
    }
    return $_;
}

sub sinsert {
    my($self, $cgi) = @_;
    my($table) = $cgi->param('table');
    $self->{'cgi'} = $cgi;

    my($insert, $primary) = $self->sinsert_1($table);

    if(defined($cgi->fct_name()) && $cgi->fct_name() eq 'insert') {
	return $self->fct_return($cgi, $insert);
    } else {
	$cgi->param('primary' => $primary);
	$cgi->param('context' => 'edit');
	$cgi->param('comment' => 'Row inserted');
	return $self->edit($cgi);
    }
}

sub sinsert_1 {
    my($self, $table) = @_;
    my($cgi) = $self->{'cgi'};

    my($info) = $self->db()->info_table($table);

    my($comment);
    my(%insert);
    my($fields) = $info->{'_fields_'};
    my($field);
    foreach $field (@$fields) {
	my($desc) = $info->{$field};
	my($param_value) = $cgi->param("${table}_${field}") || $cgi->param($field);
	$param_value = $self->dict_alt($table, $field, $desc, $param_value);
	$param_value = $self->svalue_check($table, $field, $desc, undef, $param_value);
	next if(!defined($param_value));
	next if(defined($desc->{'default'}) &&
		$desc->{'default'} eq $param_value);
	if($desc->{'type'} eq 'set' && defined($param_value)) {
	    my($value) = $self->set_handle_param($table, $field, $desc);
	    if(defined($value)) {
		$insert{$field} = $value;
	    }
	} elsif($desc->{'type'} eq 'blob') {
	    if(defined($param_value) && $param_value !~ /^\s*$/o) {
		my($filename) = $cgi->tmpFileName($param_value);
		open(FILE, "<$filename") or error("cannot open $filename ($param_value) for reading : $!");
		sysread(FILE, $insert{$field}, 100000);
		close(FILE);
	    }
	} elsif(defined($param_value)) {
	    if($param_value ne "") {
		$insert{$field} = $param_value;
	    }
	}
    }

    my($primary) = $self->db()->insert($table, %insert);
    $insert{$info->{'_primary_'}} = $primary;
    
    return (\%insert, $primary);
}

sub set_handle_param {
    my($self, $table, $field, $desc, $row) = @_;
    my($cgi) = $self->{'cgi'};

    #
    # This is an update
    #
    my(@values) = $cgi->param("${table}_${field}");
    @values = $cgi->param($field) if(!@values);

    my($new_value);
    my($old_value);
    if(defined($row)) {
	$self->db()->dict_link($desc, $table, $field);
	my($values) = $desc->{'values'};
	my(%value2key) = map { $values->{$_} => $_ } keys(%$values);

	$new_value = join(",", @values);
	my($tmp_new_value) = join(",", sort(map { $value2key{$_} } @values));
	$tmp_new_value = $self->update_check($field, $tmp_new_value);
	if(defined($row->{$field})) {
	    $old_value = join(",", sort(split(",", $row->{$field})));
	} else {
	    $old_value = '';
	}
	if($tmp_new_value eq $old_value) {
	    undef($new_value);
	}
    } else {
	#
	# This is an insert
	#
	$new_value = join(",", sort(@values));
    }
    return $new_value;
}

sub row2search {
    my($self, $table) = @_;

    return $self->row2edit_1($table, undef, undef);
}

sub row2edit {
    my($self, $table, $row) = @_;

    return $self->row2edit_1($table, $row, 'yes');
}

sub row2edit_1 {
    my($self, $table, $row, $use_default) = @_;

    my($info) = $self->db()->info_table($table);

    my($html);
    my($fields) = $info->{'_fields_'};
    my($field);
    foreach $field (@$fields) {
	$html .= "<tr><td>$field</td><td>";
	my($desc) = $info->{$field};
	my($type) = $desc->{'type'};
	my($value) = defined($row) ? $row->{$field} : undef;
	my($value_quoted) = defined($value) ? Catalog::tools::cgi::myescapeHTML($value) : '';
	if($type eq 'char') {
	    my($size);
	    if($desc->{'size'} < 2) {
		$size = 2;
	    } elsif($desc->{'size'} > 1000) {
		$size = 1000;
	    } elsif($desc->{'size'} > 30) {
		$size = 30;
	    } else {
		$size = $desc->{'size'};
	    }
	    if($size < 1000) {
		$html .= "<input type=text size=$size name=$field value=\"$value_quoted\"></td>\n";
	    } else {
		$html .= "<textarea name=$field rows=6 cols=30>$value</textarea>\n";
	    }
	} elsif($type eq 'int') {
	    $html .= "<input type=text size=10 name=$field value=\"$value_quoted\"></td>\n";
	} elsif($type eq 'time' || $type eq 'date') {
	    $html .= "<input type=text size=20 name=$field value=\"$value_quoted\"></td>\n";
	} elsif($type eq 'blob' ) {
	    if(defined($value)) {
		my($imageutil) = $self->imageutil();
		my($primary) = $info->{'_primary_'};
		$html .= "<img src=\"$imageutil?table=$table&field=$field&$primary=$row->{$primary}&context=imagedisplay&content=image/gif\"> ";
	    }
	    $html .= "<input type=file name=$field>";
	} elsif($type eq 'set' ) {
	    $self->db()->dict_link($desc, $table, $field);
	    $html .= $self->choice($table, $desc, 'table', $field, $value, $use_default, 'checkbox');
	} elsif($type eq 'enum') {
	    $self->db()->dict_link($desc, $table, $field);
	    $html .= $self->choice($table, $desc, 'select', $field, $value, $use_default);
	}
    }
    $html .= "</tr>\n";

    return $html;
}

sub imagedisplay {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($field) = $cgi->param('field');
    my($table) = $cgi->param('table');
    my($info) = $self->db()->info_table($table);
    my($primary) = $cgi->param($info->{'_primary_'});
    my($image) = $self->db()->exec_select_one("select $field from $table where $info->{'_primary_'} = $primary")->{$field};

    return $image;
}

sub row2title {
    my($self, $info, $row, $table) = @_;

    my($html);

    my($fields) = $info->{'_fields_'};
    my($field);
    foreach $field (@$fields) {
	next if($row && !defined($row->{$field}));
	$html .= "<td bgcolor=#c9c9c9>$field</td>";
    }
    return $html;
}

sub row2view {
    my($self, $row, $table, $style) = @_;

    my($info) = $self->db()->info_table($table);
    
    my($html);
    my($fields) = $info->{'_fields_'};
    my($field);
    foreach $field (@$fields) {
	my($value) = $row->{$field};
	my($quoted_value) = Catalog::tools::cgi::myescapeHTML($row->{$field});
	if($style eq 'short') {
	    $html .= "<td>";
	} else {
	    $html .= "<tr><td>$field</td><td>";
	}
	my($desc) = $info->{$field};
	my($type) = $desc->{'type'};
	if(defined($value)) {
	    if($type eq 'char') {
		if($style eq 'short' && length($value) > 30) {
		    $quoted_value = Catalog::tools::cgi::myescapeHTML(substr($value, 0, 30)) . "...";
		}
	    } elsif($type eq 'blob' && defined($value)) {
		my($imageutil) = $self->imageutil();
		my($primary) = $info->{'_primary_'};
		$value = "<img src=\"$imageutil?table=$table&field=$field&$primary=$row->{$primary}&context=imagedisplay&content=image/gif\"> ";
		$quoted_value = $value;
	    }
	    $html .= $quoted_value if(defined($value));
	} else {
	    $value = '';
	}
	if($style eq 'short') {
	    $html .= "</td>";
	} else {
	    $html .= "$value</td></tr>\n";
	}
    }
    return $html;
}

sub choice {
    my($self, $table, $desc, $type, $field, $current, $use_default, @rest) = @_;

    my($spec);
    if(exists($self->{'display'}) &&
       exists($self->{'display'}->{$type})) {
	$spec = $self->{'display'}->{$type};
	if(exists($spec->{'tables'}) &&
	   exists($spec->{'tables'}->{$table}) &&
	   exists($spec->{'tables'}->{$table}->{$field})) {
	    $spec = $spec->{'tables'}->{$table}->{$field};
	} else {
	    $spec = $spec->{'general'};
	}
    } 

    my($values) = $desc->{'values'};
    #
    # If current value null, set to default value if any
    #
    if(defined($use_default) && (!defined($current) || $current =~ /^\s*$/)) {
	if(exists($values->{'_default_'})) {
	    $current = $values->{'_default_'};
	} elsif(exists($desc->{'default'})) {
	    $current = $desc->{'default'};
	}
    }

    #
    # Prepare display by ordering the fields and adding
    # hidden fields that match the current value.
    #
    my($value, $label);
    my(@labels);
    if(exists($values->{'_order_'})) {
	my(%value2key) = map { $values->{$_} => $_ } keys(%$values);
	my($ordered) = $values->{'_order_'};
	@labels = map { $value2key{$_} } @$ordered;
	#
	# If a default is provided and it exists in the dictionnary
	# and it was not displayed, add it to the menu.
	#
	if(defined($current) && exists($desc->{'dict'})) {
	    my(@current_labels) = split(',', $current);
	    my($current_label);
	    foreach $current_label (@current_labels) {
		if(exists($values->{$current_label}) &&
		   !grep($_ eq $current_label, @labels)) {
		    push(@labels, $current_label);
		}
	    }
	}
    } else {
	@labels = sort(keys(%$values));
    }

    if($type eq 'select') {
	return values2select($spec, $field, \@labels, $values, $current, @rest);
    } elsif($type eq 'table') {
	return values2table($spec, $field, \@labels, $values, $current, @rest);
    } else {
	error("unknown type $type");
    }
}

sub values2select {
    my($spec, $field, $labels, $values, $current, $multiple) = @_;

    my($size) = $spec->{'multiple'} || 4;
    my($labelnull) = $spec->{'labelnull'} || '---------';
    if(defined($multiple)) {
	$multiple = " multiple size=$size ";
    } else {
	$multiple = '';
    }

    my($html);
    $html .= "<select name=$field>\n";
    $html .= "<option value=\"\" " . ($current ? "" : "selected") . ">$labelnull\n";
    my($label);
    foreach $label (@$labels) {
	my($value) = $values->{$label};
	my($selected) = '';
	my($quoted_label) = quotemeta($label);
	if(defined($current) && $current =~ /\b$quoted_label\b/) {
	    $selected = "selected";
	}
	$html .= "<option value=$value $selected>$label\n";
    }
    $html .= "</select>\n";

    return $html;
}

sub values2table {
    my($spec, $field, $labels, $values, $current, $type) = @_;

    my($font_start) = $spec->{'font'} || '';
    my($font_end) = $spec->{'font'} ? '</font>' : '';
    my($col_max) = $spec->{'columns'} || 5;

    my($html);
    $html .= "<table><tr>";
    my($col_count) = 0;
    my($label);
    foreach $label (@$labels) {
	my($value) = $values->{$label};
	$col_count++;
	if($col_count > $col_max) {
	    $html .= "</tr>\n<tr>";
	    $col_count = 1;
	}
	my($checked) = '';
	my($quoted_label) = quotemeta($label);
	if(defined($current) && $current =~ /\b$quoted_label\b/) {
	    $checked = "checked";
	}
	$html .= "<td><input type=$type name=$field value=$value $checked></td><td> $font_start $label $font_end</td>";
    }
    $html .= "</tr>\n</table>\n";

    return $html;
}

sub dict_alt {
    my($self, $table, $field, $desc, $param_value) = @_;
    my($cgi) = $self->{'cgi'};

    #
    # Do nothing if the value is defined or it's not an external dictionary
    # or it's a multiple values dictionary.
    #
    dbg("dict_alt: check $field is dict", "sqledit");
    return $param_value if(!exists($desc->{'dict'}));

    #
    # Nothing to be done if alternate value not specified
    #
    my($alt_value) = $cgi->param("${table}_${field}_alt") || $cgi->param("${field}_alt");
    dbg("dict_alt: check alt_value exists", "sqledit");
    return $param_value if(!defined($alt_value));

    my($values) = $self->db()->dict_link($desc, $table, $field);

    #
    # The value already exists, do nothing
    #
    my($result);
    dbg("dict_alt: check exists", "sqledit");
    $result = $values->{$alt_value} if(exists($values->{$alt_value}));

    if(!defined($result)) {
	dbg("dict_alt: add", "sqledit");
	$result = $self->db()->dict_add($desc->{'dict'}->{'table'}, $alt_value);
    }
    
    if(exists($desc->{'dict'}->{'map'})) {
	my($field) = grep(/^$field$/ || /^${table}_$field$/, $cgi->param());
        dbg("dict_alt: append to $field set $result", "sqledit");
        $cgi->append('-name' => $field, '-values' => [ $result ]);
    my(@foo) = $cgi->param($field);
    dbg("dict_alt: foo = @foo", "sqledit");
    } else {
	return $result;
    }
}

sub row2assoc_search {
    my($self, $table, $assoc) = @_;

    return $self->row2assoc_1($table, undef, $assoc, undef);
}

sub row2assoc {
    my($self, $table, $row, $assoc) = @_;

    return $self->row2assoc_1($table, $row, $assoc, 'yes');
}

sub row2assoc_1 {
    my($self, $table, $row, $assoc, $use_default) = @_;

    my($info) = $self->db()->info_table($table);

    my($func) = sub {
	my($field, $tag, $desc, $form) = @_;

	my($type) = $desc->{'type'};
	my($value) = defined($row) ? $row->{$field} : undef;

#	warn("$field $tag $form $value " . ostring($desc));

	if($type eq 'set' && $form eq 'CHECKBOX') {
	    $self->db()->dict_link($desc, $table, $field);
	    $assoc->{$tag} = $self->choice($table, $desc, 'table', $field, $value, $use_default, 'checkbox');
	} elsif($type eq 'set' && $form eq 'MENU') {
	    $self->db()->dict_link($desc, $table, $field);
	    $assoc->{$tag} = $self->choice($table, $desc, 'select', $field, $value, $use_default, 'multiple');
	} elsif($type eq 'enum' && $form eq 'RADIO') {
	    $self->db()->dict_link($desc, $table, $field);
	    $assoc->{$tag} = $self->choice($table, $desc, 'table', $field, $value, $use_default, 'radio');
	} elsif($type eq 'enum' && $form eq 'MENU') {
	    $self->db()->dict_link($desc, $table, $field);
	    $assoc->{$tag} = $self->choice($table, $desc, 'select', $field, $value, $use_default);
	} elsif($type eq 'blob' && defined($value)) {
	    my($imageutil) = $self->imageutil();
	    my($primary) = $info->{'_primary_'};
	    $assoc->{$tag} = "<img src=\"$imageutil?table=$table&field=$field&$primary=$row->{$primary}&context=imagedisplay&content=image/gif\"> ";
	} elsif(defined($value)) {
	    $value = '' if(!defined($value));
	    if($form eq 'QUOTED') {
		$assoc->{$tag} = Catalog::tools::cgi::myescapeHTML($value);
	    } elsif($form eq 'CODED') {
		$assoc->{$tag} = CGI::escape($value);
	    } else {
		$assoc->{$tag} = $value;
	    }
	}
    };

    $self->walk_table_tags($table, $assoc, $func);
}

#
# Run $func for each tag that appear in $assoc and that refer to 
# a valid field of $table.
#
sub walk_table_tags {
    my($self, $table, $assoc, $func) = @_;

    my($info) = $self->db()->info_table($table);

    my(%sub);
    my($fields) = $info->{'_fields_'};
    my($field);
    foreach $field (@$fields) {
	my($tag) = uc($field);
	my(@tags) = grep(/[_-]$tag[_-]/, keys(%$assoc));
	next if(!@tags);

	foreach $tag (@tags) {
	    my($utable, $ufield, $uform) = $tag =~ /^_(\w+)-(\w+)-(\w+)_$/;
	    ($ufield, $uform) = $tag =~ /^_(\w+)-(QUOTED|CODED|MENU|RADIO|CHECKBOX)_$/ if(!defined($ufield));
	    ($utable, $ufield) = $tag =~ /^_(\w+)-(\w+)_$/ if(!defined($ufield));
	    ($ufield) = $tag =~ /^_(\w+)_$/ if(!defined($ufield));
	    $uform = '' if(!defined($uform));
	    if(!defined($ufield)) {
		error("no match for $tag");
	    }

	    next if(defined($utable) && $utable ne uc($table));
	    next if($ufield ne uc($field));

#	    warn("replace $tag - $utable - $ufield - $uform");
	    my($desc) = $info->{$field};
	    &$func($field, $tag, $desc, $uform);
	}
    }
}

sub remove {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($table) = $cgi->param('table');

    my($template) = $self->template("sqledit_remove");

    template_set($template->{'assoc'}, '_TABLE_', $table);
    template_set($template->{'assoc'}, '_SCRIPT_', $cgi->url(-absolute => 1));
    template_set($template->{'assoc'}, '_HIDDEN_', $self->hidden('primary' => $cgi->param('primary')));
    return $self->stemplate_build($template);
}

sub remove_confirm {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($table) = $cgi->param('table');

    my($info) = $self->db()->info_table($table);

    $self->db()->mdelete($table, "$info->{'_primary_'} = " . $cgi->param('primary'));

    my($template) = $self->template("sqledit_remove_confirm");

    template_set($template->{'assoc'}, '_TABLE_', $table);
    template_set($template->{'assoc'}, '_SCRIPT_', $cgi->url(-absolute => 1));
    return $self->stemplate_build($template);
}

sub edit {
    my($self, $cgi) = @_;
    my($table) = $cgi->param('table');
    $self->{'cgi'} = $cgi;

    my($info) = $self->db()->info_table($table);
    
    my($row) = $self->db()->sexec_select_one($table, "select * from $table where $info->{'_primary_'} = " . $cgi->param('primary'));

    my($template) = $self->template("sqledit_edit");
    my($assoc) = $template->{'assoc'};
    $assoc->{'_TABLE_'} = $table;
    $assoc->{'_HIDDEN_'} = $self->hidden('primary' => $cgi->param('primary'),
					 'context' => 'supdate');
    $assoc->{'_EDITCOMMENT_'} = $cgi->param('comment') if($cgi->param('comment'));
    if(exists($assoc->{'_DEFAULT_'})) {
	$assoc->{'_DEFAULT_'} = $self->row2edit($table, $row);
    } else {
	$self->row2assoc($table, $row, $assoc);
    }

    return $self->stemplate_build($template);
}

sub update_hook {
    dbg("sqledit:update_hook\n", "sqledit");
}

sub update_check {
    my($self, $field, $value) = @_;
    return $value;
}

sub args2row {
    my($self, $table) = @_;
    my($cgi) = $self->{'cgi'};

    my(%row);

    my($info) = $self->db()->info_table($table);
    my($fields) = $info->{'_fields_'};

    my($field);
    foreach $field (@$fields) {
	my($value) =  $cgi->param("${table}_${field}") || $cgi->param($field);
	if(defined($value)) {
	    $row{$field} = $value;
	}
    }
    
    return \%row;
}

#
# Interactive update
#
sub supdate {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($table) = $cgi->param('table');

    my($primary) = $cgi->param('primary');

    my($updated_fields) = $self->supdate_1($table, $primary);
    $cgi->param('context' => 'edit');
    if(@$updated_fields) {
	$cgi->param('comment' => "Updated fields @$updated_fields");
    } else {
	$cgi->param('comment' => "No field modified");
    }
    
    if(defined($cgi->fct_name()) && $cgi->fct_name() eq 'edit') {
	return $self->fct_return($cgi);
    } else {
	return $self->edit($cgi);
    }
}

#
# Update backend
#
sub supdate_1 {
    my($self, $table, $primary) = @_;
    my($cgi) = $self->{'cgi'};

    my($info) = $self->db()->info_table($table);

    my($row) = $self->db()->sexec_select_one($table, "select * from $table where $info->{'_primary_'} = $primary");

    my(@updated_fields);
    my(%update);
    my($fields) = $info->{'_fields_'};
    my($field);
    foreach $field (@$fields) {
	my($desc) = $info->{$field};
	my($param_value) = $cgi->param("${table}_${field}") || $cgi->param($field);
	undef($param_value) if(defined($param_value) && $param_value eq '');
	$param_value = $self->dict_alt($table, $field, $desc, $param_value);
	$param_value = $self->svalue_check($table, $field, $desc, $row->{$field}, $param_value);
	if($desc->{'type'} eq 'set') {
	    my($value) = $self->set_handle_param($table, $field, $desc, $row);
	    if(defined($value)) {
		$update{$field} = $value;
		push(@updated_fields, $field);
	    }
	} elsif($desc->{'type'} eq 'blob') {
	    if(defined($param_value) && $param_value !~ /^\s*$/o) {
		my($filename) = $cgi->tmpFileName($param_value);
		open(FILE, "<$filename") or error("cannot open $filename ($param_value) for reading : $!");
		sysread(FILE, $update{$field}, 100000);
		close(FILE);
		push(@updated_fields, $field);
	    }
	} elsif(defined($param_value)) {
	    if(!defined($row->{$field}) || $param_value ne $row->{$field}) {
		$update{$field} = $param_value;
		push(@updated_fields, $field);
	    }
	}
    }

    if(@updated_fields) {
	$self->update_hook(\%update, $row, @updated_fields);
	$self->db()->update($table, "$info->{'_primary_'} = $primary",
		      %update);
    }
    return \@updated_fields;
}

sub search_sql {
    my($self, $info, $table, $template) = @_;
    my($cgi) = $self->{'cgi'};

    my($where) = '';

    my($fields) = $info->{'_fields_'};
    my($field);
    foreach $field (@$fields) {
	if($cgi->param($field)) {
	    #
	    # Prepare sql statement
	    #
	    my($value) = $cgi->param($field);
	    my($type) = $info->{$field}->{'type'};
	    $where .= "and $field ";
	    if($type eq 'char') {
		my($quoted_value) = $self->db()->quote($value);
		$where .= "like '$quoted_value' ";
	    } elsif($type eq 'int' || $type eq 'time') {
		my($operator) = "=";
		my($tmp) = $value;
		if($tmp =~ /^\s*([<>])\s*(\d+)/) {
		    $operator = $1;
		    $tmp = $2;
		} elsif($tmp =~ /(\d+)/) {
		    $tmp = $1;
		} else {
		    $tmp = undef;
		}
		if(defined($tmp)) {
		    $where .= "$operator $tmp ";
		}
	    } elsif($type eq 'set' || $type eq 'enum') {
		$where .= "like '%$value%' ";
	    }
	}
    }

    $where =~ s/^and // if($where ne '');

    if($cgi->param('limit')) {
	my($limit) = $cgi->param('limit');
	if($where ne '') {
	    $where = " ( $where ) and ( $limit ) ";
	} else {
	    $where = " $limit ";
	}
    }

    $where = " where $where " if($where ne '');

    my($order) = '';
    if($cgi->param('order')) {
	$order = "order by " . $cgi->param('order');
    }
    
    return "select * from $table $where $order";
}

sub search {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;
    my($table) = $cgi->param('table');

    my($info) = $self->db()->info_table($table);

    my($params) = $self->params();

    my($template) = $self->template("sqledit_search");
    my($assoc) = $template->{'assoc'};
    my($children) = $template->{'children'};
    error("missing children") if(!defined($children));
    my($pager) = $children->{'pager'};
    error("missing pager") if(!defined($pager));
    my($entry) = $children->{'entry'};
    error("missing entry") if(!defined($entry));
    
    my($sql) = $self->search_sql($info, $table, $entry);
    dbg("sqledit_search: $sql\n", "sqledit");

    my($fields) = $info->{'_fields_'};
    my($field);
    foreach $field (@$fields) {
	my($value) = $cgi->param($field);
	if($value) {
	    #
	    # Rebuild QUERY_STRING portion
	    #
	    $params .= "&$field=" . CGI::escape($value);
	}
    }

    my($func) = sub {
	$self->search_1($entry, $sql, @_);
    };

    pager(($cgi->param('page') || 0),
	  ($cgi->param('page_length') || 0),
	  $func,
          $cgi->url(-absolute => 1) . "?$params&",
          $pager->{'assoc'});

    if($pager->{'assoc'}->{'_MAXPAGES_'} <= 1) {
	$pager->{'skip'} = 'yes';
    }

    $assoc->{'_TABLE_'} = $table;
    if(exists($assoc->{'_LETTER_'})) {
	my($letter) = $sql =~ /like \'(\w)/;
	$assoc->{'_LETTER_'} = uc($letter);
    }
    return $self->stemplate_build($template);
}

sub hook_cgi2query {
    my($self) = @_;
    my($cgi) = $self->{'cgi'};
    
    my(%query);
    my(@tags);
    my($tag);
    my(@args) = $cgi->param();
    foreach $tag (grep(/^query_/, @args)) {
	my($query_tag) = $tag =~ /^query_(.*)/;
	$query{$query_tag} = $cgi->param($tag);
	push(@tags, $tag);
    }

    return (\%query, \@tags);
}

sub hook_search {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($hook) = $self->{'hook'};
    error("no hook") if(!defined($hook));

    my($query_params) = $hook->{$self->{'base'}}->{'query'}->{'params'};

    my($query, $tags) = $self->hook_cgi2query();

    my($layout) = sub {
	my($template, $name, $result, $context) = @_;

	my($row) = values(%$result);
	#
	# Get the first filled rowid
	#
	my($primary_value);
	my($table);
	my($key);
	foreach $key (keys(%$row)) {
	    my($tmp) = $key =~ /^r_(.*)$/i;
	    if(defined($tmp) && defined($row->{$key})) {
		$primary_value = $row->{$key};
		$table = lc($tmp);
#		warn("key = $key, table = $table, primary_value = $primary_value");
	    }
	}

	error("nothing found") if(!defined($primary_value));
	#warn("template = $template, table = $table, result = $result");
	#
	# Get the corresponding row from base
	#
	$result = $self->hook_search_retrieve($table, $primary_value);

	my($template_name) = join(',', sort(keys(%$result)));
	if(defined($query_params->{'templates'}) &&
	   exists($query_params->{'templates'}->{$template_name})) {
	    dbg("$template_name mapped to $query_params->{'templates'}->{$template_name}", "sqledit");
	    $template_name = $query_params->{'templates'}->{$template_name};
	}
#	$row->{'REL'} .= rel_split($row->{'REL'});
	my($template_used) = $template;
	if(exists($template->{'children'}->{$template_name})) {
	    $template_used = $template->{'children'}->{$template_name};
	}
	template_set($template_used->{'assoc'}, '_RELEVANCE_', $row->{'REL'});

	return $self->searcher_layout_result($template, $template_name, $result, $context);
    };
    my($template_set) = sub {
	my($template, $context) = @_;

	template_set($template->{'assoc'}, '_QUERYTEXT_', $query->{'text'});
    };

    my($sql, $relevance, $where, $order) = $hook->query2sql($query);

    if($where =~ /^\s*$/) {
	$self->serror("No full text search criterion specified");
    }
    
    my(%context) = (
		    'params' => $tags,
		    'url' => $cgi->url('-absolute' => 1),
		    'page' => scalar($cgi->param('page')),
		    'page_length' => scalar($cgi->param('page_length')),
		    'template' => 'hook_search',
		    'table' => $query_params->{'table'},
		    'sql' => $sql,
		    'select' => sub { $hook->hook_select($relevance, $where, $order, @_) },
		    'template_set' => $template_set,
		    'layout' => $layout,
		    );
    return $self->searcher(\%context);
}


sub hook_search_retrieve {
    my($self, $table, $primary_value) = @_;

    my($info) = $self->db()->info_table($table);
    my($row) = $self->db()->sexec_select_one($table, "select * from $table where $info->{'_primary_'} = $primary_value");
    return { $table => $row };
}

#
# context
#    context : symbolic name of the invocation (for derived functions to
#              find out from where they were called).
#    params : list of cgi params to add to params (opt)
#    fields : comma separated list of fields to be retrieved, in addition
#             to those found in the template (searcher_select_fields)
#    template : ref or name of template
#    table : name of the table to search
#    url : url of the cgi-bin
#    page : page number 
#    page_length : length of page
#    sql : ref to function that build the sql request, 
#          or string of sql request (opt)
#    where : ref or string to limit search (if !sql)
#    order : ref or string to order results (if !sql)
#    select : ref to function to perform the select (opt)
#    layout : ref to function to display a single row (opt)
#    template_set : ref to function in charge of tag substitution
#                   for tags in the top level template (opt)
#    accept_empty : accept empty results
#
sub searcher {
    my($self, $context) = @_;

    my($params) = $self->params();

    my($table) = $context->{'table'};
    error("missing table name") if(!defined($table));
    my($template) = $context->{'template'};
    error("missing template ref or name") if(!defined($template));
    my($build_template);
    if(!ref($template)) {
	$template = $self->template($context->{'template'});
	$build_template = 'yes';
    }
    my($assoc) = $template->{'assoc'};
    my($children) = $template->{'children'};
    error("missing children") if(!defined($children));
    my($pager) = $children->{'pager'};
    
    my($where) = $context->{'where'};
    if(!defined($where)) {
	$where = '';
    } elsif(ref($where)) {
	$where = &$where($template, $table, $context);
    } else {
	$where = "where $where";
    }
    $context->{'real where'} = $where;

    my($order) = $context->{'order'};
    if(!defined($order) || $order =~ /^\s*$/) {
	$order = '';
    } elsif(ref($order)) {
	$order = &$order($template, $table, $context);
    } else {
	$order = "order by $order";
    }
    $context->{'real order'} = $order;
    
    my($sql) = $context->{'sql'};
    if(!defined($sql)) {
	$sql = $self->searcher_sql($template, $table, $context);
    } elsif(ref($sql)) {
	$sql = &$sql($template, $table, $context);
    }
    dbg("searcher: $sql\n", "sqledit");

    my($fields) = $context->{'params'};
    if(defined($fields)) {
	my($cgi) = $self->{'cgi'};
	my($field);
	foreach $field (@$fields) {
	    my($value) = $cgi->param($field);
	    if($value) {
		#
		# Rebuild QUERY_STRING portion
		#
		$params .= "&$field=" . CGI::escape($value);
	    }
	}
    }

    my($result_count);
    if(defined($pager)) {
	my($func) = sub {
	    $self->searcher_pager($template, $sql, $context, @_);
	};

	my($page) = $context->{'page'} || 0;
	my($page_length) = $context->{'page_length'} || 0;
	my($url) = $context->{'url'};
	$result_count = pager($page,
			      $page_length,
			      $func,
			      "$url?$params&",
			      $pager->{'assoc'});

	if($pager->{'assoc'}->{'_MAXPAGES_'} <= 1) {
	    $pager->{'skip'} = 'yes';
	}
    } else {
	$result_count = $self->searcher_nopager($template, $sql, $context);
    }

    template_set($assoc, '_SCRIPT_', $context->{'url'});

    if(exists($context->{'template_set'})) {
	my($func) = $context->{'template_set'};
	&$func($template, $context);
    }
    if(exists($assoc->{'_LETTER_'})) {
	my($letter) = $context->{'real where'} =~ /like \'(\w)\%\'/;
	$assoc->{'_LETTER_'} = uc($letter);
    }

    if($build_template) {
	return $self->stemplate_build($template);
    } else {
	return $result_count;
    }
}

sub searcher_sql {
    my($self, $template, $table, $context) = @_;

    my($info) = $self->db()->info_table($table);

    return "select $info->{'_primary_'} from $table $context->{'real where'} $context->{'real order'}";
}

sub searcher_pager {
    my($self, $template, $sql, $context, $index, $length) = @_;
    my($table) = $context->{'table'};

    my($select) = $context->{'select'};
    if(!defined($select)) {
	$select = sub {
	    $self->db()->select(@_);
	};
    }

    my($rows, $rows_total) = &$select($sql, $index, $length);
    if(defined($rows) && $rows_total > 0) {
	dbg("searcher_pager: found $rows_total, show " . scalar(@$rows), "sqledit");
    } else {
	$self->serror("found nothing") if(!$context->{'accept_empty'});
    }
    if($rows_total > 0) {
	$self->searcher_layout($template, $table, $rows, $context);
    }

    return $rows_total;
}

sub searcher_nopager {
    my($self, $template, $sql, $context) = @_;

    my($table) = $context->{'table'};

    my($select) = $context->{'select'};
    if(!defined($select)) {
	$select = sub {
	    $self->db()->select(@_);
	};
    }
    
    my($rows) = &$select($sql, 0, 100000);
    my($rows_count) = 0;
    if(!defined($rows)) {
	dbg("searcher_pager: found nothing", "sqledit");
    } else {
	$rows_count = scalar(@$rows);
	$self->searcher_layout($template, $table, $rows, $context);
    }
    return $rows_count;
}

sub searcher_layout {
    my($self, $template, $tables, $rows, $context) = @_;

    if(@$rows <= 0) {
	$template->{'skip'} = 1;
	return;
    }

    if(!ref($tables)) {
	$tables = [ $tables ];
    }

    #
    # Find out which display method we should use
    #
    my($func) = $context->{'layout'};
    if(!defined($func)) {
	dbg("searcher_layout: using default row layout", "sqledit");
	$func = sub {
	    $self->searcher_layout_result(@_);
	};
    }

    #
    # Find out the entry template that allows us to compute the
    # list of fields we have to retrieve.
    #
    my($template_entry);
    my($params) = $template->{'params'};
    if(!exists($params->{'style'}) || $params->{'style'} eq 'list') {
	$template_entry = $template->{'children'}->{'entry'};
	error("missing entry template") if(!defined($template_entry));
    } elsif($params->{'style'} =~ /^v?table$/) {
	dbg("searcher_layout: style table", "sqledit");
	my($template_row) = $template->{'children'}->{'row'};
	error("missing row template") if(!defined($template_row));
	$template_entry = $template_row->{'children'}->{'entry'};
	error("missing entry template") if(!defined($template_entry));
    } else {
	croak("unknown style $params->{'style'}");
    }

    #
    # Expand rows, if necessary
    #
    my($results);
    my($expand) = $context->{'expand'};
    if(!defined($expand)) {
	foreach my $row (@$rows) {
	    push(@$results, { map { $_ => $row } @$tables });
	}
    } elsif(!ref($expand)) {
	dbg("searcher_layout: expanding rows", "sqledit");
	$results = $self->searcher_expand($template_entry, $tables, $rows, $context);
    } else {
	$results = &$expand($template_entry, $tables, $rows, $context);
    }

    #
    # Display result of expansion
    #
    my @html;
    if(!exists($params->{'style'}) || $params->{'style'} eq 'list') {
	dbg("searcher_layout: style list", "sqledit");
	foreach my $result (@$results) {
	    push @html, &$func($template_entry, '_noname_', $result, $context);
	}
	$template_entry->{'html'} = join "", @html;
    }
    elsif($params->{'style'} =~ /^v?table$/) {
	dbg("searcher_layout: style table", "sqledit");
	my($template_row) = $template->{'children'}->{'row'};
	error("missing row template") if(!defined($template_row));
	my($ncolumns) = $params->{'columns'} || 5;
	if ($params->{'style'} eq 'vtable') {
	    my($n) = scalar(@$results);
	    my($max) = $n + $ncolumns - 1;
	    my($rows) = int($max / $ncolumns);
	    @$results = map {
		my($c) = $_ % $ncolumns;
		my($r) = int($_ / $ncolumns);
		my($offset) = ($c * $rows) + $r;
		$results->[$offset];
		} 0..($max - 1);
	}
	my($count) = 0;
	my($columns) = '';
	foreach my $result (@$results) {
	    if($count >= $ncolumns) {
		$template_entry->{'html'} = $columns;
		push @html, $self->stemplate_build($template_row);
		$columns = '';
		$count = 0;
	    }
	    $count++;
	    $columns .= &$func($template_entry, '_noname_', $result, $context)
	      if $result;
	}
	if($count > 0) {
	    $template_entry->{'html'} = $columns;
	    push @html, $self->stemplate_build($template_row);
	}
	$template_row->{'html'} = join "", @html;
    }
    else {
	croak("unknown style '$params->{style}'");
    }
}

sub searcher_expand {
    my($self, $template, $tables, $rows, $context) = @_;

    my($table) = $tables->[0];
    my($info) = $self->db()->info_table($table);
    my($primary_key) = $info->{'_primary_'};
    my($primary_values) = join(',', map { $_->{$primary_key} } @$rows);
    my($fields) = $self->searcher_select_fields($template, $table, $template->{'assoc'}, $context->{'fields'});
    #
    # Combine all the fields in all children
    #
    if(exists($template->{'children'})) {
	my($child);
	foreach $child (values(%{$template->{'children'}})) {
	    $fields .= ",";
	    $fields .= $self->searcher_select_fields($child, $table, $child->{'assoc'});
	}
	$fields =~ s/^,+//;
	$fields = join(',', sortu(split(',', $fields, )));
    }
    error("no field to retrieve according to template entry") if(!defined($fields));
    my($sql) = "select $fields from $table where $primary_key in ($primary_values) $context->{'real order'}";
    dbg("searcher_layout: $sql", "sqledit");
    ($rows) = $self->db()->sexec_select($table, $sql);
    my($results);
    my($row);
    foreach $row (@$rows) {
	push(@$results, { map { $_ => $row } @$tables });
    }

    return $results;
}

sub searcher_layout_result {
    my($self, $template, $name, $result, $context) = @_;

    dbg("searcher_layout_result: name = $name", "sqledit");
    #
    # Format row according to template
    #
    my($template_child) = $template;
    if(exists($template->{'children'})) {
	my($children) = $template->{'children'};
	my($name_child);
	foreach $name_child (keys(%$children)) {
	    if($name_child eq $name) {
		$template_child = $children->{$name};
	    } elsif(!exists($children->{$name_child}->{'skip'})) {
		#
		# Only set skip if it does not exist. This gives
		# the opportunity to the caller to select children
		# to be displayed with skip = 0
		#
		$children->{$name_child}->{'skip'} = 1;
	    }
	}
    }
    my($assoc) = $template_child->{'assoc'};

    my($table, $row);
    while(($table, $row) = each(%$result)) {
	next if(!defined($row));
	if(exists($assoc->{'_DEFAULTROW_'})) {
	    $assoc->{'_DEFAULTROW_'} = $self->row2view($row, $table, 'short');
	} else {
	    $self->row2assoc($table, $row, $assoc);
	}
	if(exists($assoc->{'_LINKS_'})) {
	    $assoc->{'_LINKS_'} = $self->searcher_links($table, $row, $context);
	}
	template_set($assoc, '_SCRIPT_', $context->{'url'});
    }

    return $self->stemplate_build($template);
}

sub searcher_links {
    my($self, $table, $row, $context) = @_;

    my($info) = $self->db()->info_table($table);
    my($html);
    my($tag);
    foreach $tag ('edit', 'remove') {
	$html .= "<a href=\"" . $self->call($table, $info, $row, 'context' => $context) . "\">" . ucfirst($tag) . "</a> ";
    }
#	    my($select_call) = $self->select_call($table, $row);
#	    if(defined($select_call)) {
#		$html .= "<a href=\"$select_call\">Select</a> ";
#	    }
#	    $html .= $self->specific_link($custom, $table, $row, $info);
    return $html;
}

sub searcher_select_fields {
    my($self, $template, $table, $assoc, $fields) = @_;

    if(!defined($template)) {
	error("no entry for $table");
    }
    
    #
    # Collect fields
    #
    my(@fields);
    my($info) = $self->db()->info_table($table);
    my(@set_dict) = exists($info->{'_set_dict_'}) ? @{$info->{'_set_dict_'}} : ();
    if(exists($assoc->{'_DEFAULTROW_'})) {
	dbg("table $table use _DEFAULTROW_", "sqledit");
	#
	# Strip the fake fields generated for multivalue dictionaries.
	#
	@fields = grep { my($name) = $_; grep($_ eq $name, @set_dict) ? () : $name; } @{$info->{'_fields_'}};
    } else {
	my(%fields);
	%fields = map { $_ => 1 } split(',', $fields) if(defined($fields));
	my($func) = sub {
	    my($field, $tag, $desc, $form) = @_;

	    if(!grep($_ eq $field, @set_dict)) {
		$fields{$field} = 1;
	    }
	};
	$self->walk_table_tags($table, $assoc, $func);
	@fields = keys(%fields);
    }

    if(@fields) {
	return join(',', map { "$table.$_" } @fields);
    } else {
	return undef;
    }
}

sub template {
    my($self, $prefix) = @_;
    my($cgi) = $self->{'cgi'};

    my($template) = template_load("$prefix.html", $self->{'templates'}, $cgi->param('style'));
    if(!defined($template)) {
	error("missing template for $prefix.html");
    }
    return $template;
}

sub stemplate_build {
    my($self, $template) = @_;
    my($cgi) = $self->{'cgi'};
    template_set($template->{'assoc'}, '_SCRIPT_', $cgi->script_name());
    template_set($template->{'assoc'}, '_HTMLPATH_', $self->{'htmlpath'});
    return template_build($template);
}

sub search_1 {
    my($self, $template, $sql, $index, $length) = @_;
    my($cgi) = $self->{'cgi'};
    my($table) = $cgi->param('table');

    my($info) = $self->db()->info_table($table);

    #
    # Extract data
    #
    my($rows, $rows_total) = $self->db()->sselect($table, $sql, $index, $length);

    my($links_set) = $self->links_set();
    my($links_set_root) = defined($links_set) ? $links_set->{$table} : undef;
    my($result);
    @{$result->{$table}} = map {
	{
	    'rows' => $_,
	    'children' => (!defined($self->{'relations'}) ? undef : $self->extract_values($_, $table, $links_set_root)),
	}
    } @{$rows};

    dbg("sqledit_search: found $rows_total rows, show only " . scalar(@$rows) . " rows\n", "sqledit");
#    dbg("sqledit_search: result structure : " . ostring($result) . "\n", "sqledit");

    #
    # Display data
    #
    if(!defined($links_set)) {
	$links_set = { $table => undef };
    }

#    dbg("sqledit_search: links_set = " . ostring($links_set) . "\n", "sqledit");
    $template->{'html'} = $self->display_relations($template, $table, $result, 0, $links_set, $index);

#    dbg("sqledit_search: html page is $block\n", "sqledit");
    return $rows_total;
}

sub call {
    my($self, $table, $info, $row, %pairs) = @_;
    my($cgi) = $self->{'cgi'};
    my($primary) = $self->primary($info, $row);
    my($params) = $self->params('primary' => $primary,
				'table' => $table,
				%pairs);
    my($script) = $cgi->url(-absolute => 1);
    return "$script?$params";
}

sub primary {
    my($self, $info, $row) = @_;

    if($info->{'_primary_'}) {
	my($field) = $info->{'_primary_'};
	return $row->{$field};
    }
}

sub list_hook {
    return "";
}

sub list {
    my($self, $cgi) = @_;

    my($mode);
    if($cgi->param('mode')) {
	$mode = "_" . $cgi->param('mode');
    }

    my($html);
    my($file);
    my($databases) = $self->db()->databases();
    my($script) = $cgi->url(-absolute => 1);
    foreach $file (@$databases) {
	my($base, $table) = $file =~ m;(.*)/(.*).frm;;
	next if($cgi->param('mode') ne 'maintain' && $table ne 'start');
	$html .= "<li> $base $table ";
	$html .= "<a href=\"$script?context=search_form&base=$base&table=$table\">Search</a> ";
	$html .= "<a href=\"$script?context=insert_form&base=$base&table=$table\">Add</a> ";

	$html .= $self->list_hook($cgi, $base, $table);
	$html .= "\n";
    }

    return cgi_file_sub("sqledit_list$mode.html",
			'_SCRIPT_' => $script,
			'_BASES_' => $html);
}

sub display_relations {
    my($self, $template, $table, $result, $level, $links_set, $index) = @_;

    my($block);
    my($info) = $self->db()->info_table($table);

    dbg("sqledit_search: display_relations for $table, level $level, relations for table " . join(",", keys(%$links_set)) . "\n", "sqledit");

    #
    # Display record
    #
    my($row);
    foreach $row ( @{$result->{$table}} ) {
	$index++;
	next if(!exists($links_set->{$table}));
	$block .= $self->search_display($template, $table, $row->{'rows'}, $info, $index, $level);
	my($sub_table);
	foreach $sub_table ( keys(%{$row->{'children'}}) ) {
	    $block .= $self->display_relations($template, $sub_table, $row->{'children'}, $level+1, $links_set->{$table}, 0);
	}
    }

    return $block;
}

sub links_set {
    my($self) = @_;
    my($cgi) = $self->{'cgi'};

    my($links_set) = $cgi->param('links_set');
    if(defined($links_set) && $links_set ne '') {
	if(!exists($self->{'links_set'})) {
	    $self->{'links_set'} = parse_links_set($cgi->param('links_set'));
	}
	return $self->{'links_set'};
    }
    return undef;
}

sub parse_links_set {
    my($string) = @_;
    my(%result);

    while($string =~ /(.*?)([(),])(.*)/g) {
	my($before, $match, $after) = ($1, $2, $3);

	if($match eq "(") {
	    my($subresult);
	    ($subresult, $string) = parse_links_set($after);
	    $result{$before} = $subresult;
	} else {
	    if($before =~ /^\w+$/) {
		$result{$before} = undef;
	    }
	    if($match eq ")") {
		return (\%result, $after);
	    } else {
		$string = $after;
	    }
	}
    }
    return \%result;
}

sub extract_values {
    my($self, $row, $table, $hierarchy) = @_;

    return undef if(!defined($hierarchy));

    my($result);
    my($sub_table);
    foreach $sub_table ( keys(%$hierarchy) ) {
	my($desc) = $self->{'relations'}->{$table}->{$sub_table};
	my($linked_field) = $desc->{'field'};
	my($field_to_link) = $desc->{'key'};
	my($value_link) = $row->{$field_to_link};
	my($info_link) = $self->db()->info_table($sub_table);
	my($type_link) = $info_link->{$linked_field}->{'type'};
	my($where_link) = "$linked_field ";
	if($type_link eq 'char') {
	    my($quoted_value) = $self->db()->quote($value_link);
	    $where_link .= "like '$quoted_value' ";
	} elsif($type_link eq 'int' || $type_link eq 'time') {
	    my($operator) = "=";
	    my($tmp) = $value_link;
	    if($tmp =~ /^\s*([<>])\s*(\d+)/) {
		$operator = $1;
		$tmp = $2;
	    } elsif($tmp =~ /(\d+)/) {
		$tmp = $1;
	    } else {
		$tmp = undef;
	    }
	    if(defined($tmp)) {
		$where_link .= "$operator $tmp ";
	    }
	} elsif($type_link eq 'set' || $type_link eq 'enum') {
	    $where_link .= "like '%$value_link%' ";
	}
	my($sql_link) = "select * from $sub_table where $where_link";
	my($sub_rows, $sub_rows_total) = $self->db()->sexec_select($sub_table, $sql_link);
	@{$result->{$sub_table}} = map {
	    {
		'rows' => $_,
		'children' => $self->extract_values($_, $sub_table, $hierarchy->{$sub_table}),
	    }
	} @{$sub_rows};
    }

    return $result;
}

sub specific_link {
    my($self, $table, $row, $info) = @_;

#    if ( !$custom) {
#       return "";
#    } else {
#       return '_SPECIFICLINK_' => "";
#    }
}

sub margin {
    my($self, $legend, $level) = @_;
    my($margin);
    my($margin_table);
    if($level > 0) {
	if(!$legend) {
	    $legend = "&nbsp";
	} else {
	    $legend = "<i>$legend</i>";
	}
	$margin .= "<td width=\"5%\">&nbsp;</td>" x ($level - 1);
	$margin = "$margin<td width=\"5%\">$legend</td>";
    }
    return $margin;
}

sub search_display {
    my($self, $template, $table, $row, $info, $index, $level) = @_;
    my($assoc) = $template->{'assoc'};

    if(exists($assoc->{'_DEFAULTTITLE_'})) {
	$assoc->{'_DEFAULTTITLE_'} = $self->row2title($info, undef, $table);
    }
    if(exists($assoc->{'_DEFAULTROW_'})) {
	$assoc->{'_DEFAULTROW_'} = $self->row2view($row, $table, 'short');
    } else {
	$self->row2assoc($table, $row, $assoc);
    }
    if(exists($assoc->{'_MARGIN_'})) {
	$assoc->{'_MARGIN_'} = $self->margin('', $level);
    }
    if(exists($assoc->{'_MARGINTABLE_'})) {
	$assoc->{'_MARGINTABLE_'} = $self->margin($table, $level);
    }
    if(exists($assoc->{'_LINKS_'})) {
	my($html);
	$html .= "<td colspan=20>";
	my($context);
	foreach $context ('edit', 'remove') {
	    $html .= "<a href=\"" . $self->call($table, $info, $row, 'context' => $context) . "\">" . ucfirst($context) . "</a> ";
	}
	my($select_call) = $self->select_call($table, $row);
	if(defined($select_call)) {
	    $html .= "<a href=\"$select_call\">Select</a> ";
	}
#	    $html .= $self->specific_link($custom, $table, $row, $info);
	$html .= "</td>";
	$assoc->{'_LINKS_'} = $html;
    }
    $assoc->{'_TABLE_'} = $table if(exists($assoc->{'_TABLE_'}));
    $assoc->{'_RANK_'} = $index if(exists($assoc->{'_RANK_'}));
    $self->search_entry_tags($assoc, $info, $row, $table);

    return $self->stemplate_build($template);
}

sub layout_rows {
    my($self, $template, $tables, $rows, $func) = @_;

    if(@$rows <= 0) {
	$template->{'skip'} = 1;
	return;
    }

    if(!ref($tables)) {
	$tables = [ $tables ];
    }
 
    if(!defined($func)) {
	$func = sub {
	    my($template, $row) = @_;
	    my($assoc) = $template->{'assoc'};
	    my($table);
	    foreach $table (@$tables) {
		if(exists($assoc->{'_DEFAULTROW_'})) {
		    $assoc->{'_DEFAULTROW_'} = $self->row2view($row, $table, 'short');
		} else {
		    $self->row2assoc($table, $row, $assoc);
		}
	    }

	    return $self->stemplate_build($template);
	};
    }

    my($html) = '';
    my($params) = $template->{'params'};
    if(!exists($params->{'style'}) || $params->{'style'} eq 'list') {
	my($template_entry) = $template->{'children'}->{'entry'};

	error("missing entry template") if(!defined($template_entry));
	my($row);
	foreach $row (@$rows) {
	    $html .= &$func($template_entry, $row);
	}
	$template_entry->{'html'} = $html;
    } elsif($params->{'style'} eq 'table') {
	my($template_row) = $template->{'children'}->{'row'};
	error("missing row template") if(!defined($template_row));
	my($template_entry) = $template_row->{'children'}->{'entry'};
	error("missing entry template") if(!defined($template_entry));
	my($count_max) = $params->{'columns'} || 5;
	my($count) = 0;
	my($columns) = '';
	my($row);
	foreach $row (@$rows) {
	    if($count >= $count_max) {
		$template_entry->{'html'} = $columns;
		$html .= $self->stemplate_build($template_row);
		$columns = '';
		$count = 0;
	    }
	    $count++;
	    $columns .= &$func($template_entry, $row);
	}
	if($count > 0) {
	    $template_entry->{'html'} = $columns;
	    $html .= $self->stemplate_build($template_row);
	}
	$template_row->{'html'} = $html;
    } else {
	croak("unknown style $params->{'style'}");
    }
}

sub select_call {
    my($self, $table, $row) = @_;
    my($cgi) = $self->{'cgi'};

    return if(!defined($cgi->fct_name()) || $cgi->fct_name() ne 'select');
    
    my($returned) = $cgi->fct_returned();
    
    my($params) = $self->params('context' => 'fct_return');
    my($fields) = $returned->{'fields'};
    my($field);
    foreach $field (split(',', $fields)) {
	$params .= "&$field=" . CGI::escape($row->{$field});
    }

    return $cgi->url(-absolute => 1) . "?$params";
}

sub fct_return {
    my($self, $cgi, $row) = @_;
    $self->{'cgi'} = $cgi;

    my($returned) = $cgi->fct_returned();

    my(%hash);
    if(exists($returned->{'fields'})) {
	my($fields) = $returned->{'fields'};
	my($field);
#    dbg("fields $fields, row contains ". join(" ", keys(%$row)), "sqledit");
	foreach $field (split(',', $fields)) {
	    $hash{$field} = exists($row->{$field}) ? $row->{$field} : $cgi->param($field);
	}
    }

    eval {
	$cgi = $cgi->fct_return(%hash,
				'context' => $returned->{'context'});
    };

    if($@) {
	my($error) = $@;
	print STDERR $error;
	$self->serror("You've probably tried to execute this recursive cgi-bin action twice, see logs");
    }

    my($context) = $returned->{'context'};
    return $self->${context}($cgi);
}

sub params {
    my($self, %pairs) = @_;

    return $self->{'cgi'}->params($self->{'params'}, %pairs);
}

sub hidden {
    my($self, %pairs) = @_;

    return $self->{'cgi'}->hidden($self->{'params'}, %pairs);
}

sub confedit {
    my($self, $cgi) = @_;
    $self->{'cgi'} = $cgi;

    my($action) = $cgi->param('action');
    my($dir) = $ENV{'CONFIG_DIR'} || '.';

    my($file) = $cgi->param('file');
    $self->serror("%s may not contain / ") if($file =~ /\//);
    if(! -f $file) {
	$file = "$dir/$file";
    }
    if(! -f $file && $cgi->param('create')) {
	creat($file);
    }
    $self->serror("%s is not a known file", $file) if(! -f $file);
    my($comment);
    if($action eq "save") {
	$comment = $cgi->param('file') . " saved";
	my($text) = $cgi->param('text');
	$text =~ s/\015//sg;
	writefile($file, $text);
    }
    my($text) = readfile($file);

    my($rows) = $cgi->param('rows') || 24;
    my($cols) = $cgi->param('cols') || 80;

    my($template) = $self->template("edit");
    template_set($template->{'assoc'}, '_TEXT_', Catalog::tools::cgi::myescapeHTML($text));
    template_set($template->{'assoc'}, '_COMMENT_', $comment);
    template_set($template->{'assoc'}, '_ROWS_', $rows);
    template_set($template->{'assoc'}, '_COLS_', $cols);
    template_set($template->{'assoc'}, '_FILE_', $cgi->param('file'));
    return $self->stemplate_build($template);
}

sub close {
    my($self) = @_;

    $self->db()->logoff();
}

sub db {
    my($self) = @_;

    return $self->{'db'};
}

sub imageutil {
    my($self) = @_;

    return $self->{'imageutil'};
}

sub serror {
    my($self, @message) = @_;

    my($template) = $self->template("error");
    my($message) = istring(@message);
    $message = Carp::longmess($message) if $::opt_error_stack;
    template_set($template->{'assoc'}, '_MESSAGE_', $message);
    print $self->stemplate_build($template);
    error("HTMLIZED: $message");
}

1;
# Local Variables: ***
# mode: perl ***
# End: ***
