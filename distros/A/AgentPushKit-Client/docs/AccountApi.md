# AgentPushKit::Client::AccountApi

## Load the API package
```perl
use AgentPushKit::Client::Object::AccountApi;
```

All URIs are relative to *https://api.chatdna.co/agent-push-kit/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**delete_current_account**](AccountApi.md#delete_current_account) | **DELETE** /me | Delete the current user and customer accounts they own
[**get_current_account**](AccountApi.md#get_current_account) | **GET** /me | Get the current user and customer accounts


# **delete_current_account**
> DeletedResponse delete_current_account()

Delete the current user and customer accounts they own

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AccountApi;
my $api_instance = AgentPushKit::Client::AccountApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);


eval {
    my $result = $api_instance->delete_current_account();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AccountApi->delete_current_account: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DeletedResponse**](DeletedResponse.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_current_account**
> CurrentAccount get_current_account()

Get the current user and customer accounts

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AccountApi;
my $api_instance = AgentPushKit::Client::AccountApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);


eval {
    my $result = $api_instance->get_current_account();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AccountApi->get_current_account: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CurrentAccount**](CurrentAccount.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

