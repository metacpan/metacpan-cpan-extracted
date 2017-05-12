package tapgen;
import java.util.Random;

import org.cpan.knth.TAPGenerator;

public class Random7
{

	public static void main(String[] args)
	{
		TAPGenerator tapgen = new TAPGenerator();

		Random rand = new Random(System.nanoTime());
		int plan = rand.nextInt(50) + 1;
		
		tapgen.plan(plan);
		for (int i = 1 ; i <= plan ; i++)
		{
			String tnum = "Test number " + i; 
			if (rand.nextBoolean())
				tapgen.pass(tnum);
			else
				tapgen.fail(tnum);
			try { Thread.sleep(rand.nextInt(500) + 200); } catch (Exception e) {};
		}
		tapgen.done();
	}

}
