package CGI::OptimalQuery::SaveSearchTool;

use strict;
use POSIX qw/strftime/;
use Data::Dumper;
use Mail::Sendmail();
use CGI qw( escapeHTML );
use JSON::XS;

# save a reference to the current saved save that is running via crontab right now
our $current_saved_search;

# this is called from Base constructor
sub on_init {
  my ($o) = @_;

  # adjust config if a saved search alert is running via cron right now
  # unable to set these earlier because we dont have a constructed OQ yet
  $$o{schema}{savedSearchAlertMaxRecs} ||= 1000;
  $$o{schema}{savedSearchAlertEmailCharLimit} ||= 500000;

  # one more to detect overflow
  $$o{q}->param('rows_page', $$o{schema}{savedSearchAlertMaxRecs} + 1) if $current_saved_search;

  # request to save a search?
  if ($$o{q}->param('OQsaveSearchTitle') ne '') {

    eval {
      # serialize params
      my $params;
      { my %data;
        foreach my $p (qw( show filter sort rows_page queryDescr hiddenFilter )) {
          $data{$p} = $$o{q}->param($p);
        }
        delete $data{rows_page} unless $data{rows_page} eq 'All' || $data{rows_page} > 25;
        if (ref($$o{schema}{state_params}) eq 'ARRAY') {
          foreach my $p (@{ $$o{schema}{state_params} }) {
            my @v = $$o{q}->param($p);
            $data{$p} = \@v;
          }
        }
  
        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Quotekeys = 0;
        local $Data::Dumper::Pair = '=>';
        local $Data::Dumper::Sortkeys = 1;
        $params = Dumper(\%data);
        $params =~ s/^[^\{]+\{//;
        $params =~ s/\}\;\s*$//;
      }
  
      $$o{q}->param('queryDescr', $$o{q}->param('OQsaveSearchTitle'));
  
      my %rec = (
        user_id => $$o{schema}{savedSearchUserID},
        uri => $$o{schema}{URI},
        oq_title => $$o{schema}{title},
        user_title => $$o{q}->param('OQsaveSearchTitle'),
        params => $params
      );
      
      # does the user want to set this as the default search, and if so do they have permission
      if($$o{schema}{canSaveDefaultSearches} && defined $$o{q}->param('save_search_default')) {
        $rec{is_default} = $$o{q}->param('save_search_default') || 0;
      }

      # is saved search alerts enabled
      if ($$o{schema}{savedSearchAlerts}) {
        $rec{alert_mask} = $$o{q}->param('alert_mask') || 0;
      }

      # if user enabled search search alerts
      if ($rec{alert_mask}) {
        $rec{alert_interval_min} = $$o{q}->param('alert_interval_min');
        $rec{alert_dow} = $$o{q}->param('alert_dow');
        $rec{alert_start_hour} = $$o{q}->param('alert_start_hour');
        $rec{alert_end_hour} = $$o{q}->param('alert_end_hour');
        $rec{alert_last_dt} = [get_sysdate_sql($$o{dbh})];
  
        # get starting alert_uids
        my @uids;
        my $sth = $$o{oq}->prepare(
          show   => ['UID'],
          filter => scalar($$o{q}->param('filter')),
          forceFilter => $$o{schema}{forceFilter},
          hiddenFilter => scalar($$o{q}->param('hiddenFilter'))
        );

        $sth->execute(limit => [1, $$o{schema}{savedSearchAlertMaxRecs} + 1]);
        while (my $h = $sth->fetchrow_hashref()) {
          push @uids, $$h{U_ID};
        }
        die "MAX_ROWS_EXCEEDED - your report contains too many rows to send alerts via email. Reduce the total row count of your report by adding additional filters." if scalar(@uids) > $$o{schema}{savedSearchAlertMaxRecs};
        $rec{alert_uids} = join('~', @uids);
      }
  
      # save saved search to db
      my $is_update=0;
      if ($$o{q}->param('OQss') ne '') {
        my $id = scalar($$o{q}->param('OQss'));
        ($is_update) = $$o{dbh}->selectrow_array("SELECT 1 FROM oq_saved_search WHERE id=? AND user_id=?", undef, $id, $rec{user_id});
        if ($is_update) {
          my (@cols,@binds);
          while (my ($col,$val) = each %rec) {
            if (ref($val) eq 'ARRAY') {
              my ($sql,@rest) = @$val;
              push @cols, "$col=$sql";
              push @binds, map { $_ eq '' ? undef : $_ } @rest;
            } else {
              push @cols, "$col=?";
              push @binds, ($val eq '') ? undef : $val;
            }
          }
          push @binds, $id;
          $$o{dbh}->do("UPDATE oq_saved_search SET ".join(',', @cols)." WHERE id=?", undef, @binds);
          $rec{id} = $id;
        }
      }
      if (! $is_update) {
        ($rec{id}) = $$o{dbh}->selectrow_array("SELECT s_oq_saved_search.nextval FROM dual") if $$o{dbh}{Driver}{Name} eq 'Oracle';
        my (@cols,@vals,@binds);
        while (my ($col,$val) = each %rec) {
          push @cols, $col;
          if (ref($val) eq 'ARRAY') {
            my ($sql,@rest) = @$val;
            push @vals, $sql;
            push @binds, map { $_ eq '' ? undef : $_ } @rest;
          } else {
            push @vals, '?';
            push @binds, ($val eq '') ? undef : $val;
          }
        }
        $$o{dbh}->do("INSERT INTO oq_saved_search (".join(',',@cols).") VALUES (".join(',',@vals).")", undef, @binds);
        $rec{id} ||= $$o{dbh}->last_insert_id("","","","");
      }
      
      # ensure only one possible default saved search
      eval {
        if($$o{schema}{canSaveDefaultSearches} && $rec{is_default}) {
          my $stmt = $$o{dbh}->prepare('UPDATE oq_saved_search SET is_default = 0 WHERE id <> ? AND uri = ?');
          $stmt->execute($rec{id}, $rec{uri});
        }
      }; if($@) {}
      
      $$o{output_handler}->(CGI::header('application/json').encode_json({ status => "ok", msg => "search saved successfully", id => $rec{id} }));
    }; if ($@) {
      my $err = $@;
      $err =~ s/\ at\ .*//;

      if ($err =~ /unique\ constraint/i ||
          $err =~ /duplicate\ entry/i   ||
          $err =~ /unique\_violation/i  ||
          $err =~ /unique\ key/i        ||
          $err =~ /duplicate\ key/i     ||
          $err =~ /constraint\_unique/i) {
        $err = 'Another record with this name already exists.';
      }

      $$o{output_handler}->(CGI::header('application/json').encode_json({ status => "error", msg => $err }));
    }
    return undef;
  }
}


sub on_open {
  my ($o) = @_;
  my $buf;

  # if saved search alerts are enabled
  if ($$o{schema}{savedSearchAlerts}) {
    my $rec;
    if ($$o{q}->param('OQss') ne '') {
      $rec = $$o{dbh}->selectrow_hashref("SELECT USER_TITLE,ALERT_MASK,ALERT_INTERVAL_MIN,ALERT_DOW,ALERT_START_HOUR,ALERT_END_HOUR FROM oq_saved_search WHERE id=? AND user_id=?", undef, scalar($$o{q}->param('OQss')), $$o{schema}{savedSearchUserID});
    }
    $rec ||= {};
    my $alerts_enabled = ($$rec{ALERT_MASK} > 0) ? 1 : 0;
    $$rec{ALERT_MASK} ||= 1;
    $$rec{ALERT_INTERVAL_MIN} ||= 1440;
    $$rec{ALERT_DOW} ||= '12345';
    $$rec{ALERT_START_HOUR} ||= 8;
    $$rec{ALERT_END_HOUR} ||= 17;

    if ($$rec{ALERT_START_HOUR} > 12) {
      $$rec{ALERT_START_HOUR} = ($$rec{ALERT_START_HOUR} - 12).'PM';
    } else {
      $$rec{ALERT_START_HOUR} .= 'AM';
    }
    if ($$rec{ALERT_END_HOUR} > 12) {
      $$rec{ALERT_END_HOUR} = ($$rec{ALERT_END_HOUR} - 12).'PM';
    } else {
      $$rec{ALERT_END_HOUR} .= 'AM';
    }

    $buf .= "
<label>name <input type=text id=OQsaveSearchTitle value='".$o->escape_html($$rec{USER_TITLE})."'></label>
<fieldset id=OQSaveReportEmailAlertOpts".($alerts_enabled?' class=opened':'').">
  <legend><label class=ckbox style='width:12em;text-align:left;'><input type=checkbox id=OQalertenabled".($alerts_enabled?' checked':'')."> send email alert</label></legend>

  <p>
  <label>when records are:</label>
  <label><input type=checkbox name=OQalert_mask value=1".(($$rec{ALERT_MASK} & 1)?' checked':'')."> added</label>
  <label><input type=checkbox name=OQalert_mask value=2".(($$rec{ALERT_MASK} & 2)?' checked':'')."> removed</label>
  <label><input type=checkbox name=OQalert_mask value=4".(($$rec{ALERT_MASK} & 4)?' checked':'')."> present</label>
    
  <p>
  <label>check every: <input type=text id=OQalert_interval_min size=4 maxlength=6 value='".$o->escape_html($$rec{ALERT_INTERVAL_MIN})."'> minutes</label>
  <small>(1440 min per day)</small>

  <p>
  <label title='Specify which days to send the alert.'>on days:</label>
  <label class=ckbox title=Sunday><input type=checkbox class=OQalert_dow value=0".   ($$rec{ALERT_DOW}=~/0/?' checked':'').">S</label>
  <label class=ckbox title=Monday><input type=checkbox class=OQalert_dow value=1".   ($$rec{ALERT_DOW}=~/1/?' checked':'').">M</label>
  <label class=ckbox title=Tuesday><input type=checkbox class=OQalert_dow value=2".  ($$rec{ALERT_DOW}=~/2/?' checked':'').">T</label>
  <label class=ckbox title=Wednesday><input type=checkbox class=OQalert_dow value=3".($$rec{ALERT_DOW}=~/3/?' checked':'').">W</label>
  <label class=ckbox title=Thursday><input type=checkbox class=OQalert_dow value=4". ($$rec{ALERT_DOW}=~/4/?' checked':'').">T</label>
  <label class=ckbox title=Friday><input type=checkbox class=OQalert_dow value=5".   ($$rec{ALERT_DOW}=~/5/?' checked':'').">F</label>
  <label class=ckbox title=Saturday><input type=checkbox class=OQalert_dow value=6". ($$rec{ALERT_DOW}=~/6/?' checked':'').">S</label>

  <p>
  <label title='Specify start hour to sent an alert.'>from: <input type=text value='".$o->escape_html($$rec{ALERT_START_HOUR})."' size=4 maxlength=4 id=OQalert_start_hour placeholder=8AM></label> <label>to: <input type=text value='".$o->escape_html($$rec{ALERT_END_HOUR})."' size=4 maxlength=4 id=OQalert_end_hour placeholder=5PM></label>
  <p><strong>Notice:</strong> This tool sends automatic alerts over insecure email. By creating an alert you acknowledge that the fields in the report will never contain sensitive data. Alerts are automatically disabled when the count exceeds $$o{schema}{savedSearchAlertMaxRecs}.</strong>
</fieldset>";
  }
  else {
    my $rec;
    if ($$o{q}->param('OQss') ne '') {
      $rec = $$o{dbh}->selectrow_hashref("SELECT USER_TITLE FROM oq_saved_search WHERE id=? AND user_id=?", undef, scalar($$o{q}->param('OQss')), $$o{schema}{savedSearchUserID});
    }
    $rec ||= {};
    $buf .= "
<label>name <input type=text id=OQsaveSearchTitle value='".$o->escape_html($$rec{USER_TITLE})."'></label>";
  }

  # include checkbox to allow user to set saved search as the default settings
  if($$o{schema}{canSaveDefaultSearches}) {
    my ($is_default_ss) = $$o{dbh}->selectrow_array("SELECT is_default FROM oq_saved_search WHERE id=? AND user_id=?", undef, scalar($$o{q}->param('OQss')), $$o{schema}{savedSearchUserID});
    $buf .= "<label class=ckbox style='margin-left:17px;width:12em;text-align:left;'><input title='Set the filter, sort, and shown columns in this reports as the system default for all users' type=checkbox value=1 id=OQsave_search_default".($is_default_ss ? ' checked' : '').">set as system default</label>";
  }

  $buf .= "<p>";
  $buf .= "<button type=button class=OQSaveNewReportBut>save as new</button>" if $$o{q}->param('OQss') ne '';
  $buf .= "<button type=button class=OQSaveReportBut>save</button>";
  
  return $buf;
}

sub activate {
  my ($o) = @_;
  $$o{schema}{tools}{savereport} ||= {
    title => "Save Report",
    on_init => \&on_init,
    on_open => \&on_open
  };
}


# this function is called from a cron to help execute saved searches that have alerts that need to be checked
# Note: this custom output handler does not print anything as normal output handlers do.
# This output handler insteads updates the $current_saved_search
# it discovers which uids have been added, deleted, or are still present for a saved search.
# this information is then used by the [arent caller (execute_saved_search_alerts) to send out alert emails
sub custom_output_handler {
  my ($o) = @_;
  # verify that a proper email_to was defined
  die "missing email_to" if $$current_saved_search{email_to} eq '';

  my %opts;
  if (exists $$o{schema}{options}{__PACKAGE__}) {
    %opts = %{$$o{schema}{options}{__PACKAGE__}};
  } elsif (exists $$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}) {
    %opts = %{$$o{schema}{options}{'CGI::OptimalQuery::InteractiveQuery'}};
  }
  my %noEsc = map { $_ => 1 } @{ $opts{noEscapeCol} };


  # fetch all records in the report
  # update the uids hash
  # $$current_saved_search{uids}{<U_ID>} => 1-deleted, 2-seen before, 3-first time seen
  # Before this block all values for previously seen uids are 1
  # if the uid was previously seen and then seen again, we'll mark it with a 2
  # if it was not previously seen, and we see it now, we'll mark it with a 3
  # at the end of processing all previously found uids that weren't seen will still be marked 1
  # which indicates the record is no longer within the report
  my $cnt = 0;
  my $dataTruc = 0;
  my $row_cnt = 0;
  my $buf;
  { my $filter = $o->get_filter();
    $buf .= "<p><strong>Query: </strong>"
      .escapeHTML($$o{queryDescr}) if $$o{queryDescr};
    $buf .= "<p><strong>Filter: </strong>"
      .escapeHTML($filter) if $filter;
    $buf .= "<p><table class=OQdata><thead><tr><td></td>";
    foreach my $colAlias (@{ $o->get_usersel_cols }) {
      my $colOpts = $$o{schema}{select}{$colAlias}[3];
      $buf .= "<td>".escapeHTML($o->get_nice_name($colAlias))."</td>";
    }
    $buf .= "</tr></thead><tbody>";
  }

  # remember state param vals that were used so we can provide a link to view the live data
  if ($$o{schema}{state_params}) {
    my $args;
    foreach my $p (@{ $$o{schema}{state_params} }) {
      my $v = $$o{q}->param($p);
      $args .= '&'.$p.'='.$o->escape_uri($v) if $v;
    }
    $$current_saved_search{state_param_args} = $args;
  }

  while (my $rec = $o->sth->fetchrow_hashref()) {
    die "MAX_ROWS_EXCEEDED - your report contains too many rows to send alerts via email. Reduce the total row count of your report by adding additional filters." if ++$cnt > $$o{schema}{savedSearchAlertMaxRecs};
    $opts{mutateRecord}->($rec) if ref($opts{mutateRecord}) eq 'CODE';

    # if this record has been seen before, mark it with a '2'
    if (exists $$current_saved_search{uids}{$$rec{U_ID}}) {
      $$current_saved_search{uids}{$$rec{U_ID}}=2; 
    }

    # if this record hasn't been seen before, mark it with a '3'
    else {
      $$current_saved_search{uids}{$$rec{U_ID}}=3; 
    }

    # if we need to output report
    if (! $dataTruc && (
             # output if when rows are present is checked
             ($$current_saved_search{ALERT_MASK} & 4)
             # output if when rows are added is checked AND this is a new row not seen before
          || ($$current_saved_search{ALERT_MASK} & 1 && $$current_saved_search{uids}{$$rec{U_ID}}==3))) {

      $row_cnt++;

      # get open record link
      my $link;
      if (ref($opts{OQdataLCol}) eq 'CODE') {
        $link = $opts{OQdataLCol}->($rec);
        if ($link =~ /href\s*\=\s*\"?\'?([^\s\'\"\>]+)/i) {
          $link = $1; 
        }
      } elsif (ref($opts{buildEditLink}) eq 'CODE') {
        $link = $opts{buildEditLink}->($o, $rec, \%opts);
      } elsif ($opts{editLink} ne '' && $$rec{U_ID} ne '') {
        $link = $opts{editLink}.(($opts{editLink} =~ /\?/)?'&':'?')."act=load&id=$$rec{U_ID}";
      }
      $buf .= "<tr";

      # if this record is first time visible
      $buf .= " class=ftv" if $$current_saved_search{uids}{$$rec{U_ID}}==3;
      $buf .= "><td>";
      if ($link) {
        if ($link !~ /^https?\:\/\//i) {
          $link .= '/'.$link unless $link =~ /^\//;
          $link = $$current_saved_search{opts}{base_url}.$link;
        }
        $buf .= "<a href='".escapeHTML($link)."'>open</a>";
      }
      $buf .= "</td>";
      foreach my $col (@{ $o->get_usersel_cols }) {
        my $val;
        if (exists $noEsc{$col}) {
          if (ref($$rec{$col}) eq 'ARRAY') {
            $val = join(' ', @{ $$rec{$col} });  
          } else {
            $val = $$rec{$col};
          }
        } elsif (ref($$rec{$col}) eq 'ARRAY') {
          $val = join(', ', map { escapeHTML($_) } @{ $$rec{$col} }); 
        } else {
          $val = escapeHTML($$rec{$col});
        }
        $buf .= "<td>$val</td>";
      }
      $buf .= "</tr>\n";

      $dataTruc = 1 if length($buf) > $$o{schema}{savedSearchAlertEmailCharLimit};
    }
  }
  $o->sth->finish();

  # if we found rows, encase it in a table with thead
  if ($row_cnt > 0) {
    $buf .= "</tbody></table>";
    $buf .= "<p><strong>This report does not show all data found because the report exceeds the maximum limit. Reduce report size by hiding columns, adding additional filters, or only showing new records.</strong>" if $dataTruc;
    $$current_saved_search{buf} = $buf;
  }


  return undef;
}


