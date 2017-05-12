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





//DefaultInit2.java

class User {
    public String name;
    public int age;
    public User() { name = "John Doe";  age = 25; }               //(A)
    public String toString() { return name + "  "  + age; }       //(B)
}

class UserGroup {
    public String groupName;
    public User chief;
    public int priority;
    public User[] members;         
    public String toString() {                                    //(C)
        return groupName + " " + chief + "  " 
                         + priority + "  " + members ;
    }
}

class Test {
    public static void main( String[] args ) {
        UserGroup ug = new UserGroup();                           //(D)
        System.out.println( ug );     // null null  0  null       //(E)
    }
}