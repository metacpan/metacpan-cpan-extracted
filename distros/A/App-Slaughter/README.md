Homepage:
    http://www.steve.org.uk/Software/slaughter/

The Definitive Slaughter Guide:
    http://www.steve.org.uk/Software/slaughter/guide/

Source Repository:
    https://github.com/skx/slaughter/

Mirror:
    http://git.steve.org.uk/slaughter/slaughter


Slaughter
---------

The goal of this project is to have a lightweight system which will
allow the control and manipulation of multiple systems.

The tasks we support are pretty basic, but they include:

   1.  Replacing a file, literally.
   2.  Replacing a file, template-expanding content within it.
   3.  Appending lines to files, commenting out lines, replacing lines, etc.
   4.  Running system commands.
   5.  Testing for the existence of local users, and fetching their details.
   6.  Checking disk space, and mount-points.
   7.  Sending alerts via email.

The implementation is cleanly organised to allow it to be ported, tested, and used upon new systems easily.  Slaughter currently supports:

* GNU/Linux.
* OpenBSD.
* Microsoft Windows - using Strawberry perl.



Overview
--------

We assume that we have a "server" somewhere.  This server is designed to allow files, modules, and policies to be retrieved from it.

The actual form of the server is loosely specified, as slaughter allows different transport mechanisms to be used.  Currently there are several supported transports for fetching things from the remote server:

* HTTP-transfers.
* rsync-transfers.
* Cloning remote git/mercurial/svn repositories.

Each client which is running slaughter will connect to the server, using the appropriate mechanism, and download policies.  These policies describe the actions that must be carried out upon the local system.

Policies (and also files) are pulled by the client, meaning there is no central server which is in charge of initiating transactions, or connections.

i.e. Slaughter is client-pull rather than server-push.

The attraction of client-pull is that there is no need to maintain state on the central server, and each client can be trusted to schedule itself via a cron-like system.  The potential downside is that you might fail to notice if a client suddenly stops making appropriate requests.



Policies
--------

The list of tasks which each node should carry out is defined in a policy file.  An initial "default.policy" file is fetched from the server, and this may trigger the fetch of additional policies and modules in turn.

This policy files may contain code in (standard) Perl, and they may also use the primitives that Slaughter provides.

It is expected that because the file default.policy is fetched by all clients it should be used for house-keeping, and merely include other policies.

For example a `default.policy` file might look like this:


    # actions to carry out globally
    FetchPolicy "global.policy";

    # is there a per-client one?
    FetchPolicy "$fqdn.policy";


In this case the variable "`fqdn`" is expanded to the fully-qualified domain-name of the requesting client - this is an example of one of the many available defined variables clients may make use of in policy files, or pure perl code.

If the hostname-specific policy file does not exist then it is merely ignored.



Client Layout
-------------

To get started a client needs to have :

* The slaughter-client package installed upon it.
* The name of the server, and the transport to use against it, stored in the configuration file /etc/slaughter/slaughter.conf [*]

Once this is done cron may be used to ensure that `slaughter` is invoked upon a regular basis.  (Hourly is a good choice.)

You'll probably want to invoke slaughter manually for the first few times as you're putting together your policies.

> Alternatively you may specify these details on the command line.  See the TRANSPORT file for some examples.



Server Layout
-------------

Regardless of the transport which is in use, and examples are available in the included TRANSPORT file, slaughter does insist that the top-level of the server contain the same fixed subdirectories.

For example using the HTTP-transport the webserver should be configured to serve a tree which would look like this:

           /var/www/slaughter/
           /var/www/slaughter/modules/
           /var/www/slaughter/policies/
           /var/www/slaughter/files/

Here we see there are three specific directories:

* `modules/`
     * This is the location of any modules which are implemented.
* `policies/`
     * This is the location of the policies.
* `files/`
     * This is the root of any files which are stored on the server to be fetched.

e.g. The request for `http://$master/slaughter/policies/default.policy` should succeed.

In the interests of security it is probably wise to limit access to the `/slaughter/` location, denying access to clients you're not expecting to pull from it.




In Depth Operation
------------------

The client node will first fetch the policy, which might contain references to other policies to load.

Once the policy fetching has been completed the downloaded content will be wrapped such that it becomes a locally executable file, making use of the Slaughter.pm module (this module is where the primitives are implemented and exported to the perl script).

Finally the locally written script will be executed, before being removed.

After your script(s) have executed any messages saved with the `LogMessage` function will be displayed, or sent via email.

(Any literal output your script might have written with "print" will be sent to STDOUT, as expected.)


Steve
--
