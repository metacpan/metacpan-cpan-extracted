# Download completed FBA fulfillment report

use strict;

use Amazon::MWS::Client;

opendir(my $dir, ".");
my @requests = map { /(\d+)/ } grep { /^request\.\d+$/ && -f $_ } readdir($dir);
closedir $dir;

exit unless @requests;

my $mws = Amazon::MWS::Client->new(access_key_id=>"XXX",
                                   secret_key => "YYY",
                                   merchant_id => "ZZZ",
                                   marketplace_id => "VVV");

for my $req (@{$mws->GetReportRequestList(ReportRequestIdList => \@requests)->{ReportRequestInfo}}) {
    if ($req->{ReportProcessingStatus} eq '_DONE_' && (my $report_id = $req->{GeneratedReportId})) {
        my $report = $mws->GetReport(ReportId => $report_id);
        if (length($report)) {
            open my $file, "> report.${report_id}";
            print $file $report;
            close $file;
            unlink "request.$req->{ReportRequestId}";
        }
    }
}

