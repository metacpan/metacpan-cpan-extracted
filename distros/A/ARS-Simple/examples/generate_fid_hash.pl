# Construct a suitable label/FID hash for a particular form
# and add it to the clipboard for easy pasting into your code
use warnings;
use strict;
use ARS::Simple;
use Win32::Clipboard;

my $CLIP = Win32::Clipboard();
my $ars  = ARS::Simple->new({
        server   => 'dev_machine',
        user     => 'greg',
        password => 'password',
        });

print "Enter the name of the Remedy form: ";
my $form = <STDIN>;
chomp $form;

#----------
my $sql = qq{select
f.fieldName,
f.fieldID,
decode(FOption, 1, 'Required ', 2, 'Optional ', 3, 'System RO', '*Unknown*'),
decode(datatype, 0, 'AR_DATA_TYPE_NULL', 1, 'AR_DATA_TYPE_KEYWORD', 2, 'AR_DATA_TYPE_INTEGER', 3, 'AR_DATA_TYPE_REAL', 4, 'AR_DATA_TYPE_CHAR', 5, 'AR_DATA_TYPE_DIARY', 6, 'AR_DATA_TYPE_ENUM', 7, 'AR_DATA_TYPE_TIME', 8, 'AR_DATA_TYPE_BITMASK', 9, 'AR_DATA_TYPE_BYTES', 10, 'AR_DATA_TYPE_DECIMAL', 11, 'AR_DATA_TYPE_ATTACH', 12, 'AR_DATA_TYPE_CURRENCY', 13, 'AR_DATA_TYPE_DATE', 14, 'AR_DATA_TYPE_TIME_OF_DAY', 30, 'AR_DATA_TYPE_JOIN', 31, 'AR_DATA_TYPE_TRIM', 32, 'AR_DATA_TYPE_CONTROL', 33, 'AR_DATA_TYPE_TABLE', 34, 'AR_DATA_TYPE_COLUMN', 35, 'AR_DATA_TYPE_PAGE', 36, 'AR_DATA_TYPE_PAGE_HOLDER', 37, 'AR_DATA_TYPE_ATTACH_POOL', 40, 'AR_DATA_TYPE_ULONG', 41, 'AR_DATA_TYPE_COORDS', 42, 'AR_DATA_TYPE_VIEW', 43, 'AR_DATA_TYPE_DISPLAY'),
c.maxlength
from arschema a
join field f
on f.schemaid = a.schemaid and datatype < 30 and f.fieldID != 15
left outer join field_char c
on c.schemaid = f.schemaid and c.fieldid = f.fieldID
where a.name = '$form'
order by 1};


my $m = $ars->get_SQL({ sql => $sql });

### Sample data for 'User' form
# my $m = {
# numMatches => 30,
# rows => [
# [ 'CreateDate'               , 3,            'System RO', 'AR_DATA_TYPE_TIME', undef ],
# [ 'LastModifiedBy'           , 5,            'System RO', 'AR_DATA_TYPE_CHAR', 254 ],
# [ 'ModifiedDate'             , 6,            'System RO', 'AR_DATA_TYPE_TIME', undef ],
# [ 'RequestID'                , 1,            'System RO', 'AR_DATA_TYPE_CHAR', 15 ],
# [ 'Creator'                  , 2,            'Required', 'AR_DATA_TYPE_CHAR', 254 ],
# [ 'FullName'                 , 8,            'Required', 'AR_DATA_TYPE_CHAR', 254 ],
# [ 'FullTextLicenseType'      , 110,          'Required', 'AR_DATA_TYPE_ENUM', undef ],
# [ 'LicenseType'              , 109,          'Required', 'AR_DATA_TYPE_ENUM', undef ],
# [ 'LoginName'                , 101,          'Required', 'AR_DATA_TYPE_CHAR', 254 ],
# [ 'Status'                   , 7,            'Required', 'AR_DATA_TYPE_ENUM', undef ],
# [ 'ApplicationLicense'       , 122,          'Optional', 'AR_DATA_TYPE_CHAR', 0 ],
# [ 'ApplicationLicenseType'   , 115,          'Optional', 'AR_DATA_TYPE_CHAR', 254 ],
# [ 'AssignedTo'               , 4,            'Optional', 'AR_DATA_TYPE_CHAR', 254 ],
# [ 'ComputedGrpList'          , 119,          'Optional', 'AR_DATA_TYPE_CHAR', 255 ],
# [ 'DefaultNotifyMechanism'   , 108,          'Optional', 'AR_DATA_TYPE_ENUM', undef ],
# [ 'EmailAddress'             , 103,          'Optional', 'AR_DATA_TYPE_CHAR', 255 ],
# [ 'FlashboardsLicenseType'   , 111,          'Optional', 'AR_DATA_TYPE_ENUM', undef ],
# [ 'FromConfig'               , 250000003,    'Optional', 'AR_DATA_TYPE_CHAR', 3 ],
# [ 'GroupList'                , 104,          'Optional', 'AR_DATA_TYPE_CHAR', 255 ],
# [ 'GrouplistIT'              , 536870913,    'Optional', 'AR_DATA_TYPE_CHAR', 200 ],
# [ 'InstanceID'               , 490000000,    'Optional', 'AR_DATA_TYPE_CHAR', 38 ],
# [ 'ModifyAll'                , 536870914,    'Optional', 'AR_DATA_TYPE_ENUM', undef ],
# [ 'ObjectID'                 , 490000100,    'Optional', 'AR_DATA_TYPE_CHAR', 38 ],
# [ 'Password'                 , 102,          'Optional', 'AR_DATA_TYPE_CHAR', 30 ],
# [ 'UniqueIdentifier'         , 179,          'Optional', 'AR_DATA_TYPE_CHAR', 38 ],
# [ 'AssetLicenseUsed'         , 220000002,    '*Unknown*', 'AR_DATA_TYPE_INTEGER', undef ],
# [ 'ChangeLicenseUsed'        , 220000003,    '*Unknown*', 'AR_DATA_TYPE_INTEGER', undef ],
# [ 'HelpDeskLicenseUsed'      , 220000004,    '*Unknown*', 'AR_DATA_TYPE_INTEGER', undef ],
# [ 'NumberofLicenseAvailable' , 220000000,    '*Unknown*', 'AR_DATA_TYPE_INTEGER', undef ],
# [ 'SLALicenseUsed'           , 220000001,    '*Unknown*', 'AR_DATA_TYPE_INTEGER', undef ],
# ],
# };


unless ($m && $m->{numMatches})
{
    print "No data returned, quitting\n";
    exit;
}

# Check size and replace spaces with '_', you could also remove them!
my $max_len = 0;
foreach my $row (@{ $m->{rows} })
{
    $row->[0] =~ s/\s+/_/gms;
    if (length($row->[0]) > $max_len)
    {
        $max_len = length($row->[0]);
    }
}

# Construct the hash
my $fid_hash = "# Label/FID hash for form '$form'\n\%fid = (\n";
foreach my $row (@{ $m->{rows} })
{
    $fid_hash .= sprintf("    '%s'%s=> %10d,\t\t# %s type=%s %d\n", $row->[0], ' ' x ($max_len + 1 - length($row->[0])), $row->[1], $row->[2], $row->[3], $row->[4]);
}
$fid_hash .= "    );\n";

$CLIP->Set($fid_hash);
print "$fid_hash\nFormatted data copied to clipboard\n";