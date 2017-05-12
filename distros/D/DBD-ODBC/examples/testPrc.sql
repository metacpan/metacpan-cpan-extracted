-- $Id$
--
CREATE PROCEDURE  dbo.testPrc
@parameter1 int = 22
AS
	/* SET NOCOUNT ON */
	select 1 as some_data
	select isnull(@parameter1, 0) as parameter1, 3 as some_more_data
	
--	print 'kaboom'
	RETURN(@parameter1 + 1)
