# JSON-RPC server example

A minimal Catalyst app that mounts a JSON-RPC 2.0 endpoint at `/rpc` and registers
two methods: `echo` (returns its params) and `sum` (adds an array of numbers).

## Run it

```
plackup -p 5000 examples/app.psgi
perl examples/client.pl            # or: perl examples/client.pl http://127.0.0.1:5000
```

## Expected output

```
--> {"id":1,"jsonrpc":"2.0","method":"sum","params":[1,2,3,4]}
<-- HTTP 200 {"id":1,"jsonrpc":"2.0","result":10}

--> [{"id":2,"jsonrpc":"2.0","method":"echo","params":["hello"]},{"id":3,"jsonrpc":"2.0","method":"nope"}]
<-- HTTP 200 [{"id":2,"jsonrpc":"2.0","result":["hello"]},{"error":{"code":-32601,"message":"Method not found"},"id":3,"jsonrpc":"2.0"}]
```
