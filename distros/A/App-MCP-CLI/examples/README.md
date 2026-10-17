# Examples for App::MCP::CLI

This directory contains two small example MCP servers and a sample
configuration file. Together they let you try every `mcpcli` sub-command
without needing any third-party MCP server.

| File                | What it is                                                        |
| ------------------- | ----------------------------------------------------------------- |
| `stdio_server.pl`   | A real MCP server (stdio transport) exposing one tool, `add_numbers`. |
| `sse_server.pl`     | A minimal **mock** HTTP/SSE server exposing one tool, `get_mock_weather`. |
| `server_config.json`| A config file that registers both servers under friendly names.   |

All commands below assume you run them **from this `examples/` directory**.
`server_config.json` is found automatically only when it is in the current
directory, and it refers to `stdio_server.pl` by a relative path.

```sh
cd examples
```

## Prerequisites

`mcpcli` itself needs the modules listed in `Makefile.PL`. The examples need a
few extra modules that are **not** installed with `App::MCP::CLI`:

| Example           | Extra requirement                                            | Install                  |
| ----------------- | ------------------------------------------------------------ | ------------------------ |
| `stdio_server.pl` | `MCP::Server`, shipped in the CPAN `MCP` distribution (needs Perl 5.20 or newer) | `cpanm MCP`              |
| `sse_server.pl`   | `HTTP::Daemon` (plus `JSON::MaybeXS`, already required)      | `cpanm HTTP::Daemon`     |
| `chat` command    | A running [Ollama](https://ollama.com) on `localhost:11434`  | `ollama pull qwen2.5:1.5b` |

If you have not installed `mcpcli` yet, replace `mcpcli` with
`perl ../script/mcpcli` in every command below.

## `server_config.json`

```json
{
  "mcpServers": {
    "perl-math-server": {
      "command": "perl",
      "args": ["stdio_server.pl"]
    },
    "weather-sse-service": {
      "transport": "sse",
      "url": "http://localhost:8080/sse"
    }
  },
  "confirmTools": false
}
```

* `perl-math-server` is launched as a child process and spoken to over
  stdin/stdout (stdio transport).
* `weather-sse-service` is contacted over HTTP/SSE at the given URL.
* `confirmTools: false` lets the `chat` command run tools without asking for
  a `y/N` confirmation each time. Set it to `true` (the default when the key is
  absent) if you want to approve every call.

See `perldoc App::MCP::CLI::Config` for the full file format.

Check that the file is read correctly:

```sh
mcpcli servers
```

This prints a table with one row per server and its transport (`stdio` or
`SSE`).

## Example 1: stdio server (`stdio_server.pl`)

This server registers a single tool:

| Tool          | Arguments                  | Result                                  |
| ------------- | -------------------------- | --------------------------------------- |
| `add_numbers` | `a` (number), `b` (number) | A sentence containing the sum of `a` and `b` |

You do not start this server yourself: `mcpcli` launches it on demand, as
described by the `command` and `args` entries in the config file.

**List the tools**

```sh
mcpcli list --server perl-math-server
```

**Call the tool with inline arguments**

```sh
mcpcli call add_numbers --server perl-math-server a=10 b=5
```

Expected response text:

```
The result of adding 10 and 5 is 15.
```

**Call the tool interactively.** Omit the arguments and `mcpcli` reads the
tool's input schema and prompts for each property. Required fields are marked
`(required)`.

```sh
mcpcli call add_numbers --server perl-math-server
```

**Talk to it in natural language** (requires Ollama):

Follow this to install `Ollama` first:

```sh
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```

Then pull the model `qwen2.5:1.5b`, the default model used by the `mcpcli`.

This can be overriden by the switch `--model` flag.

```sh
docker exec -it ollama ollama pull qwen2.5:1.5b
```

Verify if the model is installed:

```sh
docker exec -it ollama ollama list
```

Now start the `mcpcli` session in `chat` mode:

```sh
mcpcli chat --server perl-math-server
```

```
You> what is 12 plus 30?
```

The local model decides whether to call `add_numbers`, `mcpcli` executes the
call, and the model summarises the result. Type `exit` or `quit` to leave.

You can also skip the config file and give a script path directly:

```sh
mcpcli chat --server ./stdio_server.pl
```

## Example 2: SSE server (`sse_server.pl`)

`sse_server.pl` is a deliberately small **stub** for trying out the HTTP/SSE
code path. It is not a complete or spec-compliant MCP server. In particular:

* It always answers `get_mock_weather` with the same fixed text
  (21°C and clear skies) and ignores the `location` argument.
* It returns each JSON-RPC response in the body of the HTTP `POST` reply.
  A real HTTP+SSE server delivers responses as `message` events on the SSE
  stream instead.
* It handles one client at a time and has no authentication.

Use it for local experiments only, and keep it bound to `127.0.0.1` (the
default).

**Start the server.** It listens on `127.0.0.1:8080`, which is what
`server_config.json` expects:

```sh
perl sse_server.pl
```

Leave it running and open a second terminal in the same directory. The
following environment variables are supported (if you change the port, change
the `url` in `server_config.json` too):

| Variable   | Default     | Meaning                    |
| ---------- | ----------- | -------------------------- |
| `SSE_HOST` | `127.0.0.1` | Address to listen on       |
| `SSE_PORT` | `8080`      | TCP port to listen on      |

**List the tools and call the tool:**

```sh
mcpcli list --server weather-sse-service
mcpcli call get_mock_weather --server weather-sse-service location=London
```

**Chat with it** (requires Ollama):

```sh
mcpcli chat --server weather-sse-service
```

```
You> what is the weather in London?
```

You can also pass the URL directly instead of a config name:

```sh
mcpcli list --server http://127.0.0.1:8080/sse
```

`list`, `call` and `chat` all support SSE servers. `mcpcli` accepts a response
either in the body of the `POST` reply (as this stub does) or as a `message`
event on the stream (as spec-compliant servers do).

## Troubleshooting

| Symptom                                              | Likely cause and fix                                           |
| ---------------------------------------------------- | -------------------------------------------------------------- |
| `Can't locate MCP/Server.pm`                         | Install the CPAN `MCP` distribution: `cpanm MCP`.              |
| `Can't locate HTTP/Daemon.pm`                        | `cpanm HTTP::Daemon`.                                          |
| `Cannot connect to http://...`                       | `sse_server.pl` is not running, or is on a different port than the URL in the config. |
| `HTTP Error (599): Internal Exception` in `chat`     | Ollama is not running on `localhost:11434` (set `OLLAMA_HOST` for another address), or the model has not been pulled. |
| `No server specified. Use --server ...` (`list`, `call`, `chat`) or `No servers found in configuration.` (`servers`) | You are not in `examples/`, so `server_config.json` was not found (or several servers are configured). Run from `examples/`, or pass `--config examples/server_config.json --server <name>`. |
| `Failed to start MCP server ...`                     | The `command` could not be started. Check that `perl` is on your `PATH` and that `stdio_server.pl` is reachable from the current directory. |
| `Timed out waiting for ...`                          | The server did not answer within 30 seconds. Use `--timeout <seconds>` to wait longer, or `MCPCLI_DEBUG=1` to see the messages exchanged. |

## See also

* `perldoc App::MCP::CLI`
* `perldoc App::MCP::CLI::Command::interactive`
* `perldoc App::MCP::CLI::Config`
* MCP specification: <https://modelcontextprotocol.io/specification>
* Perl MCP SDK (provides `MCP::Server`): <https://metacpan.org/pod/MCP>
