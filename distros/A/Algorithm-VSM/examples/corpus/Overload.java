// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 9  Functions And Methods
//
// Section:     Section 9.11 Functions Overload Resolution In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//Overload.java

class Employee { String name; }
class Manager extends Employee { int level; }

class Test {
    static void foo( Employee e1, Employee e2 ) {   //first foo   //(A)
        System.out.println( "first foo" ); 
    }
    static void foo( Employee e, Manager m ) {      //second foo  //(B)
        System.out.println( "second foo" ); 
    }
    static void foo( Manager m, Employee e) {       //third foo   //(C)
        System.out.println( "third foo" ); 
    }

    public static void main( String[] args )
    {
        Employee emp = new Employee();
        Manager man = new Manager();

        foo( emp, man );      // will invoke the second foo       //(D)

        //foo( man, man );    // Error because it produces an     //(E) 
                              // ambiguity in overload resolution
  }
}