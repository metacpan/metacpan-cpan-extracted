# AgentPushKit::Client::EventsApi

## Load the API package
```perl
use AgentPushKit::Client::Object::EventsApi;
```

All URIs are relative to *https://api.chatdna.co/agent-push-kit/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**get_event**](EventsApi.md#get_event) | **GET** /organizations/{organizationId}/events/{eventId} | Get one event including metadata
[**list_events**](EventsApi.md#list_events) | **GET** /organizations/{organizationId}/events | List a paginated inbox
[**list_notification_types**](EventsApi.md#list_notification_types) | **GET** /organizations/{organizationId}/types | List distinct notification types
[**list_services**](EventsApi.md#list_services) | **GET** /organizations/{organizationId}/services | List services discovered from ingested events
[**search_events**](EventsApi.md#search_events) | **POST** /organizations/{organizationId}/events/search | Search events with a validated Boolean filter tree
[**send_event**](EventsApi.md#send_event) | **POST** /events | Send an event using an application ingestion key
[**send_event_as_user**](EventsApi.md#send_event_as_user) | **POST** /organizations/{organizationId}/events | Send an event as an authenticated user or agent


# **get_event**
> EventDetail get_event(organization_id => $organization_id, event_id => $event_id)

Get one event including metadata

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::EventsApi;
my $api_instance = AgentPushKit::Client::EventsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $organization_id = "organization_id_example"; # string | 
my $event_id = "event_id_example"; # string | 

eval {
    my $result = $api_instance->get_event(organization_id => $organization_id, event_id => $event_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling EventsApi->get_event: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **organization_id** | **string**|  | 
 **event_id** | **string**|  | 

### Return type

[**EventDetail**](EventDetail.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list_events**
> EventPage list_events(organization_id => $organization_id, service => $service, type => $type, search => $search, cursor => $cursor, limit => $limit)

List a paginated inbox

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::EventsApi;
my $api_instance = AgentPushKit::Client::EventsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $organization_id = "organization_id_example"; # string | 
my $service = "service_example"; # string | 
my $type = "type_example"; # string | 
my $search = "search_example"; # string | 
my $cursor = "cursor_example"; # string | 
my $limit = 50; # int | 

eval {
    my $result = $api_instance->list_events(organization_id => $organization_id, service => $service, type => $type, search => $search, cursor => $cursor, limit => $limit);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling EventsApi->list_events: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **organization_id** | **string**|  | 
 **service** | **string**|  | [optional] 
 **type** | **string**|  | [optional] 
 **search** | **string**|  | [optional] 
 **cursor** | **string**|  | [optional] 
 **limit** | **int**|  | [optional] [default to 50]

### Return type

[**EventPage**](EventPage.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list_notification_types**
> ARRAY[string] list_notification_types(organization_id => $organization_id, service_id => $service_id)

List distinct notification types

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::EventsApi;
my $api_instance = AgentPushKit::Client::EventsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $organization_id = "organization_id_example"; # string | 
my $service_id = "service_id_example"; # string | Optionally restrict types to one service ID.

eval {
    my $result = $api_instance->list_notification_types(organization_id => $organization_id, service_id => $service_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling EventsApi->list_notification_types: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **organization_id** | **string**|  | 
 **service_id** | **string**| Optionally restrict types to one service ID. | [optional] 

### Return type

**ARRAY[string]**

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list_services**
> ARRAY[Service] list_services(organization_id => $organization_id)

List services discovered from ingested events

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::EventsApi;
my $api_instance = AgentPushKit::Client::EventsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $organization_id = "organization_id_example"; # string | 

eval {
    my $result = $api_instance->list_services(organization_id => $organization_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling EventsApi->list_services: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **organization_id** | **string**|  | 

### Return type

[**ARRAY[Service]**](Service.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **search_events**
> EventPage search_events(organization_id => $organization_id, search_events_input => $search_events_input)

Search events with a validated Boolean filter tree

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::EventsApi;
my $api_instance = AgentPushKit::Client::EventsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $organization_id = "organization_id_example"; # string | 
my $search_events_input = AgentPushKit::Client::Object::SearchEventsInput->new(); # SearchEventsInput | 

eval {
    my $result = $api_instance->search_events(organization_id => $organization_id, search_events_input => $search_events_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling EventsApi->search_events: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **organization_id** | **string**|  | 
 **search_events_input** | [**SearchEventsInput**](SearchEventsInput.md)|  | 

### Return type

[**EventPage**](EventPage.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **send_event**
> IngestionResult send_event(send_event_input => $send_event_input)

Send an event using an application ingestion key

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::EventsApi;
my $api_instance = AgentPushKit::Client::EventsApi->new(

    # Configure bearer access token for authorization: OrganizationApiKey
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $send_event_input = AgentPushKit::Client::Object::SendEventInput->new(); # SendEventInput | 

eval {
    my $result = $api_instance->send_event(send_event_input => $send_event_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling EventsApi->send_event: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **send_event_input** | [**SendEventInput**](SendEventInput.md)|  | 

### Return type

[**IngestionResult**](IngestionResult.md)

### Authorization

[OrganizationApiKey](../README.md#OrganizationApiKey)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **send_event_as_user**
> IngestionResult send_event_as_user(organization_id => $organization_id, send_event_input => $send_event_input)

Send an event as an authenticated user or agent

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::EventsApi;
my $api_instance = AgentPushKit::Client::EventsApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $organization_id = "organization_id_example"; # string | 
my $send_event_input = AgentPushKit::Client::Object::SendEventInput->new(); # SendEventInput | 

eval {
    my $result = $api_instance->send_event_as_user(organization_id => $organization_id, send_event_input => $send_event_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling EventsApi->send_event_as_user: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **organization_id** | **string**|  | 
 **send_event_input** | [**SendEventInput**](SendEventInput.md)|  | 

### Return type

[**IngestionResult**](IngestionResult.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

