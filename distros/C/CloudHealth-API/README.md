# NAME

CloudHealth::API - A REST API Client for the CloudHealth API

# SYNOPSIS

     use CloudHealth::API;
     my $ch = CloudHealth::API->new;
     
     my $res = $ch->MetricsForSingleAsset(
       asset => $asset,
     );
     print Dumper($res);
    

# DESCRIPTION

This module implements the CloudHealth REST API found in [https://apidocs.cloudhealthtech.com/](https://apidocs.cloudhealthtech.com/)

# METHODS

Each method on the client corresponds to an API action. You can find a class in the 
`CloudHealth::API::Call` namespace that describes the parameters that the method call accepts:

[CloudHealth::API::Call::EnableAWSAccount](https://metacpan.org/pod/CloudHealth::API::Call::EnableAWSAccount)

    $ch->EnableAWSAccount(authentication => { protocol => '..' }, ...);

[CloudHealth::API::Call::AWSAccounts](https://metacpan.org/pod/CloudHealth::API::Call::AWSAccounts)

    $ch->AWSAccounts;

[CloudHealth::API::Call::SingleAWSAccount](https://metacpan.org/pod/CloudHealth::API::Call::SingleAWSAccount)

    $ch->SingleAWSAccount(id => $id);

[CloudHealth::API::Call::UpdateExistingAWSAccount](https://metacpan.org/pod/CloudHealth::API::Call::UpdateExistingAWSAccount)

    $ch->UpdateExistingAWSAccount(id => $id, authentication => { protocol => '..' }, ...);

[CloudHealth::API::Call::GetExternalID](https://metacpan.org/pod/CloudHealth::API::Call::GetExternalID)

    $ch->GetExternalID(id => $id)

[CloudHealth::API::Call::MetricsForSingleAsset](https://metacpan.org/pod/CloudHealth::API::Call::MetricsForSingleAsset)

    $ch->MetricsForSingleAsset(asset => $id, from => '...', to => '...');

[CloudHealth::API::Call::DeleteAWSAccount](https://metacpan.org/pod/CloudHealth::API::Call::DeleteAWSAccount)

[CloudHealth::API::Call::RetrieveAllPerspectives](https://metacpan.org/pod/CloudHealth::API::Call::RetrieveAllPerspectives)

[CloudHealth::API::Call::RetrievePerspectiveSchema](https://metacpan.org/pod/CloudHealth::API::Call::RetrievePerspectiveSchema)

[CloudHealth::API::Call::CreatePerspectiveSchema](https://metacpan.org/pod/CloudHealth::API::Call::CreatePerspectiveSchema)

[CloudHealth::API::Call::UpdatePerspectiveSchema](https://metacpan.org/pod/CloudHealth::API::Call::UpdatePerspectiveSchema)

[CloudHealth::API::Call::DeletePerspectiveSchema](https://metacpan.org/pod/CloudHealth::API::Call::DeletePerspectiveSchema)

[CloudHealth::API::Call::ListQueryableReports](https://metacpan.org/pod/CloudHealth::API::Call::ListQueryableReports)

[CloudHealth::API::Call::ListReportsOfSpecificType](https://metacpan.org/pod/CloudHealth::API::Call::ListReportsOfSpecificType)

[CloudHealth::API::Call::ListOfQueryableAssets](https://metacpan.org/pod/CloudHealth::API::Call::ListOfQueryableAssets)

[CloudHealth::API::Call::AttributesOfSingleAsset](https://metacpan.org/pod/CloudHealth::API::Call::AttributesOfSingleAsset)

[CloudHealth::API::Call::SearchForAssets](https://metacpan.org/pod/CloudHealth::API::Call::SearchForAssets)

[CloudHealth::API::Call::UpdateTagsForSingleAsset](https://metacpan.org/pod/CloudHealth::API::Call::UpdateTagsForSingleAsset)

[CloudHealth::API::Call::SpecificCustomerReport](https://metacpan.org/pod/CloudHealth::API::Call::SpecificCustomerReport)

[CloudHealth::API::Call::AssetsForSpecificCustomer](https://metacpan.org/pod/CloudHealth::API::Call::AssetsForSpecificCustomer)

[CloudHealth::API::Call::CreatePartnerCustomer](https://metacpan.org/pod/CloudHealth::API::Call::CreatePartnerCustomer)

[CloudHealth::API::Call::ModifyExistingCustomer](https://metacpan.org/pod/CloudHealth::API::Call::ModifyExistingCustomer)

[CloudHealth::API::Call::DeleteExistingCustomer](https://metacpan.org/pod/CloudHealth::API::Call::DeleteExistingCustomer)

[CloudHealth::API::Call::GetSingleCustomer](https://metacpan.org/pod/CloudHealth::API::Call::GetSingleCustomer)

[CloudHealth::API::Call::GetAllCustomers](https://metacpan.org/pod/CloudHealth::API::Call::GetAllCustomers)

[CloudHealth::API::Call::StatementForSingleCustomer](https://metacpan.org/pod/CloudHealth::API::Call::StatementForSingleCustomer)

[CloudHealth::API::Call::StatementsForAllCustomers](https://metacpan.org/pod/CloudHealth::API::Call::StatementsForAllCustomers)

[CloudHealth::API::Call::CreateAWSAccountAssignment](https://metacpan.org/pod/CloudHealth::API::Call::CreateAWSAccountAssignment)

[CloudHealth::API::Call::ReadAllAWSAccountAssignments](https://metacpan.org/pod/CloudHealth::API::Call::ReadAllAWSAccountAssignments)

[CloudHealth::API::Call::ReadSingleAWSAccountAssignment](https://metacpan.org/pod/CloudHealth::API::Call::ReadSingleAWSAccountAssignment)

[CloudHealth::API::Call::UpdateAWSAccountAssignment](https://metacpan.org/pod/CloudHealth::API::Call::UpdateAWSAccountAssignment)

[CloudHealth::API::Call::DeleteAWSAccountAssignment](https://metacpan.org/pod/CloudHealth::API::Call::DeleteAWSAccountAssignment)

# AUTHENTICATION

As the documentation states, you need an API KEY to query the API. The default authentication
mechanism expects to find that API key in the `CLOUDHEALTH_APIKEY` environment variable.

You can also pass any object that implements an `api_key` method to the `credentials` attribute
of the constructor

# RESULTS

Results are returned as a Perl HashRef representing the JSON returned by the API.

# SEE ALSO

[https://apidocs.cloudhealthtech.com/](https://apidocs.cloudhealthtech.com/)

There is a CLI wrapper available as a CPAN module: [App::CloudHealth](https://metacpan.org/pod/App::CloudHealth)

# AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com

# BUGS and SOURCE

The source code is located here: [https://github.com/pplu/cloudhealth-api-perl/](https://github.com/pplu/cloudhealth-api-perl/)

Please report bugs to: [https://github.com/pplu/cloudhealth-api-perl/issues](https://github.com/pplu/cloudhealth-api-perl/issues)

# COPYRIGHT and LICENSE

Copyright (c) 2018 by Jose Luis Martinez Torres

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.
