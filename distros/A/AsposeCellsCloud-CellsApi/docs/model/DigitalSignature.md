# AsposeCellsCloud::Object::DigitalSignature 

## Load the model package
```perl
use AsposeCellsCloud::Object::DigitalSignature;
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**Comments** | **string** | The purpose to signature. |
**SignTime** | **string** | The time when the document was signed. |
**Id** | **string** | Specifies a GUID which can be cross-referenced with the GUID of the signature line stored in the document content. Default value is Empty (all zeroes) Guid. |
**Password** | **string** | Specifies the text of actual signature in the digital signature. Default value is Empty.             |
**Image** | **ARRAY[byte?]** | Specifies an image for the digital signature. Default value is null. |
**ProviderId** | **string** | Specifies the class ID of the signature provider. Default value is Empty (all zeroes) Guid.             |
**IsValid** | **boolean** | If this digital signature is valid and the document has not been tampered with, this value will be true. |
**XAdESType** | **string** | XAdES type. Default value is None(XAdES is off). |  

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)

