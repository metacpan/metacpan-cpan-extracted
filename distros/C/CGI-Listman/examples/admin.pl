#!/usr/bin/perl -wT

use strict;

use lib '/home/wolfgang/programmes/perl/CGI-Listman';
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use CGI::Listman;
use CGI::Listman::exporter;
use POSIX qw(strftime);

use lib '.';
use config;

use constant export_file => 'export.csv';

use vars qw ($script_name);

$CGI::POST_MAX = 1024;
$ENV{'PATH'} = '/bin:/usr/bin';

sub decor_cell {
  my ($cell, $seen, $exported) = @_;

  my $decorated = undef;

  $decorated = $cell || '&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;';
  $decorated = '<b>'.$decorated.'</b>' unless ($seen);
  $decorated = '<font color="blue">'.$decorated.'</font>' if ($exported);

  return $decorated;
}

sub print_legend {
  print "<table align=\"right\" nowrap=\"nowrap\" border=1 cellspacing=0 cellpadding=1><tbody><tr>\n";
  print "<td>Légende&nbsp;:</td><td>Normal</td><td><b>Nouveau</b></td>".
    "<td><font color=blue>Exporté</font></td></tr>";
  print "</tbody></table>\n";
}

sub check_uri_file {
  my $file = $ENV{'REQUEST_URI'};

  if (defined $script_name) {
    $file =~ s/^${script_name}//;
    $file =~ s@^/@@ unless (-z $file);
  }

  return $file;
}

sub parse_line {
  my $line_ref = shift;

  my $content_line = '<tr><td nowrap="nowrap"><input type="checkbox" ';

  my $number = $line_ref->number ();
  $content_line .= 'checked="checked" ' unless $line_ref->{'seen'};
  $content_line .= 'name="select_'.$number.'">'.$number.'</td>';

  my $fields_ref = $line_ref->line_fields ();
  foreach my $field (@$fields_ref) {
    $content_line .= '<td bgcolor="lightgrey" nowrap="nowrap">'.
      decor_cell ($field, $line_ref->{'seen'}, $line_ref->{'exported'}).
	'</td>';
  }

  my $time = strftime "%a %b %e %H:%M:%S %Y", localtime ($line_ref->{'timestamp'});
  $content_line .= '<td nowrap="nowrap">';
  $content_line .= $time;
  $content_line .= "</td></tr>\n";

  return $content_line;
}

sub make_contents_header {
  my $listman = shift;;

  my $header = '<tr><td>No</td>';

  my $dictionary = $listman->dictionary ();
  my $dict_terms = $dictionary->terms ();

  foreach my $term (@$dict_terms) {
    my $field_name = $term->definition_or_key ();
    $header .= '<td nowrap="nowrap" align="center">'.$field_name.'</td>';
  }
  $header .= '<td nowrap="nowrap" align="center">'
    ."Date d'inscription</td></tr>\n";

  return $header;
}

sub interpret_contents {
  my $listman = shift;

  my $contents_ref = $listman->list_contents ();

  my $contents;
  if (defined $contents_ref && @$contents_ref) {
    $contents = make_contents_header ($listman);
    foreach my $contents_line (@$contents_ref) {
      $contents .= parse_line ($contents_line);
      $contents_line->mark_seen ();
    }
  } else {
    $contents = "<p>Aucune inscription.</p>" unless (defined $contents);
  }

  return $contents;
}

sub get_main {
  my ($cgi, $listman, $redirect_uri) = @_;

  if (defined $cgi->param ('edit')) {
    edit_dict ($listman, $cgi->param ('edit'), $cgi->param ('key'));
  } else {
    my $request_file = check_uri_file ();

    if ($request_file) {
      export_records ();
    } else {
      print "Content-type: text/html\r\n\r\n";

      print '<html><head>';
      print '<meta http-equiv="refresh" content="0; url='
	.$redirect_uri.'">' if (defined $redirect_uri);
      print '<title>Administration</title><head><body>'."\n";
      print '<form action="'.$ENV{'SCRIPT_NAME'}.'" method="POST"><table>';
      print "<tbody>\n";

      my $content = interpret_contents ($listman);
      print $content;

      print "</tbody></table>\n";
      print '<table><tbody><tr>';
      print '<td><input type="submit" name="submit" value="Effacer"></td>';
      print '<td><input type="submit" name="submit" value="Exporter"></td>';
      #  print '<td nowrap=nowrap><input type="radio" name="export_fmt" value="CSV" checked=checked>&nbsp;CSV</td>';
      #  print '<td nowrap=nowrap><input type="radio" name="export_fmt" value="Excel">&nbsp;Excel</td>';
      print '<td><input type="reset" value="Recommencer"></td>';
      print '<td><input type="submit" name="submit" value="Dictionnaire"></td>';
      print "</form>\n";
      print_legend ();
      print "</body></html>\n";
    }
  }
}

# sub print_params {
#   my $cgi = shift;

#   print "<html><head><title>Param</title></head><body>";
#   foreach my $param ($cgi->param ()) {
#     print "<p>".$param." = ".$cgi->param ($param)."</p>";
#   }
#   print "</body></html>";
# }

