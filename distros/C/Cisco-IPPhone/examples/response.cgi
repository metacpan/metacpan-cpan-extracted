#!/usr/bin/perl

# Response objects are returned from the phone
# There is usually no need to build your own

use Cisco::IPPhone;

$myresponse = new Cisco::IPPhone;

$myresponse->Response; # Execute Object takes no Input

# One Response Object can take up to 3 Execute Items
$myresponse->AddResponseItem( { Status => "URL1",
                                Data => "Data1",
                                URL => "URL1" });
$myresponse->AddResponseItem( { Status => "URL2",
                                Data => "Data2",
                                URL => "URL2" });
$myresponse->AddResponseItem( { Status => "URL3",
                                Data => "Data3",
                                URL => "URL3" });
print $myresponse->Content;

__END__
