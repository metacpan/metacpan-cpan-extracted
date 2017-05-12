#!/usr/bin/perl

=head1 NAME

DBedit - Class to handle database editing

=head1 SYNOPSIS

This class takes an HTML form and fills it in with database material.

=head1 LICENSE

This class is copyright (C) 2002 Globewide Network Academy and released
under the terms of the Scheme License.

=cut

use DBstorage::RDB;
use strict;
use Carp;
use HTML::FillInForm;
use Data::Dumper;
package DBedit;

$DBedit::VERSION = '1.96';
sub new {
    my $proto = shift;
    my $inref = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    my ($field);
    my(%default_params) = ("scan_marker", "*",
			   "scan_header_marker", "Scan all records",
			   "append_marker", "Append record",
			   "search_marker", "Search record",
			   "submit_append_marker", "Do append",
			   "submit_search_marker", "Do search",
			   "submit_form_marker", "Do it",
			   "scan_page_size", 0);

    foreach $field (keys %default_params) {
	if ($inref->{$field} eq "") {
	    $self->{$field} = $default_params{$field};
	} else {
	    $self->{$field} = $inref->{$field};
	}
    }
    if (!defined($self->{'storage'})) {
	$self->{"storage"} = DBstorage::RDB->new();
    }
    $self->{'handler'} = {};
    $self->{'status_out'} = "";
    $self->{'abort_transaction'} = 0;
    $self->{'record'} = 0;
    $self->{'last'} = 0;
    $self->{'next'} = 0;
    $self->{'script'} = "";
    $self->{'menu_hide'} = 0;
    $self->{'permission'} = {};
    $self->{'keycols'} = [];
    $self->{'form'} = "";
    $self->{'table'} = "";
    $self->{'fill_form'} = HTML::FillInForm->new();
    $self->{'permission'} = {
	"read"=>1,
	"write"=>1,
	"append"=>1,
	"delete"=>1
	};

    $self->set_handler("scan_menu",
sub {
    my($self) = @_;
    my($returnval) =  
	"<br><a href=\"$self->{'script'}RDBaction=scan\">$self->{'scan_header_marker'}</a>";
    $returnval .=  "<br><a href=\"$self->{'script'}RDBaction=search\">$self->{'search_marker'}</a>";


    if ($self->permission("append")) {
	$returnval .=  "<br><A HREF=\"" .
	    $self->{'script'} . 
		"RDBaction=append\">$self->{'append_marker'}</A>";
    }
    $returnval .=  "<p>";
    return $returnval;
});
    $self->set_handler("scan_header",
sub {
    my($self) = @_;
    my($returnval) = <<EOP;
<hr>
<table border=1>
<tr>
<td> </td><td><b>
EOP
    $returnval .=
	join("</b></td> <td><b>", @{$self->{'keycols'}}) . 
	     "</b></td></tr><h6></h6>";
    return $returnval;
});


    $self->set_handler("scan_line",
sub {
    my($self, $name, $href, $fref) = @_;
    my ($returnval);
    $returnval .= "<tr><td><a name=\"$name\" href=\"$href\">(edit)</a></td> <td>";
    $returnval .= join("</td> <td>", @{$fref}{@{$self->{'keycols'}}}) . "</td></tr><h6></h6>";
    return $returnval;
});


    $self->set_handler("scan_footer",
sub {
    return "</table><hr>\n";
});
    return $self;
}

sub permission {
    my ($self, $action, $set) = @_;
    if (defined($set)) {
	$self->{'permission'}->{$action} =
	    $set;
    }
    return $self->{'permission'}->{$action};
}

sub form {
    my($self, $formin) = @_;
    $self->{'form'} = $formin;
}

sub keycols {
    my($self, $keycolref) = @_;
    $self->{'keycols'} = $keycolref;
}

sub table {
    my($self, $tablein) = @_;
    $self->{'table'} = $tablein;
}

sub param {
    my($self, $param, $value) = @_;
    $self->{$param} = $value;
}

sub scan_table {
    my($self, $tablein) = @_;
    $self->{'scan_table'} = $tablein;
}
    

