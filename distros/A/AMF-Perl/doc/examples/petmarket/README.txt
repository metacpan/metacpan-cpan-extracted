README for the server side of the Macromedia Petstore implementation

1. Sources.

The original Macromedia client can be downloaded from
http://www.macromedia.com/devnet/mx/blueprint/

There are a few steps to get it working - you need to compile each movie separately, for example.
To make thing easier, a fully precompiled client side is provided at the AMF::Perl web site:

http://www.simonf.com/amfperl/examples/petmarket/index.html

(Unlike other examples, the client is NOT included into the AMF::Perl distribution due to its size.)

2. Usage.

You need to load the data in petmarket.sql into a database and configure
the database server, name username and password in dbConn.pm.

You HAVE to set your server URL in initFunction/mainInit.as and then recompile main.fla in order to point your
client to your server.

3. Notes about implementation.

You HAVE to have these files in the directory petmarket/api relative to your Perl gateway script,
because this is what the Flash client assumes.

