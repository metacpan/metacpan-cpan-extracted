# MCP server example

A minimal Catalyst app that loads `Catalyst::Plugin::JSONRPC::Server` and then
`Catalyst::Plugin::MCP`, mounting a Model Context Protocol (2025-06-18) server
at `/mcp`. It registers two providers: an `echo` tool that echoes back a `msg`
argument, and a static resource (`mem://greeting`) that returns a fixed
greeting string.

## Not a production shape

This example is deliberately minimal: `/mcp` is wide open, with no
authentication and no `Origin` check, so anything that can POST to it can run
the `echo` tool. That is fine for a localhost demo and wrong for real code.
Before copying this layout, read the `Security` section of the top-level README:
authentication and `Origin` validation are the application's job, and this
example does neither.

## Run it

```
plackup -p 5000 examples/app.psgi
perl examples/client.pl            # or: perl examples/client.pl http://127.0.0.1:5000
```

The client replays the MCP handshake: `initialize`, `tools/list`,
`tools/call` (the `echo` tool), then `resources/read` (the `mem://greeting`
resource).

## Expected output

```
--> {"id":1,"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-06-18"}}
<-- HTTP 200 {"id":1,"jsonrpc":"2.0","result":{"capabilities":{"resources":{},"tools":{}},"protocolVersion":"2025-06-18","serverInfo":{"name":"example-mcp","version":"0.001"}}}

--> {"id":2,"jsonrpc":"2.0","method":"tools/list"}
<-- HTTP 200 {"id":2,"jsonrpc":"2.0","result":{"tools":[{"description":"Echo back the msg argument","name":"echo"}]}}

--> {"id":3,"jsonrpc":"2.0","method":"tools/call","params":{"arguments":{"msg":"hi"},"name":"echo"}}
<-- HTTP 200 {"id":3,"jsonrpc":"2.0","result":{"content":[{"text":"echo: hi","type":"text"}]}}

--> {"id":4,"jsonrpc":"2.0","method":"resources/read","params":{"uri":"mem://greeting"}}
<-- HTTP 200 {"id":4,"jsonrpc":"2.0","result":{"contents":[{"text":"hello from the example resource","uri":"mem://greeting"}]}}
```
