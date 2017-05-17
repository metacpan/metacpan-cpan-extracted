package org.cpan.knth;

import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * @author knth@cpan.org
 * @version 0.033
 * 
 *          <h1>Simple TAP generator</h1>
 * 
 *          <p>
 *          This class allows a client the basic building blocks of generating
 *          TAP (<a href="http://www.testanything.org">Test Anything
 *          Protocol</a>output.) and is somewhat inspired by the Test::* Perl
 *          modules, although more advanced helper methods like 'is()', 'like()'
 *          and others are intended to be provided by inheritance or other
 *          methods.
 *          </p>
 * 
 *          <p>
 *          The class attempts to fulfill the TAP version 12 specification,
 *          allowing access to basic pass/fail methods, note/diag messages and
 *          todo/skip/bailout functionality.<br/>
 *          Additionally, it supports the concept of marking individual tests as
 *          'known to fail', so that a fail will automatically be marked as a
 *          pass but if such a test suddenly/unexpectedly passes, it becomes a
 *          fail.
 *          </p>
 *
 */
public class TAPGenerator
{
	// Places to print regular TAP vs diagnostics to
	//
	private PrintWriter					m_out;
	private PrintWriter					m_err;

	// The number of planned and performed tests
	// The plannedTests may be null, which means
	// the 'done()' just reports the performedTests
	// after the fact (e.g. 'no plan').
	//
	private Integer						m_plannedTests;
	private int							m_performedTests	= 0;

	// keep a buffer around to simplify creating tap strings
	//
	private StringBuilder				m_tapBuilder		= new StringBuilder();

	// keep track of todo and skip mode
	// if both are set, give preference to skip
	//
	private static StringBuilder		NULL_DIRECTIVE		= new StringBuilder();
	private StringBuilder				m_todoDirective		= NULL_DIRECTIVE;
	private StringBuilder				m_skipDirective		= NULL_DIRECTIVE;

	// keep track of which tests are marked as known to fail, and for what
	// reason(s)
	//
	private Map<Integer, List<String>>	m_testsKnownToFail	= new HashMap<Integer, List<String>>();

	// If non-null, we are in bail out or done mode
	// always rethrow them if we keep getting called...
	//
	private AlreadyBailedOutException	m_boExc;
	private IllegalStateException		m_done;

	private Boolean						m_dontHandleKnownFailures;

	/**
	 * Create an instance with out/err simply going to stdout/stderr.
	 */
	public TAPGenerator()
	{
		this(new PrintWriter(System.out, true), new PrintWriter(System.err, true));
	}

	/**
	 * Create an instance with out/err to the given PrintWriters(s).
	 * 
	 * @param out The writer for the TAP stream
	 * @param err The writer for non-TAP data, such as diagnostics
	 */
	public TAPGenerator(PrintWriter out, PrintWriter err)
	{
		m_out = out;
		m_err = err;
	}

	/**
	 * Request to bail out with no message.
	 * 
	 * @see #bailOut(String)
	 */
	public void bailOut()
	{
		bailOut(null);
	}

	/**
	 * Request to bail out with message.
	 * 
	 * @param message The detail message for the bail out
	 * @see #bailOut()
	 */
	public void bailOut(String message)
	{
		assertNotStoppedState();

		// store an instance of an exception to be thrown
		// if we're called again after bailout
		//
		m_boExc = new AlreadyBailedOutException(message);

		// send bailout TAP
		//
		StringBuilder tapBuilder = getTapBuilder("Bail out!");
		if (message != null)
			tapBuilder.append(" ").append(message);
		tapOut(tapBuilder);
	}

	/**
	 * Provide the number of tests planned to run. Calling this is optional, but
	 * must be called before any tests have been recorded. If never called, the
	 * done() call will output the plan after the fact.
	 * 
	 * @param tests Number of tests planned to run
	 * @return nothing
	 * @see #done()
	 */
	public void plan(int tests)
	{
		assertNotStoppedState();

		// not allowed to start a plan if already planned, or tests have started
		//
		if (m_plannedTests != null || m_performedTests > 0)
			throw new IllegalStateException("Plan already set, or tests has commenced");

		// well, can't handle less than zero tests...
		//
		if (tests < 0)
			throw new IllegalArgumentException("Planned test count is negative: " + tests);

		// store the plan and send TAP
		//
		m_plannedTests = new Integer(tests);
		tapOut("1..", m_plannedTests.toString());
	}

