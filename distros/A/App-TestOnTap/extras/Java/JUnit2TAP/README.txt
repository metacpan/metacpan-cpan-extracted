This tree contains java code for the "JUnit2TAP" class, and some associated
classes.

This is a fairly simple mechanism for running JUnit tests, and translate the
JUnit events to a TAP stream.

For convenience, a simple Ant build script is supplied to build it as a jar
file. You need to supply the paths to the junit/hamcrest jars to make it build.

If this is put into the test suite, you probably want to set an include
in the config so this jar is not attempted to run. Vice versa, for java code
that does tests, you need to execute the main() method in the JUnit2TAP class.
See the SampleSuite extra.
