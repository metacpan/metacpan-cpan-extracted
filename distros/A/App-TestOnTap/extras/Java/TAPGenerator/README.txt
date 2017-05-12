This tree contains java code for the "TAPGenerator" class, and some associated
exceptions.

This class is roughly similar to the Test::More module, in that it will allow
you to write Java code and report pass/fail events through a TAPGenerator
instance and it will handle generation of the TAP protocol.

Feel free to simply include it as-is in the test suite, and/or inheriting from
it to create more higher-level pass/fail methods, e.g. such as the ok() or 
like() methods in Test::More.

For convenience, a simple Ant build script is supplied to build it as a jar
file. If this is put into the test suite, you probably want to set an include
in the config so this jar is not attempted to run. Vice versa, for java code
that does tests, you should package them in jars and set the Main-Class (to
ensure the main class is started) and the Class-Path (to find the TAPGenerator)
attributes in the manifest. See the SampleSuite extra.