sub make_selection {
  my ($cgi, $listman) = @_;

  my @list;
  my @params = $cgi->param ();

  if (@params) {
    foreach my $param (@params) {
      if ($param =~ m/^select_([0-9].*$)/) {
	push @list, $1 if ($cgi->param ($param) eq 'on');
      }
    }
  }

  my $selection = undef;
  if (@list) {
    $selection = CGI::Listman::selection->new ();
    $selection->add_lines_by_number ($listman, \@list);
  }

  return $selection;
}

sub export_records {
  my $exporter = CGI::Listman::exporter->new ($config::list_dir.'/'.export_file);
  my $contents = $exporter->file_contents ();

  if (defined $contents) {
    print "Content-type: application/binary\r\n\r\n".$contents;
    unlink $config::list_dir.'/'.export_file;
  } else {
    print "Content-type: text/html\r\n\r\n";
    print "<html><body>No export file.</body></html>";
  }
}

sub make_export_uri {
  my $date = strftime ("%Y-%m-%d", localtime);
  my $uri = $ENV{'HTTP_REFERER'}.'/'.$config::list_name.'_'.$date.'.csv';

#  my $extension = ($format eq 'CSV') ? '.csv' : '.xls';

  return $uri;
}

# sub prepare_export {
# my $list_ref= shift;

#   my $new_content = undef;

#   open OUTF, '>'.$config::list_dir.'/'.export_file;
#   open INF, $config::list_dir.'/'.$config::list_name.'.csv'
#     or carp "Could not open ".$config::list_dir.'/'.$config::list_name.'.csv'."\n";
#   while (<INF>) {
#     my $line = $_;

#     $line =~ m/^([0-9]*),/;
#     my $nbr = $1;
#     if (number_matches ($list_ref, $nbr)) {
#       $new_content .= mark_line_exported ($line);
#       my $csv = Text::CSV_XS->new({'binary' => 1});
#       $csv->parse ($line);
#       my @list = $csv->fields ();

#       shift @list; shift @list;
#       pop @list; pop @list; pop @list;

#       $csv->combine (@list);
#       print OUTF $csv->string ()."\n";
#     } else {
#       $new_content .= $line;
#     }
#   }
#   close INF;
#   close OUTF;

#   if (defined $new_content) {
#     open OUTF, '>'.$config::list_dir.'/'.$config::list_name.'.csv'
#       or carp "Could not open ".$config::list_dir.'/'.$config::list_name.'.csv'."\n";
#     print OUTF $new_content;
#     close OUTF;
#   }

#   my $export_uri = make_export_uri ();

#   get_main ($export_uri);
# }

sub error {
  my ($title, $line) = @_;

  print "<html><head><title>Error: ".$title.
    "</title></head><body>".$line.
      "</body></html>";
}

sub erase_selection {
  my ($cgi, $listman, $selection) = @_;

  $listman->delete_selection ($selection);

  get_main ($cgi, $listman);
}

sub export_selection {
  my ($cgi, $listman, $selection) = @_;

  my $exporter = CGI::Listman::exporter->new
    ($config::list_dir.'/'.export_file, $config::separator);
  $exporter->add_selection ($selection);
  $exporter->save_file ();

  get_main ($cgi, $listman, make_export_uri ());
}

sub make_normal_edit_dict_line {
  my ($number, $max_number, $term) = @_;

  my $dict_line = '<tr>'
    .'<td align="right">'.$number.'</td>';
  $dict_line .= '<td bgcolor="lightgrey" nowrap="nowrap">'
    .$term->{'key'}.'</td>';
  my $definition = $term->definition () || '- aucune -';
  $dict_line .= '<td bgcolor="lightgrey" nowrap="nowrap"><a href="'
    .$script_name.'?edit=definition&key='.$term->{'key'}.'">'
      .$definition.'</a></td>';
  $dict_line .= '<td bgcolor="lightgrey" nowrap="nowrap"><a href="'
    .$script_name.'?edit=mandatory&key='.$term->{'key'}.'">';
  if ($term->{"mandatory"}) {
    $dict_line .= '<b>Oui</b>';
  } else {
    $dict_line .= 'Non';
  }
  $dict_line .= '</a></td>';

  $dict_line .= '<td>';
  $dict_line .= '<a href="'.$script_name.'?edit=decrease&key='
    .$term->{'key'}.'"><img border="0" src="fleche_haut.jpg"></a>'
      if ($number > 1);
  $dict_line .= '</td>';
  $dict_line .= '<td>';
  $dict_line .= '<a href="'.$script_name.'?edit=increase&key='
    .$term->{'key'}.'"><img border="0" src="fleche_bas.jpg"></a>'
      if ($number < $max_number);
  $dict_line .= '</td>';
  $dict_line .= "</tr>\n";

  return $dict_line;
}

