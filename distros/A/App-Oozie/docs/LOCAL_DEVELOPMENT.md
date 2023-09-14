# Local development

You won't need these settings, if you can already access a Hadoop installation.
The parts below discusses setting up a hadoop instance on your local machine.

This documentation will be referring to the usage under `MacOS`.

## Setting up the Hadoop environment

If you don't have an accessible hadoop environment, then you can use the
docker image provided by Cloudera. See the program `docs/bin/launch-cloudera-docker-image.sh`
inside this distribution.

To be able to test this toolkit, you'd need a running Hadoop + Oozie at least.

You might also need a local installation of hadoop command line utilities.
For example, On MacOS, you can use HomeBrew to install it:

```
brew install hadoop
```

You will also need the Oozie client specs, which you can fetch from a Hadoop node,
if you have access to such a server. Otherwise, you need to build the client
and its libs. See above for the discussion on that.

## Building Oozie (Client)

See the Oozie documentation for all of the details.

https://oozie.apache.org/docs/5.2.1/DG_QuickStart.html#System_Requirements

Download the latest release from the above link. Untar and cd to that folder,
and then:

```
    bin/mkdistro.sh -DskipTests -Puber
```

This will take some time and there might be some failures, hence the `skipTests`.

Read the README if you want to resolve them. You should now have a new distro under
`distro/target`.

`5.3.0` was the tarball created when testing, your version might be different,
depending on when and where you are building from.

Switch to the distro folder and locate the client tarball and untar.

```
    tar xvzf  oozie-client-5.3.0.tar.gz
```

You now have the `oozie` command under `bin`, which you can pass to the application.

Now also locate the `oozie-client-5.3.0-SNAPSHOT.tar.gz` and untar that file
and now you can have the `oozie-client-5.3.0-SNAPSHOT.jar` which you can
also pass to the application.

## Markdown rendering

You can chek this document from some IDEs if they have a Markdown renderer to
see the final formatted result. But you can also install a cli tool like
[glow](https://github.com/charmbracelet/glow).