sub storage {
    my($self, $storage) = @_;
    if (defined($self->{'storage'})) {
	undef($self->{'storage'});
    }
    $self->{'storage'} = $storage;
}

sub process {
    my($self, $inref) = @_;
    my(%in, %found);
    my(@keycols) = @{$self->{'keycols'}};
    local ($_);
    my ($returnval) = "";
    %in = %{$inref};

    my($scan_table);
    if (defined($self->{'scan_table'}) &&
	$self->{'scan_table'} ne "") {
	$scan_table = $self->{'scan_table'};
    } else {
	$scan_table = $self->{'table'};
    } 

    my($dbh) = $self->{'storage'};

    if ($in{'RDBscan_page_size'} != 0) {
        $self->{'scan_page_size'} = $in{'RDBscan_page_size'};
   }

    $self->{'scan_page_start'} = $in{'RDBscan_page_start'};
    if ($self->{'scan_page_size'} != 0 &&
	$self->{'scan_page_start'} < 1) {
	$self->{'scan_page_start'} = 1;
    } 

    my ($action) = $in{'RDBaction'};
    $self->{'record'} = $in{'RDBrecord'};
    $self->{'last'} = $in{'RDBlast'};

    $self->{'script'} = $ENV{'SCRIPT_NAME'} . "?";
    $self->{'script'} .= "RDBdate=";
    $self->{'script'} .= &get_time;
    $self->{'script'} .= "&";

    foreach (keys %{$self->{'attrib'}}) {
	$self->{'script'} .= "$_=" . $self->{'attrib'}->{$_} . "&";
    }

    my ($field);
    foreach $field (keys %in) {
	if ($field =~ /^RDB/) {
	    delete $in{$field};
	}
    }

    my (%keys);
    foreach (@keycols) {
	$keys{$_} = $in{"$_.old"};
	delete $in{"$_.old"};
    }
    
# w is for write permission
# a is for append permission
# d is for delete permission

    $returnval .= $self->{'page_header'};
    my($record) = $self->{'record'};
    my($last) = $self->{'last'};
    my($table) = $self->{'table'};
    $self->{'abort_transction'} = 0;
    $self->{'status_out'} = "";

    if ($action eq "do_append" && $self->permission("append")) {
	$self->run_handler("preprocess.append", \%in);
	if (!$self->{'abort_transaction'}) {
	    $dbh->append($table, \%in);
	    $self->run_handler("postprocess.append", \%in);
	}

	$action="find_key_only";
    } elsif ($action eq "do_replace" && $self->permission("write")) {
	$self->run_handler("preprocess.replace", \%in);
	if (!$self->{'abort_transaction'}) {
	    $dbh->replace($table, \%keys, \%in, 0);
	    $self->run_handler("postprocess.replace", \%in);
	}
	$action = "find_key_only";
    } elsif ($action eq "do_delete" && $self->permission("delete")) {
	$self->run_handler("preprocess.delete", \%in);
	if (!$self->{'abort_transaction'}) {
	    $dbh->delete($table, \%keys);
	    $self->run_handler("postprocess.delete", \%in);
	}
	$action = "scan";
    } elsif ($action eq "do_search") {
	$self->scan($scan_table, \%in);
    } elsif (!$dbh->exists($table)) {
	return $self->show_form(\%in, "append");
    };

    if ($action eq "append") {
	return $self->show_form(\%in, "append");
    } elsif ($action eq "search") {
	return $self->show_form(\%in, "search");
    } elsif ($action eq "scan" || ($record == 0 && $action eq "")) {
	return $self->scan($scan_table, \%in);
    } elsif ($action eq "find_key_only") {
	my (%key);
	(@key{@keycols}) = (@in{@keycols});
	$record = $dbh->find($self->{'table'}, \%key, \%found, \$last);
    } elsif ($action eq "find") {
	$record = $dbh->find($self->{'table'}, \%in, \%found, \$last);
    } elsif ($action eq "last") {
	$dbh->open($self->{'table'}) || die;
	while ($dbh->read(\%found)) {
	    $last++; 
	}
	$dbh->close();
	$record = $last;
    } else {
	$record = $dbh->get_nth($scan_table, $record, \%found, \$last);
    }

    $self->{'record'} = $record;
    $self->{'last'} = $last;

    $record ?
	return $self->show_form(\%found, "replace") :
	    return "Cannot find record $record";
}


