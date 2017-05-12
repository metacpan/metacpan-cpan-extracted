package Amazon::MWS::Reports;

use Amazon::MWS::Routines qw(:all);

define_api_method RequestReport =>
    version => '2009-01-01',
    parameters => {
        ReportType => {
            type     => 'string',
            required => 1,
        },
        StartDate => { type => 'datetime' },
        EndDate   => { type => 'datetime' },
    },
    respond => sub {
        my $root = shift;
        convert_ReportRequestInfo($root);
        return $root;
    };

define_api_method GetReportRequestList =>
    version => '2009-01-01',
    parameters => {
        ReportRequestIdList        => { type => 'IdList' },
        ReportTypeList             => { type => 'TypeList' },
        ReportProcessingStatusList => { type => 'StatusList' },
        MaxCount                   => { type => 'nonNegativeInteger' },
        RequestedFromDate          => { type => 'datetime' },
        RequestedToDate            => { type => 'datetime' },
    },
    respond => sub {
        my $root = shift;
        convert($root, HasNext => 'boolean');
        convert_ReportRequestInfo($root);
        return $root;
    };

define_api_method GetReportRequestListByNextToken =>
    version => '2009-01-01',
    parameters => {
        NextToken => { 
            required => 1,
            type      => 'string',
        },
    },
    respond => sub {
        my $root = shift;
        convert($root, HasNext => 'boolean');
        convert_ReportRequestInfo($root);
        return $root;
    };

define_api_method GetReportRequestCount =>
    version => '2009-01-01',
    parameters => {
        ReportTypeList             => { type => 'TypeList' },
        ReportProcessingStatusList => { type => 'StatusList' },
        RequestedFromDate          => { type => 'datetime' },
        RequestedToDate            => { type => 'datetime' },
    },
    respond => sub { $_[0]->{Count} };

define_api_method CancelReportRequests =>
    version => '2009-01-01',
    parameters => {
        ReportRequestIdList        => { type => 'IdList' },
        ReportTypeList             => { type => 'TypeList' },
        ReportProcessingStatusList => { type => 'StatusList' },
        RequestedFromDate          => { type => 'datetime' },
        RequestedToDate            => { type => 'datetime' },
    },
    respond => sub {
        my $root = shift;
        convert_ReportRequestInfo($root);
        return $root;
    };

define_api_method GetReportList =>
    version => '2009-01-01',
    parameters => {
        MaxCount            => { type => 'nonNegativeInteger' },
        ReportTypeList      => { type => 'TypeList' },
        Acknowledged        => { type => 'boolean' },
        AvailableFromDate   => { type => 'datetime' },
        AvailableToDate     => { type => 'datetime' },
        ReportRequestIdList => { type => 'IdList' },
    },
    respond => sub {
        my $root = shift;
        convert($root, HasNext => 'boolean');
        convert_ReportInfo($root);
        return $root;
    };

define_api_method GetReportListByNextToken =>
    version => '2009-01-01',
    parameters => {
        NextToken => {
            type     => 'string',
            required => 1,
        },
    },
    respond => sub {
        my $root = shift;
        convert($root, HasNext => 'boolean');
        convert_ReportInfo($root);
        return $root;
    };

define_api_method GetReportCount =>
    version => '2009-01-01',
    parameters => {
        ReportTypeList      => { type => 'TypeList' },
        Acknowledged        => { type => 'boolean' },
        AvailableFromDate   => { type => 'datetime' },
        AvailableToDate     => { type => 'datetime' },
    },
    respond => sub { $_[0]->{Count} };

define_api_method GetReport =>
    version => '2009-01-01',
    raw_body   => 1,
    parameters => {
        ReportId => { 
            type     => 'nonNegativeInteger',
            required => 1,
        }
    };

define_api_method ManageReportSchedule =>
    version => '2009-01-01',
    parameters => {
        ReportType    => { type => 'string' },
        Schedule      => { type => 'string' },
        ScheduledDate => { type => 'datetime' },
    },
    respond => sub {
        my $root = shift;
        convert_ReportSchedule($root, ScheduledDate => 'datetime');
        return $root;
    };

define_api_method GetReportScheduleList =>
    version => '2009-01-01',
    parameters => {
        ReportTypeList => { type => 'ReportType' },
    },
    respond => sub {
        my $root = shift;
        convert($root, HasNext => 'boolean');
        convert_ReportSchedule($root);
        return $root;
    };

define_api_method GetReportScheduleListByNextToken =>
    version => '2009-01-01',
    parameters => {
        NextToken => {
            type     => 'string',
            required => 1,
        },
    },
    respond => sub {
        my $root = shift;
        convert($root, HasNext => 'boolean');
        convert_ReportSchedule($root);
        return $root;
    };

define_api_method GetReportScheduleCount =>
    version => '2009-01-01',
    parameters => {
        ReportTypeList => { type => 'ReportType' },
    },
    respond => sub { $_[0]->{Count} };

define_api_method UpdateReportAcknowledgements =>
    version => '2009-01-01',
    parameters => {
        ReportIdList => { 
            type     => 'IdList',
            required => 1,
        },
        Acknowledged => { type => 'boolean' },
    },
    respond => sub {
        my $root = shift;
        convert_ReportInfo($root);
        return $root;
    };

sub convert_FeedSubmissionInfo {
    my $root = shift;
    force_array($root, 'FeedSubmissionInfo');

    foreach my $info (@{ $root->{FeedSubmissionInfo} }) {
        convert($info, SubmittedDate => 'datetime');
    }
}

sub convert_ReportRequestInfo {
    my $root = shift;
    force_array($root, 'ReportRequestInfo');

    foreach my $info (@{ $root->{ReportRequestInfo} }) {
        convert($info, StartDate     => 'datetime');
        convert($info, EndDate       => 'datetime');
        convert($info, Scheduled     => 'boolean');
        convert($info, SubmittedDate => 'datetime');
    }
}

sub convert_ReportInfo {
    my $root = shift;
    force_array($root, 'ReportInfo');

    foreach my $info (@{ $root->{ReportInfo} }) {
        convert($info, AvailableDate => 'datetime');
        convert($info, Acknowledged  => 'boolean');
    }
}

sub convert_ReportSchedule {
    my $root = shift;
    force_array($root, 'ReportSchedule');

    foreach my $info (@{ $root->{ReportSchedule} }) {
        convert($info, ScheduledDate => 'datetime');
    }
}

1;
