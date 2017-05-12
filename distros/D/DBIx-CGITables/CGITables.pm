# Copyright (c) Green Smoked Socks Productions y2k

package DBIx::CGITables;

use strict;
use Carp qw(cluck);
use vars qw($VERSION $CGI_Class $Template_Class $Recordset_Class $Client_Error_Class);

$CGI_Class='CGI';
$Template_Class='HTML::Template';
$Recordset_Class='DBIx::Recordset';
$Client_Error_Class='CGI::ClientError';

# Remember to update the POD (yes, even the version number) 
# and to tag the cvs (v-major-minor) upon new version numbers
$VERSION="0.001";

# HACKING INFORMATION
# ===================

# The CGITable class is structured like this:

# Special parameters:
#     $self->{filename}, $self->{query}

# Parameters to DBIx::Recordset:
#     $self->{params}->{$recordset_name}->{$param_key} = $param_value

# Output to template:
#     $self->{output}->{$recordset_name}->[$i]->{$db_key} = $db_value
#     $self->{output}->{cgi_query}->[$i] = {key=>$param_key, value=>$param_value}
#     $self->{output}->{$query_key} = $query_value
#     (...and more are likely to come...)

# to avoid inprobable, but still potential name clashes, a dash (-)
# should be prepended to all the recordset names, except the default
# one ('default')

# Recordset objects:
#     $self->{recordsets}->{$recordset_name}

# Parameters to the template class:
#     $self->{T}->{$option_key}->$option_value

# Special recordset variables (PreserveCase, Debug):
#     $self->{RGV}->{$variable_name}->$variable_value

# Changes might occur to the internal data structure, but the API shouldn't.

# Some of the subs below might be splitted if it's needed (i.e. for
# making it easier to alter the class behaviour by inheritance)

sub new {
    # Class identification:
    my $object_or_class = shift; my $class = ref($object_or_class) || $object_or_class;

    # Eventually import params:
    my $self={params=>{default=>($_[0] || {})}};

    # Check for the special !!Query param and/or !!QueryClass and
    # initialize the query:
    if (!($self->{query}=$self->{params}->{default}->{'!!Query'})) {
	$self->{params}->{default}->{'!!QueryClass'}=$CGI_Class
	    unless $self->{params}->{default}->{'!!QueryClass'};
	eval "require ".$self->{params}->{default}->{'!!QueryClass'};
	$self->{query}=$self->{params}->{default}->{'!!QueryClass'}->new;
	return undef if !defined $self->{query};
    }

    # Check for the special !!Filename param:
    $self->{filename}=$self->{params}->{default}->{'!!Filename'} || 
	$ENV{'PATH_TRANSLATED'} || 
	    undef;
    unless ($self->{filename}) {
	print "What template do you want to parse?";
	# Should have used readline ... but at the other hand, this is _not_ the intended usage
	$self->{filename}=<>;
    }
    die "Template not specified"
	unless $self->{filename};

    die "Template ($self->{filename}) not readable or doesn't exist"
	unless -r $self->{filename};

    # Check for !!ParamFileDir and !!ParamFile
    $self->{param_file}=$self->{params}->{default}->{'!!ParamFile'}
        if exists $self->{params}->{default}->{'!!ParamFile'};
    $self->{param_file_dir}=$self->{params}->{default}->{'!!ParamFileDir'}
        if exists $self->{params}->{default}->{'!!ParamFileDir'};

    bless $self, $class;
    return $self;
}

sub search_execute_and_do_everything_even_parse_the_template {
    my $self=shift;
    my $hash=shift;
    $self->fetch_params_from_cookies();
    $self->fetch_params_from_query();
    $self->fetch_params_from_file();
    $self->fetch_params_from_hash($hash)
	if defined($hash);
    $self->execute_recordsets();
    $self->parse_template();
}

sub fetch_params_from_query {
    my $self=shift;
    my $q=$self->{query};
    for my $key ($q->param) {
	my $value=$q->param($key);
	$self->process_param(0, $key, $value);
	push (@{$self->{output}->{cgi_query}}, {key => $key, value => $value});
    }
}

sub fetch_params_from_cookies {
    # It might be relevant to set i.e. !Username and !Password in the cookies.
    # stub!
}

sub fetch_params_from_file {
    my $self=shift;
    my $file=$self->find_param_file() || return 0;
    open(FILE, "<$file");
    while(<FILE>) {
	chop;
	$self->process_param(1, $_);
    }
    close(FILE);
}

