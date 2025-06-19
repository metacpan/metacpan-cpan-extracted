# **Spreadsheet Cloud API: postAccessToken**

Get Access Token Result: The Cells Cloud Get Token API acts as a proxy service,forwarding user requests to the Aspose Cloud authentication server and returning the resulting access token to the client. 


## **Quick Start**

- **Base URL**: `http://api.aspose.cloud/v4.0`
- **Authentication Method**: `JWT (OAuth2, application)`  **Token URL**: `https://api.aspose.cloud/connect/token`
## **Interface Details**

### **Endpoint** 

```
POST http://api.aspose.cloud/v4.0/cells/connect/token
```
### **Function Description**
- This API acts as an intermediary proxy, transparently forwarding client authentication requests to the Aspose Cloud authorization service.- Upon successful authentication, the access token issued by Aspose Cloud is returned intact to the caller.- Use cases: Middleware systems requiring integration with Aspose Cloud services that delegate OAuth or similar authentication processes.- Considerations:▸ Ensure valid Aspose Cloud API credentials are registered before invocation.▸ Should be invoked over HTTPS secure channels to prevent token leakage.▸ Securely store returned access tokens and implement proper expiration management.▸ Handle potential error responses (e.g., 401 Unauthorized, 503 Service Unavailable).

### The request parameters of **postAccessToken** API are: 

| Parameter Name | Type | Path/Query String/HTTPBody | Description | 
| :- | :- | :- |:- | 

### **Response Description**
```json
{
String
}
```


## OpenAPI Specification

The [OpenAPI Specification](https://reference.aspose.cloud/cells/#/CellsAuthorityController/PostAccessToken) defines a publicly accessible programming interface and lets you carry out REST interactions directly from a web browser.
