# AsposeThreeDCloud::Object::DracoSaveOption

## Load the model package
```perl
use AsposeThreeDCloud::Object::DracoSaveOption;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**save_format** | [**SaveFormat**](SaveFormat.md) | Gets or sets  of the SaveFormat. | [optional] 
**lookup_paths** | **ARRAY[string]** | Some files like OBJ depends on external file, the lookup paths will allows Aspose.3D to look for external file to load | [optional] 
**file_name** | **string** | The file name of the exporting/importing scene. This is optional, but useful when serialize external assets like OBJ&#39;s material. | [optional] 
**file_format** | **string** | The file format like FBX,U3D,PDF .... | [optional] 
**position_bits** | **int** | Quantization bits for position, default value is 14 | [optional] 
**texture_coordinate_bits** | **int** | Quantization bits for texture coordinate, default value is 12 | [optional] 
**color_bits** | **int** | Quantization bits for vertex color, default value is 10 | [optional] 
**normal_bits** | **int** | Quantization bits for normal vectors, default value is 10 | [optional] 
**compression_level** | [**DracoCompressionLevel**](DracoCompressionLevel.md) | Compression level, default value is Aspose.ThreeD.Formats.DracoCompressionLevel.Standard. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


