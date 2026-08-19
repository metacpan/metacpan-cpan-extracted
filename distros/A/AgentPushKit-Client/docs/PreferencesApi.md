# AgentPushKit::Client::PreferencesApi

## Load the API package
```perl
use AgentPushKit::Client::Object::PreferencesApi;
```

All URIs are relative to *https://api.chatdna.co/agent-push-kit/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**list_preferences**](PreferencesApi.md#list_preferences) | **GET** /organizations/{organizationId}/preferences | List service defaults and exact-type overrides
[**remove_type_preference**](PreferencesApi.md#remove_type_preference) | **DELETE** /services/{serviceId}/types/{type}/preference | Remove an exact-type override so it inherits the service default
[**set_service_preference**](PreferencesApi.md#set_service_preference) | **PUT** /services/{serviceId}/preference | Enable or disable pushes for a service by default
[**set_type_preference**](PreferencesApi.md#set_type_preference) | **PUT** /services/{serviceId}/types/{type}/preference | Override push delivery for one exact notification type


# **list_preferences**
> ARRAY[ServicePreference] list_preferences(organization_id => $organization_id)

List service defaults and exact-type overrides

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::PreferencesApi;
my $api_instance = AgentPushKit::Client::PreferencesApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $organization_id = "organization_id_example"; # string | 

eval {
    my $result = $api_instance->list_preferences(organization_id => $organization_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling PreferencesApi->list_preferences: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **organization_id** | **string**|  | 

### Return type

[**ARRAY[ServicePreference]**](ServicePreference.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **remove_type_preference**
> InheritedResponse remove_type_preference(service_id => $service_id, type => $type)

Remove an exact-type override so it inherits the service default

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::PreferencesApi;
my $api_instance = AgentPushKit::Client::PreferencesApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $service_id = "service_id_example"; # string | 
my $type = "type_example"; # string | 

eval {
    my $result = $api_instance->remove_type_preference(service_id => $service_id, type => $type);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling PreferencesApi->remove_type_preference: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **service_id** | **string**|  | 
 **type** | **string**|  | 

### Return type

[**InheritedResponse**](InheritedResponse.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **set_service_preference**
> PreferenceRecord set_service_preference(service_id => $service_id, set_enabled_input => $set_enabled_input)

Enable or disable pushes for a service by default

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::PreferencesApi;
my $api_instance = AgentPushKit::Client::PreferencesApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $service_id = "service_id_example"; # string | 
my $set_enabled_input = AgentPushKit::Client::Object::SetEnabledInput->new(); # SetEnabledInput | 

eval {
    my $result = $api_instance->set_service_preference(service_id => $service_id, set_enabled_input => $set_enabled_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling PreferencesApi->set_service_preference: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **service_id** | **string**|  | 
 **set_enabled_input** | [**SetEnabledInput**](SetEnabledInput.md)|  | 

### Return type

[**PreferenceRecord**](PreferenceRecord.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **set_type_preference**
> PreferenceRecord set_type_preference(service_id => $service_id, type => $type, set_enabled_input => $set_enabled_input)

Override push delivery for one exact notification type

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::PreferencesApi;
my $api_instance = AgentPushKit::Client::PreferencesApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $service_id = "service_id_example"; # string | 
my $type = "type_example"; # string | 
my $set_enabled_input = AgentPushKit::Client::Object::SetEnabledInput->new(); # SetEnabledInput | 

eval {
    my $result = $api_instance->set_type_preference(service_id => $service_id, type => $type, set_enabled_input => $set_enabled_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling PreferencesApi->set_type_preference: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **service_id** | **string**|  | 
 **type** | **string**|  | 
 **set_enabled_input** | [**SetEnabledInput**](SetEnabledInput.md)|  | 

### Return type

[**PreferenceRecord**](PreferenceRecord.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

