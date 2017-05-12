// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 7  Declarations, Definitions, And Initializations
//
// Section:     Section 7.3  Are The Defined Variables In Java Initialized By Default?
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//DefaultInit.java

class User {
    private String name;
    private int age;
    public User() { name = "John Doe";  age = 25; }
    public String toString() { return name + "  " + age; }
}

class Test {
    public static void main( String[] args ) {

        //u1 declared but not defined:
        User u1;                                             //(A)
        // System.out.println( u1 );   // ERROR              //(B)

        //u2 defined and initialized:
        User u2 = new User();                                //(C)
        System.out.println( u2 );      // John Doe  25       //(D)
    }
}