sub find_param_file {
    # See the POD for naming conventions

    my $self=shift;
    return $self->{param_file}
        if exists $self->{param_file};
    my $f=$self->{filename};
    $f =~ /\.(\w+)$/ 
	|| die "The template filename ($f) should have an ending (like .databasetemplate or .end or .dct or whatever)";
    my $pf="$`.param.$1";
    if (my $d=$self->{param_file_dir}) {
	$pf =~ m|/([^/]+)$| || die "given template is a dir?";
	$pf = $d . $1;
    }
    die "Parameter file ($pf) not readable (template filename: $f, param )" unless -r $pf;
    return $pf;
}

sub process_param {
    my $self=shift;
    my $single=shift;
    my $special;
    my $key;
    my $value;
    my $name='default';
    $_=shift;

    /^(;|#|--)/ && return;
    /^(\s*)$/ && return;

    if (/^\%([^\ ]*) /) {
	chop($special=$&);
	$_=$';
    }
    
    if ($single) {
	if (m#^(.+?)\=#) {
	    $key=$1;
	    $value=$';
	} else {
	    $key=$_;
	    $value=1;
	}
    } else {
	$key=$_;
	$value=shift;
    }

    if ($key =~ m#/(\w+)/#) {
	$name=$1;
	$key=$';
    }

    # Ordinary variable, override or yield and no previous param set.
    if (!$special || ($special =~ /^\%[\=\!]/)
	|| ($special =~ /^\%\?/ && !exists $self->{params}->{$name}->{$key})) {
	# Special key containing '/':
	$self->{output}->{$key}=$value;
	my @keys=split(/\//, $key);
	$self->{params}->{$name}={}
	    unless (exists $self->{params}->{$name});
	my $p=$self->{params}->{$name};
	while (@keys) {
	    $key=shift @keys;
	    if (@keys) {
		if (!exists $p->{$key}) {
		    $p->{$key}={};
		}
		$p=$p->{$key};
	    } else {
		$p->{$key}=$value;
	    }
	}
    }

    # Ignore!
    elsif ($special eq '%()') {
	return;
    } 

    # Ignore or override!
    elsif ($special eq '%!()') {
	die "stub!";
    } 

    # Recordset Global Variable or Template option
    elsif ($special =~ '%(RGV|T)') {
	$self->{$1}->{$key}=$value;
    } 

    # Oup!
    elsif (2) {
	die "stub!";
    }

}

# Used in sub execute_recordsets.  Can be overridden.
sub load_recordset_class {
    my $self=shift;
    eval "require $$self{recordset_class}";

    for (keys %{$self->{'RGV'}}) {
	no strict 'refs';
	if (/^(Debug|PreserveCase|FetchsizeWarn)$/) {
	    $ {*{"$$self{recordset_class}::$1"}{SCALAR}}=$self->{'RGV'}->{$_};
	} else {

	    # Somebody (the web user or anyone with access to the
	    # parameter file or the (F)CGI script) has tried tom
	    # modify some variable (s)he's not allowed to update.

	    # I didn't see the need for setting other things than
	    # Debug, PreserveCase and FetchsizeWarn, if I'm wrong, the
	    # (Debug|PreserveCase|FetchsizeWarn) line above has to be
	    # modified (Better: put it as a package-global variable)

	    warn "Not allowed (check the code for more info)";
	}
    }
}

# Used in sub execute_recordsets.  Can be overridden.
sub massage_init_parameters {
    my $self=shift;
    my $p=shift;
    
    # Temporary.  This should be declared somewhere else.
    $p->{'!DBIAttr'}={RaiseError=>0, PrintError=>0};
    
    # Empty Usernames are perfectly valid in MySQL, and I
    # think it's more apropriate to have "" as default than
    # whatever user the webserver is running as.
    $p->{'!Username'} = 
	$self->{params}->{default}->{'!Username'} || "";
    
    # Locally I have set up different security models; login
    # without a password (or by submitting a password in the
    # clear), login with password over a secure line, and a
    # login with a valid SSL certificate.  For the first I've
    # put on an extention "_nopass" to the username, the
    # latter "_ssl".  Anyway, the user shouldn't have to know
    # about those extentions.
    $p->{'!Username'} .= 
	$p->{'!UsernameExtention'} || "";
    if (my $val=$p->{'!ConvertTimestampMysql2Iso'}) {
	for my $v (split /,/, $val) {
	    $p->{'!Filter'}->{$v}=
		[undef, \&timestamp_mysql2iso]
	}
    }

    # Do this recursively
    for my $l (keys %{$p->{'!Links'}}) {
	$self->massage_init_parameters($p->{'!Links'}->{$l});
    }
}

# Used in sub execute_recordsets.  Can be overridden.
sub massage_where_parameters {
    my $self=shift;
    my $p=shift;

    # Support/expand the $substring_search parameter
    if (my $val=$p->{'$substring_search'}) {
	for (split(/,/, $val)) {
	    $p->{'*'.$_}=" LIKE ";
	    $p->{$_}= "%$$p{$_}%"
		unless exists $p->{'=update'} 
	            || exists $p->{'=insert'} 
                    || !$p->{$_};
	}
    }

    # Do this recursively
    for my $l (keys %{$p->{'!Links'}}) {
	$self->massage_where_parameters($p->{'!Links'}->{$l});
    }
}

sub execute_recordsets {
    my $self=shift;

    $self->{params}->{default}->{'!DoNothing'} && return;

    # Check for the special !RecordsetClass:
    $self->{recordset_class}=
	$self->{params}->{default}->{'!RecordsetClass'} ||
	    $Recordset_Class;

    $self->load_recordset_class();

    for my $query (keys %{$self->{params}}) {

	if ($self->{params}->{$query}->{'!SearchForm'}) {

	    # Set ?count
	    $self->{output}->{'?count'}=0;

	    # Make one empty LOOP element
	    $self->{output}->{$query}=[{}];

	} else {

	    $self->massage_init_parameters($self->{params}->{$query});

	    unless ($self->{recordsets}->{$query}=
		tie (@{$self->{output}->{$query}}, 
		     $self->{recordset_class}, 
		     $self->{params}->{$query})) {
		my $error=$DBIx::Recordset::LastError || $DBI::errstr
		    || die "Could not tie array and no error message present";
		$self->handle_error($error);
	    }

	    $self->massage_where_parameters($self->{params}->{$query});

	    $self->{recordsets}->{$query}->Execute($self->{params}->{$query}) 
		|| $self->handle_error($self->{recordsets}->{$query}->LastError())
		    if (defined $self->{recordsets}->{$query});

	    # If we have added/updated something, we usually also want to
	    # display the changes/new record:

	    if (0||$self->{params}->{default}->{'=update'} ||
		$self->{params}->{default}->{'=insert'}) {

		$self->{recordsets}->{$query}->Select($self->{params}->{$query})
		    || $self->handle_error($self->{recordsets}->{$query}->LastError())
			if (defined $self->{recordsets}->{$query});

	    }

	    # Copy the data if needed (Tie::ARRAY not implemented properly
	    # in earlier versions of perl + many DBMS'es doesn't give away
	    # the count anyway ... and the current version of HTML::Template
	    # need to know the size of the array.
	    
	    no strict 'refs';

	    if ($ {*{"$$self{recordset_class}::FetchsizeWarn"}{SCALAR}} ||
		$]<5.00504) {
		# This really shouldn't be necessary :/
		my $hash_with_broken_arrays=$self->{output};
		$self->{output}={};
		&faenskopiering($hash_with_broken_arrays, $self->{output}, 
				$self->{recordsets}, $self->{params});
	    }

	    # Set ?count
	    $self->{output}->{'?count'}=scalar @{$self->{output}->{default}};
	}
    }
}

sub handle_error {
    my $self=shift;
    my $errorobject=shift;
    if (ref $errorobject) {
	die "stub!";
    } else {
	# Is this DBD-dependent?  I guess so.  It should be considered
	# if it can be done in some DBD-independent way.

	# First the client errors:
	if ($errorobject =~ /^Access denied/) {
	    $self->{status}->{error}="The database reported:\n$errorobject\n\nThis probably means either that you're using the wrong username, wrong password or that you haven't been granted access.";
	} else {  

# We shouldn't give away the error message to the user (security
# reasons + that it's likely to be misunderstood by a stupid end user
# + that probably only the server administrator can do anything
# anyway).  Let's view a 500 page, preferable with lots of bells and
# whistles and even a banner to increase the income.

	    die $errorobject;
	}
    }
}

sub parse_template {
    my $self=shift;

    my $f=$self->{filename};

    # An alternative template might be chosen with the "!Goto" parameter
    my $g=$self->{params}->{'!Goto'} || undef ; 

    # Let's see if there is an alternative template...
    # See the POD for naming conventions

    # Separate dir, base and ending
    my ($dir, $base, $ending) = $f =~ /(.*?)([^\/]*)\.(\w+)$/;

    # (I guess there might be problems under substandard OS'es using
    # different directory naming schemes.  As if I care.  But I might
    # be willing to accept a patch)

    my $st=$self->{status};

    if ($st->{error}) {
	$f="$dir$base.error.$ending";
	if (! -r $f) {
	    warn "Error: $$st{error} (error template not found)";
	    eval "require $Client_Error_Class";
	    $Client_Error_Class->error($$st{error}); return;
	}
    }

    my $cnt=$self->{output}->{'?count'}; 

    # templates with extentions found_more, found_one, found_none and
    # found_35 can be used.

    my $found1=($cnt>1 ? "found_more" : ($cnt==1 ? "found_one" : "found_none"));
    my $found2="found_".$cnt;

  STATUS_TEMPLATE:
    for ("update_ok", "delete_ok", 
	 "add_ok", $found2, $found1) {
	if ($st->{$_}||/^found_/) {
	    if (-r "$g.$_.$ending") {
		$self->{filename}="$dir$g.$_.$ending";
		last STATUS_TEMPLATE;
	    } elsif (-r "$dir$base.$_.$ending") {
		$self->{filename}="$dir$base.$_.$ending";
		last STATUS_TEMPLATE;
	    }
	}
    }

    # Check for the special !TemplateClass:
    $self->{template_class}=
	$self->{params}->{default}->{'!TemplateClass'} ||
	    $Template_Class;

    eval "require $$self{template_class}";

    $self->{T}->{filename}=$self->{filename};

    my $template=$self->{template_class}->new(%{$self->{T}});

    no strict 'refs';

    $template->param(%{$self->{output}});

    if (my $http=$self->{params}->{default}->{'!HTTPHeaders'}) {
	print $http, "\n";
    } elsif (my $ct=$self->{params}->{default}->{'!ContentType'}) {
	print "Content-Type: $ct\n\n";
    }

    print $template->output;
}

# Recursive sub for copying the output hash. This one shouldn't be
# necessary ... but it seems like it is, due to the TIE not working as
# good as it should :(

# This sub will eventually produce weird results or even recurse
# forever if given hashes with "reused" data or looping references.
# So don't do it.

# Eventually I inserted other features here as well.  It's hacky, and
# should disappear.  The features are:

# - mod2
# - fetch_* (not supported, subqueries are always fetched here)
# - generate_booleans

sub faenskopiering {
    my $src=shift;
    my $dst=shift;
    my $rsh=shift; # What? Why? Shouldn't params be good enough, huh?
    my $params=shift;

    for (keys %$src) {
	if (ref $src->{$_} eq "ARRAY"
	    || $src->{$_} =~ /^\*DBIx::Recordset/) # Ouch, ugly, ugly, ugly..
	{ 
	    my $i=0;

	    # Aaaahhrgghajgkjgussakjlf!
	    my $links;
	    my $p;
	    if (defined $rsh && ref $rsh eq "HASH" && exists $rsh->{$_}) {
		$links=$rsh->{$_};
		$p=$params->{$_};
		if (defined $links && ref $links ne "HASH") {
		    $links=$links->Links();
		} else {
		    $links=$links->{'!Links'};
		}
	    }
	    
	    while (my $z=$src->{$_}->[$i] || undef) {
		if (ref $z eq "HASH") {
		    $dst->{$_}->[$i]={};

		    # Feature hack to get mod2 working:
		    $dst->{$_}->[$i]->{'?mod2'}=$i%2;

		    # Feature hack to get generate_booleans working:
		    for my $k (split(/\,/, $p->{'$generate_booleans'})) {
			$dst->{$_}->[$i]->{$k.'_'.$src->{$_}->[$i]->{$k}}=1;
		    }

		    for my $l (keys %$links) {
			# gurgleblargefaensdritt!
			my $dumb=$src->{$_}->[$i]->{$l};
		    }
		    &faenskopiering($z, $dst->{$_}->[$i], $links, $p->{'!Links'});
		} else {
		    warn "This code shouldn't be executed?";
		    $dst->{$_}->[$i]=$z;
		}
		$i++;
	    }
	} elsif (ref $src->{$_} eq "HASH") {
	    &faenskopiering($src->{$_}, $dst->{$_});
	} else {
	    $dst->{$_}=$src->{$_};
	}
    }
}

sub timestamp_mysql2iso {
    $_=shift;
    /^(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})$/; 
    return "$1-$2-$3 $4:$5:$6";
}



