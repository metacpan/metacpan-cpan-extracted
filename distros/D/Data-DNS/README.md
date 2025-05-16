# SYNOPSIS

    use Data::DNS;

    if (Data::DNS->exists("org")) {
        $org = Data::DNS->get("org");

        say ".org is operated by ".$org->rdap_record->registrant->jcard->first('org')->value;
    }

# DESCRIPTION

Information about the DNS root zone is distributed across multiple data sources.
This module organises this information and provides a single entry point to it.

# PACKAGE METHODS

## exists($tld)

This method returns true if the TLD specified by `$tld` exists in the root
zone.

## get($tld)

This method returns a [Data::DNS::TLD](https://metacpan.org/pod/Data%3A%3ADNS%3A%3ATLD) object corresponding to the TLD
specified by `$tld`. An exception will be thrown if the TLD does not exist.
