package org.cpan.knth;

import java.io.PrintStream;

import org.junit.runner.Description;
import org.junit.runner.Result;
import org.junit.runner.notification.Failure;
import org.junit.runner.notification.RunListener;

public class JUnit2TAPListener extends RunListener
{
	private enum Status
	{
		INPROGRESS, FAILED, ASSUMPTION_FAILED, IGNORED;
	}

	private final PrintStream out;
	private final int verbosity;
	private int			currentTest;
	private Status		currentStatus;
	private Description	currentDescription;
	private Failure		currentFailure;

	public JUnit2TAPListener(int verbosity, PrintStream out)
	{
		this.verbosity = verbosity;
		this.out = out;
	}

	public void testRunStarted(Description description) throws Exception
	{
		int testCount = description.testCount();
		out.println("1.." + testCount);
		if (verbosity > 0)
			for (Description d : description.getChildren())
				System.out.println(d);
		currentTest = 0;
	}

	public void testRunFinished(Result result) throws Exception
	{
		if (currentTest != result.getRunCount())
			out.println("Bail out! - Invalid count, expected " + result.getRunCount() + ", have " + currentTest);
	}

	public void testStarted(Description description) throws Exception
	{
		if (currentStatus != null)
			testFinished(currentDescription);
		currentTest++;
		currentDescription = description;
		currentStatus = Status.INPROGRESS;
		currentFailure = null;
	}

	public void testFinished(Description description) throws Exception
	{
		if (currentStatus == Status.INPROGRESS)
			out.println("ok " + currentTest + " - " + description);
		else if (currentStatus == Status.IGNORED)
			out.println("ok " + currentTest + " - " + description + " # TODO");
		else if (currentStatus == Status.ASSUMPTION_FAILED)
		{
			out.println("ok " + currentTest + " - " + description + " # SKIP");
			diagCurrentFailure(description);
		}
		else if (currentStatus == Status.FAILED)
		{
			out.println("not ok " + currentTest + " - " + description + ": " + currentFailure.getException());
			diagCurrentFailure(description);
		}
		else
			out.println("Bail out! - Unexpected status " + currentStatus + " (" + description + ")");
		currentStatus = null;
		currentFailure = null;
	}

	public void testFailure(Failure failure) throws Exception
	{
		currentStatus = Status.FAILED;
		currentFailure = failure;
	}

	public void testAssumptionFailure(Failure failure)
	{
		currentStatus = Status.ASSUMPTION_FAILED;
		currentFailure = failure;
	}

	public void testIgnored(Description description) throws Exception
	{
		currentStatus = Status.IGNORED;
		currentDescription = description;
	}

	private void diagCurrentFailure(Description description)
	{
		if (currentFailure != null && verbosity > 0)
		{
			String fullMethodName = description.getClassName() + "." + description.getMethodName();
			boolean seenFullMethodName = false;
			int remainingElements = 0;
			Throwable t = currentFailure.getException();
			System.err.println(t);
			for (StackTraceElement ste : currentFailure.getException().getStackTrace())
			{
				String steStr = ste.toString();
				if (verbosity > 1)
					System.err.println("  " + steStr);
				else
				{
					if (seenFullMethodName)
						remainingElements++;
					else
						System.err.println("  " + steStr);
						if (steStr.startsWith(fullMethodName + "("))
							seenFullMethodName = true;
				}
			}
			if (remainingElements > 0)
				System.err.println("  ... (" + remainingElements + ")");
		}
	}
}