__END__

=head1 NAME

DBIx::CGITables 0.001 - Easy DB access from a CGI

=head1 SYNOPSIS

use DBIx::CGITables;

my %parameters=();

my $query=DBIx::CGITables->new(\%parameters));

$query->search_execute_and_do_everything_even_parse_the_template();


=head1 DESCRIPTION

This module is under development - and this version is not tested very
well.  The documentation might not be completely in sync with the
latest changes, and the documentation is not optimized for easy
understanding at the moment.  Sorry.

DBIx::CGITables is made for making database access through CGIs really
easy.

It's completely template-oriented.  The templates are in
HTML::Template format.  Some templates might be set up quickly by
using DBIx::CGITables::MakeTemplates; see the doc for this module.
Some web designer should fix the templates a bit.

The template approach might make the system a bit "static".  Gerald
Richter has another approach based upon HTML::Embperl (not published
at the time I write this), if you'd better like a more dynamic system.
Anyway, I find it quite important not to mix HTML and code - the HTML
documents should be easy to manipulate by non-technical web editors.

Ideally, HTML and (language-dependent) content should be splitted.  I
think such things might be done better by using Zope than cgis.

The database handling is done by DBIx::Recordset - this module gets
its parametres first from a CGI query, then it might be overridden or
completed by a parameter file, and the caller (your .cgi script or
whatever) is also free to modify or add parameters.

