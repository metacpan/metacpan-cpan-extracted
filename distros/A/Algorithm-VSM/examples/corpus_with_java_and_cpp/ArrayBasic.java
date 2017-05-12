// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 7  Declarations, Definitions, And Initializations
//
// Section:     Section 7.10  Arrays And Their Initialization In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//







//ArrayBasic.java

class User {
    String name; 
    int age;
    public User( String nam, int yy ) {
        name = nam;
        age = yy;
    }
}

class Test {
    public static void main( String[] args ) {
        User[] user_list = new User[ 4 ];
        for ( int i=0; i<user_list.length; i++ )
            System.out.print( user_list[ i ] + "  " ); 
                                       // null null null null
    }
}