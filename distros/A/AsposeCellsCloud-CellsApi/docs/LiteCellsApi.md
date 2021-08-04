# AsposeCellsCloud::LiteCellsApi

## Load the API package
```perl
use AsposeCellsCloud::Object::LiteCellsApi;
```

All URIs are relative to *https://api.aspose.cloud/v3.0*

Method | HTTP request | Description
------------- | ------------- | -------------
[**delete_metadata**](LiteCellsApi.md#delete_metadata) | **POST** /cells/metadata/delete | 
[**get_metadata**](LiteCellsApi.md#get_metadata) | **POST** /cells/metadata/get | 
[**post_assemble**](LiteCellsApi.md#post_assemble) | **POST** /cells/assemble | 
[**post_clear_objects**](LiteCellsApi.md#post_clear_objects) | **POST** /cells/clearobjects | 
[**post_export**](LiteCellsApi.md#post_export) | **POST** /cells/export | 
[**post_merge**](LiteCellsApi.md#post_merge) | **POST** /cells/merge | 
[**post_metadata**](LiteCellsApi.md#post_metadata) | **POST** /cells/metadata/update | 
[**post_protect**](LiteCellsApi.md#post_protect) | **POST** /cells/protect | 
[**post_search**](LiteCellsApi.md#post_search) | **POST** /cells/search | 
[**post_split**](LiteCellsApi.md#post_split) | **POST** /cells/split | 
[**post_unlock**](LiteCellsApi.md#post_unlock) | **POST** /cells/unlock | 
[**post_watermark**](LiteCellsApi.md#post_watermark) | **POST** /cells/watermark | 


# **delete_metadata**
> FilesResult delete_metadata(file => $file, type => $type)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $type = 'type_example'; # string | 

eval { 
    my $result = $api_instance->delete_metadata(file => $file, type => $type);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->delete_metadata: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **string**| File to upload | 
 **type** | **string**|  | [optional] [default to all]

### Return type

[**FilesResult**](FilesResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_metadata**
> ARRAY[CellsDocumentProperty] get_metadata(file => $file, type => $type)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $type = 'type_example'; # string | 

eval { 
    my $result = $api_instance->get_metadata(file => $file, type => $type);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->get_metadata: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **string**| File to upload | 
 **type** | **string**|  | [optional] [default to all]

### Return type

[**ARRAY[CellsDocumentProperty]**](CellsDocumentProperty.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_assemble**
> FilesResult post_assemble(file => $file, datasource => $datasource, format => $format)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $datasource = 'datasource_example'; # string | 
my $format = 'format_example'; # string | 

eval { 
    my $result = $api_instance->post_assemble(file => $file, datasource => $datasource, format => $format);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->post_assemble: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **string**| File to upload | 
 **datasource** | **string**|  | 
 **format** | **string**|  | [optional] [default to Xlsx]

### Return type

[**FilesResult**](FilesResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_clear_objects**
> FilesResult post_clear_objects(file => $file, objecttype => $objecttype)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = '/path/to/file.txt'; # File | File to upload
my $objecttype = 'objecttype_example'; # string | 

eval { 
    my $result = $api_instance->post_clear_objects(file => $file, objecttype => $objecttype);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->post_clear_objects: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **File**| File to upload | 
 **objecttype** | **string**|  | 

### Return type

[**FilesResult**](FilesResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_export**
> FilesResult post_export(file => $file, object_type => $object_type, format => $format)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $object_type = 'object_type_example'; # string | 
my $format = 'format_example'; # string | 

eval { 
    my $result = $api_instance->post_export(file => $file, object_type => $object_type, format => $format);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->post_export: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **string**| File to upload | 
 **object_type** | **string**|  | 
 **format** | **string**|  | 

### Return type

[**FilesResult**](FilesResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_merge**
> FileInfo post_merge(file => $file, format => $format, merge_to_one_sheet => $merge_to_one_sheet)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $format = 'format_example'; # string | 
my $merge_to_one_sheet = 1; # boolean | 

eval { 
    my $result = $api_instance->post_merge(file => $file, format => $format, merge_to_one_sheet => $merge_to_one_sheet);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->post_merge: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **string**| File to upload | 
 **format** | **string**|  | [optional] [default to xlsx]
 **merge_to_one_sheet** | **boolean**|  | [optional] [default to false]

### Return type

[**FileInfo**](FileInfo.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_metadata**
> FilesResult post_metadata(file => $file, document_properties => $document_properties)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $document_properties = AsposeCellsCloud::Object::CellsDocumentProperty->new(); # CellsDocumentProperty | Cells document property.

eval { 
    my $result = $api_instance->post_metadata(file => $file, document_properties => $document_properties);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->post_metadata: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **string**| File to upload | 
 **document_properties** | [**CellsDocumentProperty**](CellsDocumentProperty.md)| Cells document property. | 

### Return type

[**FilesResult**](FilesResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: multipart/form-data

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_protect**
> FilesResult post_protect(file => $file, password => $password)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $password = 'password_example'; # string | 

eval { 
    my $result = $api_instance->post_protect(file => $file, password => $password);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->post_protect: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **string**| File to upload | 
 **password** | **string**|  | 

### Return type

[**FilesResult**](FilesResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_search**
> ARRAY[TextItem] post_search(file => $file, text => $text, password => $password)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $text = 'text_example'; # string | 
my $password = 'password_example'; # string | 

eval { 
    my $result = $api_instance->post_search(file => $file, text => $text, password => $password);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->post_search: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **string**| File to upload | 
 **text** | **string**|  | 
 **password** | **string**|  | [optional] 

### Return type

[**ARRAY[TextItem]**](TextItem.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_split**
> FilesResult post_split(file => $file, format => $format, password => $password, from => $from, to => $to)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $format = 'format_example'; # string | 
my $password = 'password_example'; # string | 
my $from = 56; # int | 
my $to = 56; # int | 

eval { 
    my $result = $api_instance->post_split(file => $file, format => $format, password => $password, from => $from, to => $to);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->post_split: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **string**| File to upload | 
 **format** | **string**|  | 
 **password** | **string**|  | [optional] 
 **from** | **int**|  | [optional] 
 **to** | **int**|  | [optional] 

### Return type

[**FilesResult**](FilesResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_unlock**
> FilesResult post_unlock(file => $file, password => $password)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = AsposeCellsCloud::Object::string->new(); # string | File to upload
my $password = 'password_example'; # string | 

eval { 
    my $result = $api_instance->post_unlock(file => $file, password => $password);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->post_unlock: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **string**| File to upload | 
 **password** | **string**|  | 

### Return type

[**FilesResult**](FilesResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_watermark**
> FilesResult post_watermark(file => $file, text => $text, color => $color)



### Example 
```perl
use Data::Dumper;
use AsposeCellsCloud::LiteCellsApi;
my $api_instance = AsposeCellsCloud::LiteCellsApi->new(
);

my $file = '/path/to/file.txt'; # File | File to upload
my $text = 'text_example'; # string | 
my $color = 'color_example'; # string | 

eval { 
    my $result = $api_instance->post_watermark(file => $file, text => $text, color => $color);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling LiteCellsApi->post_watermark: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **file** | **File**| File to upload | 
 **text** | **string**|  | 
 **color** | **string**|  | 

### Return type

[**FilesResult**](FilesResult.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