I'm hoping that anybody should get a working (though, probably ugly)
CGI interface to any kind of database simply:

1. Run DBIx::CGITables::MakeTemplates (see the pod)

2. Create the script given above at SYNOPSIS

3. Set up the webserver correct.

4. If you're not satisfied with the look, try to edit the html
   templates.

5. If you're not satisfied with the functionality, try reading the
   rest of this documentation, and the DBIx::Recordset documentation.

6. If you're still not satisfied with the functionality and/or you
   find bugs, hack the code and submit the patches to the mailinglist
   and/or me and/or (if DBIx::Recordset is affected) Gerhard Richter.
   If you're not a perl hacker, or if you don't have time, send a mail
   about what's wrong and/or what's missing to the mailinglist anyway.
   Or privately to me if you don't want to write to a mailinglist.

=head1 PARAMETERS

=head2 How to feed the script with parameters

Firstly, parameters are taken from the query.

Then, parameters on are taken from the I<parameter file>.  This file
is either located in the same folder as the templates, or in a folder
as specified in the parameters.  The parameter file contains options
to DBIx::CGITables and to DBIx::Recordsets.  I'm more or less trying
to follow up the parameter style DBIx::Recordset is using - with one
special character in front of the parameter suggesting what kind of
parameter it is.  It is quite a bit kludgy, but it works.  The
parameters should be at the key=value form, i.e.:

