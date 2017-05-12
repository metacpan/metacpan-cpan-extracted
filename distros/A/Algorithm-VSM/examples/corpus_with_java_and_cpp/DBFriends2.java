// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 20  Database Programming
//
// Section:     Section 20.4  JDBC Programming: Invoking SQL Through Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//DBFriends2.java

import java.sql.*;

class DBFriends2 {
    public static void main( String[] args )
    {
        try {
            Class.forName( "org.gjt.mm.mysql.Driver").newInstance(); 
            String url = "jdbc:mysql:///test";
            Connection con = DriverManager.getConnection( url );
            Statement stmt = con.createStatement();

            stmt.executeQuery( "SET AUTOCOMMIT=1" );
            stmt.executeQuery( "DROP TABLE IF EXISTS Friends" );
            stmt.executeQuery( "DROP TABLE IF EXISTS SportsClub" );

            stmt.executeQuery( 
                "CREATE TABLE Friends ( Name CHAR (30) PRIMARY KEY, " +
                                  "Phone CHAR (15), Email CHAR(30), " +
                                    "Age TINYINT (3), Married BOOL, " +
                              "NumKids TINYINT (3), Sport CHAR(20) )" 
            );
            stmt.executeQuery( 
             "CREATE TABLE SportsClub ( Name CHAR (30) PRIMARY KEY, " +
                                  "Age TINYINT (3), Sport CHAR(20), " +
                                   "Level Char(20) )" 
            );
            stmt.executeQuery( 
               "LOAD DATA LOCAL INFILE 'Friends.txt' INTO TABLE " +
                                        " Friends" ); 
            stmt.executeQuery( 
                "LOAD DATA LOCAL INFILE 'SportsClub.txt' INTO " +
                              " TABLE SportsClub" ); 

            // which of the Friends also play tennis at the club:
            ResultSet rs = stmt.executeQuery(
               "SELECT Friends.Name, SportsClub.Level FROM Friends, " 
                 + "SportsClub WHERE " 
                 + "Friends.Name = SportsClub.Name AND "
                 + "Friends.Sport = SportsClub.Sport AND "
                 + "Friends.Sport = 'tennis' " );

            ResultSetMetaData rsmd = rs.getMetaData();
            int numCols = rsmd.getColumnCount();

            while ( rs.next() ) {
                for ( int i = 1; i <= numCols; i++ ) {
                    if ( i > 1 ) 
                        System.out.print( " plays tennis at level " );
                System.out.print( rs.getString( i ) );
                }
                System.out.println( "" );
            }
            rs.close();
            con.close();      
        } catch(Exception ex ) { System.out.println(ex); }
    }
}