// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 9  Functions And Methods
//
// Section:     Section 9.3.2  Passing a Class Type Argument by Value of Object Reference
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//







//PassClassTypeByValue.java

class User {
    String name;
    int age;
    User( String nam, int yy ) { name = nam; age = yy; }
};

class Test {
    public static void main( String[] args )
    {
        User u = new User( "Xeno", 89 );                          //(A)
        g(u);                                                     //(B)
        System.out.println( u.name + "  " + u.age );    // Yuki 200
    }

    static void g( User v ) {                                     //(C)
        v.name = "Yuki";                                          //(D)
        v.age = 200;                                              //(E)
    }
}