package org.cpan.knth;

public class AlreadyBailedOutException extends TAPGeneratorException
{
	private static final long serialVersionUID = 9207478666136604841L;

	public AlreadyBailedOutException(String message)
	{
		super(message);
	}
}
