import javax.servlet.*;
import javax.servlet.http.*;

import java.io.*;
import java.util.Hashtable;
import com.vizdom.dbd.jdbc.CgiProcess;

/**
 * This servlet manages a user session and associated JDBC connection,
 * but invokes a Perl script to do the actual database query and 
 * HTML generation.
 */
public class PerlServlet extends HttpServlet 
{
    private String jdbcDriverClass = "com.opentext.basis.jdbc.BasisDriver";
    private String jdbcUrl = "jdbc:opentext:basis://poe:7000/tour_all";
    private String user = "user1";
    private String password = "demo";

    private String perlCommand = "perl d:/testPerlServlet.pl";

    public void init(ServletConfig aConfig) throws ServletException
    {
        super.init(aConfig);
        try
        {
            Class.forName(jdbcDriverClass);
        }
        catch (Exception e)
        {
            System.out.println("Initialization error: " + e.toString());
            throw new ServletException(e);
        }
    }

    public void doPost(HttpServletRequest aRequest, 
        HttpServletResponse aResponse)
        throws ServletException, java.io.IOException
    {
        doGet(aRequest, aResponse);
    }

    public void doGet(HttpServletRequest aRequest, 
        HttpServletResponse aResponse)
        throws ServletException, java.io.IOException
    {
        try
        {
            // Create and cache a JDBC connection. Each user will
            // get their own connection back on each request.
            HttpSession session = aRequest.getSession();
            java.sql.Connection conn = 
                (java.sql.Connection) session.getValue("jdbcConnection");
            if (conn == null)
            {
                conn = java.sql.DriverManager.getConnection(jdbcUrl, user, 
                                                            password);
                session.putValue("jdbcConnection", conn);
            }

            // Use the JDBC connection here, if desired.

            // Create some arguments for the Perl script. These
            // values could obviously come from the HttpRequest.
            Hashtable args = new Hashtable();
            args.put("fields", "eno, name");

            // Exec a Perl script, allowing it to use the JDBC
            // connection.
            CgiProcess cgi = new CgiProcess(perlCommand, args, conn);

            // Ignore any buffering issues and just read each stream.
            String results = getOutput(cgi.getInputStream());
            String errors = getOutput(cgi.getErrorStream());
            int returnValue = cgi.waitFor();
            if (results.equals("") && errors.equals(""))
            {
                String message = (returnValue == 0)
                    ? "No response from " :  "Non-zero return value from ";
                aResponse.sendError(500, message + perlCommand);
                return;
            }

            PrintWriter out = aResponse.getWriter();
            if (!errors.equals(""))
                out.println(errors);
            else
                out.println(results);
        }
        catch (Exception e)
        {
            throw new ServletException(e);
        }
    }

    // This assumes that the output is character, not binary, data.
    private String getOutput(InputStream aStream) throws IOException
    {
        Reader reader = new InputStreamReader(aStream);
        char[] chars = new char[1024];
        java.io.CharArrayWriter buffer = 
            new java.io.CharArrayWriter(5096);
        int count;
        while ((count = reader.read(chars)) != -1)
            buffer.write(chars, 0, count);
        buffer.close();
        return buffer.toString();
    }

}