!Table=tablename
!DataSource=...
!NoRGV
!NoT

CGITables will recognize a key starting with =, so it's possible to
put up '=execute=1' at a line.  The default value will be 1, so
'=execute' should be equivalent.

If the line contains more than one equal sign which is not at the
start of the line, the other equal signs will be threated as a part of
the value.

Eventually conflicts will appear as the param keys are duplicated in
the query and in the param file.  The default is that the param file
overrides the query.  This might be changed by a special code inserted
in front of the key=value-pair to override this behaviour.  (I think
too many special codes might be a bit hairy ... but I hope this will
work out anyway).  Those codes start with '%' since this character is
not used by DBIx::Recordset, and they're separated from the key=value
couple by one space.  In addition to suggesting how collitions should
be 

%= or
%! 	  Always override options set other places

%+, 	  Add new stuff to a comma separated list.  The comma might be
	  replaced by any other character, and to \t and \n, or simply
	  removed. Use '\ ' for a blank and '\\' for a backslash.

%^, 	  Prepend, separate from existing value with a comma (same
	  rules as above)

%?        Yield - use this with default values that should only be set 
	  if no other values are set.

%!()      Override or ignore - that is, if the key exists, overwrite,
          if not, ignore.

%() 	  Ignore option (but keep it in template outputs)

