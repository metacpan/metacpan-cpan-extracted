# AgentPushKit::Client::AgentTokensApi

## Load the API package
```perl
use AgentPushKit::Client::Object::AgentTokensApi;
```

All URIs are relative to *https://api.chatdna.co/agent-push-kit/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**call_mcp**](AgentTokensApi.md#call_mcp) | **POST** /mcp | Connect through stateless MCP Streamable HTTP
[**create_agent_token**](AgentTokensApi.md#create_agent_token) | **POST** /agent-tokens | Create a named non-expiring agent token
[**list_agent_tokens**](AgentTokensApi.md#list_agent_tokens) | **GET** /agent-tokens | List agent access tokens without their secrets
[**revoke_agent_token**](AgentTokensApi.md#revoke_agent_token) | **DELETE** /agent-tokens/{tokenId} | Revoke one of the current user&#39;s agent tokens


# **call_mcp**
> call_mcp(request_body => $request_body)

Connect through stateless MCP Streamable HTTP

This endpoint accepts only an `apt_` agent access token.

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AgentTokensApi;
my $api_instance = AgentPushKit::Client::AgentTokensApi->new(

    # Configure bearer access token for authorization: AgentToken
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $request_body = AgentPushKit::Client::Object::HASH[string,object]->new(); # HASH[string,object] | 

eval {
    $api_instance->call_mcp(request_body => $request_body);
};
if ($@) {
    warn "Exception when calling AgentTokensApi->call_mcp: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **request_body** | [**HASH[string,object]**](object.md)|  | 

### Return type

void (empty response body)

### Authorization

[AgentToken](../README.md#AgentToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create_agent_token**
> AgentTokenCreated create_agent_token(create_agent_token_input => $create_agent_token_input)

Create a named non-expiring agent token

The raw `apt_` token is shown once. Store it before dismissing the response.

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AgentTokensApi;
my $api_instance = AgentPushKit::Client::AgentTokensApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $create_agent_token_input = AgentPushKit::Client::Object::CreateAgentTokenInput->new(); # CreateAgentTokenInput | 

eval {
    my $result = $api_instance->create_agent_token(create_agent_token_input => $create_agent_token_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AgentTokensApi->create_agent_token: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **create_agent_token_input** | [**CreateAgentTokenInput**](CreateAgentTokenInput.md)|  | 

### Return type

[**AgentTokenCreated**](AgentTokenCreated.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **list_agent_tokens**
> ARRAY[AgentToken] list_agent_tokens()

List agent access tokens without their secrets

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AgentTokensApi;
my $api_instance = AgentPushKit::Client::AgentTokensApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);


eval {
    my $result = $api_instance->list_agent_tokens();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AgentTokensApi->list_agent_tokens: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ARRAY[AgentToken]**](AgentToken.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revoke_agent_token**
> RevokedResponse revoke_agent_token(token_id => $token_id)

Revoke one of the current user's agent tokens

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AgentTokensApi;
my $api_instance = AgentPushKit::Client::AgentTokensApi->new(

    # Configure bearer access token for authorization: UserOrAgent
    access_token => 'YOUR_BEARER_TOKEN',
    
);

my $token_id = "token_id_example"; # string | 

eval {
    my $result = $api_instance->revoke_agent_token(token_id => $token_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AgentTokensApi->revoke_agent_token: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token_id** | **string**|  | 

### Return type

[**RevokedResponse**](RevokedResponse.md)

### Authorization

[UserOrAgent](../README.md#UserOrAgent)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