sub show_form {
    my($self, $fref, $action) = @_;
    my($dbh) = $self->{'storage'};
    my ($returnval);
    my (%insert);
    my($field, $next, $prev);
    my($noedit);
    my($last) = $self->{'last'};
    my($record) = $self->{'record'};
    my($form) = $self->{'form'};

    $self->run_handler("preprocess.show_form", $fref, \$form);
    $insert{'header'} = "<TITLE>Table: $self->{'table'}</TITLE>";


    if ($action eq "replace") {
	$next=$record+1;
	$prev=$record-1;	# 

	($record==$last) && ($next=1);
	($record==1) && ($prev=$last);
	if ($dbh->{'nocursor'} == 0) {
	    $insert{'top'} = "Record $record of $last\n<hr>\n";
	} else {
	    $insert{'top'} = "";
	}



	if (!$self->{"menu_hide"}) {
	    $insert{'top'} .= '
<A HREF="' . $self->{'script'} . 'RDBaction=scan#record' . 
    $self->{'record'} . '">Scan</A> 
';
	    if ($dbh->{'nocursor'} == 0) {
		$insert{'top'} .= "
<A HREF=\"$self->{'script'}RDBaction=search\">Search</a> 
<A HREF=\"$self->{'script'}RDBrecord=1\">First</a> 
<A HREF=\"$self->{'script'}RDBrecord=$prev\">Previous</a>
<A HREF=\"$self->{'script'}RDBrecord=$next\">Next</a>
<A HREF=\"$self->{'script'}RDBrecord=$last\">Last</a>";
	    }
	}


        $self->permission("append") &&
	    ($insert{'top'} .= " <A HREF=\"". $self->{'script'} . 
	     "RDBaction=append\">Append</a>");

        $insert{'top'} .= "<HR>\n";

        if ($self->permission("write") || $self->permission("delete")) {
	    $insert{'top'} .= "<FORM METHOD=POST ACTION=$ENV{'SCRIPT_NAME'}>
<INPUT TYPE=hidden NAME=RDBrecord VALUE=$self->{'record'}>
<INPUT TYPE=hidden NAME=RDBlast VALUE=$self->{'last'}>
";

            foreach $field (keys %{$self->{'attrib'}}) {
		$insert{'top'} .= 
		    "<INPUT TYPE=\"hidden\" NAME=\"$field\" VALUE=\"$self->{'attrib'}->{$_}\">";
            }

	    foreach $field (@{$self->{'keycols'}}) {
		$insert{'top'} .= '<input type="hidden" name="'. $field . '.old" value="'. $fref->{$field} . '">'. "\n";
	    }		 
	    $insert{'bottom'} .= "<p>";
	    $self->permission("write") && ($insert{'bottom'} .=
				     '<input type="radio" name="RDBaction" value="do_replace" CHECKED>Replace');
	    $self->permission("delete") && ($insert{'bottom'} .=
				      '<input type="radio" name="RDBaction" value="do_delete">Delete');
	    $insert{'bottom'} .= "<br>\n" 
		. '<input type="submit" name="RDBsubmit" value="'. 
		    $self->{'submit_form_marker'} . '">'. '</FORM>';
	    $noedit = 0;

	} else {
	    $noedit=1;
	}

    } elsif ($action eq "append") {
	(!$self->permission("append")) && return "";
	$insert{'top'} = "<hr>";
	if (!$self->{"menu_hide"}) { 
	    $insert{'top'} .= "<A HREF=\"$self->{'script'}RDBaction=scan\">Scan</a>
<hr>
";
	}

	
	if ($self->permission("append")) {
	    $insert{'top'} .= "Appending record<br>
<FORM METHOD=POST ACTION=$ENV{'SCRIPT_NAME'}>
<INPUT type=hidden name=RDBaction value=do_append>";
	    foreach $field (keys %{$self->{'attrib'}}) {
		$insert{'top'} .= '<INPUT TYPE="hidden" NAME="' .
		    $field . '" VALUE="' .
			$self->{'attrib'}->{$field} . '">';
	    }

	    $insert{'bottom'} = "<hr>
<input type=submit name=RDBsubmit value=\"$self->{'submit_append_marker'}\">
</FORM>
";
	}

    } elsif ($action eq "search") {
	$insert{'top'} = "<hr>";

	if (!$self->{"menu_hide"}) { 
	    $insert{'top'} .= '<A HREF="' .
		$self->{'script'} . 
		    'RDBaction=scan">Scan</a>
<hr>
';
	}
	$insert{'top'} .= "Search record<br>
<FORM METHOD=POST ACTION=$ENV{'SCRIPT_NAME'}>
<INPUT type=hidden name=RDBaction value=do_search>";
	foreach (keys %{$self->{'attrib'}}) {
	    $insert{'top'} .= '<INPUT TYPE=hidden NAME="' .
		$_ . '" VALUE="' .
		    $self->{'attrib'}->{$_} . '">';
	}

	$insert{'bottom'} = "<hr>
<input type=submit name=RDBsubmit value=\"$self->{'submit_search_marker'}\">
</FORM>
";
    }

    $returnval .= $insert{'header'};
    $returnval .= $insert{'top'};
    $returnval .= $self->{'status_out'};
    $returnval .= $self->fill_form($form, $fref, $noedit);
    $returnval .= $insert{'bottom'};
    $self->run_handler("postprocess.show_form", $fref, \$returnval);
    return $returnval;
}