%T        Template option.  The key=value is given the Template Class.

%RGV      Recordset Global Variable, most important ones are
          PreserveCase and Debug.

For =execute parameters (see DBIx::Recordset), %= or %! will
`override' other =execute by deleting those.  %+ and %^ will execute
things in order.  The default is to use the priority set by
DBIx::Recordset.

In my older system, I had something called dependent and independent
subqueries.  A `dependent subquery' is a link in the DBIx::Recordset
terminology.  An `independent subquery' would be an independent
DBIx::Recordset object, i.e. for fetching data for a HTML select box.
I also had an option to only `resolve' links when the select returned
only one row - not to waste time fetching too much data when a long
list was fetched.  I guess Recordset handles this more or less
automagically.

`dependent subqueries' (or links, if you'd like) might be handed over
like this:

!Links/-street/!Table=street
!Links/-street/!LinkedField=id
!Links/-street/!MainField=street_id

Drop the first `!Links' to create an independent subquery.  The
primary subquery has the tag "default" without a starting minus.  The
tags should better start with minus, to avoid inprobable though
potential clashes with other output template substitutions.

My earlier systems had some weird syntax for creating misc lists from
the parameters.  DBIx::Recordset uses string splitting.

=head2 First characters

The first character in a parameter key or a line in the parameter file
is often special.  It's a bit messy, but I think it's the easiest way
to do it, anyway - if the rules are obeyed there shouldn't be any
ambiguisities.  Here's a complete list of the first characters:

 % - reserved for a `special handling' code putted in front of the
     real key/param.  This special code is usually describing how to
     handle parameter collitions, but also to tell that the key/param
     should be ignored, or belongs somewhere else (i.e. the
     PreserveCase option is a global variable that might need
     modification)

 / - reserved for extra named Recordset objects.

 ! - reserved for Recordset initialization and important parameters to
     CGITables.

 - - reserved for the name of a named Recordset object.

See the DBIx::Recordset manual for those:
 ' - reserved for a DB column key = value that needs quoting
 # -      ...... numeric value
 \ -      ...... value that should not be quoted (i.e. SQL function)
 + -      ...... value with multiple fields
 * -      ...... Operator for DB column key

 $ - misc options to Recordset and CGITables.

 = - execute commands to Recordset

 ? - extra output (typically ?id and ?count)

 ; - If you need extra parameters for containing state, start the
     variable name with one of those "comment" signs to avoid possible
     clashes.


=head2 Supported and future parameters

Supported parameters:

!!Filename - defaults to $ENV{PATH_TRANSLATED}

!!ParamFileDir - Default directory for finding ParamFile

!!ParamFile - See below for default.  Ignores ParamFileDir.

!!QueryClass - defaults to 'CGI', but I'm intending to head for CGI::Fast

!!Query - defaults to new !!QueryClass

!TemplateClass - defaults to 'HTML::Template'

!RecordsetClass - defaults to 'DBIx::Recordset'

!DoNothing

!SearchForm specifies that a search form should be printed. No
	searching is done, and the default loop is returned with one
	empty element.  This is typically useful when viewing the data
	in a looped form, then this one will create an empty form.


The parameters starting with '!!' must be set before the query and
parameter file is parsed.

!Mod2 should give an output variable ?mod2 which indicates whether the
row count is an odd or not.  This is a very popular feature demand,
though not possible to implement in a nice way in this scheme.  I
don't think it belongs to the template engine, but it would be quite
ugly putting it elsewhere, I think.  I've putted a hack into the sub
faenskopiering which really shouldn't be called in the first place.
This hack ignores !Mod2 and inserts ?mod2 into the tables.

$substring_search=column[,column..] will enable substring search for
the selected attribute.  This means *column will be set to " LIKE "
and the value will be set to "%value%" in searches.  This should be
used with care, as it might strain on most databases.  Anyway, mysql
handles it well. Case sensitivity might be an issue, searches in mysql
are always case insensitive.

Possible future parameters:
!IncludeParamfile
!ParamMacro
!Ooups
!OtherTemplate
!SetSelected

For !Links:
$fetch_always (default)
$fetch_when_found_one 
$fetch_when_found_more
$fetch_when_found_none


Unfortunately I don't have the time writing more docs due to
deadlines.

=head2 Output to the templates

Unfortunately I don't have the time writing more docs due to
deadlines.

    ?count (at the top level)
        The number of elements returned.  Nice to use in constructs
        like 
           <TMPL_UNLESS name="?count">Sorry, didn't find
           anything</TMPL_UNLESS>

    ?mod2 (in all recordset loops)
        0 for even, 1 for odd (0 beeing "odd")    

    any parameter key (at the top level) will give the corresponding
    value.

    a loop called cgi_query with the variables key and value will give
    the query - nice for forwarding a query in hidden input tags.

    Each database query have a loop with _only_ the database values
    (except ?mod2 which really is a hack).  It would have helped a lot
    to have access to the outer scope variables in the inner loop, but
    it seems like the author of the template engine in use disagrees.

=head1 TEMPLATE NAMING CONVENTIONS

The templates should have an extention matching /\.(\w+)$/ - typically
sth like mydatabase.CGITables or mydatabase.db or mydatabase.db_html.
The script will then search for the param file mydatabase.param.$1,
i.e. mydatabase.param.db.  It might also use another template if
found, mydatabase.$status.$1, where $status might be one of (in
prioritied order):

    error
    update_ok
    delete_ok
    add_ok    
    found_$n
    found_more

(this is not completely implemented yet)

=head1 TODO

Probably a lot of important features are missing.  It might also be
slow as it's costly to build Recordsets, and they're discarded after
each call to the cgi; I'm intending to solve this by optimizing for
CGI::Fast and storing the frequently used recordsets in a cache.
Eventually such a cache should be kept in shared memory.  I haven't
looked at it yet, but Sam Tregar has announced some general module for
keeping caches in shared memory.

=head1 KNOWN BUGS

The code contains this line several places:
   die "stub!";

When this code is executed with the warning flag, there might be some
warnings popping up from the DBIx::Recordset module.  Those will
eventually disappear in newer versions of DBIx::Recordset.

This is UNDER DEVELOPMENT and ABSOLUTELY NOT GOOD ENOUGH TESTED.  The
number of unknown bugs is probably high.

=head1 HISTORY

Version 0.

This started as some template cgi system that needed database access.
To allow better flexibility, I made some hacks to allow SQL code to be
inserted into the template.  This was ... ugly, hairy and hacky.  I
expanded it, so the SQL code could be in separate files.  It still was
ugly, hairy and hacky.

Version 1.

I started more or less from scratch, and made a new system, where SQL
code and other parameters to the script could be inserted into a
special parameter file.  The script would "automagically" generate SQL
to select, update, insert and delete rows from tables.  It started out
a lot better than version 0, but it was still hairy, and it certainly
only became worse and worse as more and more features was to be added.

Version 2.

I started from scratch again, this time with object oriented modules -
DBIx::Access and DBIx::CGIAccess.  This time I aimed for cleanliness.
But I think it has grown more messy as more features was to be crammed
in.  I'm currently merging from the Solid database to MySQL - and I'm
a bit horrified because MySQL is case sensitive, and Solid wasn't -
which might mean that I will have to redesign some of the parameter
syntax (I've chosen UPPERCASE for database column names, and lowercase
for misc options).

Version 3.

I registered at CPAN and got a "go" for DBIx::Tables and
DBIx::CGITables.

I scratched my head in a week.  Then I started from scratch again,
discarding DBIx::Tables for DBIx::Recordset.

Some of the uglyness from earlier versions remain - a quite "ugly"
symbol usage in the param file/query, like "%() !Table=foo".  Maybe I
would have tried doing it in a better way if it wasn't for Recordset
already having parameters prepended by a special character.

=head1 HACKING

Feel free to submit patches, but also normal feedback, bugfixes and
wishlists.

=head1 SECURITY

It's up to you to provide proper security.  I think the Right Way to
do it is to let the .cgi do the authentication (i.e. by SSL
certificates or transmitting the DB login and password encrypted) and
then let the DBMS control what privilegies the user should have.

Another way is to override all potentially harmful parameters to the
DBIx::Recordset, either by the param file or by a hash to sub
search_execute_and_do_everything_even_parse_the_template

=head1 AUTHOR

Tobias Brox <tobiasb@funcom.com>

Feedback is appreciated - even flames.  I will eventually put up a
mailing list if I notice any interesst about this module.

This module was written partly in my worktime.  Shameless plug for my
employer:

Check our upcoming MMORPG at http://www.anarchy-online.com/ - Linux
client will be available.

Play multiplayer Spades, Backgammon, Poker and more for free at
http://www.funcom.com/ (Java)

