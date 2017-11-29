package CGI::OptimalQuery::LoadSearchTool;

use strict;
use JSON::XS();
use CGI::OptimalQuery::Base();

sub escapeHTML { CGI::OptimalQuery::Base::escapeHTML(@_) }

sub load_default_saved_search {
  my ($o) = @_;
  return undef unless exists $$o{canSaveDefaultSearches};
  local $$o{dbh}{LongReadLen};
  if ($$o{dbh}{Driver}{Name} eq 'Oracle') {
    $$o{dbh}{LongReadLen} = 900000;
    my ($readLen) = $$o{dbh}->selectrow_array("SELECT dbms_lob.getlength(params) FROM oq_saved_search WHERE uri=? AND is_default=1", undef, $$o{schema}{URI});
    $$o{dbh}{LongReadLen} = $readLen if $readLen > $$o{dbh}{LongReadLen};
  }
  my ($params) = $$o{dbh}->selectrow_array("
    SELECT params
    FROM oq_saved_search
    WHERE uri=?
    AND is_default=1", undef, $$o{schema}{URI});

  if ($params) {
    $params = eval '{'.$params.'}'; 
    if (ref($params) eq 'HASH') {
      delete $$params{module};
      while (my ($k,$v) = each %$params) {
        if(!defined($$o{q}->param($k))) {
          $$o{q}->param( -name => $k, -values => $v ); 
        }
      }
    }
  }
  return undef;
}


sub load_saved_search {
  my ($o, $id) = @_;
  local $$o{dbh}{LongReadLen};
  if ($$o{dbh}{Driver}{Name} eq 'Oracle') {
    $$o{dbh}{LongReadLen} = 900000;
    my ($readLen) = $$o{dbh}->selectrow_array("SELECT dbms_lob.getlength(params) FROM oq_saved_search WHERE id = ?", undef, $id);
    $$o{dbh}{LongReadLen} = $readLen if $readLen > $$o{dbh}{LongReadLen};
  }
  my ($params) = $$o{dbh}->selectrow_array(
    "SELECT params FROM oq_saved_search WHERE id=?", undef, $id);

  if ($params) {
    $params = eval '{'.$params.'}'; 
    if (ref($params) eq 'HASH') {
      delete $$params{module};
      while (my ($k,$v) = each %$params) {
        if(!defined($$o{q}->param($k))) {
          $$o{q}->param( -name => $k, -values => $v ); 
        }
      }
    }

    # remember saved search ID
    $$o{q}->param('OQss', $id);
  }
  return undef;
}

sub on_init {
  my ($o) = @_;

  my $delete_id = $$o{q}->param('OQDeleteSavedSearch') || $$o{q}->url_param('OQDeleteSavedSearch');

  # request to delete a saved search
  if ($delete_id) {
    $$o{dbh}->do("DELETE FROM oq_saved_search WHERE user_id=? AND id=?", undef, $$o{schema}{savedSearchUserID}, $delete_id);
    $$o{output_handler}->(CGI::header('text/html')."report deleted");
    return undef;
  }

  # request to load a saved search?
  elsif ($$o{q}->param('OQLoadSavedSearch') =~ /^\d+$/) {
    load_saved_search($o, $$o{q}->param('OQLoadSavedSearch'));
  }

  # if intial request, load default saved search if it exists
  elsif (! defined $$o{q}->param('module')) {
    load_default_saved_search($o);
  }
}

sub on_open {
  my ($o) = @_;
  my $ar = $$o{dbh}->selectall_arrayref("
    SELECT id, uri, user_title
    FROM oq_saved_search
    WHERE user_id = ?
    AND upper(uri) = upper(?)
    AND oq_title = ?
    ORDER BY 2", undef, $$o{schema}{savedSearchUserID},
      $$o{schema}{URI}, $$o{schema}{title});
  my $buf;
  # must include state params because server code may not run without them defined
  my $args;
  if ($$o{schema}{state_params}) {
    my @args;
    foreach my $p (@{ $$o{schema}{state_params} }) {
      my $v = $$o{q}->param($p);
      push @args, "$p=".$o->escape_uri($v) if $v;
    }
    $args = '&'.join('&', @args) if $#args > -1;
  }
  foreach my $x (@$ar) {
    my ($id, $uri, $user_title) = @$x;
    $buf .= "<tr><td><a href='$uri?OQLoadSavedSearch=$id".$args."'>".escapeHTML($user_title)."</a></td><td><button type=button class=OQDeleteSavedSearchBut data-id=$id>x</button></td></tr>";
  }
  if (! $buf) {
    $buf = "<em>none</em>";
  } else {
    $buf = "<table>".$buf."</table>";
  }
  return $buf;
}

sub activate {
  my ($o) = @_;
  $$o{schema}{tools}{loadreport} ||= {
    title => "Load Report",
    on_init => \&on_init,
    on_open => \&on_open
  };
}

1;
