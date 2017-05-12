// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 7  Declarations, Definitions, And Initializations
//
// Section:     Section 7.3.1  Is Default Initialization Affected by Default Values for Class Members?
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//






//DefaultInit3.java

class User {
    public String name = "John Doe";                              //(A)
    public int age = 25;                                          //(B)

    public String toString() { return name + "  "  + age; }
}

class Test {
    public static void main( String[] args ) {
        User u = new User();                                      //(C)
        System.out.println( u );      // John Doe  25             //(D)
    }
}