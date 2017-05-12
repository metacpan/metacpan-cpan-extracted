// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 9  Functions And Methods 
//
// Section:     Section 9.3.2 Passing a Class Type Argument by Value of Object Reference
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//







//Swap.java

class User {
    String name; 
    int age; 
    User(String nm, int a) {name=nm; age=a;} 
}

class Test {
    public static void main(String[] args)
    {
        User u1 = new User("Xeno", 95);                           //(A)
        User u2 = new User("Yuki", 98);                           //(B)
        swap( u1, u2 );                                           //(C)
        System.out.println( u1.name );     // Xeno
        System.out.println( u2.name );     // Yuki
    }

    static void swap(User s, User t) {                            //(D)
        User temp = s; 
        s = t;
        t = temp;
    }
}