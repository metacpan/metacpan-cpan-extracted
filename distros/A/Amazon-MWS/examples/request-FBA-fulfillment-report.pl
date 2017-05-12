# Initiate FBA fulfillment report generation

use strict;

use Amazon::MWS::Client;
use DateTime;

my $mws = Amazon::MWS::Client->new(access_key_id=>"XXX",
                                   secret_key => "YYY",
                                   merchant_id => "ZZZ",
                                   marketplace_id => "VVV");

my $req = $mws->RequestReport(ReportType => '_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_',
                              StartDate => DateTime->now->add(weeks => -1),
                              EndDate => DateTime->now);

if (my $req_id = $req->{ReportRequestInfo}->[0]->{ReportRequestId}) {
    open my $req, "> request.${req_id}";
    close $req;
}

