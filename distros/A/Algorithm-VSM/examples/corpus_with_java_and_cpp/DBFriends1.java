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



//DBFriends1.java

import java.sql.*;

class DBFriends1 {
    public static void main( String[] args )
    {
        try {
            Class.forName( "org.gjt.mm.mysql.Driver").newInstance();
            String url = "jdbc:mysql:///test";
            Connection con = DriverManager.getConnection( url );
            Statement stmt = con.createStatement();
 
            stmt.executeQuery( "SET AUTOCOMMIT=1" );
            stmt.executeQuery( "DROP TABLE IF EXISTS Friends" );
            stmt.executeQuery( "DROP TABLE IF EXISTS Rovers" );

            // new table (Friends):
            stmt.executeQuery( 
                "CREATE TABLE Friends ( Name CHAR (30) PRIMARY KEY, " +
                                       "Phone INT, Email CHAR(30) )" );       
            stmt.executeQuery( 
                "INSERT INTO Friends VALUES ( 'Ziggy Zaphod', 
                                    4569876, " +  "'ziggy@sirius' )" );
            stmt.executeQuery( 
                "INSERT INTO Friends VALUES ( 'Yo Yo Ma', 3472828, " +
                                               " 'yoyo@yippy' )" );
            stmt.executeQuery( 
                "INSERT INTO Friends VALUES ( 'Gogo Gaga', 
                                    27278927, " + " 'gogo@garish' )" );

            //new table (Rovers):

            stmt.executeQuery( 
                "CREATE TABLE Rovers ( Name CHAR (30) NOT NULL, " +
                                             "RovingTime CHAR(10) )" );
            stmt.executeQuery( 
                "INSERT INTO Rovers VALUES ( 'Dusty Dodo', '2 pm' )" );
            stmt.executeQuery( 
                "INSERT INTO Rovers VALUES ( 'Yo Yo Ma', '8 pm' )" );
            stmt.executeQuery( 
                "INSERT INTO Rovers VALUES ( 'BeBe Beaut', '6 pm' )" );

            // Query: which Friends are Rovers ?
            ResultSet rs = stmt.executeQuery(
                "SELECT Friends.Name, Rovers.RovingTime FROM Friends, "
                        +  "Rovers WHERE Friends.Name = Rovers.Name" );

            ResultSetMetaData rsmd = rs.getMetaData();
            int numCols = rsmd.getColumnCount();
            while ( rs.next() ) {
                for ( int i = 1; i <= numCols; i++ ) {
                    if ( i > 1 ) System.out.print( " | " );
                        System.out.print( rs.getString( i ) );
                }
                System.out.println( "" );
            }
            rs.close();
            con.close();      
        } catch(Exception ex ) { System.out.println(ex); }
    }
}