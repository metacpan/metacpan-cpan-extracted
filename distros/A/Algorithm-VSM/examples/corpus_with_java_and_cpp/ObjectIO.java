
// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 6 The Primitive Types and Their Input/Output
//
// Section:     Section 6.11  HomeWork
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//ObjectIO.java

import java.io.*;

class User implements Serializable {
    private String name;
    private int age;
 
    public User( String nam, int yy ) { name = nam;  age = yy; }
    public String toString(){return "User: " + name + "  " + age;}

    public static void main( String[] args ) throws Exception {
        User user1 = new User( "Melinda", 33 );
        User user2 = new User( "Belinda", 43 );
        User user3 = new User( "Tralinda", 53 );

        FileOutputStream os = new FileOutputStream( "object.dat" );
        ObjectOutputStream out = new ObjectOutputStream( os );        
       
        out.writeObject( user1 );
        out.writeObject( user2 );
        out.writeObject( user3 );

        out.flush();
        os.close();

        FileInputStream is = new FileInputStream( "object.dat" );
        ObjectInputStream in = new ObjectInputStream( is );

        User user4 = (User) in.readObject();
        User user5 = (User) in.readObject();
        User user6 = (User) in.readObject();

        is.close();
 
        System.out.println( user4 );
        System.out.println( user5 );
        System.out.println( user6 );
    }
}