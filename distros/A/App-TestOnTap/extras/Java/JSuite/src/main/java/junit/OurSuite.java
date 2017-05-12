package junit;

import org.cpan.knth.JUnit2TAP;
import org.junit.runner.RunWith;
import org.junit.runners.Suite;

@RunWith(Suite.class)
@Suite.SuiteClasses({ SuitePart1.class, SuitePart2.class, SuitePartRandomPassFail.class })

public class OurSuite
{
	public static void main(String[] args)
	{
		JUnit2TAP.run("verbosity=1", OurSuite.class.getName());
	}
}
