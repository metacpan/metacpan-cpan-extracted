# BmltClient::RootServerApi

## Load the API package
```perl
use BmltClient::Object::RootServerApi;
```

All URIs are relative to *http://localhost:8000/main_server*

Method | HTTP request | Description
------------- | ------------- | -------------
[**auth_logout**](RootServerApi.md#auth_logout) | **POST** /api/v1/auth/logout | Revokes a token
[**auth_refresh**](RootServerApi.md#auth_refresh) | **POST** /api/v1/auth/refresh | Revokes and issues a new token
[**auth_token**](RootServerApi.md#auth_token) | **POST** /api/v1/auth/token | Creates a token
[**create_format**](RootServerApi.md#create_format) | **POST** /api/v1/formats | Creates a format
[**create_meeting**](RootServerApi.md#create_meeting) | **POST** /api/v1/meetings | Creates a meeting
[**create_service_body**](RootServerApi.md#create_service_body) | **POST** /api/v1/servicebodies | Creates a service body
[**create_user**](RootServerApi.md#create_user) | **POST** /api/v1/users | Creates a user
[**delete_format**](RootServerApi.md#delete_format) | **DELETE** /api/v1/formats/{formatId} | Deletes a format
[**delete_meeting**](RootServerApi.md#delete_meeting) | **DELETE** /api/v1/meetings/{meetingId} | Deletes a meeting
[**delete_service_body**](RootServerApi.md#delete_service_body) | **DELETE** /api/v1/servicebodies/{serviceBodyId} | Deletes a service body
[**delete_user**](RootServerApi.md#delete_user) | **DELETE** /api/v1/users/{userId} | Deletes a user
[**get_format**](RootServerApi.md#get_format) | **GET** /api/v1/formats/{formatId} | Retrieves a format
[**get_formats**](RootServerApi.md#get_formats) | **GET** /api/v1/formats | Retrieves formats
[**get_meeting**](RootServerApi.md#get_meeting) | **GET** /api/v1/meetings/{meetingId} | Retrieves a meeting
[**get_meetings**](RootServerApi.md#get_meetings) | **GET** /api/v1/meetings | Retrieves meetings
[**get_service_bodies**](RootServerApi.md#get_service_bodies) | **GET** /api/v1/servicebodies | Retrieves service bodies
[**get_service_body**](RootServerApi.md#get_service_body) | **GET** /api/v1/servicebodies/{serviceBodyId} | Retrieves a service body
[**get_user**](RootServerApi.md#get_user) | **GET** /api/v1/users/{userId} | Retrieves a single user
[**get_users**](RootServerApi.md#get_users) | **GET** /api/v1/users | Retrieves users
[**partial_update_user**](RootServerApi.md#partial_update_user) | **PATCH** /api/v1/users/{userId} | Patches a user
[**patch_format**](RootServerApi.md#patch_format) | **PATCH** /api/v1/formats/{formatId} | Patches a format
[**patch_meeting**](RootServerApi.md#patch_meeting) | **PATCH** /api/v1/meetings/{meetingId} | Patches a meeting
[**patch_service_body**](RootServerApi.md#patch_service_body) | **PATCH** /api/v1/servicebodies/{serviceBodyId} | Patches a service body
[**update_format**](RootServerApi.md#update_format) | **PUT** /api/v1/formats/{formatId} | Updates a format
[**update_meeting**](RootServerApi.md#update_meeting) | **PUT** /api/v1/meetings/{meetingId} | Updates a meeting
[**update_service_body**](RootServerApi.md#update_service_body) | **PUT** /api/v1/servicebodies/{serviceBodyId} | Updates a Service Body
[**update_user**](RootServerApi.md#update_user) | **PUT** /api/v1/users/{userId} | Update single user


# **auth_logout**
> auth_logout()

Revokes a token

Revoke token and logout.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);


eval {
    $api_instance->auth_logout();
};
if ($@) {
    warn "Exception when calling RootServerApi->auth_logout: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **auth_refresh**
> Token auth_refresh()

Revokes and issues a new token

Refresh token.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);


eval {
    my $result = $api_instance->auth_refresh();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->auth_refresh: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**Token**](Token.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **auth_token**
> Token auth_token(token_credentials => $token_credentials)

Creates a token

Exchange credentials for a new token

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(
);

my $token_credentials = BmltClient::Object::TokenCredentials->new(); # TokenCredentials | User credentials

eval {
    my $result = $api_instance->auth_token(token_credentials => $token_credentials);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->auth_token: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **token_credentials** | [**TokenCredentials**](TokenCredentials.md)| User credentials | 

### Return type

[**Token**](Token.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create_format**
> Format create_format(format_create => $format_create)

Creates a format

Creates a format.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $format_create = BmltClient::Object::FormatCreate->new(); # FormatCreate | Pass in format object

eval {
    my $result = $api_instance->create_format(format_create => $format_create);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->create_format: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **format_create** | [**FormatCreate**](FormatCreate.md)| Pass in format object | 

### Return type

[**Format**](Format.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create_meeting**
> Meeting create_meeting(meeting_create => $meeting_create)

Creates a meeting

Creates a meeting.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $meeting_create = BmltClient::Object::MeetingCreate->new(); # MeetingCreate | Pass in meeting object

eval {
    my $result = $api_instance->create_meeting(meeting_create => $meeting_create);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->create_meeting: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **meeting_create** | [**MeetingCreate**](MeetingCreate.md)| Pass in meeting object | 

### Return type

[**Meeting**](Meeting.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create_service_body**
> ServiceBody create_service_body(service_body_create => $service_body_create)

Creates a service body

Creates a service body.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $service_body_create = BmltClient::Object::ServiceBodyCreate->new(); # ServiceBodyCreate | Pass in service body object

eval {
    my $result = $api_instance->create_service_body(service_body_create => $service_body_create);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->create_service_body: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **service_body_create** | [**ServiceBodyCreate**](ServiceBodyCreate.md)| Pass in service body object | 

### Return type

[**ServiceBody**](ServiceBody.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create_user**
> User create_user(user_create => $user_create)

Creates a user

Creates a user.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $user_create = BmltClient::Object::UserCreate->new(); # UserCreate | Pass in user object

eval {
    my $result = $api_instance->create_user(user_create => $user_create);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->create_user: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **user_create** | [**UserCreate**](UserCreate.md)| Pass in user object | 

### Return type

[**User**](User.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_format**
> delete_format(format_id => $format_id)

Deletes a format

Deletes a format by id.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $format_id = 1; # int | ID of format

eval {
    $api_instance->delete_format(format_id => $format_id);
};
if ($@) {
    warn "Exception when calling RootServerApi->delete_format: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **format_id** | **int**| ID of format | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_meeting**
> delete_meeting(meeting_id => $meeting_id)

Deletes a meeting

Deletes a meeting by id.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $meeting_id = 1; # int | ID of meeting

eval {
    $api_instance->delete_meeting(meeting_id => $meeting_id);
};
if ($@) {
    warn "Exception when calling RootServerApi->delete_meeting: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **meeting_id** | **int**| ID of meeting | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_service_body**
> delete_service_body(service_body_id => $service_body_id)

Deletes a service body

Deletes a service body by id.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $service_body_id = 1; # int | ID of service body

eval {
    $api_instance->delete_service_body(service_body_id => $service_body_id);
};
if ($@) {
    warn "Exception when calling RootServerApi->delete_service_body: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **service_body_id** | **int**| ID of service body | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_user**
> delete_user(user_id => $user_id)

Deletes a user

Deletes a user by id

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $user_id = 1; # int | ID of user

eval {
    $api_instance->delete_user(user_id => $user_id);
};
if ($@) {
    warn "Exception when calling RootServerApi->delete_user: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **user_id** | **int**| ID of user | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_format**
> Format get_format(format_id => $format_id)

Retrieves a format

Retrieve a format

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $format_id = 1; # int | ID of format

eval {
    my $result = $api_instance->get_format(format_id => $format_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->get_format: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **format_id** | **int**| ID of format | 

### Return type

[**Format**](Format.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_formats**
> ARRAY[Format] get_formats()

Retrieves formats

Retrieve formats

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);


eval {
    my $result = $api_instance->get_formats();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->get_formats: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ARRAY[Format]**](Format.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_meeting**
> Meeting get_meeting(meeting_id => $meeting_id)

Retrieves a meeting

Retrieve a meeting.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $meeting_id = 1; # int | ID of meeting

eval {
    my $result = $api_instance->get_meeting(meeting_id => $meeting_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->get_meeting: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **meeting_id** | **int**| ID of meeting | 

### Return type

[**Meeting**](Meeting.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_meetings**
> ARRAY[Meeting] get_meetings(meeting_ids => $meeting_ids, days => $days, service_body_ids => $service_body_ids, search_string => $search_string)

Retrieves meetings

Retrieve meetings for authenticated user.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $meeting_ids = 1,2; # string | comma delimited meeting ids
my $days = 0,1; # string | comma delimited day ids between 0-6
my $service_body_ids = 3,4; # string | comma delimited service body ids
my $search_string = Just for Today; # string | string

eval {
    my $result = $api_instance->get_meetings(meeting_ids => $meeting_ids, days => $days, service_body_ids => $service_body_ids, search_string => $search_string);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->get_meetings: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **meeting_ids** | **string**| comma delimited meeting ids | [optional] 
 **days** | **string**| comma delimited day ids between 0-6 | [optional] 
 **service_body_ids** | **string**| comma delimited service body ids | [optional] 
 **search_string** | **string**| string | [optional] 

### Return type

[**ARRAY[Meeting]**](Meeting.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_service_bodies**
> ARRAY[ServiceBody] get_service_bodies()

Retrieves service bodies

Retrieve service bodies for authenticated user.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);


eval {
    my $result = $api_instance->get_service_bodies();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->get_service_bodies: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ARRAY[ServiceBody]**](ServiceBody.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_service_body**
> ServiceBody get_service_body(service_body_id => $service_body_id)

Retrieves a service body

Retrieve a single service body by id.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $service_body_id = 1; # int | ID of service body

eval {
    my $result = $api_instance->get_service_body(service_body_id => $service_body_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->get_service_body: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **service_body_id** | **int**| ID of service body | 

### Return type

[**ServiceBody**](ServiceBody.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_user**
> User get_user(user_id => $user_id)

Retrieves a single user

Retrieve single user.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $user_id = 1; # int | ID of user

eval {
    my $result = $api_instance->get_user(user_id => $user_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->get_user: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **user_id** | **int**| ID of user | 

### Return type

[**User**](User.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_users**
> ARRAY[User] get_users()

Retrieves users

Retrieve users for authenticated user.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);


eval {
    my $result = $api_instance->get_users();
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling RootServerApi->get_users: $@\n";
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ARRAY[User]**](User.md)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **partial_update_user**
> partial_update_user(user_id => $user_id, user_partial_update => $user_partial_update)

Patches a user

Patches a user by id.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $user_id = 1; # int | ID of user
my $user_partial_update = BmltClient::Object::UserPartialUpdate->new(); # UserPartialUpdate | Pass in fields you want to update.

eval {
    $api_instance->partial_update_user(user_id => $user_id, user_partial_update => $user_partial_update);
};
if ($@) {
    warn "Exception when calling RootServerApi->partial_update_user: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **user_id** | **int**| ID of user | 
 **user_partial_update** | [**UserPartialUpdate**](UserPartialUpdate.md)| Pass in fields you want to update. | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **patch_format**
> patch_format(format_id => $format_id, format_partial_update => $format_partial_update)

Patches a format

Patches a single format by id.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $format_id = 1; # int | ID of format
my $format_partial_update = BmltClient::Object::FormatPartialUpdate->new(); # FormatPartialUpdate | Pass in fields you want to update.

eval {
    $api_instance->patch_format(format_id => $format_id, format_partial_update => $format_partial_update);
};
if ($@) {
    warn "Exception when calling RootServerApi->patch_format: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **format_id** | **int**| ID of format | 
 **format_partial_update** | [**FormatPartialUpdate**](FormatPartialUpdate.md)| Pass in fields you want to update. | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **patch_meeting**
> patch_meeting(meeting_id => $meeting_id, meeting_partial_update => $meeting_partial_update)

Patches a meeting

Patches a meeting by id

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $meeting_id = 1; # int | ID of meeting
my $meeting_partial_update = BmltClient::Object::MeetingPartialUpdate->new(); # MeetingPartialUpdate | Pass in fields you want to update.

eval {
    $api_instance->patch_meeting(meeting_id => $meeting_id, meeting_partial_update => $meeting_partial_update);
};
if ($@) {
    warn "Exception when calling RootServerApi->patch_meeting: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **meeting_id** | **int**| ID of meeting | 
 **meeting_partial_update** | [**MeetingPartialUpdate**](MeetingPartialUpdate.md)| Pass in fields you want to update. | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **patch_service_body**
> patch_service_body(service_body_id => $service_body_id, service_body_partial_update => $service_body_partial_update)

Patches a service body

Patches a single service body by id.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $service_body_id = 1; # int | ID of service body
my $service_body_partial_update = BmltClient::Object::ServiceBodyPartialUpdate->new(); # ServiceBodyPartialUpdate | Pass in fields you want to update.

eval {
    $api_instance->patch_service_body(service_body_id => $service_body_id, service_body_partial_update => $service_body_partial_update);
};
if ($@) {
    warn "Exception when calling RootServerApi->patch_service_body: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **service_body_id** | **int**| ID of service body | 
 **service_body_partial_update** | [**ServiceBodyPartialUpdate**](ServiceBodyPartialUpdate.md)| Pass in fields you want to update. | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **update_format**
> update_format(format_id => $format_id, format_update => $format_update)

Updates a format

Updates a format.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $format_id = 1; # int | ID of format
my $format_update = BmltClient::Object::FormatUpdate->new(); # FormatUpdate | Pass in format object

eval {
    $api_instance->update_format(format_id => $format_id, format_update => $format_update);
};
if ($@) {
    warn "Exception when calling RootServerApi->update_format: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **format_id** | **int**| ID of format | 
 **format_update** | [**FormatUpdate**](FormatUpdate.md)| Pass in format object | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **update_meeting**
> update_meeting(meeting_id => $meeting_id, meeting_update => $meeting_update)

Updates a meeting

Updates a meeting.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $meeting_id = 1; # int | ID of meeting
my $meeting_update = BmltClient::Object::MeetingUpdate->new(); # MeetingUpdate | Pass in meeting object

eval {
    $api_instance->update_meeting(meeting_id => $meeting_id, meeting_update => $meeting_update);
};
if ($@) {
    warn "Exception when calling RootServerApi->update_meeting: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **meeting_id** | **int**| ID of meeting | 
 **meeting_update** | [**MeetingUpdate**](MeetingUpdate.md)| Pass in meeting object | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **update_service_body**
> update_service_body(service_body_id => $service_body_id, service_body_update => $service_body_update)

Updates a Service Body

Updates a single service body.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $service_body_id = 1; # int | ID of service body
my $service_body_update = BmltClient::Object::ServiceBodyUpdate->new(); # ServiceBodyUpdate | Pass in service body object

eval {
    $api_instance->update_service_body(service_body_id => $service_body_id, service_body_update => $service_body_update);
};
if ($@) {
    warn "Exception when calling RootServerApi->update_service_body: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **service_body_id** | **int**| ID of service body | 
 **service_body_update** | [**ServiceBodyUpdate**](ServiceBodyUpdate.md)| Pass in service body object | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **update_user**
> update_user(user_id => $user_id, user_update => $user_update)

Update single user

Updates a user.

### Example
```perl
use Data::Dumper;
use BmltClient::RootServerApi;
my $api_instance = BmltClient::RootServerApi->new(

    # Configure OAuth2 access token for authorization: bmltToken
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $user_id = 1; # int | ID of user
my $user_update = BmltClient::Object::UserUpdate->new(); # UserUpdate | Pass in user object

eval {
    $api_instance->update_user(user_id => $user_id, user_update => $user_update);
};
if ($@) {
    warn "Exception when calling RootServerApi->update_user: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **user_id** | **int**| ID of user | 
 **user_update** | [**UserUpdate**](UserUpdate.md)| Pass in user object | 

### Return type

void (empty response body)

### Authorization

[bmltToken](../README.md#bmltToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

