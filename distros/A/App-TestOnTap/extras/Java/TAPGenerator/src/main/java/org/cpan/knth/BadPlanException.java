package org.cpan.knth;

public class BadPlanException extends TAPGeneratorException
{
	private static final long serialVersionUID = 6495051146362086859L;

	private int planned;
	private int performed;
	
	public BadPlanException(int planned, int performed)
	{
		super("Planned " + planned + ", performed " + performed);
		this.planned = planned;
		this.performed = performed;
	}
	
	public int getPlanned()
	{
		return planned;
	}

	public int getPerformed()
	{
		return performed;
	}
}
