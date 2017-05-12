package CGI::OptimalQuery::InteractiveFilter2;

use strict;
use warnings;
no warnings qw( uninitialized );
use base 'CGI::OptimalQuery::Base';

use CGI::OptimalQuery::FilterParser;
use CGI qw(escapeHTML);

sub output {
  my $o = shift;
  my $buf = CGI::header('text/html')."<!DOCTYPE html>\n<html><body><div class=OQFilterPanel><h1>filter</h1><table>";
  my $types = $$o{oq}->get_col_types('filter');
  my $s = $$o{schema}{select};

  my $filter = $$o{q}->param('filter');

  # add new field to filter?
  if ($$o{q}->param('field') ne '') {
    my $field = $$o{q}->param('field');

    # if named filter exists for this field, use the named filter
    if (exists $$o{schema}{named_filters}{$field}) {
      $filter .= " AND " if $filter;
      $filter .= $field.'()';
    }
    elsif (! $$s{$field}[3]{disable_filter}) {
      $filter .= " AND " if $filter;
      if ($$types{$field} eq 'char') {
        $filter .= "[$field] contains ''";
      } else {
        $filter .= "[$field] = ''";
      }
    }
  }
  

  my @cols = grep {
    $$s{$_}[2] ne '' && ! $$s{$_}[3]{disable_filter} && ! $$s{$_}[3]{is_hidden}
  } sort { $$s{$a}[2] cmp $$s{$b}[2] } keys %$s;
  my @op = (qw( = != < <= > >= like ), 'not like', 'contains', 'not contains');

  my $parsedFilter = CGI::OptimalQuery::FilterParser::parseFilter($o, $filter);
  foreach my $f (@$parsedFilter) {
    $buf .= "<tr>";

    my $typenum = $$f[0] if ref($f) eq 'ARRAY';

    if (! $typenum) {
      $buf .= "<td colspan=6><select class=logicop><option>AND<option";
      $buf .= " selected" if $f eq 'OR';
      $buf .= ">OR</select></td>";
    }

    # else if (selectalias operator literal)
    elsif ($typenum == 1 || $typenum == 3) {
      $buf .= "<td>";
      my ($type,$numLeftParen,$leftExp,$operator,$rightExp,$numRightParen) = @$f;
      if ($numLeftParen == 0) {
        $buf .= "<button type=button class=lp>(</button>";
      } else {
        $buf .= "<select class=lp><option value=''> </option><option";
        $buf .= " selected" if $numLeftParen==1;
        $buf .= ">(<option";
        $buf .= " selected" if $numLeftParen==2;
        $buf .= ">((<option";
        $buf .= " selected" if $numLeftParen==3;
        $buf .= ">(((</select>";
      }
      $buf .= "</td><td><select class=lexp>";
      foreach my $c (@cols) {
        $buf .= "<option value='[".escapeHTML($c)."]'";
        $buf .= " data-type=".$$types{$c} if $$types{$c} ne 'char';
        $buf .= " selected" if $c eq $leftExp;
        $buf .= ">".escapeHTML($$o{schema}{select}{$c}[2]);
      }
      $buf .= "</select></td><td><select class=op>";
      foreach my $op (@op) {
        $buf .= "<option";
        $buf .= " selected" if $op eq $operator;
        $buf .= ">$op";
      }
      $buf .= "</select></td><td><div class=rexptypesel><select class=rexp><optgroup label='Either: '><option value=''> type in a value </optgroup><optgroup label='OR select another field'>";
      my $rightSelectedField = $rightExp if $type == 3;
      foreach my $c (@cols) {
        $buf .= "<option value='[".escapeHTML($c)."]'";
        $buf .= " data-type=".$$types{$c} if $$types{$c} ne 'char';
        $buf .= " selected" if $c eq $rightSelectedField;
        $buf .= ">".escapeHTML($$o{schema}{select}{$c}[2]);
      }
      $buf .= "</optgroup></select><input type=text class=rexp";
      if ($rightSelectedField) {
        $buf .= " style='display: none;'";
      } else {
        $buf .= " value='".escapeHTML($rightExp)."'";
      }
      $buf .= "></div></td><td>";
      if ($numRightParen == 0) {
        $buf .= "<button type=button class=rp>)</button>";
      } else {
        $buf .= "<select class=rp><option value=''> </option><option";
        $buf .= " selected" if $numRightParen==1;
        $buf .= ">)<option";
        $buf .= " selected" if $numRightParen==2;
        $buf .= ">))<option";
        $buf .= " selected" if $numRightParen==3;
        $buf .= ">)))</select>";
      }
      $buf .= "</td><td><button type=button class=DeleteFilterElemBut>x</button></td>";
    }

    # else if (namedfilter, arguments)
    elsif ($typenum == 2) {
      $buf .= "<td>";
      my ($type,$numLeftParen,$namedFilter,$argArray,$numRightParen) = @$f; 
      if ($numLeftParen == 0) {
        $buf .= "<button type=button class=lp>(</button>";
      } else {
        $buf .= "<select class=lp><option value=''> </option><option";
        $buf .= " selected" if $numLeftParen==1;
        $buf .= ">(<option";
        $buf .= " selected" if $numLeftParen==2;
        $buf .= ">((<option";
        $buf .= " selected" if $numLeftParen==3;
        $buf .= ">(((</select>";
      }
      $buf .= "</td><td colspan=3>";
      my $nf = $$o{schema}{named_filters}{$namedFilter};
      if (ref($nf) eq 'ARRAY') {
        my $title = $$nf[2] || $namedFilter;
        $buf .= '<span>'.escapeHTML($title).'</span>'
          .'<input type=hidden value="'
          .escapeHTML("$namedFilter("
          .join(',', map { '"'.$_.'"' } @$argArray).")").'">';
      }
      elsif (ref($nf) eq 'HASH') {
        if (ref($$nf{html_generator}) eq 'CODE') {
          #before we call the html_generator, set the params up
          my %args;
          for (my $i=0; $i <= $#$argArray; $i+=2) { 
            my $name = $$argArray[$i];
            my $val  = $$argArray[$i + 1];
            $args{$name}||=[];
            push @{$args{$name}}, $val;
          }
          while (my ($name,$vals) = each %args) {
            $$o{q}->param('_nf_arg_'.$name, @$vals);
          }
          $buf .= 
            '<input type=hidden value="'.escapeHTML("$namedFilter(").'">'
            .$$nf{html_generator}->($$o{q}, '_nf_arg_')
            .'<input type=hidden value="'.escapeHTML(")").'">';
        } else {
          my $title = $$nf{title} || $namedFilter;
          $buf .= '<span>'.escapeHTML($title).'</span>'
            .'<input type=hidden value="'
            .escapeHTML("$namedFilter("
            .join(',', map { '"'.$_.'"' } @$argArray).")").'">';
        }
      }
      $buf .= "</td><td>";
      if ($numRightParen == 0) {
        $buf .= "<button type=button class=rp>)</button>";
      } else {
        $buf .= "<select class=rp><option value=''> </option><option";
        $buf .= " selected" if $numRightParen==1;
        $buf .= ">)<option";
        $buf .= " selected" if $numRightParen==2;
        $buf .= ">))<option";
        $buf .= " selected" if $numRightParen==3;
        $buf .= ">)))</select>";
      }
      $buf .= "</td><td><button type=button class=DeleteFilterElemBut>x</button></td>";
    }

    else {
      die "invalid typenum: $typenum; this should never happen";
    }


    $buf .= "</tr>";
  }
  $buf .= "</table><br>";

  $buf .= "<select class=newfilter><option value=''>-- add new filter element</option><optgroup label='Column to compare:'>";

  foreach my $c (@cols) {
    # if there is a named filter for this field, skip it and make user use named filter instead
    next if exists $$o{schema}{named_filters}{$c};

    $buf .= "<option value='".escapeHTML($c)."'";
    $buf .= " data-type=".$$types{$c} if $$types{$c} ne 'char';
    $buf .= ">".escapeHTML($$o{schema}{select}{$c}[2]);
  }
  $buf .= "</optgroup>";
  my $f = $$o{schema}{named_filters};
  my @k = sort {
    ((ref($$f{$a}) eq 'ARRAY') ? $$f{$a}[2] : $$f{$a}{title}) cmp
    ((ref($$f{$b}) eq 'ARRAY') ? $$f{$b}[2] : $$f{$b}{title}) } keys %$f;
  if ($#k > -1) {
    $buf .= "<optgroup label='Named Filters:'>";
    foreach my $alias (@k) {
      my $label;
      if (ref($$f{$alias}) eq 'ARRAY') {
        $label = $$f{$alias}[2];
      } else {
        $label = $$f{$alias}{title};
      }
      next unless $label;
      $buf .= "<option value='".escapeHTML($alias)."()'>".escapeHTML($label);
    }
    $buf .= "</optgroup>";
  }
  $buf .= "</select><br><button type=button class=CancelFilterBut>cancel</button><button type=button class=OKFilterBut>ok</button></div></body></html>";

  $$o{output_handler}->($buf);
  return undef;
}

1;
