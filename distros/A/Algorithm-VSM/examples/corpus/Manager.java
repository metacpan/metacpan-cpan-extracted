// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.20  A Java Study Of A Small Class Hierarchy Exhibiting 
                               Moderately Complex Behavior
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//Manager.java

import java.util.*;            // for Comparator, Collections, etc

////////////////////////////  class Date  /////////////////////////////
class Date implements Cloneable {
    private int month;
    private int day;
    private int year;
    public Date( int mm, int dd, int yy ) {
        month = mm; day = dd; year = yy;
    }
    public String toString() { 
        return month + " : " + day + " : " + year;
    }
    public Object clone() {
        Date date = null;
        try {
            date = ( Date ) super.clone();
        } catch( CloneNotSupportedException e ) {}
        return date;
    }
}

/////////////////////////////  class Cat  /////////////////////////////
class Cat implements Cloneable {
    private String name;
    private int age;
    public Cat( String nam, int a ) { name = nam ; age = a; }
    public String toString() { return "  Name: " 
                              + name + "   Age: " + age; }
    public Object clone() {
        Cat cat = null;
        try {
            cat = ( Cat ) super.clone();
        } catch( CloneNotSupportedException e ) {}
        return cat;
    }
}

/////////////////////////////  class Dog  /////////////////////////////
class Dog implements Cloneable {
    private String name;
    private int age;
    public Dog( String nam, int a ) { name = nam; age = a; }
    public String toString() { 
        return "\nName: " + name + "   Age: " + age; 
    }
    public String getName() { return name; }
    public int getAge() { return age; }
    public void print() {
        System.out.println( this );    
    }
    public Object clone() {
        Dog dog = null;
        try {
            dog = ( Dog ) super.clone();
        } catch( CloneNotSupportedException e ) {}
        return dog;
    }
    public double getDogCompareParameter(){ return 0; }           //(G)
    public static class Dog_Comparator implements Comparator {    //(H)
        public int compare( Object o1, Object o2 ) {
            Dog d1 = (Dog) o1;  
            Dog d2 = (Dog) o2;
            if ( d1.getDogCompareParameter() 
                              == d2.getDogCompareParameter() )
                return 0;
            return ( d1.getDogCompareParameter() 
                        < d2.getDogCompareParameter() ) ? -1 : 1;
        }
    }
}

