# AgentPushKit::Client::AuthenticationApi

## Load the API package
```perl
use AgentPushKit::Client::Object::AuthenticationApi;
```

All URIs are relative to *https://api.chatdna.co/agent-push-kit/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**complete_password_reset**](AuthenticationApi.md#complete_password_reset) | **POST** /auth/password-reset/complete | Choose a new password and log in
[**login_with_apple**](AuthenticationApi.md#login_with_apple) | **POST** /auth/apple | Log in or attach an account using a Sign in with Apple identity token
[**login_with_google**](AuthenticationApi.md#login_with_google) | **POST** /auth/google | Log in or attach an account using a verified Google ID token
[**login_with_password**](AuthenticationApi.md#login_with_password) | **POST** /auth/login | Log in with email and password
[**register**](AuthenticationApi.md#register) | **POST** /auth/register | Create a user and first customer account
[**request_password_reset**](AuthenticationApi.md#request_password_reset) | **POST** /auth/password-reset/request | Email a single-use password reset token


# **complete_password_reset**
> AuthResponse complete_password_reset(password_reset_complete_input => $password_reset_complete_input)

Choose a new password and log in

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AuthenticationApi;
my $api_instance = AgentPushKit::Client::AuthenticationApi->new(
);

my $password_reset_complete_input = AgentPushKit::Client::Object::PasswordResetCompleteInput->new(); # PasswordResetCompleteInput | 

eval {
    my $result = $api_instance->complete_password_reset(password_reset_complete_input => $password_reset_complete_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AuthenticationApi->complete_password_reset: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **password_reset_complete_input** | [**PasswordResetCompleteInput**](PasswordResetCompleteInput.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **login_with_apple**
> AuthResponse login_with_apple(provider_login_input => $provider_login_input)

Log in or attach an account using a Sign in with Apple identity token

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AuthenticationApi;
my $api_instance = AgentPushKit::Client::AuthenticationApi->new(
);

my $provider_login_input = AgentPushKit::Client::Object::ProviderLoginInput->new(); # ProviderLoginInput | 

eval {
    my $result = $api_instance->login_with_apple(provider_login_input => $provider_login_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AuthenticationApi->login_with_apple: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **provider_login_input** | [**ProviderLoginInput**](ProviderLoginInput.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **login_with_google**
> AuthResponse login_with_google(provider_login_input => $provider_login_input)

Log in or attach an account using a verified Google ID token

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AuthenticationApi;
my $api_instance = AgentPushKit::Client::AuthenticationApi->new(
);

my $provider_login_input = AgentPushKit::Client::Object::ProviderLoginInput->new(); # ProviderLoginInput | 

eval {
    my $result = $api_instance->login_with_google(provider_login_input => $provider_login_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AuthenticationApi->login_with_google: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **provider_login_input** | [**ProviderLoginInput**](ProviderLoginInput.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **login_with_password**
> AuthResponse login_with_password(password_login_input => $password_login_input)

Log in with email and password

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AuthenticationApi;
my $api_instance = AgentPushKit::Client::AuthenticationApi->new(
);

my $password_login_input = AgentPushKit::Client::Object::PasswordLoginInput->new(); # PasswordLoginInput | 

eval {
    my $result = $api_instance->login_with_password(password_login_input => $password_login_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AuthenticationApi->login_with_password: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **password_login_input** | [**PasswordLoginInput**](PasswordLoginInput.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **register**
> AuthResponse register(register_input => $register_input)

Create a user and first customer account

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AuthenticationApi;
my $api_instance = AgentPushKit::Client::AuthenticationApi->new(
);

my $register_input = AgentPushKit::Client::Object::RegisterInput->new(); # RegisterInput | 

eval {
    my $result = $api_instance->register(register_input => $register_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AuthenticationApi->register: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **register_input** | [**RegisterInput**](RegisterInput.md)|  | 

### Return type

[**AuthResponse**](AuthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **request_password_reset**
> AcceptedResponse request_password_reset(password_reset_request_input => $password_reset_request_input)

Email a single-use password reset token

### Example
```perl
use Data::Dumper;
use AgentPushKit::Client::AuthenticationApi;
my $api_instance = AgentPushKit::Client::AuthenticationApi->new(
);

my $password_reset_request_input = AgentPushKit::Client::Object::PasswordResetRequestInput->new(); # PasswordResetRequestInput | 

eval {
    my $result = $api_instance->request_password_reset(password_reset_request_input => $password_reset_request_input);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling AuthenticationApi->request_password_reset: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **password_reset_request_input** | [**PasswordResetRequestInput**](PasswordResetRequestInput.md)|  | 

### Return type

[**AcceptedResponse**](AcceptedResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

