package tapgen;
import org.cpan.knth.TAPGenerator;

public class SimpleFail
{

	public static void main(String[] args)
	{
		TAPGenerator tapgen = new TAPGenerator();

		tapgen.plan(1);
		tapgen.fail("Doesn't work");
		tapgen.done();
	}

}
