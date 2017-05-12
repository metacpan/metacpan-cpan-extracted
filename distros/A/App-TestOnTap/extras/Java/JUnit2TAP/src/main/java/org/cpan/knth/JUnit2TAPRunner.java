package org.cpan.knth;

import java.io.PrintStream;
import java.util.ArrayList;
import java.util.List;

import org.junit.runner.JUnitCore;

public class JUnit2TAPRunner
{
	static public boolean run(int verbosity, String... args) throws ClassNotFoundException
	{
	    List<Class<?>> classes = new ArrayList<Class<?>>();
        for (String arg : args)
			classes.add(Class.forName(arg));
		return run(verbosity, classes.toArray(new Class<?>[classes.size()]));
	}
	
	static private boolean run(int verbosity, Class<?>... classes)
	{
		boolean ok = false;
		PrintStream stdout = System.out;
		PrintStream stderr = System.err;
		try
		{
			TAPCommentStream tapcs = new TAPCommentStream(stdout); 
			System.setOut(tapcs);
			System.setErr(tapcs);
			JUnitCore core = new JUnitCore();
			core.addListener(new JUnit2TAPListener(verbosity, stdout));
			ok = core.run(classes).wasSuccessful();
		}
		finally
		{
			System.setErr(stderr);
			System.setOut(stdout);
		}
		
		return ok;
	}
}