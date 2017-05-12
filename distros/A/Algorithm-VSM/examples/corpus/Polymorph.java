// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 3 ---- The Notion of a Class and Some Other Key Ideas
//
// Section:     Section 3.5 -- Defining A Subclass In Java
//


//Polymorph.java

class User {      
    private String name;
    private int age;

    public User( String str, int yy ) { name = str; age = yy; } 
    public void print() {                                         //(F)
        System.out.print( "name: " + name + "   age: " + age ); 
    }
}

class StudentUser extends User {                                 
    private String schoolEnrolled;

    public StudentUser( String nam, int y, String sch ) {        
        super(nam, y);                                           
        schoolEnrolled = sch;
    }
    public void print() {                                         //(G)
        super.print();                                           
        System.out.print( "   School: " + schoolEnrolled );
    }
}

class Test {
    public static void main( String[] args ) 
    {
        User[] users = new User[3];                               //(H)

        users[0] = new User( "Buster Dandy", 34 );                //(I)
        users[1] = new StudentUser("Missy Showoff",25,"Math");    //(J)
        users[2] = new User( "Mister Meister", 28 );              //(K)

        for (int i=0; i<3; i++) {                                 //(L)
            users[i].print();                                     //(M)
            System.out.println();                 
        }
    }
}
