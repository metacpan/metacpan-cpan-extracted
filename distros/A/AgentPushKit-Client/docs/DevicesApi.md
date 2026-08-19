# AgentPushKit::Client::DevicesApi

## Load the API package
```perl
use AgentPushKit::Client::Object::DevicesApi;
```

All URIs are relative to *https://api.chatdna.co/agent-push-kit/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**get_web_push_configuration**](DevicesApi.md#get_web_push_configuration) | **GET** /web-push/configuration | Get browser push availability and its public VAPID key
[**register_device**](DevicesApi.md#register_device) | **POST** /devices | Register or refresh an APNs device
[**register_web_push_subscription**](DevicesApi.md#register_web_push_subscription) | **POST** /web-push/subscriptions | Register or refresh a browser push subscription
[**remove_device**](DevicesApi.md#remove_device) | **DELETE** /devices/{installationId} | Disable push delivery to one installation
[**remove_web_push_subscription**](DevicesApi.md#remove_web_push_subscription) | **DELETE** /web-push/subscriptions/{subscriptionId} | Disable a browser push subscription


# **get_web_push_configuration**
> WebPushConfiguration get_web_push_configuration()

Get browser push availability and its public VAPID key

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::DevicesApi;
my $api_instance = AgentPushKit::Client::DevicesApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);


eval {
    my $result = $api_instance->get_web_push_configuration();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DevicesApi->get_web_push_configuration: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**WebPushConfiguration**](WebPushConfiguration.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **register_device**
> Device register_device(register_device_input => $register_device_input)

Register or refresh an APNs device

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::DevicesApi;
my $api_instance = AgentPushKit::Client::DevicesApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $register_device_input = AgentPushKit::Client::Object::RegisterDeviceInput->new(); # RegisterDeviceInput | 

eval {
    my $result = $api_instance->register_device(register_device_input => $register_device_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DevicesApi->register_device: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **register_device_input** | [**RegisterDeviceInput**](RegisterDeviceInput.md)|  | 

### Return type

[**Device**](Device.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **register_web_push_subscription**
> WebPushSubscription register_web_push_subscription(register_web_push_subscription_input => $register_web_push_subscription_input)

Register or refresh a browser push subscription

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::DevicesApi;
my $api_instance = AgentPushKit::Client::DevicesApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $register_web_push_subscription_input = AgentPushKit::Client::Object::RegisterWebPushSubscriptionInput->new(); # RegisterWebPushSubscriptionInput | 

eval {
    my $result = $api_instance->register_web_push_subscription(register_web_push_subscription_input => $register_web_push_subscription_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DevicesApi->register_web_push_subscription: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **register_web_push_subscription_input** | [**RegisterWebPushSubscriptionInput**](RegisterWebPushSubscriptionInput.md)|  | 

### Return type

[**WebPushSubscription**](WebPushSubscription.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **remove_device**
> DisabledResponse remove_device(installation_id => $installation_id)

Disable push delivery to one installation

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::DevicesApi;
my $api_instance = AgentPushKit::Client::DevicesApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $installation_id = "installation_id_example"; # string | 

eval {
    my $result = $api_instance->remove_device(installation_id => $installation_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DevicesApi->remove_device: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **installation_id** | **string**|  | 

### Return type

[**DisabledResponse**](DisabledResponse.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **remove_web_push_subscription**
> DisabledResponse remove_web_push_subscription(subscription_id => $subscription_id)

Disable a browser push subscription

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::DevicesApi;
my $api_instance = AgentPushKit::Client::DevicesApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $subscription_id = "subscription_id_example"; # string | 

eval {
    my $result = $api_instance->remove_web_push_subscription(subscription_id => $subscription_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling DevicesApi->remove_web_push_subscription: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **subscription_id** | **string**|  | 

### Return type

[**DisabledResponse**](DisabledResponse.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