	/**
	 * Start a todo section with no particular message.
	 * 
	 * @see #beginTodo(String)
	 */
	public void beginTodo()
	{
		beginTodo(null);
	}

	/**
	 * Start a todo section with a directive/message to be suffixed to all
	 * descriptions, e.g. 'not ok 42 Some description # TODO message'.
	 * 
	 * Must be ended by a call to endTodo() in order to stop generating todo
	 * suffixes, but it is not an error to not call it if done() is the next
	 * call.
	 * 
	 * Note that a skip section takes precedence for a suffix in case both
	 * sections are active.
	 * 
	 * @param message The detail message for the skip
	 * @see #endTodo()
	 * @see #beginSkip(String)
	 */
	public void beginTodo(String message)
	{
		assertNotStoppedState();

		// we can only use one directive at a time
		//
		if (m_todoDirective != NULL_DIRECTIVE)
			throw new IllegalStateException("Already in TODO mode");

		// record TAP for later use
		//
		m_todoDirective = new StringBuilder("# TODO");
		if (message != null)
			m_todoDirective.append(" ").append(message);
	}

	/**
	 * Stops the todo directive.
	 * 
	 * @see #beginTodo(String)
	 */
	public void endTodo()
	{
		assertNotStoppedState();

		// stop what?
		//
		if (m_todoDirective == NULL_DIRECTIVE)
			throw new IllegalStateException("Not in TODO mode");

		m_todoDirective = NULL_DIRECTIVE;
	}

	/**
	 * Start a skip section with no particular message.
	 * 
	 * @see #beginSkip(String)
	 */
	public void beginSkip()
	{
		beginSkip(null);
	}

	/**
	 * Start a skip section with a directive/message to be suffixed to all
	 * descriptions, e.g. 'not ok 42 Some description # SKIP message'.
	 * 
	 * Must be ended by a call to endSkip() in order to stop generating skip
	 * suffixes, but it is not an error to not call it if done() is the next
	 * call.
	 * 
	 * Note that a skip section takes precedence for a suffix in case a todo
	 * section is also active.
	 * 
	 * @param message The detail message for the skip
	 * @see #endSkip()
	 * @see #beginTodo(String)
	 */
	public void beginSkip(String message)
	{
		assertNotStoppedState();

		// we can only use one directive at a time
		//
		if (m_skipDirective != NULL_DIRECTIVE)
			throw new IllegalStateException("Already in SKIP mode");

		// record TAP for later use
		//
		m_skipDirective = new StringBuilder("# SKIP");
		if (message != null)
			m_skipDirective.append(" ").append(message);
	}

	/**
	 * Stops the skip directive.
	 * 
	 * @see #beginSkip(String)
	 */
	public void endSkip()
	{
		assertNotStoppedState();

		// stop what?
		//
		if (m_skipDirective == NULL_DIRECTIVE)
			throw new IllegalStateException("Not in SKIP mode");

		m_skipDirective = NULL_DIRECTIVE;
	}

	/**
	 * Initiate a skipall with no specific message.
	 * 
	 * @see #skipAll(String)
	 */
	public void skipAll()
	{
		skipAll(null);
	}

	/**
	 * This is a shortcut if it's realized that there is no point in keeping
	 * testing. It behaves slightly different if tests have already been done,
	 * or not.<br/>
	 * In the latter case, a single and proper line with '1..0 # SKIP <message>'
	 * is generated and a harness will properly display this.<br/>
	 * In the former case, remaining tests will be called as as passed,
	 * generating TAP with SKIP messages as if startSkip() had been started.
	 * This is not visible in the harness, unless the TAP stream is visible.
	 * <br/>
	 * Calling this is optional, but must be called before any tests have been
	 * recorded. If never called, the done() call will output the plan after the
	 * fact.
	 * 
	 * @param message Reason for skipping
	 * @return nothing
	 * @see #beginSkip(String)
	 */
	public void skipAll(String message)
	{
		assertNotStoppedState();

		// act as is we're starting a skip section
		//
		beginSkip(message);

		// in case we've started seeing tests, artifically
		// pass the rest with a hardcoded description
		// (which will be followed by the SKIP message)
		//
		if (m_plannedTests != null)
		{
			while (m_performedTests < m_plannedTests)
				pass("(skipall)");
		}

		// just go to a done state, done() will show the proper
		// skip message if there is no plan
		//
		done();
	}

