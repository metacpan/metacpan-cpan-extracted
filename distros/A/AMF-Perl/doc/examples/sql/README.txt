Installation notes on the ParkServices example.

1. Make sure you have access to a mysql database and that the DBI and DBD::Mysql modules are installed.
2. Import the park.sql script into your database.
3. Don't forget to put DataGlue.as in the same directory as the Flash movie.
4. Recompile the Flash movie to point to the location of your park.pl script.


Note that normally AMF::Perl tries to guess whether you are sending a number. 
And if the database used is Mysql, AMF::Perl will retrieve column types
from the statement handle. This is done so that the server could send back
primitive data types in a recordset as numbers or strings avoiding the
guessing (which may be wrong if you do intend to send a number as a string).
