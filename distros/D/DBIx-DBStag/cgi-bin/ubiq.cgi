#!/usr/local/bin/perl -w

BEGIN{
    eval{do "dbenv.pl"};
    die $@ if $@;
};   # end of sub: 

use strict;
use lib split(/:/, $ENV{STAGLIB} || '');

use IO::String;
use DBIx::DBStag;
use CGI qw/:standard/;
use vars qw(%IS_FORMAT_FLAT $cscheme);

#$ENV{DBSTAG_TRACE}=1;


# --------------------------
# MAIN
ubiq();
exit 0;
# --------------------------


# ++++++++++++++++++++++++++++++++++++++++++++++++++
# ubiq
#
# This is the core function. It does everything
# ++++++++++++++++++++++++++++++++++++++++++++++++++
sub ubiq {

    # =============================================
    # DECLARE VARIABLES
    # note: the functions below are lexically closed
    #       and can thus access these variables.
    #
    # if you're not familiar with closures you might
    # find this a bit confusing...
    # =============================================
    %IS_FORMAT_FLAT =
      map {$_=>1} qw(flat-CSV flat-TSV flat-HTML-table);
    $cscheme =
      {
       'keyword'=>'cyan',
       'variable'=>'magenta',
       'text' => 'reset',
       'comment' => 'red',
       'block' => 'blue',
       'property' => 'green',
      };

    my $cgi = CGI->new;

    my $sdbh = 
      DBIx::DBStag->new;

    # child dbh
    my $dbh;

    my $stag;
    my $res;
    my $schema;
    my $loc;
    my $templates = [];
    my $varnames = [];
    my $example_input = {};
    my $options = {};
    my $nesting = '';
    my $rows;
    my $template;
    my $template_name = '';
    my %exec_argh = ();
    my $resources = $sdbh->resources_list;
    my $resources_hash = $sdbh->resources_hash;
    my @dbresl = grep {$_->{type} eq 'rdb'} @$resources;
    my @dbnames = (map {$_->{name}} @dbresl);
    my $W = Data::Stag->getformathandler('sxpr');
    my $ofh = \*STDOUT;
    my $format;
    my $dbname;
    my $errmsg = '';

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # keep
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub keep;			#
    *keep = sub {
	join('&',
	     map {"$_=".param(myescapeHTML($_))} grep {param($_)} qw(dbname template format save mode));
    };				# end of sub: keep

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # url
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub url;			#
    *url = sub {
	my $base = shift;
	my %p = @_;
	%p = map {
	    my $v = param($_);
	    $p{$_} ? 
	      ($_ => $p{$_}) :
		($v ? ($_=>$v) : ());
	} (keys %p, qw(dbname template format save mode));
	return "$base?".
	  join('&',
	       map {"$_=".$p{$_}} keys %p);
    };				# end of sub: url


    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # conn
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub conn;			#
    *conn = sub {
	$dbh = DBIx::DBStag->connect($dbname) unless $dbh;
    };				# end of sub: conn

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # is_format_flat
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub is_format_flat;		#
    *is_format_flat = sub {
	#	my $f = shift;
	$IS_FORMAT_FLAT{$format};
    };				# end of sub: is_format_flat



    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    #
    # BASIC LAYOUT
    #
    # headers, footers, help, etc
    #
    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # g_title
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub g_title;		#
    *g_title = sub {
	"U * B * I * Q";
    };				# end of sub: g_title

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # short_intro
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub short_intro;		#
    *short_intro = sub {
	"This is the generic UBIQ interface";
    };				# end of sub: short_intro

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # top_of_page
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub top_of_page;			#
    *top_of_page = sub {
	(h1(g_title), 
	 href("ubiq.cgi", "Ubiq"),
	 ' | ',
	 href("ubiq.cgi?help=1", "Help"),
	 br,
	 href('#templates', '>>Templates'),
	 br,
	 short_intro,
	 hr,
	);

    };				# end of sub: top_of_page

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # footer
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub footer;			#
    *footer = sub {
	(hr,
	 href('http://stag.sourceforge.net'),
	 br,
	 myfont('$Id: ubiq.cgi,v 1.8 2004/04/12 18:23:10 cmungall Exp $x',
		(size=>-2)),
	);
    };				# end of sub: footer

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    #
    # VIEW WIDGETS
    #
    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # template_detail
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub template_detail;	#
    *template_detail = sub {
	my $templates = shift;
	my @tbls =
	  map {
	      my $io = IO::String->new;
	      $_->show($io, $cscheme, \&htmlcolor);
	      my $sr = $io->string_ref;
	      ('<a name="'.$_->name.'"',
	       'template: ',
	       em($_->name),
	       table({-border=>1},
		     Tr(
			[td(["<pre>$$sr</pre>"])])))
	  } @$templates;
	return '<a name="templates">'.join("\n", @tbls);
    };				# end of sub: template_detail

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # stag_detail
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub stag_detail;		#
    *stag_detail = sub {
	#    my $W = Data::Stag->getformathandler($format || 'sxpr');
	#    $stag->events($W);
	#    my $out = $W->popbuffer;
	my $out = $stag->generate(-fmt=>$format);
	return resultbox($out);
    };				# end of sub: stag_detail

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # rows_detail
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub rows_detail;		#
    *rows_detail = sub {
	if ($format eq 'flat-HTML-table') {
	    my $hdr = shift @$rows;
	    h2('Results').
	      table({-border=>1, -bgcolor=>'yellow'},
		    Tr({},
		       [th([@$hdr]),
			map {td([map {colval2cell($_)} @$_])} @$rows]));
	} else {
	    my $j = "\t";
	    if ($format eq 'flat-CSV') {
		$j = ',';
	    }	
	    my $out = join("\n",
			   map {
			       join($j,
				    map {escape($_, ("\n"=>'\n', $j=>"\\$j"))} @$_)
			   } @$rows);
	    resultbox($out);
	}
    };				# end of sub: rows_detail

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # query_results
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub query_results;		#
    *query_results = sub {
	(
	 ($stag ? stag_detail() : ''),
	 ($rows ? rows_detail() : ''),
	);
    };				# end of sub: query_results

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    #
    # CHOOSERS
    #
    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # template_chooser
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub template_chooser;	#
    *template_chooser = sub {
	#my $templates = shift;
	return 
	  table(Tr({-valign=>"TOP"},
		   [
		    map {
			my $is_selected = $_->name eq $template_name;
			my $h = {};
			if ($is_selected) {
			    $h = {bgcolor=>'red'}
			}
			my $desc = $_->desc;
			my $name = $_->name;
			my $nl = "\n";
			$desc =~ s/\n/\<br\>/gs;
			td($h,
			   [
			    href("#$name", '[scroll]'),
			    #			href("#$name", '[view]'),
			    href(url('ubiq.cgi', (template=>$name)),
				 strong($name)),
			    $desc.hr,
			   ])
		    } @$templates,
		
		   ]));
    };				# end of sub: template_chooser

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # attr_settings
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub attr_settings;		#
    *attr_settings = sub {
	return unless $template;
	my @vals = ();
	my @popups = ();
	my @extra = ();

	my $basic_tbl = 
	  table(Tr({},
		   [
		    map {
			my $examples = '';
			my $ei = $example_input->{$_} || [];
			while (length("@$ei") > 100) {
			    pop @$ei;
			}
			if (@$ei) {
			    $examples = "  Examples: ".em(join(', ', @$ei));
			}
			td([$_, textfield("attr_$_").$examples])
		    } @$varnames
		   ]));
	my $adv_tbl =
	  table(Tr({},
		   [td([
			join(br,
			     "Override SQL SELECT:",
			     textarea(-name=>'select',
				      -cols=>80,
				     ),
			     "Override SQL WHERE:",
			     textarea(-name=>'where',
				      -cols=>80,
				     ),
			     "Override Full SQL Query:",
			     textarea(-name=>'sql',
				      -cols=>80,
				     ),
			     "Use nesting hierarchy:",
			     textarea(-name=>'nesting',
				      -cols=>80,
				     ),
			    )
					
		       ])]));
      

	return 
	  (
	   hr,
	   "Selected Template: ",
	   strong($template_name),
	   br,
	   submit(-name=>'submit',
		  -value=>'exectemplate'),
	   $basic_tbl,
	   $adv_tbl,
	   #       table({-border=>1},
	   #	     Tr({-valign=>"TOP"},
	   #		[td([
		     
	   #		    ])])),

	   ("Tree/Flat format: ",
	    popup_menu(-name=>'format',
		       -values=>[qw(sxpr itext XML nested-HTML flat-TSV flat-CSV flat-HTML-table)]),
	    checkbox(-name=>'save',
		     -value=>1,
		     -label=>'Save Results to Disk'),
	    ' ',
	    checkbox(-name=>'showsql',
		     -value=>1,
		     -label=>'Show SQL Statement'),
	   ),

	   br,
	   submit(-name=>'submit',
		  -value=>'exectemplate'),
	   hr);
    };				# end of sub: attr_settings

    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    #
    # SETTERS
    #
    #  these set variables depending on users selections
    #
    # %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # setdb
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub setdb;			#
    *setdb = sub {
	#$dbname = shift;
	return unless $dbname;
	msg("Set dbname to $dbname");
	$res = $resources_hash->{$dbname};
	if ($res) {
	    $schema = $res->{schema} || '';
	    $loc = $res->{loc} || '';
	    msg("loc: $loc") if $loc;
	    if ($schema) {
		$templates = $sdbh->find_templates_by_schema($schema);
		msg("schema: $schema");
	    } else {
		msg("schema not known; templates unrestricted");
		$templates = $sdbh->template_list;
	    }
	    msg("Templates available: " . scalar(@$templates));
	} else {
	    warnmsg("Unknown $dbname");
	}
	$res;
    };				# end of sub: setdb
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # settemplate
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub settemplate;		#
    *settemplate = sub {
	my $n = shift;
	my @matches = grep {$_->name eq $n} @$templates;
	die "looking for $n, got @matches" unless @matches == 1;
	$template = shift @matches;
	$varnames = $template->get_varnames;
	conn;
	my $cachef = "./cache/cache-$dbname-$n";
	$example_input = $template->get_example_input($dbh,
						      $cachef,
						      1);
	system("chmod 777 $cachef");
	$template_name = $n;
    };				# end of sub: settemplate

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # resultbox
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub resultbox;		#
    *resultbox = sub {
	my $out = shift;
	if (param('save')) {
	    return $out;
	}
	h2('Results').
	  table({-border=>1},
		Tr({},
		   td({bgcolor=>"yellow"},["<pre>$out</pre>"])));
    };				# end of sub: resultbox

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # msg
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub msg;			#
    *msg = sub {
    };				# end of sub: msg


    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # htmlcolor
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub htmlcolor;		#
    *htmlcolor = sub {
	my $c = shift;
	if ($c eq 'reset') {
	    '</font>';
	} else {
	    "<font color=\"$c\">";
	}
    };				# end of sub: htmlcolor


    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # display_helppage
    #
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub display_helppage;			#
    *display_helppage = sub {
	print(header,
	      start_html("UBIQ: Instructions"),
	      h1("UBIQ: Instructions for use"),

	      h3("What is this?"),
	      p("UBIQ is a generic interface to any relational database.",
		"It allows web-based queries either through SQL or an",
		"extensible set of",strong("SQL Templates"),
		"which must be defined for the database of interest."),
	      p("UBIQ will take the SQL query results and make a",
		strong("hierarchical"), "data structure which is displayed",
		"in a format such as XML or indented text"),
	      p("This is achieved using the ",
		href("http://stag.sourceforge.net", "DBStag"),
		"perl module"),
	      p("UBIQ is intended for advanced, generic queries.",
		"If you want user-friendly queries you should use an",
		"interface that has been custom-designed for the database",
		"you are interested in."),
	      
	      h3("Using UBIQ"),
	      p("First of all select the database of interest and",
		"click 'selectdb'. (There may only be one database,",
		"in which case you can skip this part)."),
	      p("Next, choose a template from the list available for",
		"That database. Each template should have a description of",
		"what kind of query it is. You can also scroll down to the full",
		"SQL Template definition. For a description of the SQL Template",
		"syntax, see",
		href("http://stag.sourceforge.net", "Stag Documentation"),
	       ),
	      p("After you have selected a template, you can paste in settings",
		"for template attributes.",
		"The character '*' gets treated as a wildcard.",
	       ),
	      
	      p("You can now choose a format for the results.",
		"Most of the formats are ", strong("hierarchical."),
		"if a hierarchical format is selected, then UBIQ will",
		"perform a transformation on the flat, tabular query results",
		"and build a tree-type structure that should reflect the",
		"natural organisation of the data."),
	      p("Hierarchical formats are XML, sxpr (Lisp S-Expressions),",
		"itext (indented text)."),
	      p("Non-hierarchical formats are tables of comma/tab seperated fields,",
		"which can optionally formatted into an HTML table"),
	      p("You can also choose to see the actual SQL that gets executed"),
	      p("When you have set the parameters, you can execute the template"),
	      p(em("Note"), "As yet, UBIQ has no means of prioritising queries,",
		"it is possible to launcg queries that put a large load on the",
		"server, please be careful"),
	      p(
		"If you receive an internal server error it probably means your query was terminated",
		"because it was not fully constrained. If this happens, pass in more constraints.",
		"DO NOT keep hitting reload - this will cause the database server to slow down.",
		"If this service becomes overloaded, it will have to be removed"
		),
	      
	      h3("Advanced use"),
	      p("Yes, a SOAP interface would be nice. No plans as yet.",
	       ),
	      
	      p(href("ubiq.cgi", "Start UBIQ")),
	      
	     );
    };                          # end of sub: display_helppage

    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    # display_htmlpage
    #
    # MAIN PAGE
    #
    # ++++++++++++++++++++++++++++++++++++++++++++++++++
    sub display_htmlpage;			#
    *display_htmlpage = sub {
	print(
	      header, 
	      start_html(g_title), 
	      top_of_page,
	      start_form(-action=>'ubiq.cgi', -method=>'GET'),

	      # DATABASE SELECTION
	      ("Database",
	       popup_menu(-name=>'dbname',
			  -values=>[sort {$a cmp $b} @dbnames],
			  -onChange=>"submit()",
			 ),
	       submit(-name=>'submit',
		      -value=>"selectdb")),

	      # QUERY RESULTS - if present
	      (query_results),

	      # ERRORS - if present
	      ($errmsg),

	      # ATTRIBUTE CHOOSER - if template is set
	      (attr_settings(),
	       ($template ? template_detail([$template]) : ''),
	       hr),

	      # TEMPLATE CHOOSER
	      (h3("Choose a template:"),
	       template_chooser,
	       hr),

	      # TEMPLATES - all or just selected
	      ($template ? '' : template_detail($templates)),

	      # PERSISTENT VARS
	      hidden('template', param('template')),

	      end_form,
	      footer,
	     );
    };				# end of sub: display_htmlpage

    # ================================
    #
    # SETTING THINGS UP
    #
    # ================================

    my @initfuncs = ();

    *add_initfunc = sub {
	push(@initfuncs, shift);
    };

    add_initfunc(sub {
		     $format = param('format') || 'sxpr';
		     $dbname = param('dbname');
		     if (@dbnames == 1) {
			 # only one to choose from; autoselect
			 $dbname = $dbnames[0];
		     }
		     
		     setdb;                # sets $dbh

		     # sets $template $varnames
		     settemplate(param('template'))
		       if param('template') && param('submit') ne 'selectdb';
		     
		     # set variable bindings
		     foreach (@$varnames) {
			 my $v = param("attr_$_");
			 if ($v) {
			     $v =~ s/\*/\%/g;
			     $exec_argh{$_} = $v;
			 }
		     }
		 });

    if (-f 'ubiq-customize.pl') {
	eval `cat ubiq-customize.pl`;
	die $@ if $@;
    }


    $_->() foreach @initfuncs;

    # execute query
    if ($template && param('submit') eq 'exectemplate') {
	eval {
	    conn();
	    
            my $no_query_params_set = !scalar(keys %exec_argh);
	    if (param('where')) {
		$template->set_clause(where=>param('where'));
                $no_query_params_set = 0;
	    }
	    if (param('select')) {
		$template->set_clause(where=>param('select'));
	    }
            if ($no_query_params_set) {
                $errmsg = h2("No Query Constraints Set");
            }
            else {
		# kill killer queries
		my $tag = "kill$$"."TAG";
		my $tagf = "/tmp/$tag";
		my $t=time;
		print STDERR "Launched killer $tagf at $t\n";
		system("touch $tagf && chmod 777 $tagf && sleep 15 && test -f $tagf && kill -9 $$ && rm $tagf &");
                if (is_format_flat) {
                    $rows =
                      $dbh->selectall_rows(
                                           -template=>$template,
                                           -bind=>\%exec_argh,
                                          );
                } else {
                    $stag =
                      $dbh->selectall_stag(
                                           -template=>$template,
                                           -bind=>\%exec_argh,
                                           -nesting=>$nesting,
                                          );
                }
		# inactivate killer (killer only kills if $tagf is present)
		$t=time;
		print STDERR "Inactivated killer $tagf at $t\n";
		system("rm $tagf &");
            }
	};
	if ($@) {
	    my $err = $@;
	    $errmsg =
	      br.strong("Database Error:")."<pre>$err</pre>";
	}
    }

    # WRITE HTML TO BROWSER
    if (param('save')) {
	# WRITE TO FILE
	print(header({-type=>"text/text"}),
	      query_results);
    }
    if (param('help')) {
	# WRITE TO FILE
	display_helppage
    }
    else {
	# WRITE HTML
	display_htmlpage;

    }

}

# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
#
# CGI UTILITY FUNCTIONS
#
# %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

# ++++++++++++++++++++++++++++++++++++++++++++++++++
# href
#
#
# ++++++++++++++++++++++++++++++++++++++++++++++++++
sub href {
    my $url = shift;
    my $n = shift || $url;
    "<a href=\"$url\">$n</a>";
}				# end of sub: href

# ++++++++++++++++++++++++++++++++++++++++++++++++++
# myfont
#
#
# ++++++++++++++++++++++++++++++++++++++++++++++++++
sub myfont ($%) {
    my $str = shift;
    my %h = @_;
    sprintf("<font %s>$str</font>",
	    join(' ',
		 map {sprintf('%s="%s"',
			      $_, $h{$_})} keys %h));
}				# end of sub: myfont

# ++++++++++++++++++++++++++++++++++++++++++++++++++
# escape
#
#   escapes characters using a map
# ++++++++++++++++++++++++++++++++++++++++++++++++++
sub escape ($@) {
    my $s = shift || '';
    my %cmap = @_;
    $cmap{'\\'} = '\\\\';
    my @from = keys %cmap;
    my @to = map{$cmap{$_}} @from;
    my $f = join('', @from);
    my $t = join('', @to);
    $s =~ tr/$f/$t/;
    $s;
}				# end of sub: escape

# ++++++++++++++++++++++++++++++++++++++++++++++++++
# myescapeHTML
#
#   
# ++++++++++++++++++++++++++++++++++++++++++++++++++
sub myescapeHTML ($) {
    my $s = shift;
    return $s;
}				# end of sub: myescapeHTML


# ++++++++++++++++++++++++++++++++++++++++++++++++++
# colval2cell
#
#
# ++++++++++++++++++++++++++++++++++++++++++++++++++
sub colval2cell ($) {
    my $cell = shift;
    if (!defined($cell)) {
	return '<font color="red">NULL</font>';
    }
    $cell;
}				# end of sub: colval2cell

