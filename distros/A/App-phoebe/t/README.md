# Notes on Testing

## Oddmuse

Some features of the Oddmuse integration require an Oddmuse server
running.

From Oddmuse, we need “wiki.pl” as “t/oddmuse-wiki.pl”, unchanged.

From Oddmuse, we need “modules/namespaces.pl” as
“t/oddmuse-namespaces.pl”, unchanged.

From Oddmuse, we adapted “server.pl” as “t/oddmuse-server.pl”. It now
no longer tries to load wiki.pl but expects the code references to
already be available.