sub scan {
    my ($self, $scan_table, $keyref) = @_;
    my ($returnval) = "";
    my (%f);
    my ($dbh) = $self->{'storage'};
    $returnval .= $self->run_handler("scan_menu");
    $returnval .= $self->run_handler("scan_header");

    my ($j) = 1;

    if (defined($scan_table) 
	&& $scan_table ne "") {
	$dbh->open($scan_table) || die;
loop:
	while ($dbh->read(\%f)) {
	    if ($self->{'scan_page_size'} == 0 ||
		($self->{'scan_page_start'} <= $j &&
		 $j < $self->{'scan_page_start'} + 
		 $self->{'scan_page_size'})) {
		
		if ($keyref->{'RDBaction'} eq "do_search") {
		    my($key);
		    foreach $key (keys %{$keyref}) {
			if ($key !~ /^RDB/ && $keyref->{$key}  !~ /^\s*$/) {
			    if ($f{$key} !~ /$keyref->{$key}/i) {
				next loop;
			    }
			}
		    }
		    
		}
		my ($href) = $self->{'script'};
		$href .= "RDBaction=find";
		foreach (@{$self->{'keycols'}}) {
		    $href .= "&$_=" . &cgi_quote($f{$_});
		}
		$returnval .= $self->run_handler("scan_line", "record$j", 
						 $href, \%f);

	    }
	    $j++;
	}
	
	$dbh->close();
    }
    $returnval .= $self->run_handler("scan_footer");

    if ($self->{'scan_page_size'} > 0) {
	my ($number_of_pages) = int(($j-1)/$self->{'scan_page_size'}) + 1;
	my ($page_start) = $self->{'scan_page_start'};
	my ($page_size) = $self->{'scan_page_size'};
	my ($page_prev_start) = $page_start - $page_size;
	my ($page_next_start) = $page_start + $page_size;
	my ($page_cur_page) = int ($page_start / $page_size) + 1;
	my ($i, $field);
	my($script_root) = $self->{'script'};
	foreach $i (keys %{$keyref}) {
            if ($i ne "RDBaction" && $i ne "RDBscan_page_size" &&
                $i ne "RDBscan_page_start") {
             $script_root .= "${i}=" . &cgi_quote($keyref->{$i}) . "&";
            }
        }

        $returnval .=  "<center>";

	if ($page_prev_start > 0) {
	    $returnval .=  "<a href=${script_root}RDBaction=scan&RDBscan_page_size=${page_size}&RDBscan_page_start=${page_prev_start}>[Prev Page]</a>";
	}
	foreach $i (1..$number_of_pages) {
            my ($page_link_start) = 
                ($i-1) * $page_size + 1;
		    $returnval .=  " ";
            if ($i == $page_cur_page) {
                  $returnval .=  "<b>";
            } else {
        	    $returnval .=  "<a href=${script_root}RDBaction=scan&RDBscan_page_size=${page_size}&RDBscan_page_start=${page_link_start}>";
}
	    $returnval .=  "[$i]";
            if ($i == $page_cur_page) {
                  $returnval .=  "</b>";
            } else {
	$returnval .=  "</a>";
}
$returnval .=  " ";

	}

	if ($page_next_start <= $j) {
	    $returnval .=  "<a href=${script_root}RDBaction=scan&RDBscan_page_size=${page_size}&RDBscan_page_start=${page_next_start}>[Next Page]</a>";
	}
        $returnval .=  "</center>";
    }
    
    $returnval .=  $self->{"page_footer"};
    return $returnval;
}

