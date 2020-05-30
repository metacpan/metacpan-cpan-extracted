# AsposeThreeDCloud::Object::FBXSaveOption

## Load the model package
```perl
use AsposeThreeDCloud::Object::FBXSaveOption;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**save_format** | [**SaveFormat**](SaveFormat.md) | Gets or sets  of the SaveFormat. | [optional] 
**lookup_paths** | **ARRAY[string]** | Some files like OBJ depends on external file, the lookup paths will allows Aspose.3D to look for external file to load | [optional] 
**file_name** | **string** | The file name of the exporting/importing scene. This is optional, but useful when serialize external assets like OBJ&#39;s material. | [optional] 
**file_format** | **string** | The file format like FBX,U3D,PDF .... | [optional] 
**enable_compression** | **boolean** |  Compression large binary data in the FBX file, default value is true | [optional] 
**fold_repeated_curve_data** | **boolean** | Gets or sets whether reuse repeated curve data by increasing last data&#39;s ref count | [optional] 
**export_legacy_material_properties** | **boolean** | Gets or sets whether export legacy material properties, used for back compatibility. This option is turned on by default | [optional] 
**video_for_texture** | **boolean** | Gets or sets whether generate a Video instance for Aspose.ThreeD.Shading.Texture when exporting as FBX. | [optional] 
**generate_vertex_element_material** | **boolean** | Gets or sets whether always generate a Aspose.ThreeD.Entities.VertexElementMaterial for geometries if the attached node contains materials. This is turned off by default. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


