# AgentPushKit::Client::CustomerAccountsApi

## Load the API package
```perl
use AgentPushKit::Client::Object::CustomerAccountsApi;
```

All URIs are relative to *https://api.chatdna.co/agent-push-kit/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**add_organization_member**](CustomerAccountsApi.md#add_organization_member) | **POST** /organizations/{organizationId}/members | Add an already-registered user to a customer account
[**create_organization**](CustomerAccountsApi.md#create_organization) | **POST** /organizations | Create another Agent Push Kit customer account
[**list_organization_members**](CustomerAccountsApi.md#list_organization_members) | **GET** /organizations/{organizationId}/members | List members of a customer account
[**list_organizations**](CustomerAccountsApi.md#list_organizations) | **GET** /organizations | List customer accounts available to the current user
[**regenerate_organization_api_key**](CustomerAccountsApi.md#regenerate_organization_api_key) | **POST** /organizations/{organizationId}/api-key/regenerate | Rotate the application event-ingestion key


# **add_organization_member**
> Membership add_organization_member(organization_id => $organization_id, add_member_input => $add_member_input)

Add an already-registered user to a customer account

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::CustomerAccountsApi;
my $api_instance = AgentPushKit::Client::CustomerAccountsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $organization_id = "organization_id_example"; # string | 
my $add_member_input = AgentPushKit::Client::Object::AddMemberInput->new(); # AddMemberInput | 

eval {
    my $result = $api_instance->add_organization_member(organization_id => $organization_id, add_member_input => $add_member_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CustomerAccountsApi->add_organization_member: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **organization_id** | **string**|  | 
 **add_member_input** | [**AddMemberInput**](AddMemberInput.md)|  | 

### Return type

[**Membership**](Membership.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create_organization**
> OrganizationCreated create_organization(create_organization_input => $create_organization_input)

Create another Agent Push Kit customer account

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::CustomerAccountsApi;
my $api_instance = AgentPushKit::Client::CustomerAccountsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $create_organization_input = AgentPushKit::Client::Object::CreateOrganizationInput->new(); # CreateOrganizationInput | 

eval {
    my $result = $api_instance->create_organization(create_organization_input => $create_organization_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CustomerAccountsApi->create_organization: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **create_organization_input** | [**CreateOrganizationInput**](CreateOrganizationInput.md)|  | 

### Return type

[**OrganizationCreated**](OrganizationCreated.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list_organization_members**
> ARRAY[Membership] list_organization_members(organization_id => $organization_id)

List members of a customer account

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::CustomerAccountsApi;
my $api_instance = AgentPushKit::Client::CustomerAccountsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $organization_id = "organization_id_example"; # string | 

eval {
    my $result = $api_instance->list_organization_members(organization_id => $organization_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CustomerAccountsApi->list_organization_members: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **organization_id** | **string**|  | 

### Return type

[**ARRAY[Membership]**](Membership.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list_organizations**
> ARRAY[Organization] list_organizations()

List customer accounts available to the current user

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::CustomerAccountsApi;
my $api_instance = AgentPushKit::Client::CustomerAccountsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);


eval {
    my $result = $api_instance->list_organizations();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CustomerAccountsApi->list_organizations: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ARRAY[Organization]**](Organization.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **regenerate_organization_api_key**
> OrganizationApiKeyCreated regenerate_organization_api_key(organization_id => $organization_id)

Rotate the application event-ingestion key

The previous `apk_` key stops working immediately. The replacement is returned only in this response.

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::CustomerAccountsApi;
my $api_instance = AgentPushKit::Client::CustomerAccountsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $organization_id = "organization_id_example"; # string | 

eval {
    my $result = $api_instance->regenerate_organization_api_key(organization_id => $organization_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling CustomerAccountsApi->regenerate_organization_api_key: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **organization_id** | **string**|  | 

### Return type

[**OrganizationApiKeyCreated**](OrganizationApiKeyCreated.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

