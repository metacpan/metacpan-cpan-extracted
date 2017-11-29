package CGI::OptimalQuery::ShowColumns;

use strict;
use warnings;
no warnings qw( uninitialized );
use base 'CGI::OptimalQuery::Base';

sub escapeHTML { CGI::OptimalQuery::Base::escapeHTML(@_) }

sub output {
  my $o = shift;
  my $buf = CGI::header('text/html').
"<!DOCTYPE html>
<html>
<body>
<div class=OQAddColumnsPanel>
<h2>select fields to add ..</h2>";
  my $s = $$o{schema}{select};
  my @c = sort { $$s{$a}[2] cmp $$s{$b}[2] } keys %$s;
  foreach my $colAlias (@c) {
    my $label = $$s{$colAlias}[2];
    my $colOpts = $$s{$colAlias}[3];
    $buf .= '<label class=ckbox><input type=checkbox value="'.escapeHTML($colAlias).'">'
      .escapeHTML($label).'</label>'
      unless $label eq '' || $$colOpts{disable_select} || $$colOpts{is_hidden};
  }
  $buf .= "
<p>
<label>display as:
<select id=ShowColumnsDisplayAs>
  <option value=default>table rows
  <option value=recview".(($$o{q}->param('mode') eq 'recview')?" selected":"").">records
</select>
</label>
<p>
<button class=OQAddColumnsCancelBut>cancel</button>
<button class=OQAddColumnsOKBut>ok</button>
</div>
</body>
</html>";
  $$o{output_handler}->($buf);
  return undef;
}

1;
