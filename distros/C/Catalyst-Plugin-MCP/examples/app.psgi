use v5.36;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Example::MCP;

Example::MCP->psgi_app;
