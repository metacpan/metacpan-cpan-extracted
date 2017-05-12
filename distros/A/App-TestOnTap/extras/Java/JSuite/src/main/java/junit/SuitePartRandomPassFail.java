package junit;

import static org.junit.Assert.assertTrue;

import java.util.Random;

import org.junit.Test;

public class SuitePartRandomPassFail
{
	private Random m_rand = new Random(System.nanoTime());
	
	@Test public void rand01() { randomAssert(); }
	@Test public void rand02() { randomAssert(); }
	@Test public void rand03() { randomAssert(); }
	@Test public void rand04() { randomAssert(); }
	@Test public void rand05() { randomAssert(); }
	@Test public void rand06() { randomAssert(); }
	@Test public void rand07() { randomAssert(); }
	@Test public void rand08() { randomAssert(); }
	@Test public void rand09() { randomAssert(); }
	@Test public void rand10() { randomAssert(); }
	@Test public void rand11() { randomAssert(); }
	@Test public void rand12() { randomAssert(); }
	@Test public void rand13() { randomAssert(); }
	@Test public void rand14() { randomAssert(); }
	@Test public void rand15() { randomAssert(); }
	@Test public void rand16() { randomAssert(); }
	@Test public void rand17() { randomAssert(); }
	@Test public void rand18() { randomAssert(); }
	@Test public void rand19() { randomAssert(); }
	@Test public void rand20() { randomAssert(); }

	private void randomAssert()
	{
		assertTrue(m_rand.nextBoolean());
		try { Thread.sleep(m_rand.nextInt(500) + 200); } catch (Exception e) {};
	}
}
