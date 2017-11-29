package CGI::OptimalQuery::SavedSearches;

use strict;
use warnings;
no warnings qw( uninitialized redefine );
use CGI::OptimalQuery::Base();

sub escapeHTML { CGI::OptimalQuery::Base::escapeHTML(@_) }

sub get_html {
  my ($q,$dbh,$userid) = @_;

  my $oracleReadLen;
  if ($$dbh{Driver}{Name} eq 'Oracle') {
    ($oracleReadLen) = $dbh->selectrow_array("SELECT max(dbms_lob.getlength(params)) FROM oq_saved_search WHERE user_id=?", undef, $userid);
  }
  local $dbh->{LongReadLen} = $oracleReadLen
    if $oracleReadLen && $oracleReadLen > $dbh->{LongReadLen};

  local $$dbh{FetchHashKeyName} = 'NAME_uc';

  my $sth = $dbh->prepare(
    "SELECT *
     FROM oq_saved_search
     WHERE user_id=?
     ORDER BY oq_title, user_title");

  $sth->execute($userid);
  my $last_oq_title = '';
  my $buf = '';
  while (my $h = $sth->fetchrow_hashref()) {
    next if $$h{IS_DEFAULT};

    my $state_params='';
    if ($$h{PARAMS}) {
      my $params = eval '{'.$$h{PARAMS}.'}';
      foreach my $k (keys %$params) {
        next if $k =~ /^(module|show|rows_page|page|hiddenFilter|filter|queryDescr|sort)$/;
        my $v = $$params{$k};
        if (ref($v) eq 'ARRAY') {
          $state_params .= '&'.$k.'='.$_ for @$v;
        } else {
          $state_params .= '&'.$k.'='.$v;
        }
      }
    }

    if ($last_oq_title ne $$h{OQ_TITLE}) {
      $buf .= '</ul>' if $last_oq_title;
      $last_oq_title = $$h{OQ_TITLE};
      $buf .= "<h4>".escapeHTML($$h{OQ_TITLE})."</h4><ul>";
    }
    $buf .= "<li>
<a href='".escapeHTML("$$h{URI}?OQLoadSavedSearch=$$h{ID}".$state_params)."' title='load saved search' class='opwin oqssload'>".escapeHTML($$h{USER_TITLE})."</a>
<button type=button title='delete saved search' class=oqssdelete data-url='".escapeHTML("$$h{URI}?OQDeleteSavedSearch=$$h{ID}".$state_params)."'>&#10005;</button>
</li>";
  }
  $buf .= '</ul>' if $last_oq_title;

  if ($buf) {
    $buf = '<div id=loadsavedsearches>'.$buf.'</div>
<script>
$("#loadsavedsearches").on("click", ".oqssdelete", function(){
  var $t = $(this);
  var $li = $t.closest("li");
  $.ajax({
    type: "get",
    url: $t.attr("data-url"),
    success: function() {
      if ($li.siblings().length==0) {
        var $ul = $li.parent();
        $ul.add($ul.prev("h4")).remove();
      }
      else {
        $li.remove();
      }
    }
  });
  return false;
});
</script>';
  }
  return $buf;
}
1;
