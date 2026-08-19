# AgentPushKit::Client::HealthApi

## Load the API package
```perl
use AgentPushKit::Client::Object::HealthApi;
```

All URIs are relative to *https://api.chatdna.co/agent-push-kit/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**get_health**](HealthApi.md#get_health) | **GET** /health | Check Agent Push Kit API health


# **get_health**
> HealthResponse get_health()

Check Agent Push Kit API health

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::HealthApi;
my $api_instance = AgentPushKit::Client::HealthApi->new(
);


eval {
    my $result = $api_instance->get_health();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling HealthApi->get_health: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthResponse**](HealthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

