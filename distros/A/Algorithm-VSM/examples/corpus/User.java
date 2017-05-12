// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 3 ---- The NOtion Of A Class And Some Other Key Ideas
//
// Section:     Section 3.2 -- Defining A Class In Java
//
// The links to the rest of the code in this book are at
//     


//User.java

class User {                                                      //(D)
    private String name;
    private int age;
    
    public User( String str, int yy ) { name = str;  age = yy; } 
    public void print() { 
        System.out.println( "name: " + name + "  age: " + age ); 
  }
}

class Test {                                                      //(E)
    public static void main( String[] args ) {
        User u = new User("Zaphod", 23 );
        u.print();
    }
}
