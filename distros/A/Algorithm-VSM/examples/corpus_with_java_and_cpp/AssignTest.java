// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.11  Semantics Of The Assignment Operator In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//AssignTest.java

class User {
    public String name;
    public int age;
    public User( String str, int n ) { name = str; age = n; }
}

class Test {
    public static void main( String[] args )
    {
        User u1 = new User( "ariel", 112 );
        System.out.println( u1.name );        // ariel
        User u2 = u1;                                             //(A)      
        u2.name = "muriel";                                       //(B)
        System.out.println( u1.name );        // muriel
    }
}