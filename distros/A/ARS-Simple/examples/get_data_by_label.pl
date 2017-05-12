use strict;
use warnings FATAL => 'all';
use ARS::Simple;
use Data::Dumper;

# Dump detail of all User form records

my $ars = ARS::Simple->new({
        server   => 'dev_machine',
        user     => 'greg',
        password => 'password',
        });

%fid = (
        'CreateDate'               => 3,            # System RO type=AR_DATA_TYPE_TIME
        'LastModifiedBy'           => 5,            # System RO type=AR_DATA_TYPE_CHAR 254
        'ModifiedDate'             => 6,            # System RO type=AR_DATA_TYPE_TIME
        'RequestID'                => 1,            # System RO type=AR_DATA_TYPE_CHAR 15
        'Creator'                  => 2,            # Required  type=AR_DATA_TYPE_CHAR 254
        'FullName'                 => 8,            # Required  type=AR_DATA_TYPE_CHAR 254
        'FullTextLicenseType'      => 110,          # Required  type=AR_DATA_TYPE_ENUM
        'LicenseType'              => 109,          # Required  type=AR_DATA_TYPE_ENUM
        'LoginName'                => 101,          # Required  type=AR_DATA_TYPE_CHAR 254
        'Status'                   => 7,            # Required  type=AR_DATA_TYPE_ENUM
        'ApplicationLicense'       => 122,          # Optional  type=AR_DATA_TYPE_CHAR 0
        'ApplicationLicenseType'   => 115,          # Optional  type=AR_DATA_TYPE_CHAR 254
        'AssignedTo'               => 4,            # Optional  type=AR_DATA_TYPE_CHAR 254
        'ComputedGrpList'          => 119,          # Optional  type=AR_DATA_TYPE_CHAR 255
        'DefaultNotifyMechanism'   => 108,          # Optional  type=AR_DATA_TYPE_ENUM
        'EmailAddress'             => 103,          # Optional  type=AR_DATA_TYPE_CHAR 255
        'FlashboardsLicenseType'   => 111,          # Optional  type=AR_DATA_TYPE_ENUM
        'FromConfig'               => 250000003,    # Optional  type=AR_DATA_TYPE_CHAR 3
        'GroupList'                => 104,          # Optional  type=AR_DATA_TYPE_CHAR 255
        'UniqueIdentifier'         => 179,          # Optional  type=AR_DATA_TYPE_CHAR 38
        'AssetLicenseUsed'         => 220000002,    # *Unknown* type=AR_DATA_TYPE_INTEGER
        'ChangeLicenseUsed'        => 220000003,    # *Unknown* type=AR_DATA_TYPE_INTEGER
        'HelpDeskLicenseUsed'      => 220000004,    # *Unknown* type=AR_DATA_TYPE_INTEGER
        'NumberofLicenseAvailable' => 220000000,    # *Unknown* type=AR_DATA_TYPE_INTEGER
        'SLALicenseUsed'           => 220000001,    # *Unknown* type=AR_DATA_TYPE_INTEGER
        );

my $data = $ars->get_data_by_label({
        form        => 'User',
        query       => '1=1',
        lfid        => \%fid,
        max_returns => 50,
        });

print Dumper($data), "\n";