	/**
	 * Describes a message for a specific test known to fail, but which should
	 * be treated as a pass anyway. In case such a test <strong>does</strong>
	 * pass, a bail out will be generated.
	 * 
	 * Note that this method can be called multiple times; new messages will be
	 * added to the previous.
	 * 
	 * The mechanism can be turned off by setting the system property
	 * 'dont_handle_known_failures'. Any attempts to set a test as known to fail
	 * will simply ignored and consequently the test(s) will be reported as
	 * normally failing/passing.
	 * 
	 * @param message A message to use when handling a known to fail test
	 * @param testnum The number of the test known to fail
	 * 
	 * @see #testsKnownToFail(String, int...)
	 * @see #nextTestKnownToFail(String)
	 * @see #nextTestsKnownToFail(String, int)
	 */
	public void testKnownToFail(String message, int testnum)
	{
		assertNotStoppedState();

		if (m_dontHandleKnownFailures == null)
			m_dontHandleKnownFailures = Boolean.valueOf(System.getProperty("dont_handle_known_failures"));

		if (!m_dontHandleKnownFailures)
		{
			List<String> msgs = m_testsKnownToFail.get(testnum);
			if (msgs == null)
				msgs = new ArrayList<String>();
			msgs.add(message);
			m_testsKnownToFail.put(testnum, msgs);
		}
	}

	/**
	 * A helper for marking a range of test numbers as known to fail (using the
	 * same message).
	 * 
	 * @param message A message to use when handling a known to fail test
	 * @param testnums A list of test numbers
	 * @see #testKnownToFail(String, int)
	 */
	public void testsKnownToFail(String message, int... testnums)
	{
		for (int testnum : testnums)
			testKnownToFail(message, testnum);
	}

	/**
	 * A helper for marking the next test as known to fail.
	 * 
	 * @param message A message to use when handling a known to fail test
	 * @see #testKnownToFail(String, int)
	 */
	public void nextTestKnownToFail(String message)
	{
		nextTestsKnownToFail(message, 1);
	}

	/**
	 * A helper for marking a range of next tests as known to fail.
	 * 
	 * @param message A message to use when handling a known to fail test
	 * @param count The count of coming tests known to fail
	 * @see #testKnownToFail(String, int)
	 */
	public void nextTestsKnownToFail(String message, int count)
	{
		for (int i = 1; i <= count; i++)
			testKnownToFail(message, m_performedTests + i);
	}

	/**
	 * Sends an arbitrary number of strings to the TAP stream all prefixed with
	 * '# ' and guaranteed not to interfere with normal TAP lines.
	 * 
	 * note() lines will not normally be seen when a harness is interpreting the
	 * TAP stream, only in the preserved stream or when the harness is verbose.
	 * 
	 * @param strings A list of strings to print
	 * @see #diag(String...)
	 */
	public void note(String... strings)
	{
		for (String s : strings)
			tapOut("# ", s);
	}

	/**
	 * Sends an arbitrary number of strings outside the TAP stream all prefixed
	 * with '# ' and guaranteed not to interfere with normal TAP lines.
	 * 
	 * diag() lines will only be seen when running, it will not be preserved in
	 * the TAP stream. Note that due to buffering out/err is probably not in
	 * sync.
	 * 
	 * @param strings A list of strings to print
	 * @see #note(String...)
	 */
	public void diag(String... strings)
	{
		for (String s : strings)
			tapErr("# ", s);
	}

	/**
	 * Signal that a test passed with no specific description.
	 * 
	 * @return The test number
	 */
	public int pass()
	{
		return pass(null);
	}

	/**
	 * Signal that a test passed with a description.
	 * 
	 * @param description The test description
	 * @return The test number
	 */
	public int pass(String description)
	{
		return passOrFail(true, description);
	}

	/**
	 * Signal that a test failed with no specific description.
	 * 
	 * @return The test number
	 */
	public int fail()
	{
		return fail(null);
	}

