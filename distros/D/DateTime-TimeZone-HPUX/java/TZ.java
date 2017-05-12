import java.util.TimeZone;
class TZ
{
    public static void main(String[] args)
    {
	TimeZone tz;
	if (args.length > 0)
	    tz = TimeZone.getTimeZone(args[0]);
	else
	    tz = TimeZone.getDefault();
	System.out.println(tz.getID());
    }
}
