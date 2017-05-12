// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.16  A Java Study Of Interleaved Classes Of Moderate Complexity
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//Interleaved.java

import java.util.*;   

////////////////////////////  class Date  ////////////////////////////        

class Date implements Cloneable {
    int month;
    int day;
    int year;
    public Date( int mm, int dd, int yy ) {
        month = mm; day = dd; year = yy;
    }
    public String toString() { 
        return month + " : " + day + " : " + year;
    }
    public Object clone()
    {
        Date date = null;
        try {
            date = ( Date ) super.clone();
        } catch( CloneNotSupportedException e ) {}
        return date;
    }
}


/////////////////////////////  class Cat  /////////////////////////////

class Cat implements Cloneable {
    String name;
    int age;
    public Cat( String nam, int a ) { name = nam ; age = a; }
    public String toString() { return "  Name: " + name 
                                        + "   Age: " + age; }
    public Object clone() {
        Cat cat = null;
        try {
            cat = ( Cat ) super.clone();
        } catch( CloneNotSupportedException e ) {}
        return cat;
    }
}


/////////////////////////////  class Dog  ////////////////////////////

class Dog implements Cloneable {
    String name;
    int age;
    public Dog( String nam, int a ) { name = nam; age = a; }
    public String toString() { return "\nName: " + name 
                                      + "   Age: " + age; }

    public String getName() { return name; }
    public int getAge() { return age; }

    public void print() {
        System.out.println( this );    
    }

    public Object clone() throws CloneNotSupportedException {
        Dog dog = null;
        try {
            dog = ( Dog ) super.clone();
        } catch( CloneNotSupportedException e ) {}
        return dog;
    }
}


//////////////////////////  class Employee  //////////////////////////

class Employee {                 // intentionally left uncloneable

    String firstName, lastName;
    Date dateOfBirth;
    Employee[] friends;
    Auto[] autos;
    Cat kitty;
    Vector dogs;
    Map phoneList;

    public Employee( String first, String last ) {
        firstName = first;  lastName = last;
    }

    public Employee( String first, String last, Date dob ) {
        firstName = first;  lastName = last;
        dateOfBirth = dob == null ? null : (Date) dob.clone();
    }

    public Employee( String first, String last, Date dob, Cat kit ) {
        firstName = first;  lastName = last;
        dateOfBirth = dob == null ? null : (Date) dob.clone();  
        kitty = kit == null ? null : (Cat) kit.clone();
    }

    public Employee( String first, String last, Vector dogs ) {
        firstName = first;  lastName = last;
        this.dogs = dogs == null ? null : (Vector) dogs.clone();
    }

    Employee( String first, String last, Date dob, Employee[] fnds ) {
        firstName = first;  lastName = last;
        dateOfBirth = dob == null ? null : (Date) dob.clone(); 
        friends = fnds == null ? null : (Employee[]) fnds.clone();
    }

    Employee( String first, String last, Map phoneList ) {
        firstName = first;  lastName = last;
        this.phoneList = phoneList == null ? null 
          : new TreeMap( (TreeMap) phoneList );  
    }

    Employee( String first, String last, Date dob, Employee[] fnds, 
                   Auto[] ats, Cat c )
    {
        firstName = first;  lastName = last;
        dateOfBirth = dob == null ? null : (Date) dob.clone(); 
        friends = fnds == null ? null : (Employee[]) fnds.clone();
        autos = ats == null ? null : (Auto[]) ats.clone();
        kitty =  c == null ? null : (Cat) c.clone();
    }

    String getFirstName() { return firstName; }

    String getLastName() { return lastName; }

    public String toString() {
        String str = "";
        if ( dogs != null ) {
            str += "\nDOGS: ";
            for ( int i=0; i<dogs.size(); i++ ) {
                str += (Dog) dogs.elementAt(i);
            }       
            str += "\n";
        }
        if ( autos != null ) {
            str += "\nAUTOS: ";
            for ( int i=0; i<autos.length - 1; i++ ) {
                str += " " + autos[i] + ",";
            }       
            str += " " + autos[autos.length - 1];  
            str += "\n";
        }
        if ( friends != null ) {
            str += "\nFRIENDS:";
            for ( int i=0; i<friends.length; i++ ) {
                str += "\n";
                str += friends[i].getFirstName();
                str += " " + friends[i].getLastName();
            }       
            str += "\n";
        }
        if ( kitty != null ) {
            str += "\nCAT:";
            str += kitty;
        }
        if ( phoneList != null ) {
            str += "\nPhone List:";
            str += phoneList;
        }

        return "\nFirst Name: " + firstName 
                    + "\nLast Name: " + lastName 
                    + "\n" + str + "\n";
    }
}


////////////////////////////  class Auto  /////////////////////////////

class Auto {
    String autoBrand;
    Employee owner;
    public Auto( String brand ) { autoBrand = brand; }
    public Auto( String brand, Employee e ) 
    { 
        autoBrand = brand; 
        owner = e;
    }
    public String toString()
    {
        return autoBrand;
    }
}


////////////////////////  class TestEmployee  ////////////////////////

class TestEmployee {
    public static void main( String[] args )
    {
        Employee e1 = new Employee( "Zoe", "Zaphod" );
        Employee e2 = new Employee ( "YoYo", "Ma", 
                                 new Date( 2, 12, 2000 ) );

        Employee[] empList = new Employee[2];
        empList[0] = e1;  
        empList[1] = e2;  

        Auto[] autoList = new Auto[2];
        Auto a1 = new Auto( "Chevrolet" );
        Auto a2 = new Auto( "Ford" );
        autoList[0] = a1;         
        autoList[1] = a2;

        Cat purr = new Cat( "socks", 5 );

        System.out.println( "TEST 1:  " );
        Employee e3 = new Employee( "Bebe", "Ruth", 
                       new Date(1, 2, 2000), 
                       empList, autoList, purr );
        System.out.println( e3 );        


        Employee e4;
        e4 = e3;
        System.out.println( e4 );        


        System.out.println( "\n\nTEST 2: " );

        // what if the kitty reference is null ?
        Employee e5 = new Employee( "Bebe", "Ruth", 
                         new Date(1, 2, 2000), 
                         empList, autoList, null );
        System.out.println( e5 );        


        System.out.println( "\n\nTEST 3: " );

        // what if autoList reference is null also ?
        Employee e6 = new Employee( "Bebe", "Ruth", 
                           new Date(1, 2, 2000), 
                           empList, null, null );
        System.out.println( e6 );        


        System.out.println( "\n\nTEST 4: " );

        // what if empList reference for friends is null also ?
        Employee e7 = new Employee( "Bebe", "Ruth", 
                           new Date(1, 2, 2000), 
                           null, null, null );
        System.out.println( e7 );        

        Employee e8 = e7;    


        System.out.println( "\n\nTEST 5: " );

        // try the vector data member
        Dog dog1 = new Dog( "fido", 3 );
        Dog dog2 = new Dog( "spot", 4 );
        Vector dawgs = new Vector();
        dawgs.addElement( dog1 );
        dawgs.addElement( dog2 );

        Employee e9 = new Employee( "Linda", "Ellerbee", dawgs );
        System.out.println( e9 );


        System.out.println( "\n\nTEST 6: ") ;

        // try the map<string, int> data member
        Map phList = new TreeMap();
        phList.put( "Steve Martin", new Integer( 1234567 ) );
        phList.put( "Bill Gates", new Integer( 100100100 ) );

        Employee e10 = new Employee( "Will", "Rogers", phList );
        System.out.println( e10 );
    }
}