sub sendmail_handler {
  my %email = @_;
  $email{from} ||= ($ENV{USER}||'root').'@'.($ENV{HOSTNAME}||'localhost');
  return Mail::Sendmail::sendmail(%email);
}

sub get_sysdate_sql {
  my ($dbh) = @_;
  my $now;
  if ($$dbh{Driver}{Name} eq 'Oracle') {
    $now = 'SYSDATE';
  } elsif ($$dbh{Driver}{Name} eq 'SQLite') {
    $now = 'DATETIME()';
  } elsif ($$dbh{Driver}{Name} eq 'mysql') {
    $now = 'NOW()';
  } elsif ($$dbh{Driver}{Name} eq 'Pg' || $$dbh{Driver}{Name} eq 'Microsoft SQL Server') {
    $now = 'CURRENT_TIMESTAMP';
  } else {
    die "Driver: $$dbh{Driver}{Name} not yet supported. Please add support for this database";
  }
  return $now;
}


sub execute_saved_search_alerts {
  my %opts = @_;
  my $sendmail_handler = $opts{sendmail_handler} ||= \&sendmail_handler;

  if ($opts{base_url} =~ /^(https?\:\/\/[^\/]+)(.*)/i) {
    $opts{server_url} = $1;
    $opts{path_prefix} = $2;
  } else {
    die "invalid option base_url";
  }
  die "missing option handler" unless ref($opts{handler}) eq 'CODE';
  my $dbh = $opts{dbh} or die "missing dbh";
  
  $opts{error_handler} ||= sub {
    my ($type, @msg) = @_;
    my $dt = strftime "%F %T", localtime $^T;
    my $msg = join(' ', $dt, lc($type), @msg)."\n";
    if ($type =~ /^(err|debug)$/i) {
      print STDERR $msg;
    } else {
      print $msg;
    }
  };

  $opts{error_handler}->("info", "execute_saved_search_alerts started");

  local $CGI::OptimalQuery::CustomOutput::custom_output_handler = \&custom_output_handler;

  my @dt = localtime;
  my $dow = $dt[6];
  my $hour = $dt[2];

  if ($$dbh{Driver}{Name} eq 'Oracle') {
    $$dbh{LongReadLen} = 900000;
    my ($readLen) = $dbh->selectrow_array("
      SELECT GREATEST(
        dbms_lob.getlength(params),
        dbms_lob.getlength(alert_uids)
      )
      FROM oq_saved_search");
    $$dbh{LongReadLen} = $readLen if $readLen > $$dbh{LongReadLen};
  }

  # find all saved searches that need to be checked
  my @recs;
  { local $$dbh{FetchHashKeyName} = 'NAME_uc';
    my @binds = ('%'.$dow.'%', $hour);
    my $sql = "
SELECT *
FROM oq_saved_search
WHERE alert_dow LIKE ?
AND alert_mask > 0
AND ? BETWEEN alert_start_hour AND alert_end_hour";

    # only select if interval has been exceeded
    if ($$dbh{Driver}{Name} eq 'Oracle') {
      $sql .= "\nAND ((SYSDATE - alert_last_dt) * 24 * 60) > alert_interval_min";
    }
    elsif ($$dbh{Driver}{Name} eq 'SQLite') {
      $sql .= "\nAND (strftime('%s','now') - strftime('%s',COALESCE(alert_last_dt,'2000-01-01'))) > alert_interval_min";
    }
    elsif ($$dbh{Driver}{Name} eq 'mysql') {
      $sql .= "\nAND alert_last_dt <= DATE_SUB(NOW(), INTERVAL alert_interval_min MINUTE)";
    }
    elsif ($$dbh{Driver}{Name} eq 'Pg') {
      $sql .= "\nAND ((CURRENT_TIMESTAMP - alert_last_dt) * 24 * 60) > alert_interval_min";
    }
    elsif ($$dbh{Driver}{Name} eq 'Microsoft SQL Server') {
      $sql .= "\nAND DATEADD(minute, alert_interval_min, alert_last_dt) < CURRENT_TIMESTAMP";
    }
    else {
      die "Driver: $$dbh{Driver}{Name} not yet supported. Please add support for this database";
    }
    $sql .= "\nORDER BY id";
    my $sth = $dbh->prepare($sql);
    
    $opts{error_handler}->("debug", "search for saved searches that need checked. BINDS: ".join(',', @binds)) if $opts{debug};
    $sth->execute(@binds);
    while (my $h = $sth->fetchrow_hashref()) { push @recs, $h; }
  }

  $opts{error_handler}->("debug", "found ".scalar(@recs)." saved searches to execute") if $opts{debug};

  # for each saved search that has alerts which need to be checked
  local $current_saved_search = undef;
  while ($#recs > -1) {
    my $rec = pop @recs;

    $current_saved_search = $rec;
    my %uids = map { $_ => 1 } split /\~/, $$rec{ALERT_UIDS};
    $$rec{opts} = \%opts;
    $$rec{uids} = \%uids; # contains all the previously seen uids
    $$rec{buf} = ''; # will be populated with a table containing report rows for a simple HTML email
    $$rec{err_msg} = '';
    $opts{error_handler}->("info", "executing saved search: $$rec{ID}");

    # configure CGI environment
    # construct a query string
    local $ENV{QUERY_STRING};
    { my $p = eval '{'.$$rec{PARAMS}.'}'; 
      $p = {} unless ref($p) eq 'HASH';
      $$p{module} = 'CustomOutput'; # this will call our custom_output_handler function
      $$p{page} = 1;
      my @args;
      while (my ($k,$v) = each %$p) {
        if (ref($v) eq 'ARRAY') {
          foreach my $v2 (@$v) {
            push @args, "$k=".CGI::escape($v2);
          }
        } else {
          push @args, "$k=".CGI::escape($v);
        }
      }
      $ENV{QUERY_STRING} = join('&', @args);
    }
    local $ENV{REQUEST_METHOD} ||= 'GET';
    local $ENV{REMOTE_ADDR} ||= '127.0.0.1';
    local $ENV{SCRIPT_URL} = $$rec{URI};

    local $ENV{REQUEST_URI} = $$rec{URI};
    $ENV{REQUEST_URI} .= '?'.$ENV{QUERY_STRING} if $ENV{QUERY_STRING};

    local $ENV{HTTP_HOST} ||= ($opts{base_url} =~ /https?\:\/\/([^\/]+)/) ? $1 : 'localhost';
    local $ENV{SERVER_NAME} ||= $ENV{HTTP_HOST};
    local $ENV{SCRIPT_URI} = $opts{base_url}.$ENV{REQUEST_URI};

    # The CGI library has some globals that need to be reset otherwise the previous params stick around
    CGI::initialize_globals();

    # call app specific request bootstrap handler
    # which will execute a CGI::OptimalQuery object somehow
    # and populate $$rec{buf}, $$rec{uids}, $$rec{err_msg}
    eval {
      $opts{handler}->($rec);
      die "email_to not defined" if $$rec{email_to} eq ''; 
      $opts{error_handler}->("debug", "after OQ execution uids: ".Dumper(\%uids)) if $opts{debug};
    };
    if ($@) {
      $$rec{err_msg} = $@;
      $$rec{err_msg} =~ s/\ at\ .*//;
    }

    my @update_uids;
    # if there was an error processing saved search, send user an email
    if ($$rec{err_msg}) {
      $opts{error_handler}->("err", "Error: $@\n\nsaved search:\n".Dumper($rec)."\n\nENV:\n".Dumper(\%ENV)."\n\n");
      if ($$rec{email_to}) {
        my %email = (
          to => $$rec{email_to},
          from => $$rec{email_from} || $opts{email_from},
          'Reply-To' => $$rec{'email_Reply-To'} || $opts{'email_Reply-To'},
          subject => "Problem with email alert: $$rec{OQ_TITLE} - $$rec{USER_TITLE}",
          body => "Your saved search alert encountered the following error:

$$rec{err_msg}

load report:
".$opts{base_url}.$$rec{URI}.'?OQLoadSavedSearch='.$$rec{ID}.$$rec{state_param_args}."

Please contact your administrator if you are unable to fix the problem."
        );

        if ($opts{debug}) {
          $opts{error_handler}->("debug", "debug sendmail (not sent): ".Dumper(\%email));
        } else {
          $opts{error_handler}->("info", "sending email to: $email{to}; subject: $email{subject}");
          $sendmail_handler->(%email) or die "could not send email to: $$rec{email_to}";
        }
      }
    }

    else {
      my $total_new = 0;
      my $total_deleted = 0;
      my $total_count = 0;
      while (my ($uid, $status) = each %uids) {
        if ($status == 1) {
          $total_deleted++;
        }
        else {
          push @update_uids, $uid;
          $total_count++;
          if ($status == 3) {
            $total_new++;
          }
        }
      }
      $opts{error_handler}->("info", "total_new: $total_new; total_deleted: $total_deleted; total_count: $total_count");

      my $should_send_email = 1 if
        ( # alert when records are added
          ($$rec{ALERT_MASK} & 1 && $total_new > 0) ||
          # alert when records are deleted
          ($$rec{ALERT_MASK} & 2 && $total_deleted > 0) ||
          # alert when records are present
          ($$rec{ALERT_MASK} & 4 && $total_count > 0)
        );

      if ($should_send_email) {
        my %email = (
          to => $$rec{email_to},
          from => $$rec{email_from} || $opts{email_from},
          'Reply-To' => $$rec{'email_Reply-To'} || $opts{'email_Reply-To'},
          subject => "$$rec{OQ_TITLE} - $$rec{USER_TITLE}",
          'content-type' => 'text/html; charset="iso-8859-1"'
        );
        $email{subject} .= " ($total_new added)" if $total_new > 0; 

        $email{body} = 
"<html>
<head>
<title>".escapeHTML("$$rec{OQ_TITLE} - $$rec{USER_TITLE}")."</title>
<style>
.OQSSAlert * {
  font-family: sans-serif;
}
.OQSSAlert h2 {
  margin: 0;
  font-size: 14px;
}
.OQSSAlert table {
  border-collapse: collapse;
}
.OQSSAlert thead td {
  font-weight: bold;
  color: white;
  background-color: #999;
}
.OQSSAlert td {
  padding: 4px;
  border: 1px solid #aaa;
  font-size: 11px;
}
.OQSSAlert .ftv {
  background-color: #E2FFE2;
}
.OQSSAlert p {
  margin: .5em 0;
}
.OQSSAlert .ib {
  display: inline-block;
  margin-left: 6px;
  padding: 6px;
}
</style>
</head>
<body>
<div class=OQSSAlert>
<h2>".escapeHTML("$$rec{OQ_TITLE} - $$rec{USER_TITLE}")."</h2>
<p>
$$rec{buf}
<p>
<span class=ib>total: $total_count</span>
<span class='ftv ib'>added: $total_new</span>
<span class=ib>removed: $total_deleted</span>
<p>
<a href='".escapeHTML($opts{base_url}.$$rec{URI}.'?OQLoadSavedSearch='.$$rec{ID}.$$rec{state_param_args})."'>load report</a>
</div>
</body>
</html>";

        if ($opts{debug}) {
          $opts{error_handler}->("debug", "debug sendmail (not sent): ".Dumper(\%email));
        } else {
          $opts{error_handler}->("info", "sending email to: $email{to}; subject: $email{subject}");
          $sendmail_handler->(%email) or die "could not send email to: $$rec{email_to}";
        }
      }
    }

    # update database
    my $update_uids = join('~', sort @update_uids);
    $update_uids = undef if $update_uids eq '';
    $$rec{err_msg} = undef if $$rec{err_msg} eq '';
    my @binds = ($$rec{err_msg});
    my $now = get_sysdate_sql($dbh);

    my $sql = "UPDATE oq_saved_search SET alert_last_dt=$now, alert_err=?";
    if ($update_uids ne $$rec{ALERT_UIDS}) {
      $sql .= ", alert_uids=?";
      push @binds, $update_uids;
    }
    $sql .= " WHERE id=?";
    push @binds, $$rec{ID};
    $opts{error_handler}->("debug", "SQL: $sql\nBINDS: ".join(',', @binds)) if $opts{debug};
    my $sth = $dbh->prepare_cached($sql);
    $sth->execute(@binds);

    $current_saved_search = undef;
  }

  $opts{error_handler}->("info", "execute_saved_search_alerts done");
}


# helper function to execute a script. called from with execute_saved_search_alerts from perl script
my %COMPILED_FUNCS;
sub execute_script {
  my ($fn) = @_;
  if (! exists $COMPILED_FUNCS{$fn}) {
    open my $fh, "<", $fn or die "can't read file $fn; $!";
    local $/=undef;
    my $code = 'sub { '.scalar(<$fh>). ' }';
    $COMPILED_FUNCS{$fn} = eval $code;
    die "could not compile $fn; $@" if $@;
  }
  $COMPILED_FUNCS{$fn}->();
  return undef;
}

sub execute_handler {
  my ($pack, $func) = @_;
  $func ||= 'handler';
  my $rv = eval "require $pack";
  die "NOT_FOUND - $@" if $@ =~ /Can\'t locate/;
  die "COMPILE_ERROR - $@" if $@;
  die "COMPILE_ERROR - module must end with true value" unless $rv == 1;
  my $codeRef = $pack->can($func);
  die "MISSING_HANDLER - could not find ".$pack.'::'.$func unless $codeRef;
  return $codeRef->();
}
1;
