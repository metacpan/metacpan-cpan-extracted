package CGI::OptimalQuery::ExportDataTool;

use strict;

sub on_open {
  return "


<label class=ckbox><input type=checkbox class=OQExportAllResultsInd checked> all pages</label>
<p>
<strong>download as..</strong><br>
<a class=OQDownloadCSV href=#>CSV (Excel)</a>,
<a class=OQDownloadHTML href=#>HTML</a>,
<a class=OQDownloadJSON href=#>JSON</a>,
<a class=OQDownloadXML href=#>XML</a>";
}

sub activate {
  my ($o) = @_;
  $$o{schema}{tools}{export} ||= {
    title => "Export Data",
    on_open => \&on_open
  };
}

1;
