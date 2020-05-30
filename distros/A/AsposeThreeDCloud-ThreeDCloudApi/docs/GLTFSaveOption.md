# AsposeThreeDCloud::Object::GLTFSaveOption

## Load the model package
```perl
use AsposeThreeDCloud::Object::GLTFSaveOption;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**save_format** | [**SaveFormat**](SaveFormat.md) | Gets or sets  of the SaveFormat. | [optional] 
**lookup_paths** | **ARRAY[string]** | Some files like OBJ depends on external file, the lookup paths will allows Aspose.3D to look for external file to load | [optional] 
**file_name** | **string** | The file name of the exporting/importing scene. This is optional, but useful when serialize external assets like OBJ&#39;s material. | [optional] 
**file_format** | **string** | The file format like FBX,U3D,PDF .... | [optional] 
**pretty_print** | **boolean** | The JSON content of GLTF file is indented for human reading, default value is false. | [optional] 
**embed_assets** | **boolean** | Embed all external assets as base64 into single file in ASCII mode, default value is false. | [optional] 
**use_common_materials** | **boolean** | Serialize materials using KHR common material extensions, default value is false. Set this to false will cause Aspose.3D export a set of vertex/fragment shader if Aspose.ThreeD.Formats.GLTFSaveOptions.ExportShaders | [optional] 
**flip_tex_coord_v** | **boolean** | Flip texture coordinate v(t) component, default value is true. | [optional] 
**buffer_file** | **boolean** | The file name of the external buffer file used to store binary data. If this file is not specified, Aspose.3D will generate a name for you. This is ignored when export glTF in binary mode. | [optional] 
**save_extras** | **boolean** | Save scene object&#39;s dynamic properties into &#39;extra&#39; fields in the generated glTF file. This is useful to provide application-specific data. Default value is false.. | [optional] 
**draco_compression** | **boolean** | Gets or sets whether to enable draco compression. | [optional] 
**file_content_type** | [**FileContentType**](FileContentType.md) | Gets or sets  of the FileContent type. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