///////////////////////////  class Employee  ////////////////////////// 
class Employee {              // intentionally left uncloneable
    String firstName, lastName;
    Date dateOfBirth;
    Employee[] friends;
    Auto[] autos;
    Cat kitty;
    ArrayList dogs;
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
    public Employee( String first, String last, ArrayList dogs ) {
        firstName = first;  lastName = last;
        this.dogs = dogs == null ? null : (ArrayList) dogs.clone();
    }
    Employee( String first, String last, Date dob, Employee[] fnds ) {
        firstName = first;  lastName = last;
        dateOfBirth = dob == null ? null : (Date) dob.clone(); 
        friends = fnds == null ? null : (Employee[]) fnds.clone();
    }
    Employee( String first, String last, Map phoneList ) {
        firstName = first;  lastName = last;
        this.phoneList = phoneList == null 
           ? null : new TreeMap( (TreeMap) phoneList );  
        // creates the same mappings
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
    Employee( Employee e ) {
        firstName = e.firstName;  lastName = e.lastName;
        dateOfBirth = e.dateOfBirth == null 
              ? null : (Date) e.dateOfBirth.clone();  
        friends = e.friends == null 
              ?  null : (Employee[]) e.friends.clone();
        autos = e.autos == null 
              ? null : (Auto[]) e.autos.clone();
        kitty = e.kitty == null 
              ? null : (Cat) e.kitty.clone();
        phoneList = e.phoneList == null 
              ? null : new TreeMap( (TreeMap) e.phoneList );
    }
    public String getFirstName() { return firstName; }
    public String getLastName() { return lastName; }
    public void addDogToDogs( Dog newDog ) {                      //(I)
        if ( dogs == null ) dogs = new ArrayList();
        dogs.add( newDog );
        Collections.sort( dogs, new Dog.Dog_Comparator() );       //(J)
    }
    public String toString() {
        String str = "";
        if ( dogs != null ) {
            str += "\nDOGS: ";
            ListIterator iter = dogs.listIterator();
            while ( iter.hasNext() )
                str += (Dog) iter.next();
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
        return "\nFirst Name: " + firstName + "\nLast Name: " 
          + lastName  + "\n" + str + "\n";
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

////////////////////////////  class Poodle  ///////////////////////////
class Poodle extends Dog {
    private Employee owner;
    private double weight;                                        //(K)
    private double height;
    public Poodle( Employee owner, String name, int age, 
                       double weight, double height ) 
    {
        super( name, age );
        this.owner = owner;
        this.weight = weight;
        this.height = height;
     }
    public Object clone() {
        Poodle poo = null;
        poo = ( Poodle ) super.clone();
        return poo;
    }
    public String toString() { 
        return super.toString() + "   Pedigree: " + "Poodle " 
               + "   Weight: " + weight + "   Height: " + height ; 
    }
    public double getDogCompareParameter(){ return weight; }      //(L)
}

//////////////////////////  class Chihuahua  //////////////////////////
class Chihuahua extends Dog {
    private Employee owner;
    private double weight;                                        //(M)
    private double height;
    public Chihuahua( Employee owner, String name, int age, 
                            double weight, double height ) 
    {
        super( name, age );
        this.owner = owner;
        this.weight = weight;
        this.height = height;
    }
    public Object clone() {
        Chihuahua huahua = null;
        huahua = ( Chihuahua ) super.clone();
        return huahua;
    }
    public String toString() { 
        return super.toString() + "   Pedigree: " + "Chihuahua " 
               + "   Weight: " + weight + "   Height: " + height ; 
    }
    public double getDogCompareParameter(){ return weight; }      //(N)
}

//////////////////////////  class Manager  ////////////////////////////
class Manager extends Employee {
    private Employee[] workersSupervised;       
    public Manager( Employee e, ArrayList dogs ) {                //(O)
        super( e );
        ListIterator iter = dogs.listIterator();
        while ( iter.hasNext() ) {
            Object object = iter.next();
            try {
                Poodle p = (Poodle) object;
                addDogToDogs( (Dog) p.clone() );                  
            } catch( ClassCastException badpoodlecast ) {
                try {
                    Chihuahua c = (Chihuahua) object;
                    addDogToDogs( (Dog) c.clone() );              
                } catch( ClassCastException badhuahuacast ) {} 
            }
        }
    }
}

/////////////////////////  class TestManager  /////////////////////////
class TestManager {
    public static void main( String[] args )
    {
        Employee e1 = new Employee( "Zoe", "Zaphod" );

        //                         name         age
        Dog dog1  =  new Dog(    "fido",        3 );
        Dog dog2  =  new Dog(    "spot",        4 );
        Dog dog3  =  new Dog(    "bruno",       2 );
        Dog dog4  =  new Dog(    "darth",       1 );

        //                            emp  name   age  weight  height  
        Poodle dog5 = new Poodle(     e1, "pooch",  4,   15.8,  2.1 );
        Poodle dog6 = new Poodle(     e1, "doggy",  3,   12.9,  3.4 );
        Poodle dog7 = new Poodle(     e1, "lola",   3,   12.9,  3.4 );
        Chihuahua dog8 =new Chihuahua(e1, "bitsy",  5,    3.2,  0.3 );
        Chihuahua dog9 =new Chihuahua(e1, "bookum", 5,    7.2,  0.9 );
        Chihuahua dog10=new Chihuahua(e1, "pie",    5,    4.8,  0.7 );

        ArrayList dawgs = new ArrayList();
        dawgs.add( dog1 );
        dawgs.add( dog2 );
        dawgs.add( dog5 );
        dawgs.add( dog6 );
        dawgs.add( dog3 );
        dawgs.add( dog4 );
        dawgs.add( dog10 );
        dawgs.add( dog7 );
        dawgs.add( dog8 );
        dawgs.add( dog9 );

        Manager m1 = new Manager( e1, dawgs );
        Employee e = (Employee) m1;
        System.out.println( e );    // will invoke Employee's toString
    }
}