package tapgen;
import org.cpan.knth.TAPGenerator;

public class SimplePass
{

	public static void main(String[] args)
	{
		TAPGenerator tapgen = new TAPGenerator();

		tapgen.plan(1);
		tapgen.pass("Works");
		tapgen.done();
	}

}
