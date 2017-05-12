This tree contains some extra code in order to help write Java code that
generates a TAP stream, as well as some extra Perl Test::More helpers
to handle a concept called 'known to fail'.

The Java part is in two parts: if you have JUnit code you want to reuse, you
can wrap it to run under a custom JUnit listener, that will create a TAP stream
out of the JUnit events. For more free code, there is a class to help generate
a TAP stream, loosely inspired by Test::More.

Copy the code and use as-is or edited to your taste in your own test suites.

As illustration, a sample suite can be built by invoking Ant on the build.xml
in this directory. As the samples holds JUnit code, you must supply the junit
and hamcrest jars, e.g. 'ant -Djunit-jar=/path/to/junit.jar -Dhamcrest-jar=
/path/to/hamcrest.jar'.

When completed, you can run 'testontap build/suite' and watch the fireworks.