sub perform_edit_action {
  my ($listman, $edit_action, $dictionary, $edit_key) = @_;

  my $term = $dictionary->get_term ($edit_key)
    or carp "Performing action on an unknown key!?\n";

  if ($edit_action eq 'mandatory') {
    $term->{'mandatory'} = (!$term->{'mandatory'});
  } elsif ($edit_action eq 'increase') {
    my $contents = $listman->list_contents ();
    carp "Videz d'abord la liste avant d'effectuer"
      ." tout changement sur l'ordre des clefs!\n"
	if (defined $contents && @$contents);
    $dictionary->increase_term_pos ($term);
  } elsif ($edit_action eq 'decrease') {
    my $contents = $listman->list_contents ();
    carp "Videz d'abord la liste avant d'effectuer"
      ." tout changement sur l'ordre des clefs!\n"
	if (defined $contents && @$contents);
    $dictionary->decrease_term_pos ($term);
  } elsif ($edit_action eq 'definition') {
    print "Content-type: text/html\r\n\r\n";

    print '<html><head><title>Dictionnaire: '
      .$config::list_name." clef: ".$edit_key."</title></head>\n"
	.'<body bgcolor="#FFFFFF" text="#000000" link="#000000" vlink="#000000">'
	  .'<h1>&Eacute;dition de la clef "'.$edit_key
	    .'"</h1>'."\n";
    print '<form action="'.$ENV{'SCRIPT_NAME'}.'" method="POST">'."\n";
    print '<table align="center"><tbody>'."\n";
    my $definition = $term->definition || '';
    print '<tr><td>'.$edit_key
      .'</td><td><input type="text" name="definition" value="'
	.$definition.'"></td></tr>'
	  ."\n";
    print '<tr><td align="center" colspan="2">'
      .'<input type="hidden" name="key" value="'.$edit_key.'">'
	.'<input type="submit" name="submit" value="Valider la d&eacute;finition">'.
	  '</td></tr>'."\n";
    print '</tbody></table>'."\n";
    print '</form>'."\n";
    print '</body></html>';

    exit 0;
  } else {
    return;
  }

  $dictionary->save ();
}

sub edit_dict {
  my ($listman, $edit_action, $edit_key) = @_;

  my $dictionary = $listman->dictionary ();

  perform_edit_action ($listman, $edit_action, $dictionary, $edit_key)
    if (defined $edit_action && defined $edit_key);

  my $terms = $dictionary->terms ();

  print "Content-type: text/html\r\n\r\n";

  print '<html><head><title>Dictionnaire: '
    .$config::list_name."</title></head>\n"
      .'<body bgcolor="#FFFFFF" text="#000000" link="#000000" vlink="#000000">'
	.'<h1>&Eacute;dition du dictionnaire pour la liste "'
	  .$config::list_name
	    .'"</h1>'."\n"
	      .'<form action="'.$script_name.'" method="POST">'
		.'<table align="center"><tbody>'."\n";
  print '<tr><td align="center">No</td>'
    .'<td align="center">Clef</td>'
      .'<td align="center">D&eacute;finition</td>'
	.'<td align="center">Obligatoire?</td>'
	  .'<td></td><td></td></tr>'
	    ."\n";

  my $number = 1;
  foreach my $term (@$terms) {
    my $max_number = @$terms;
    my $dict_line = make_normal_edit_dict_line ($number,
						$max_number,
						$term);
    print $dict_line;
    $number++;
  }
  print '<tr><td align="center" colspan="4"><input type="submit" name="submit" value="Retour"></td></tr>';
  print "</tbody></table></form>\n";
  print "</body></html>\n";
}

sub post_main {
  my ($cgi, $listman) = @_;

  my $selection = make_selection ($cgi, $listman);

  my $submit = $cgi->param ('submit');
  if ($submit eq 'Dictionnaire') {
    edit_dict ($listman);
  } elsif ($submit eq 'Valider la définition') {
    my $contents = $listman->list_contents ();
    my @fields = $cgi->param ();

    my $dictionary = $listman->dictionary ();
    my $key = $cgi->param ('key');
    my $newdef = $cgi->param ('definition');

    my $term = $dictionary->get_term ($key);
    carp "Clef non-trouv&eacute;e.\n" unless (defined $term);

    $term->set_definition ($newdef);
    $dictionary->save ();
    edit_dict ($listman);
  } elsif (defined $selection) {
    if ($submit eq 'Exporter') {
      export_selection ($cgi, $listman, $selection);
    } elsif ($submit eq 'Effacer') {
      erase_selection ($cgi, $listman, $selection);
    }
  } else {
    get_main ($cgi, $listman);
  }
}

sub main {
  my $cgi = new CGI;
  my $rm = $cgi->request_method ();
  carp "No request method!??\n" unless ($rm);

  $script_name = $ENV{'SCRIPT_NAME'};
  my $listman = CGI::Listman->new ($config::backend,
				   $config::list_name,
				   $config::list_dir);
  $listman->{'db_name'} = $config::db_name;
  $listman->{'db_uname'} = $config::db_uname;
  $listman->{'db_passwd'} = $config::db_passwd;
  $listman->{'db_host'} = $config::db_host;
#  $listman->set_table_name ($config::db_table);

  ($rm eq 'GET') ? get_main ($cgi, $listman) : post_main ($cgi, $listman);

  $listman->commit ();
}

main ();
