# AsposeThreeDCloud::Object::HTMLSaveOption

## Load the model package
```perl
use AsposeThreeDCloud::Object::HTMLSaveOption;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**save_format** | [**SaveFormat**](SaveFormat.md) | Gets or sets  of the SaveFormat. | [optional] 
**lookup_paths** | **ARRAY[string]** | Some files like OBJ depends on external file, the lookup paths will allows Aspose.3D to look for external file to load | [optional] 
**file_name** | **string** | The file name of the exporting/importing scene. This is optional, but useful when serialize external assets like OBJ&#39;s material. | [optional] 
**file_format** | **string** | The file format like FBX,U3D,PDF .... | [optional] 
**show_grid** | **boolean** |  Display a grid in the scene. Default value is true. | [optional] 
**show_rulers** | **boolean** |  Display rulers of x/y/z axises in the scene to measure the model. Default value is false | [optional] 
**show_ui** | **boolean** | Display a simple UI in the scene. Default value is true | [optional] 
**orientation_box** | **boolean** | Display a orientation box. Default value is true. | [optional] 
**up_vector** | **string** | Gets or sets the up vector, value can be \&quot;x\&quot;/\&quot;y\&quot;/\&quot;z\&quot;, default value is \&quot;y\&quot;. | [optional] 
**far_plane** | **double** | Gets or sets the far plane of the camera, default value is 1000 | [optional] 
**near_plane** | **double** | Gets or sets the near plane of the camera, default value is 1 | [optional] 
**look_at** | [**Vector3**](Vector3.md) | Gets or sets the default look at position, default value is (0, 0, 0) | [optional] 
**camera_position** | [**Vector3**](Vector3.md) | Gets or sets the initial position of the camera, default value is (10, 10, 10) | [optional] 
**field_of_view** | **double** |  Gets or sets the field of the view, default value is 45, measured in degree | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


