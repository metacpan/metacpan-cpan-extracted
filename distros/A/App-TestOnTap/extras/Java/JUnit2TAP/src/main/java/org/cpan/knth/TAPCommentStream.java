package org.cpan.knth;

import java.io.PrintStream;
import java.util.Arrays;

public class TAPCommentStream extends PrintStream
{
	private final int LINE_SEP = 10;
	private final String LINE_PREFIX = "# ";
	private boolean writeLinePrefix = true; 
	
	public TAPCommentStream(PrintStream wrap)
	{
		super(wrap);
	}
	
	public void write(int b)
	{
		if (writeLinePrefix)
			for (int i = 0 ; i < LINE_PREFIX.length() ; i++)
				super.write(Character.codePointAt(LINE_PREFIX, i));
		super.write(b);
		writeLinePrefix = (b == LINE_SEP);
	}
	
	public void write(byte[] buf)
	{
		String s = new String(buf);
		for (int i = 0 ; i < s.length() ; i++)
			write(s.codePointAt(i));
	}

	public void write(byte[] buf, int off, int len)
	{
		if (off == 0 && len == buf.length)
			write(buf);
		else
			write(Arrays.copyOfRange(buf, off, (off + len)));
	}
}
