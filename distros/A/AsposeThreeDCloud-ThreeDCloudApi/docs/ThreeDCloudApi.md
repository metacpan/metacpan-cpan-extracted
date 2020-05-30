# AsposeThreeDCloud::ThreeDCloudApi

## Load the API package
```perl
use AsposeThreeDCloud::Object::ThreeDCloudApi;
```

All URIs are relative to *https://api.aspose.cloud/v3.0*

Method | HTTP request | Description
------------- | ------------- | -------------
[**copy_file**](ThreeDCloudApi.md#copy_file) | **PUT** /3d/storage/file/copy/{srcPath} | Copy file
[**copy_folder**](ThreeDCloudApi.md#copy_folder) | **PUT** /3d/storage/folder/copy/{srcPath} | Copy folder
[**create_folder**](ThreeDCloudApi.md#create_folder) | **PUT** /3d/storage/folder/{path} | Create the folder
[**delete_file**](ThreeDCloudApi.md#delete_file) | **DELETE** /3d/storage/file/{path} | Delete file
[**delete_folder**](ThreeDCloudApi.md#delete_folder) | **DELETE** /3d/storage/folder/{path} | Delete folder
[**delete_nodes**](ThreeDCloudApi.md#delete_nodes) | **DELETE** /3d/nodes | Delete nodes from scene,nodes are addressed by Object Addressing Path
[**download_file**](ThreeDCloudApi.md#download_file) | **GET** /3d/storage/file/{path} | Download file
[**get_disc_usage**](ThreeDCloudApi.md#get_disc_usage) | **GET** /3d/storage/disc | Get disc usage
[**get_file_versions**](ThreeDCloudApi.md#get_file_versions) | **GET** /3d/storage/version/{path} | Get file versions
[**get_files_list**](ThreeDCloudApi.md#get_files_list) | **GET** /3d/storage/folder/{path} | Get all files and folders within a folder
[**move_file**](ThreeDCloudApi.md#move_file) | **PUT** /3d/storage/file/move/{srcPath} | Move file
[**move_folder**](ThreeDCloudApi.md#move_folder) | **PUT** /3d/storage/folder/move/{srcPath} | Move folder
[**o_auth_post**](ThreeDCloudApi.md#o_auth_post) | **POST** /connect/token | Get Access token
[**object_exists**](ThreeDCloudApi.md#object_exists) | **GET** /3d/storage/exist/{path} | Check if file or folder exists
[**post_convert_by_format**](ThreeDCloudApi.md#post_convert_by_format) | **POST** /3d/saveas/newformat | Convert file on server to other formats with fileformat parameter             
[**post_convert_by_opt**](ThreeDCloudApi.md#post_convert_by_opt) | **POST** /3d/saveas/saveoption | Convert file on server to other formats with saveOption parameter             
[**post_create**](ThreeDCloudApi.md#post_create) | **POST** /3d/new | Create new file with specified format.             
[**post_model**](ThreeDCloudApi.md#post_model) | **POST** /3d/root | Parametric Modeling, Create a Entity with size and located in ...
[**post_pdf_raw_data**](ThreeDCloudApi.md#post_pdf_raw_data) | **POST** /3d/extract/rawdata | Extract raw data(without any modification) from a password protected PDF file             
[**post_save_as_part**](ThreeDCloudApi.md#post_save_as_part) | **POST** /3d/saveas/part | Convert part of the file into different format
[**post_scene_to_file**](ThreeDCloudApi.md#post_scene_to_file) | **POST** /3d/extract/scene | Extract and save in different format             
[**post_triangulate_new**](ThreeDCloudApi.md#post_triangulate_new) | **POST** /3d/triangulate/new | Triangulate whole file and save to the different file
[**post_triangulate_original**](ThreeDCloudApi.md#post_triangulate_original) | **POST** /3d/triangulate/original | Triangulate whole file and save to original file
[**post_triangulate_part**](ThreeDCloudApi.md#post_triangulate_part) | **POST** /3d/triangulate/part | Triangulate part of the scene(Specified by OAP) and save the scene to different file 
[**storage_exists**](ThreeDCloudApi.md#storage_exists) | **GET** /3d/storage/{storageName}/exist | Check if storage exists
[**upload_file**](ThreeDCloudApi.md#upload_file) | **PUT** /3d/storage/file/{path} | Upload file


# **copy_file**
> copy_file(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name, version_id => $version_id)

Copy file

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $src_path = 'src_path_example'; # string | Source file path e.g. '/folder/file.ext'
my $dest_path = 'dest_path_example'; # string | Destination file path
my $src_storage_name = 'src_storage_name_example'; # string | Source storage name
my $dest_storage_name = 'dest_storage_name_example'; # string | Destination storage name
my $version_id = 'version_id_example'; # string | File version ID to copy

eval { 
    $api_instance->copy_file(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name, version_id => $version_id);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->copy_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **src_path** | **string**| Source file path e.g. &#39;/folder/file.ext&#39; | 
 **dest_path** | **string**| Destination file path | 
 **src_storage_name** | **string**| Source storage name | [optional] 
 **dest_storage_name** | **string**| Destination storage name | [optional] 
 **version_id** | **string**| File version ID to copy | [optional] 

### Return type

void (empty response body)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **copy_folder**
> copy_folder(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name)

Copy folder

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $src_path = 'src_path_example'; # string | Source folder path e.g. '/src'
my $dest_path = 'dest_path_example'; # string | Destination folder path e.g. '/dst'
my $src_storage_name = 'src_storage_name_example'; # string | Source storage name
my $dest_storage_name = 'dest_storage_name_example'; # string | Destination storage name

eval { 
    $api_instance->copy_folder(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->copy_folder: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **src_path** | **string**| Source folder path e.g. &#39;/src&#39; | 
 **dest_path** | **string**| Destination folder path e.g. &#39;/dst&#39; | 
 **src_storage_name** | **string**| Source storage name | [optional] 
 **dest_storage_name** | **string**| Destination storage name | [optional] 

### Return type

void (empty response body)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **create_folder**
> create_folder(path => $path, storage_name => $storage_name)

Create the folder

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $path = 'path_example'; # string | Folder path to create e.g. 'folder_1/folder_2/'
my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    $api_instance->create_folder(path => $path, storage_name => $storage_name);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->create_folder: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| Folder path to create e.g. &#39;folder_1/folder_2/&#39; | 
 **storage_name** | **string**| Storage name | [optional] 

### Return type

void (empty response body)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_file**
> delete_file(path => $path, storage_name => $storage_name, version_id => $version_id)

Delete file

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $path = 'path_example'; # string | File path e.g. '/folder/file.ext'
my $storage_name = 'storage_name_example'; # string | Storage name
my $version_id = 'version_id_example'; # string | File version ID to delete

eval { 
    $api_instance->delete_file(path => $path, storage_name => $storage_name, version_id => $version_id);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->delete_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| File path e.g. &#39;/folder/file.ext&#39; | 
 **storage_name** | **string**| Storage name | [optional] 
 **version_id** | **string**| File version ID to delete | [optional] 

### Return type

void (empty response body)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_folder**
> delete_folder(path => $path, storage_name => $storage_name, recursive => $recursive)

Delete folder

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $path = 'path_example'; # string | Folder path e.g. '/folder'
my $storage_name = 'storage_name_example'; # string | Storage name
my $recursive = 1; # boolean | Enable to delete folders, subfolders and files

eval { 
    $api_instance->delete_folder(path => $path, storage_name => $storage_name, recursive => $recursive);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->delete_folder: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| Folder path e.g. &#39;/folder&#39; | 
 **storage_name** | **string**| Storage name | [optional] 
 **recursive** | **boolean**| Enable to delete folders, subfolders and files | [optional] [default to false]

### Return type

void (empty response body)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **delete_nodes**
> File delete_nodes(name => $name, objectaddressingpath => $objectaddressingpath, folder => $folder, storage => $storage)

Delete nodes from scene,nodes are addressed by Object Addressing Path

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $name = 'name_example'; # string | The name of the source file.
my $objectaddressingpath = 'objectaddressingpath_example'; # string | The object addressing path.
my $folder = 'folder_example'; # string | The folder of the source file.
my $storage = 'storage_example'; # string | The storage type

eval { 
    my $result = $api_instance->delete_nodes(name => $name, objectaddressingpath => $objectaddressingpath, folder => $folder, storage => $storage);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->delete_nodes: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The name of the source file. | 
 **objectaddressingpath** | **string**| The object addressing path. | 
 **folder** | **string**| The folder of the source file. | [optional] 
 **storage** | **string**| The storage type | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **download_file**
> File download_file(path => $path, storage_name => $storage_name, version_id => $version_id)

Download file

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $path = 'path_example'; # string | File path e.g. '/folder/file.ext'
my $storage_name = 'storage_name_example'; # string | Storage name
my $version_id = 'version_id_example'; # string | File version ID to download

eval { 
    my $result = $api_instance->download_file(path => $path, storage_name => $storage_name, version_id => $version_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->download_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| File path e.g. &#39;/folder/file.ext&#39; | 
 **storage_name** | **string**| Storage name | [optional] 
 **version_id** | **string**| File version ID to download | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: multipart/form-data

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_disc_usage**
> DiscUsage get_disc_usage(storage_name => $storage_name)

Get disc usage

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    my $result = $api_instance->get_disc_usage(storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->get_disc_usage: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **storage_name** | **string**| Storage name | [optional] 

### Return type

[**DiscUsage**](DiscUsage.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_file_versions**
> FileVersions get_file_versions(path => $path, storage_name => $storage_name)

Get file versions

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $path = 'path_example'; # string | File path e.g. '/file.ext'
my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    my $result = $api_instance->get_file_versions(path => $path, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->get_file_versions: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| File path e.g. &#39;/file.ext&#39; | 
 **storage_name** | **string**| Storage name | [optional] 

### Return type

[**FileVersions**](FileVersions.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **get_files_list**
> FilesList get_files_list(path => $path, storage_name => $storage_name)

Get all files and folders within a folder

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $path = 'path_example'; # string | Folder path e.g. '/folder'
my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    my $result = $api_instance->get_files_list(path => $path, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->get_files_list: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| Folder path e.g. &#39;/folder&#39; | 
 **storage_name** | **string**| Storage name | [optional] 

### Return type

[**FilesList**](FilesList.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **move_file**
> move_file(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name, version_id => $version_id)

Move file

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $src_path = 'src_path_example'; # string | Source file path e.g. '/src.ext'
my $dest_path = 'dest_path_example'; # string | Destination file path e.g. '/dest.ext'
my $src_storage_name = 'src_storage_name_example'; # string | Source storage name
my $dest_storage_name = 'dest_storage_name_example'; # string | Destination storage name
my $version_id = 'version_id_example'; # string | File version ID to move

eval { 
    $api_instance->move_file(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name, version_id => $version_id);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->move_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **src_path** | **string**| Source file path e.g. &#39;/src.ext&#39; | 
 **dest_path** | **string**| Destination file path e.g. &#39;/dest.ext&#39; | 
 **src_storage_name** | **string**| Source storage name | [optional] 
 **dest_storage_name** | **string**| Destination storage name | [optional] 
 **version_id** | **string**| File version ID to move | [optional] 

### Return type

void (empty response body)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **move_folder**
> move_folder(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name)

Move folder

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $src_path = 'src_path_example'; # string | Folder path to move e.g. '/folder'
my $dest_path = 'dest_path_example'; # string | Destination folder path to move to e.g '/dst'
my $src_storage_name = 'src_storage_name_example'; # string | Source storage name
my $dest_storage_name = 'dest_storage_name_example'; # string | Destination storage name

eval { 
    $api_instance->move_folder(src_path => $src_path, dest_path => $dest_path, src_storage_name => $src_storage_name, dest_storage_name => $dest_storage_name);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->move_folder: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **src_path** | **string**| Folder path to move e.g. &#39;/folder&#39; | 
 **dest_path** | **string**| Destination folder path to move to e.g &#39;/dst&#39; | 
 **src_storage_name** | **string**| Source storage name | [optional] 
 **dest_storage_name** | **string**| Destination storage name | [optional] 

### Return type

void (empty response body)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **o_auth_post**
> AccessTokenResponse o_auth_post(grant_type => $grant_type, client_id => $client_id, client_secret => $client_secret)

Get Access token

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(
);

my $grant_type = 'grant_type_example'; # string | Grant Type
my $client_id = 'client_id_example'; # string | App SID
my $client_secret = 'client_secret_example'; # string | App Key

eval { 
    my $result = $api_instance->o_auth_post(grant_type => $grant_type, client_id => $client_id, client_secret => $client_secret);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->o_auth_post: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **grant_type** | **string**| Grant Type | 
 **client_id** | **string**| App SID | 
 **client_secret** | **string**| App Key | 

### Return type

[**AccessTokenResponse**](AccessTokenResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/x-www-form-urlencoded
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **object_exists**
> ObjectExist object_exists(path => $path, storage_name => $storage_name, version_id => $version_id)

Check if file or folder exists

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $path = 'path_example'; # string | File or folder path e.g. '/file.ext' or '/folder'
my $storage_name = 'storage_name_example'; # string | Storage name
my $version_id = 'version_id_example'; # string | File version ID

eval { 
    my $result = $api_instance->object_exists(path => $path, storage_name => $storage_name, version_id => $version_id);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->object_exists: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| File or folder path e.g. &#39;/file.ext&#39; or &#39;/folder&#39; | 
 **storage_name** | **string**| Storage name | [optional] 
 **version_id** | **string**| File version ID | [optional] 

### Return type

[**ObjectExist**](ObjectExist.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_convert_by_format**
> File post_convert_by_format(name => $name, newformat => $newformat, newfilename => $newfilename, folder => $folder, is_overwrite => $is_overwrite, storage => $storage)

Convert file on server to other formats with fileformat parameter             

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $name = 'name_example'; # string | The name of the source file.
my $newformat = 'newformat_example'; # string | The format of the new file.
my $newfilename = 'newfilename_example'; # string | The name of the new file.
my $folder = 'folder_example'; # string | The folder of the source file.
my $is_overwrite = 1; # boolean | Overwrite the source file? true or false.
my $storage = 'storage_example'; # string | The storage type.

eval { 
    my $result = $api_instance->post_convert_by_format(name => $name, newformat => $newformat, newfilename => $newfilename, folder => $folder, is_overwrite => $is_overwrite, storage => $storage);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->post_convert_by_format: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The name of the source file. | 
 **newformat** | **string**| The format of the new file. | 
 **newfilename** | **string**| The name of the new file. | 
 **folder** | **string**| The folder of the source file. | [optional] 
 **is_overwrite** | **boolean**| Overwrite the source file? true or false. | [optional] [default to false]
 **storage** | **string**| The storage type. | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_convert_by_opt**
> File post_convert_by_opt(name => $name, save_options => $save_options, newfilename => $newfilename, folder => $folder, is_overwrite => $is_overwrite, storage => $storage)

Convert file on server to other formats with saveOption parameter             

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $name = 'name_example'; # string | The name of the source file.
my $save_options = AsposeThreeDCloud::Object::SaveOptions->new(); # SaveOptions | The saveOptions to save the file
my $newfilename = 'newfilename_example'; # string | The name of the new file
my $folder = 'folder_example'; # string | The folder of the source file
my $is_overwrite = 1; # boolean | Overwrite the source file? true or false
my $storage = 'storage_example'; # string | The storage type

eval { 
    my $result = $api_instance->post_convert_by_opt(name => $name, save_options => $save_options, newfilename => $newfilename, folder => $folder, is_overwrite => $is_overwrite, storage => $storage);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->post_convert_by_opt: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The name of the source file. | 
 **save_options** | [**SaveOptions**](SaveOptions.md)| The saveOptions to save the file | 
 **newfilename** | **string**| The name of the new file | 
 **folder** | **string**| The folder of the source file | [optional] 
 **is_overwrite** | **boolean**| Overwrite the source file? true or false | [optional] [default to false]
 **storage** | **string**| The storage type | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_create**
> File post_create(format => $format)

Create new file with specified format.             

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $format = 'format_example'; # string | The format of the new file.

eval { 
    my $result = $api_instance->post_create(format => $format);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->post_create: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **format** | **string**| The format of the new file. | 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: multipart/form-data

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_model**
> File post_model(name => $name, modeldata => $modeldata, newformat => $newformat, folder => $folder, storage => $storage)

Parametric Modeling, Create a Entity with size and located in ...

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $name = 'name_example'; # string | The name of the source file.
my $modeldata = AsposeThreeDCloud::Object::ModelData->new(); # ModelData | ModelData struct.
my $newformat = 'newformat_example'; # string | new format of the source file.
my $folder = 'folder_example'; # string | The folder of the source file.
my $storage = 'storage_example'; # string | The storage type

eval { 
    my $result = $api_instance->post_model(name => $name, modeldata => $modeldata, newformat => $newformat, folder => $folder, storage => $storage);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->post_model: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The name of the source file. | 
 **modeldata** | [**ModelData**](ModelData.md)| ModelData struct. | 
 **newformat** | **string**| new format of the source file. | [optional] 
 **folder** | **string**| The folder of the source file. | [optional] 
 **storage** | **string**| The storage type | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_pdf_raw_data**
> File post_pdf_raw_data(name => $name, multifileprefix => $multifileprefix, password => $password, folder => $folder, storage => $storage)

Extract raw data(without any modification) from a password protected PDF file             

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $name = 'name_example'; # string | The PDF file's mame
my $multifileprefix = 'multifileprefix_example'; # string | The file name for generated raw date
my $password = 'password_example'; # string | The password to open the PDF
my $folder = 'folder_example'; # string | The folder for source file
my $storage = 'storage_example'; # string | The storage type

eval { 
    my $result = $api_instance->post_pdf_raw_data(name => $name, multifileprefix => $multifileprefix, password => $password, folder => $folder, storage => $storage);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->post_pdf_raw_data: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The PDF file&#39;s mame | 
 **multifileprefix** | **string**| The file name for generated raw date | 
 **password** | **string**| The password to open the PDF | [optional] 
 **folder** | **string**| The folder for source file | [optional] 
 **storage** | **string**| The storage type | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_save_as_part**
> File post_save_as_part(name => $name, objectaddressingpath => $objectaddressingpath, newformat => $newformat, newfilename => $newfilename, folder => $folder, is_overwrite => $is_overwrite, storage => $storage)

Convert part of the file into different format

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $name = 'name_example'; # string | The name of the source file
my $objectaddressingpath = 'objectaddressingpath_example'; # string | The object addressing path
my $newformat = 'newformat_example'; # string | The format of the new file
my $newfilename = 'newfilename_example'; # string | The name of the new file
my $folder = 'folder_example'; # string | The folder of the source file
my $is_overwrite = 1; # boolean | Overwrite the source file? true or false
my $storage = 'storage_example'; # string | The storage type

eval { 
    my $result = $api_instance->post_save_as_part(name => $name, objectaddressingpath => $objectaddressingpath, newformat => $newformat, newfilename => $newfilename, folder => $folder, is_overwrite => $is_overwrite, storage => $storage);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->post_save_as_part: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The name of the source file | 
 **objectaddressingpath** | **string**| The object addressing path | 
 **newformat** | **string**| The format of the new file | 
 **newfilename** | **string**| The name of the new file | 
 **folder** | **string**| The folder of the source file | [optional] 
 **is_overwrite** | **boolean**| Overwrite the source file? true or false | [optional] [default to false]
 **storage** | **string**| The storage type | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_scene_to_file**
> File post_scene_to_file(name => $name, multifileprefix => $multifileprefix, newformat => $newformat, password => $password, folder => $folder, storage => $storage)

Extract and save in different format             

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $name = 'name_example'; # string | The PDF file's mame
my $multifileprefix = 'multifileprefix_example'; # string | The file name for extracted scene
my $newformat = 'newformat_example'; # string | The format of new file
my $password = 'password_example'; # string | The password to open the PDF
my $folder = 'folder_example'; # string | The folder for source file
my $storage = 'storage_example'; # string | The storage type

eval { 
    my $result = $api_instance->post_scene_to_file(name => $name, multifileprefix => $multifileprefix, newformat => $newformat, password => $password, folder => $folder, storage => $storage);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->post_scene_to_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The PDF file&#39;s mame | 
 **multifileprefix** | **string**| The file name for extracted scene | 
 **newformat** | **string**| The format of new file | [optional] 
 **password** | **string**| The password to open the PDF | [optional] 
 **folder** | **string**| The folder for source file | [optional] 
 **storage** | **string**| The storage type | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_triangulate_new**
> File post_triangulate_new(name => $name, newfilename => $newfilename, newformat => $newformat, folder => $folder, storage => $storage)

Triangulate whole file and save to the different file

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $name = 'name_example'; # string | The file's mame
my $newfilename = 'newfilename_example'; # string | The new file's mame
my $newformat = 'newformat_example'; # string | The new file's format
my $folder = 'folder_example'; # string | The folder for source file
my $storage = 'storage_example'; # string | The storage type

eval { 
    my $result = $api_instance->post_triangulate_new(name => $name, newfilename => $newfilename, newformat => $newformat, folder => $folder, storage => $storage);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->post_triangulate_new: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The file&#39;s mame | 
 **newfilename** | **string**| The new file&#39;s mame | 
 **newformat** | **string**| The new file&#39;s format | 
 **folder** | **string**| The folder for source file | [optional] 
 **storage** | **string**| The storage type | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_triangulate_original**
> File post_triangulate_original(name => $name, folder => $folder, storage => $storage)

Triangulate whole file and save to original file

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $name = 'name_example'; # string | The file's mame
my $folder = 'folder_example'; # string | The folder for source file
my $storage = 'storage_example'; # string | The storage type

eval { 
    my $result = $api_instance->post_triangulate_original(name => $name, folder => $folder, storage => $storage);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->post_triangulate_original: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The file&#39;s mame | 
 **folder** | **string**| The folder for source file | [optional] 
 **storage** | **string**| The storage type | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **post_triangulate_part**
> File post_triangulate_part(name => $name, objectaddressingpath => $objectaddressingpath, newfilename => $newfilename, newformat => $newformat, folder => $folder, storage => $storage)

Triangulate part of the scene(Specified by OAP) and save the scene to different file 

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $name = 'name_example'; # string | The file's mame
my $objectaddressingpath = 'objectaddressingpath_example'; # string | The node or mesh getted by OAP.
my $newfilename = 'newfilename_example'; # string | The new file's mame
my $newformat = 'newformat_example'; # string | The new file's format
my $folder = 'folder_example'; # string | The folder for source file
my $storage = 'storage_example'; # string | The storage type

eval { 
    my $result = $api_instance->post_triangulate_part(name => $name, objectaddressingpath => $objectaddressingpath, newfilename => $newfilename, newformat => $newformat, folder => $folder, storage => $storage);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->post_triangulate_part: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **name** | **string**| The file&#39;s mame | 
 **objectaddressingpath** | **string**| The node or mesh getted by OAP. | 
 **newfilename** | **string**| The new file&#39;s mame | 
 **newformat** | **string**| The new file&#39;s format | 
 **folder** | **string**| The folder for source file | [optional] 
 **storage** | **string**| The storage type | [optional] 

### Return type

[**File**](File.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **storage_exists**
> StorageExist storage_exists(storage_name => $storage_name)

Check if storage exists

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    my $result = $api_instance->storage_exists(storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->storage_exists: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **storage_name** | **string**| Storage name | 

### Return type

[**StorageExist**](StorageExist.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **upload_file**
> FilesUploadResult upload_file(path => $path, file => $file, storage_name => $storage_name)

Upload file

### Example 
```perl
use Data::Dumper;
use AsposeThreeDCloud::ThreeDCloudApi;
my $api_instance = AsposeThreeDCloud::ThreeDCloudApi->new(

    # Configure OAuth2 access token for authorization: JWT
    access_token => 'YOUR_ACCESS_TOKEN',
);

my $path = 'path_example'; # string | Path where to upload including filename and extension e.g. /file.ext or /Folder 1/file.ext             If the content is multipart and path does not contains the file name it tries to get them from filename parameter             from Content-Disposition header.             
my $file = '/path/to/file.txt'; # File | File to upload
my $storage_name = 'storage_name_example'; # string | Storage name

eval { 
    my $result = $api_instance->upload_file(path => $path, file => $file, storage_name => $storage_name);
    print Dumper($result);
};
if ($@) {
    warn "Exception when calling ThreeDCloudApi->upload_file: $@\n";
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **path** | **string**| Path where to upload including filename and extension e.g. /file.ext or /Folder 1/file.ext             If the content is multipart and path does not contains the file name it tries to get them from filename parameter             from Content-Disposition header.              | 
 **file** | **File**| File to upload | 
 **storage_name** | **string**| Storage name | [optional] 

### Return type

[**FilesUploadResult**](FilesUploadResult.md)

### Authorization

[JWT](../README.md#JWT)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

