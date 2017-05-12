package CGI::OptimalQuery::InteractiveFilter;

use strict;
use warnings;
no warnings qw( uninitialized );
use base 'CGI::OptimalQuery::Base';
use Data::Dumper;
use DBIx::OptimalQuery();
use CGI();


my $DEFAULT_CSS = <<'TILEND';
<STYLE type="text/css">
/* ----- base functionality ----- */

form.filterForm td.lp_col, 
form.filterForm td.rp_col {
  text-align: center; 
}

form.filterForm td.lp_col input, 
form.filterForm td.rp_col input { 
  color: #999999; 
  background-color: white; 
  border: 1px solid #efefef; 
  font-size: 1em; 
  width: 2em;
}

form.filterForm td.l_col input.colvalbtn { display: none; }
form.filterForm td.d_col input { color: #990000; background-color: white; border: 1px solid white;}
form.filterForm tr.footer td.d_col input { background-color: #990000; color: white; border: 1px solid #666666;}
form.filterForm .d_col { color: #990000; }

div.RO_NAMED_FILTER {
  background-color: #efefef;
  color: #222222;
  font-size: 1.1em;
  text-align: center; 
  border: 1px solid #666666;
}

form.filterForm input, 
form.filterForm select { 
  border: 1px solid #666666; 
  background-color: #efefef; 
  padding: 2px; 
  vertical-align: middle; 
}

td.f_col { text-align: center; }


form.filterForm .hide { display: none; }


/* -------------------- prefs -------------------- */
form.filterForm .submit_off,.add_off { display: none; }
form.filterForm .c_col { text-align: center; }
form.filterForm input.submit_ok { background-color: lightgreen; }
form.filterForm input.submit_off { background-color: yellow; }
form.filterForm .paren_warn { text-align: center; background-color: yellow; }
form.filterForm .paren_match { display: none; }
form.filterForm .delbtn { color: white; background-color: #990000; }
form.filterForm .noparen { color: white; }
</STYLE>
TILEND

=comment CSS MORE POSSIBILITIES
# Simplest mode 
form.filterForm .colvalbtn { display:none; }
form.filterForm .noparen { display:none; }
form.filterForm #paren_warn { display:none; }

# Disable deleting controls
form.filterForm .d_col { display:none; }

# other possibilities ...
form.filterForm label:after { content: " mark"; }
<!-- Different Style Sheet possibilites (see documentation) -->
<link title="full" rel="stylesheet" type="text/css" href="http:///css/OQfilter_full.css" />
<link title="simplest" rel="alternate stylesheet" type="text/css" href="http:///css/OQfilter_simplest.css" />
<link title="test" rel="alternate stylesheet" type="text/css" href="http:///css/OQfilter_test.css" />
=cut




# ------------------------- new -------------------------
sub new {
  my $pack = shift;
  my $o = $pack->SUPER::new(@_);
  $$o{view} = '';
  $$o{schema}{options}{'CGI::OptimalQuery::InteractiveFilter'}{css} ||= $DEFAULT_CSS;
  $o->process_actions();
  return $o;
}


# ------------------------- print -------------------------
sub output {
  my $o = shift;
  $$o{output_handler}->(CGI::header());
  my $view = $$o{view};
  $$o{output_handler}->($o->$view()) if $o->can($view);
  return undef;
}




=comment
  Grammar Translations: basically this describes how to convert rules 
  into elements of an expression array. Each element in this array
  is a hash ref with keys: L_PAREN, R_PAREN, ANDOR, CMPOP, R_VALUE,
  L_COLMN, R_COLMN, FUNCT, ARG_XYZ. Later this array can be translated
  to CGI params that represent the filter for an HTML form.
  Notice: The hash key is the rule name, the value is a sub ref where
  the following args are defined:
    $_[0] is $oq
    $_[1] is rule name
    $_[2] is token 1, $_[3] is token 2, etc ...
=cut
my %translations = (

  # *** RULE ***
  # exp:
  #    '(' exp ')' logicOp exp
  #  | '(' exp ')'
  #  | comparisonExp logicOp exp
  #  | comparisonExp
  'exp' => sub {
    # expression array is just an array of exp
    # each element is a hashref containing keys 
    # L_PAREN, R_PAREN, ANDOR, CMPOP, R_VALUE, 
    # L_COLMN, R_COLMN, FUNCT, ARG_XYZ
    my $expression_array;

    # handle tokens: 
    #   '(' exp ')' logicOp exp
    # | '(' exp ')'
    if ($_[2] eq '(') {
      $expression_array = $_[3];
      $$expression_array[0]{L_PAREN}++;
      $$expression_array[-1]{R_PAREN}++;

      # handle tokens: logicOp exp
      if (exists $_[5]{ANDOR} && ref($_[6]) eq 'ARRAY') {
        $$expression_array[-1]{ANDOR} = $_[5]{ANDOR}; 
        push @$expression_array, @{ $_[6] }; # append exp
      }
    }

    # handle tokens:
    #   comparisonExp logicOp exp
    # | comparisonExp
    else {
      $expression_array = [ $_[2] ];

      # add: logicOp exp
      if (exists $_[3]{ANDOR} && ref($_[4]) eq 'ARRAY') {
        $$expression_array[-1]{ANDOR} = $_[3]{ANDOR}; 
        push @$expression_array, @{ $_[4] }; # append exp
      }
    }
    return $expression_array;
  },

  # *** RULE ***
  #   namedFilter
  # | colAlias compOp colAlias
  # | colAlias compOp bindVal
  'comparisonExp' => sub { 

    # if not a named filter
    # combine CMPOP and R_VALUE | R_COLMN in
    if (exists $_[2]{COLMN}) {
      $_[2]{L_COLMN} = delete $_[2]{COLMN};
      $_[2]{CMPOP} = $_[3]{CMPOP};
      if (! ref $_[4]) { $_[2]{R_VALUE} = $_[4]; }
      else { $_[2]{R_COLMN} = $_[4]{COLMN}; }
    }
    return $_[2];
  },

  # remove quotes from string
  'quotedString' => sub { $_ = $_[2]; s/^\'// || s/^\"//; s/\'$// || s/\"$//; $_; },

  # *** RULE ***
  # colAlias: '[' /\w+/ ']'
  'colAlias' => sub { 
    die "could not find colAlias '$_[3]'" unless exists $_[0]{select}{$_[3]};
    return { 'COLMN' => $_[3] };
  },

  # *** RULE *** logicOp: /and/i | /or/i
  'logicOp' => sub { { ANDOR => uc($_[2]) } },

  # *** RULE *** compOp: '=' | '!=' | '<' |, ....
  'compOp'  => sub { { CMPOP => lc($_[2]) } },

  # *** RULE *** nullComp: /is\ null/i | /is\ not\ null/i
  'namedFilter' => sub {
    die "could not find named filter '$_[2]'" unless exists $_[0]{named_filters}{$_[2]};
    my $rv = { 'FUNCT' =>  $_[2].'()' };
    my %args = @{ $_[4] } if ref($_[4]) eq 'ARRAY';
    foreach my $key (keys %args) { $$rv{'ARG_'.$key} = $args{$key}; }
    return $rv;
  },

  # just return the first token for all other rules not specified
  '*default*' => sub { $_[2] }
);



# ------------------------- process actions -------------------------
sub process_actions {
  my $o = shift;
  my $q = $$o{q};
  $$o{view} = 'html_filter_form';

  # should we load a fresh filter into the appropriate params
  # representing the filter?
  if ($q->param('filter') ne '') {
    my $expression_array = $$o{oq}->parse($DBIx::OptimalQuery::filterGrammar, 
      $q->param('filter'), \%translations);
    die "bad filter!\nfilter= ".$q->param('filter').
        "\nexp=".Dumper( $expression_array )."\n" unless ref($expression_array) eq 'ARRAY';

    # fill in the params representing the filter state
    my $i = 0;
    foreach my $exp (@$expression_array) {
      $i++;
      while (my ($k,$v) = each %$exp) { $q->param('F'.$i.'_'.$k,$v); }
    }
    $q->param('FINDX', $i);
    $q->param('hideParen', ($i < 3));
    $$o{view} = 'html_filter_form';
  }    

  
  # did the user request a new expression?
  if ( defined $q->param('NEXT_EXPR')
       && scalar $q->param('NEXT_EXPR') ne '-- add new filter element --') {
      my $val = scalar $q->param('NEXT_EXPR');
      my $findx = $q->param('FINDX');
      $findx = 0 unless $findx > 0;
      $findx++;
      my $pn = 'F' . $findx . '_';
      if( $val =~ /\(\)\Z/ ) { # ends with a ()
          $q->param($pn.'FUNCT', $val);
      } else {
        $q->param($pn.'L_COLMN', $val);
        $q->param($pn.'L_VALUE', ''); 
        if ($o->typ4clm($val) eq 'char' ||
            $o->typ4clm($val) eq 'clob') {
          $q->param($pn.'CMPOP', 'contains'); 
        } else {
          $q->param($pn.'CMPOP', '='); 
        }
      }
      $q->param('FINDX', $findx);
      $q->param('hideParen', ( $findx < 3 ) );
      $q->param('NEXT_EXPR', '--- Choose Next Filter ---');
      $$o{view} = 'html_filter_form';

  } 

  # did user submit the filter?
  elsif ($q->param('act') eq 'submit_filter') {
      my $ftxt = $o->recreateFilterString();
      $q->param('filter', $ftxt);
      $$o{view} = 'html_parent_update';
      if ($$o{error}) {
        $$o{view} = 'html_filter_form';
      }
  } 

  # did user request to delete filter
  elsif ($q->param('act') eq 'submit_del') {
      delselForm( $q );
      $$o{view} = 'html_filter_form';
  }

  return undef;
}


# ------------------------- cmp_val -------------------------
sub cmp_val ( $$$$ ) {
    my( $q, $pnam, $vals, $lbls ) = @_;


    my $isUserVal = ( $q->param($pnam.'COLMN') eq ''
                      ||  $q->param($pnam.'ISVAL') );

    return
        $q->button( -name=>$pnam.'BTN',
                    -label=>$isUserVal?'value:':'column:',
                    -onClick=>"toggle_value('$pnam');",
                    -class=>'colvalbtn')
        . $q->hidden( -name=>$pnam.'ISVAL', -default=>$isUserVal )
        . $q->textfield( -name=>$pnam.'VALUE',
                         -class=> ( $isUserVal ? 'val' : 'hide' ) )
        . $q->popup_menu( -name=>$pnam.'COLMN',
                          -values=> $vals, -labels=> $lbls,
                          -onChange=>"submit_act('refresh');",
                          -class=> $isUserVal ? 'hide' : 'col');

}

# ------------------------- recreateFilterString -------------------------
sub recreateFilterString {
    my $o = shift;
    my $q = $$o{q};

    # pull out the fuctions arguments from the form
    my %funct_args = ();
    foreach my $fak ( $q->param() ){
	my @ary = split 'ARG_', $fak;
	$funct_args{$ary[0]}{$ary[1]} = $q->param($fak)
	    if defined $ary[1];
    }

    my $ftext = '';
    my $ei = scalar $q->param('FINDX');
    for( my $i = 1; $i <= $ei; $i++ ) {
	my $p = 'F' . $i . '_';

	my $parcnt = $q->param($p.'L_PAREN');
	$ftext .= ($parcnt < 1 ? '' : '('x$parcnt . ' ' );

	if( defined $q->param($p.'FUNCT')
	    && $q->param($p.'FUNCT') ne '' ) {

	    # TODO: Grab the $p.'ARG_' and Dump it.
	    my $f = $q->param($p.'FUNCT');
	    $f =~ s/\(\)\Z//;
            my $args = '';
            while (my ($k,$v) = each %{ $funct_args{$p} }) { 
              $args .= ',' if $args;
              $v = "'".$v."'" if $v =~ /\W/;
              $args .= "$k,$v";
            }
            $ftext .= " $f($args) ";
	} else {
	    if( $q->param($p.'L_ISVAL') ) {
		$ftext .= '\'' . $q->param($p.'L_VALUE') . '\'';
	    } else {
		$ftext .= '[' . $q->param($p.'L_COLMN') . ']';

        # force operator to be "like/not like" if a numeric operator
        if ($o->typ4clm(uc($q->param($p.'L_COLMN'))) eq 'clob' &&
            $q->param($p.'CMPOP') !~ /\w/) {
          if ($q->param($p.'CMPOP') =~ /\!/) {
            $q->param($p.'CMPOP', "not like");
          } else {
            $q->param($p.'CMPOP', "like");
          }
        }
	    }

	    $ftext .= ' ' . $q->param($p.'CMPOP') . ' ';

	    if( $q->param($p.'R_ISVAL') ) {
                my $val = $q->param($p.'R_VALUE');
                if ($val =~ /\'/ || $val =~ /\"/) {
                  if ($val !~ /\"/) { $val = '"'.$val.'"'; } 
                  elsif ($val !~ /\'/) { $val = "'".$val."'"; } 
                  else { $val =~ s/\'|\"//g; }
                } else {
                  $val = "'$val'";
                }
          $ftext .= $val;

          # if date comparison and right side is value and numeric operator
          # ensure the right side valud fits date_format string
          if ($q->param($p.'L_COLMN') &&
              $q->param($p.'CMPOP') !~ /\w/ &&
              exists $$o{schema}{select}{$q->param($p.'L_COLMN')} &&
              exists $$o{schema}{select}{$q->param($p.'L_COLMN')}[3]{date_format}) {
            my $date_format = $$o{schema}{select}{$q->param($p.'L_COLMN')}[3]{date_format};
            local $$o{dbh}->{RaiseError} = 0;
            local $$o{dbh}->{PrintError} = 0;
            if ($$o{dbh}{Driver}{Name} eq 'Oracle') {
              my $dt = $q->param($p.'R_VALUE');
              if ($dt ne '') {
                my ($rv) = $$o{dbh}->selectrow_array("SELECT 1 FROM dual WHERE to_date(?,'$date_format') IS NOT NULL", undef, $dt);
                if (! $rv) {
                  $$o{error} = "invalid date: \"$dt\",  must be in format: \"$date_format\"";
                  return undef;
                }
              }
            }
          }
	    } else {
		  $ftext .= '[' . $q->param($p.'R_COLMN') . ']';
	    }
	}

	$parcnt = $q->param($p.'R_PAREN');
	$ftext .= ( $parcnt<1 ? '' : ')'x$parcnt .' ' ) . "\n";

	$ftext .= $q->param($p.'ANDOR') . "\n"	unless( $i == $ei );

    }

    $ftext =~ s/\n//g;
    return $ftext;
}

# ------------------------- delselForm -------------------------
sub delselForm( $ ) {
    my( $q ) = @_;

    my $oei = scalar $q->param('FINDX');
    my $ni=1;
    for( my $oi = 1; $oi <= $oei; $oi++ ) {
        my $op = 'F' . $oi . '_';
	unless( $q->param($op.'DELME') ) {
	    if( $oi != $ni ){
		my $np = 'F' . $ni . '_';
                $q->delete($np.'FUNCT'); # clear so NOT assumed a func
                

		foreach my $par ( $q->param() ) {
		    if( $par =~ s/\A$op// ){
			$q->param( $np.$par, $q->param($op.$par) );
		    }
		}
	    }
	    $ni++;
	}
    }
    $ni--;
    $q->param('FINDX', $ni);
    return $oei - $ni;
}


# ------------------------- typ4clm -------------------------
sub typ4clm ($$) {
    my( $o, $clm ) = @_;
    $clm =~ s/\A\[//;
    $clm =~ s/\]\Z//;
    return $o->{oq}->get_col_types('filter')->{uc($clm)};
}

# ------------------------- cmpopLOV -------------------------
sub cmpopLOV { ['=','!=','<','<=','>','>=','like','not like','contains','not contains'] }


# ------------------------- html_parent_update -------------------------
sub html_parent_update( $ ) {

    my ($o) = @_;

    my $q = $o->{q};

    my $filter = $q->param('filter');
    $filter =~ s/\n/\ /g;

    my $js = "
	 if( window.opener
             && !window.opener.closed
             && window.opener.OQval ) {
           var w = window.opener;
	   w.OQval('filter', '".$o->escape_js($filter)."');
           if (w.OQval('rows_page') == 'All') w.OQval('rows_page', 10);
	   w.OQrefresh();
	   window.close();
	 }

	 function show_defaultOQ() {
           window.document.failedFilterForm.submit();
           return true;
         }
";

    my $doc = $q->start_html( -title=>'OQFilter', -script=> $js )
	  . '<H3>Unable to contact this filters parent.</H3>'
	  . $q->start_form( -name=>'failedFilterForm', -class=>'filterForm', -action => $$o{schema}{URI_standalone});


    if (ref($$o{schema}{state_params}) eq 'ARRAY') {
      foreach my $p (@{ $$o{schema}{state_params} }) {
        $doc .= "<input type='hidden' name='$p' value='".$o->escape_html($q->param($p))."'>";
      }
    }

    $doc .= $q->hidden( -name=>'filter', -value=>'')
	  . '<A HREF="" onclick="show_defaultOQ();return false;">'
	  . 'Click here for a default view</A> of the following RAW filter.'
	  . '<HR /><PRE>'
	  . $o->escape_html( $q->param('filter') )
	  . '</PRE><HR />'
          . $q->end_html() ;

    return $doc;
}

# ------------------------- getFunctionNames -------------------------
sub getFunctionNames( $ ) {
    my( $o ) = @_;
    my %functs = (); # ( t1=>'Test One', t2=>"Test Two" );
    foreach my $k ( keys %{$o->{schema}->{'named_filters'}} ) {
	my $fref = $o->{schema}->{'named_filters'}{$k};
        if (ref $fref eq 'ARRAY') { $functs{"$k".'()'} = $fref->[2]; }
        elsif (ref $fref eq 'HASH' && $fref->{'title'} ne '') { 
          $functs{"$k".'()'} = $fref->{'title'};
        }
    }
    return %functs;
}

# ------------------------- getColumnNames -------------------------
sub getColumnNames( $ ) {
    my( $o ) = @_;
    my %cols = (); # ( t1=>'Test One', t2=>"Test Two" );
    foreach my $k ( keys %{$o->{schema}->{'select'}} ) {
        next if $$o{schema}{select}{$k}[3]{is_hidden};
	my $cref = $o->{schema}->{'select'}{$k};
	$cols{"$k"} = 
	    ( ref $cref eq 'ARRAY' ) ? $cref->[2] : 'bad:'.(ref $cref) ;
    }
    return %cols;
}

# ------------------------- html_filter_form -------------------------
sub html_filter_form( $ ) {
    my( $o ) = @_;
    
    my %columnLBL = $o->getColumnNames();
    my @columnLOV = sort { $columnLBL{$a} cmp $columnLBL{$b} } keys %columnLBL;
    # TODO:  create named_functions from pre-exising filters and use them
#    my @functionLOV = map {"$_".'()'} keys %{$o->{schema}->{'named_filters'}};
#     my @functionLOV = keys %{$o->{schema}->{'named_filters'}};
    my %functionLBL = $o->getFunctionNames();
    my @functionLOV = sort { $functionLBL{$a} cmp $functionLBL{$b} } keys %functionLBL;
	# (t1=>'Test One', t2=>"Test Two");
    my @andorLOV = ('AND', 'OR');


    my $js="

	function toggle_value(basenam) {
          var f = window.document.filterForm;
	  if( f.elements[basenam+'ISVAL'].value ) {
            f.elements[basenam+'ISVAL'].value = '';
  	    f.elements[basenam+'BTN'].value = 'column:';
	    f.elements[basenam+'VALUE'].className = 'hide';
	    f.elements[basenam+'COLMN'].className = 'col';
          } else {
            f.elements[basenam+'ISVAL'].value = 1;
  	    f.elements[basenam+'BTN'].value = 'value:';
	    f.elements[basenam+'VALUE'].className = 'val';
	    f.elements[basenam+'COLMN'].className = 'hide';
          }
          return true;
	}

	function update_paren_vis(basenam) {
          var f = window.document.filterForm;
	  if( f.elements[basenam+'PAREN'].options[0].selected ) {
	    f.elements[basenam+'PARBTN'].className = 'noparen';
	    f.elements[basenam+'PAREN'].className = 'hide';
	  } else {
	    f.elements[basenam+'PARBTN'].className = 'hide';
	    f.elements[basenam+'PAREN'].className = 'paren';
	  }
          window.check_paren();
          return true;
	}

	function toggle_paren(basenam) {
          var f = window.document.filterForm;
	  if( f.elements[basenam+'PAREN'].options[0].selected ) {
	    f.elements[basenam+'PAREN'].options[1].selected = true;
	  } else {
	    f.elements[basenam+'PAREN'].options[0].selected = true;
	  }
          window.update_paren_vis(basenam);
          return true;
	}

	function show_submit_del() {
          var f = window.document.filterForm;
          var i = f.elements['FINDX'].value;
          for(; i>0; i--){
            if( f.elements['F'+i+'_DELME'].checked ) {
  	      f.elements['SUBMIT_DEL'].className = 'delbtn';
              window.document.getElementById('submit_text').className = 'submit_off';
              window.document.getElementById('submit_add').className = 'add_off';
              return true;
            }
	  }
          f.elements['SUBMIT_DEL'].className = 'hide';
  	  f.elements['CHECKALL'].checked = false;
          window.document.getElementById('submit_add').className = 'add_ok';
          window.check_paren();
          return true;
	}

	function submit_act(actval) {
          var f = window.document.filterForm;
          f.elements.act.value = actval;
          f.submit();
          return true;
	}

	function checkall_delme() {
          var f = window.document.filterForm;
          var newval = f.elements['CHECKALL'].checked;
          var i = f.elements['FINDX'].value;
          for(; i>0; i--){
            f.elements['F'+i+'_DELME'].checked = newval;
	  }
          window.show_submit_del();
          return true;
	}

	function check_paren() {
          var f = window.document.filterForm;
          var i = f.elements['FINDX'].value;
          var ocnt = 0;
          for(; i>0; i--){
            ocnt += f.elements['F'+i+'_R_PAREN'].value - f.elements['F'+i+'_L_PAREN'].value;
            if( ocnt < 0 ) {
              i = -3;
            }
	  }
          if( ocnt == 0 ) {
            window.document.getElementById('submit_text').className = 'submit_ok';
            window.document.getElementById('paren_warn').className = 'paren_match';
          } else {
            window.document.getElementById('submit_text').className = 'submit_off';
            window.document.getElementById('paren_warn').className = 'paren_warn';
          }
          return true;
	}

        ";



    my $q = $o->{q};

    # pull out the fuctions arguments from the form
    my %funct_args = ();
    foreach my $fak ( $q->param() ){
	my @ary = split 'ARG_', $fak;
	$funct_args{$ary[0]}{$ary[1]} = $q->param($fak)
	    if defined $ary[1];
    }


    my $html = 
	$q->start_html ( -title=>"Interactive Filter - $$o{schema}{title}",
			 -script=> $js,
			 -head=>
          $$o{schema}{options}{'CGI::OptimalQuery::InteractiveFilter'}{css} ).
          "<center>".
        (($$o{error}) ? "<strong>".$q->escapeHTML($$o{error})."</strong>" : "").
	  $q->start_form ( -action=> $$o{schema}{URI_standalone}, -name=>'filterForm',
			   -class=>'filterForm');


    if (ref($$o{schema}{state_params}) eq 'ARRAY') {
      foreach my $p (@{ $$o{schema}{state_params} }) {
        $html .= "<input type='hidden' name='$p' value='".$o->escape_html($q->param($p))."'>";
      }
    }

      $html .= 
	  $q->hidden ( -name=>'module', -value=>'InteractiveFilter',
		       -override=>1 )
	. $q->hidden ( -name=>'act', -value=>'submit_filter',
		      -override=>1 )
	. $q->hidden ( -name=>'hideParen', -value=>1 )
	. $q->hidden ( -name=>'FINDX', -value=>'0') ;
	  

    $html .= "<TABLE COLUMNS=6>\n";


    my $hideParen = $q->param('hideParen');
    my $pnp; # parameter name prefix

    my $thing_to_focus_on;

    for( my $findx = 1; $findx <= $q->param('FINDX'); $findx++ ) {
	$pnp = 'F' . $findx . '_';
	$html .= '<TR><TD class="lp_col">'
	    . $q->button ( -name=>$pnp.'L_PARBTN', -label=>'(',
			   -onClick=>"toggle_paren('$pnp"."L_');",
			   -class=> $hideParen
			   ? 'hide' : ( $q->param($pnp.'L_PAREN') > 0
					? 'hide' : 'noparen' ) )
	    . $q->popup_menu
	        ( -name=>$pnp.'L_PAREN', -values=>[0 .. 3], -default=>'0',
		  -labels=>{'0'=>'','1'=>'(','2'=>'((','3'=>'((('},
		  -onChange=>"update_paren_vis('$pnp"."L_');",
		  -class=>$q->param($pnp.'L_PAREN')<1 ?'hide':'paren' )
	    . '</TD>';

	if( defined $q->param($pnp.'FUNCT') ) {
	    my $func_nam = $q->param($pnp.'FUNCT');
	    $func_nam =~ s/\(\)//;

            # if a predefined named filter
            if (ref($o->{schema}->{'named_filters'}{$func_nam}) eq 'ARRAY') {
    	      $html .= '<TD class="f_col" colspan=3>'
	  	  . $q->popup_menu( -name=>$pnp.'FUNCT',
		  		    -values=> \ @functionLOV,
				    -labels=> \ %functionLBL,
				    -default=> $q->param($pnp.'FUNCT'),
				    -onChange=>"submit_act('refresh');" ) ;
	      $html .= '</TD>';
            }
            
            # if named filter has an html generator
            elsif (exists $o->{schema}->{'named_filters'}{$func_nam}{html_generator}) {
    	      $html .= '<TD class="f_col" colspan=3>'
	  	  . $q->popup_menu( -name=>$pnp.'FUNCT',
		  		    -values=> \ @functionLOV,
				    -labels=> \ %functionLBL,
				    -default=> $q->param($pnp.'FUNCT'),
				    -onChange=>"submit_act('refresh');" ) ;
	      $html .=
		$o->{schema}->{'named_filters'}{$func_nam}{'html_generator'}->($q, $pnp.'ARG_');
	      $html .= '</TD>';
            } 

            # else if named filter does not have a html_generator 
            else {
              $html .= "<TD class='f_col' colspan=3><input type=hidden name='$pnp"."FUNCT' value='".$o->escape_html("$func_nam()")."' />";
              my %args;
              my $arg_prefix = quotemeta($pnp.'ARG_');
              foreach my $param (grep { /^$arg_prefix/ } $q->param) {
                my $k = $param; $k =~ s/$arg_prefix//;
                my $v = $q->param($param); 
                $args{$k} = $v;
                $html .= "<input type=hidden name='$param' value='".$o->escape_html($q->param($param))."' />";
              }

              my $rv = $o->{schema}->{'named_filters'}{$func_nam}{'sql_generator'}->(%args);
	      $html .= "<div class=RO_NAMED_FILTER>".$o->escape_html($$rv[2])."</div></TD>";
            }
        }

	else {
	    $html .= '<TD class="l_col">'
		. &cmp_val($q, $pnp.'L_', \ @columnLOV, \ %columnLBL)
		. '</TD><TD class="c_col">'
		. $q->popup_menu ( 
                    -name=>$pnp.'CMPOP', -values=> cmpopLOV(), -class=>'cmpop')
		. '</TD><TD class="r_col">'
		. &cmp_val($q, $pnp.'R_', \ @columnLOV, \ %columnLBL )
		. '</TD>';
	}

	$html .= '<TD class="rp_col">'
	    . $q->popup_menu ( -name=>$pnp.'R_PAREN',
			       -values=>[0 .. 3], -default=>'0',
			       -labels=>
			         {'0'=>'', '1'=>')', '2'=>'))', '3'=>')))'},
			       -onChange=>"update_paren_vis('$pnp"."R_');",
			       -class=> ( $q->param($pnp.'R_PAREN')<1
					  ? 'hide' : 'paren' ) )
	    . $q->button ( -name=>$pnp.'R_PARBTN', -label=>')',
			   -onClick=>"toggle_paren('$pnp"."R_');",
			   -class=> $hideParen 
			   ? 'hide'
			   : ( $q->param($pnp.'R_PAREN')>0
			       ? 'hide' : 'noparen') )
	    . '</TD><TD class="d_col">'
	    . $q->checkbox ( -name=>$pnp.'DELME', -label=>'remove',
			     -value=>'1', -checked=>0, -override=>1,
			     -onClick=>'show_submit_del();',
			     -class=>'delbox' )
	    . "</TD></TR>\n<TR><TD colspan=5 align=center>"
	    . $q->popup_menu ( -name=>$pnp.'ANDOR', -values=> \ @andorLOV,
			       -class=>$findx == $q->param('FINDX')?'hide':'')
	    . "</TD></TR>\n" ;

    }

    
    $html .= '<TR><TD colspan=5><HR width="90%" /></TD><TD class="d_col">'
	. $q->checkbox ( -name=>'CHECKALL', -label=>'ALL', -value=>'1',
			 -checked=>0, -override=>1,
			 -onClick=>'checkall_delme();',
			 -class=>'delbox' )
	. '</TD></TR> <TR class="footer"><TD colspan=5></TD><TD class="d_col">'
	. $q->button ( -name=>'SUBMIT_DEL', -label=>'REMOVE',
		       -onClick=>"submit_act('submit_del');",
		       -class=> 'hide' )
	. '</TD></TR>' 
	if( $q->param('FINDX') > 0 ); # we printed something above here

    my @sel_opts = ('-- add new filter element --', $q->optgroup ( -name=>'Column to compare:',
                                       -values=> \ @columnLOV ,
                                       -labels=> \ %columnLBL ) );
    if (@functionLOV) {
      push @sel_opts, $q->optgroup ( -name=>'Named Filters:',
                                     -values=> \ @functionLOV ,
                                     -labels=> \ %functionLBL );
    }

    $html .= "</TABLE>\n"
	. '<DIV id="paren_warn" class="paren_match">( Parenthesis must be matching pairs )</DIV>'
	. '<SPAN id="submit_add" class="submit_ok">'
	. $q->popup_menu ( -name=>'NEXT_EXPR', 
			   -default=>'--- Choose Next Filter ---',
			   -override=>1,
			   -values=>\@sel_opts,
			   -onChange=>"submit();" )
	. '</SPAN><SPAN id="submit_text" class="submit_ok"> or '
	. $q->submit( -name=>'SUBMIT', -class=>'submit_ok' )
	. "</SPAN> "
	. $q->end_form()
	. "\n</center>
<script type='text/javascript'>
  check_paren();
  if (window.document.forms[0].elements['F".$q->param('FINDX')."_R_VALUE']) 
    window.document.forms[0].elements['F".$q->param('FINDX')."_R_VALUE'].focus();
</script><noscript>Javascript is required when viewing this page.</noscript>
".$q->end_html();

    return $html;

}


1;