	/**
	 * Signal that a test failed with a description.
	 * 
	 * @param description The test description
	 * @return The test number
	 */
	public int fail(String description)
	{
		return passOrFail(false, description);
	}

	/**
	 * This method should be called when testing is completed. If there was no
	 * initial plan defined, this will output the 'plan' after the fact.<br/>
	 * It's not a strict requirement to call this if plan() was initally called,
	 * but it is good form to do so as it will check the plan as well as putting
	 * the instance into a 'stopped' state.
	 * 
	 * @return The number of tests performed.
	 */
	public int done()
	{
		assertNotStoppedState();

		// Store an exception to indicate that we're stopped
		//
		m_done = new AlreadyDoneException();

		if (m_plannedTests == null)
		{
			// In case there was no initial plan, send TAP for a plan
			// after the fact. Include the skip directive if there is one
			// and no tests have been run (e.g typically after a skipAll() in
			// the
			// beginning).
			//
			StringBuilder tapBuilder = getTapBuilder("1..").append(m_performedTests);
			if (m_performedTests == 0 && m_skipDirective != NULL_DIRECTIVE)
				tapBuilder.append(" ").append(m_skipDirective);
			tapOut(tapBuilder);
		}
		else
		// Otherwise, keep the user honest by complaining about a bad plan
		// if there's a mismatch
		//
		if (m_plannedTests != m_performedTests)
			throw new BadPlanException(m_plannedTests, m_performedTests);

		return m_performedTests;
	}

	// privates
	//
	private int passOrFail(boolean result, String description)
	{
		assertNotStoppedState();

		// regardless of the outcome, the
		m_performedTests++;

		StringBuilder directive = null;
		directive = (m_todoDirective != NULL_DIRECTIVE ? m_todoDirective : directive);
		directive = (m_skipDirective != NULL_DIRECTIVE ? m_skipDirective : directive);

		List<String> msgs = m_testsKnownToFail.get(m_performedTests);
		if (msgs != null)
		{
			if (result)
			{
				// the test unexpectedly passed!
				// complain
				//
				StringBuilder sbmsgs = new StringBuilder();
				for (String s : msgs)
				{
					if (s != null)
					{
						if (sbmsgs.length() > 0)
							sbmsgs.append(" # ");
						sbmsgs.append(s);
					}
				}

				StringBuilder sb = new StringBuilder("Test number ").append(m_performedTests)
						.append(" is marked as 'known to fail', but unexpectedly passed!").append(" Message(s): ").append(sbmsgs);

				bailOut(sb.toString());
			}

			// mark test as ok
			//
			result = true;
		}

		StringBuilder tapBuilder = getTapBuilder();
		if (!result)
			tapBuilder.append("not ");
		tapBuilder.append("ok ").append(m_performedTests);
		if (description != null)
			tapBuilder.append(" ").append(description);
		if (msgs != null)
			tapBuilder.append(" (known to fail)");
		if (directive != null)
			tapBuilder.append(" ").append(directive);
		tapOut(tapBuilder);

		if (msgs != null)
		{
			StringBuilder sb = new StringBuilder("Test number ").append(m_performedTests).append(" failed as expected.")
					.append(" Message(s):");
			note(sb.toString());
			for (String s : msgs)
			{
				sb.setLength(0);
				sb.append("==> ").append(s);
				note(sb.toString());
			}
		}

		return m_performedTests;
	}

	private StringBuilder getTapBuilder(String... strings)
	{
		m_tapBuilder.setLength(0);
		for (String s : strings)
			m_tapBuilder.append(s);
		return m_tapBuilder;
	}

	private void tapOut(String... strings)
	{
		tapOut(getTapBuilder(strings));
	}

	private void tapErr(String... strings)
	{
		tapErr(getTapBuilder(strings));
	}

	private void tapOut(StringBuilder sb)
	{
		tap(m_out, sb);
	}

	private void tapErr(StringBuilder sb)
	{
		tap(m_err, sb);
	}

	private void tap(PrintWriter ps, StringBuilder sb)
	{
		ps.println(sb);
		ps.flush();
	}

	private void assertNotStoppedState()
	{
		if (m_boExc != null)
			throw m_boExc;

		if (m_done != null)
			throw m_done;
	}
}
