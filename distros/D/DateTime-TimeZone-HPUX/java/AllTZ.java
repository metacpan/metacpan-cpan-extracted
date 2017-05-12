import java.util.regex.Pattern;
import java.util.regex.Matcher;

class AllTZ
{
    public static void main(String[] args)
    {
        Pattern filter = null;
        if (args.length == 1) {
            filter = java.util.regex.Pattern.compile(args[0]);
        }
        String[] all_tz = java.util.TimeZone.getAvailableIDs();
        for(int i=0; i<all_tz.length; i++) {
            if (filter != null && ! filter.matcher(all_tz[i]).find())
                continue;
            //System.out.println(all_tz[i]);
            System.out.println(java.util.TimeZone.getTimeZone(all_tz[i]).getID());
        }
    }
}
