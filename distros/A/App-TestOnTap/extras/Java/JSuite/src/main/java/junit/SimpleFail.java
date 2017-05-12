package junit;

import static org.junit.Assert.assertTrue;

import org.cpan.knth.JUnit2TAP;
import org.junit.Test;

public class SimpleFail
{
	public static void main(String[] args)
	{
		JUnit2TAP.run("verbosity=1", SimpleFail.class.getName());
	}

	@Test
	public void simpleTruth()
	{
		assertTrue(false);
	}

}