sub get_time {
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(time);
    $year += 1900;
    $mon++;
    return sprintf("%04d%02d%02d%02d%02d%02d", $year, $mon, $mday, $hour, $min, $sec);
}

sub fill_form {
    my($self, $input, $fref, $noedit) = @_;


    return $self->{'fill_form'}->fill(scalarref=>\$input,
				      fdat=>$fref);
}



sub split_tag {
    my($fulltag)=@_;
    my($tagname,$etc,$var,$quote,$arg,$value,@tagargs);
    undef $etc;
    ($tagname,$etc)=$fulltag=~/\s*(\S+)\s*(.*)$/;
    while ($etc!~/^\s*$/) {
	($arg,$var,$value,$etc)=$etc=~/\s*([^=\s]+)\s*(=)?\s*(\S+)?(.*)$/;
	($value,$etc)=((undef),$value.$etc) unless $var=~/^=$/;
	($quote)=$value=~/^([\"\'])/;
	if ($quote) {
	    if ($value!~/.$quote$/) {
		($_,$etc)=$etc=~/^([^$quote]*)$quote?(.*)$/;
		$value.=$_.$quote;
	    }
	    $value=~s/$quote\s*(.*)\s*$quote$/$1/;
	    $value=~s/\s*$//;
	}
	$arg="\U$arg\E";
	$arg =~ y/a-z/A-Z/;
	push(@tagargs,$arg,$value);
    }
  
    $tagname="\U$tagname\E";
    $tagname =~ y/a-z/A-Z/;
    ($tagname,@tagargs);
}



sub make_tag {
    my($tag, %args) = @_;
    local($_);
    my ($output);
    $output = "$tag ";
    foreach (keys %args) {
	$output .= "$_=\"$args{$_}\" ";
    }
    return $output;
}

sub cgi_quote {
    my ($s) = @_;
    $s =~ s/\%/%25/g;
     $s =~ s/\+/%2b/g;
    $s =~ s/ /%20/g;
     $s =~ s/&/%26/g;
     $s =~ s/</%3c/g;
     $s =~ s/>/%3e/g;
    $s =~ s/\;/%3b/g;
     $s =~ s/!/%41/g;
     $s =~ s/#/%23/g;
    $s =~ s/\"/%22/g;
    $s =~ s/\'/%27/g;
    $s =~ s/\?/%3f/g;
    $s =~ s/([\x00-\x1f]|[\x80-\xff])/"%" . sprintf("%x", ord($1)) /ge;

# Next line not strictly necessary but may break some browsers if not done
    $s =~ s/\//%2f/g;
    return $s;
}

sub set_handler {
    my ($self, $value, $func) = @_;
    $self->{'handler'}->{$value} = $func;
}

sub run_handler {
    my ($self, $value, @args) = @_;

    if (defined($self->{'handler'}->{$value})) {
	return &{$self->{'handler'}->{$value}}($self, @args);

    }
}
1;
