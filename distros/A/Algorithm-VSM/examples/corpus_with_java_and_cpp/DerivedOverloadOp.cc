// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.5  Overloading Operators For Derived Classes In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//DerivedOverloadOp.cc

#include <iostream>
#include <string>
using namespace std;

///////////////////////////  class Person  ///////////////////////////
class Person {
    string name;
public:
    Person( string nom ) : name( nom ) {}            
    Person( const Person& p ) : name( p.name ) {}    
    Person& operator=( const Person& p ) {                    
        if ( this != &p ) name = p.name;
        return *this;
    }
    virtual ~Person() {}
    friend ostream& operator<<( ostream& os, const Person& p );
};

//overload << for base class Person:
ostream& operator<<( ostream& os, const Person& p ) {             //(D)
    os << p.name;
    return os;
}

//////////////////////////  class Employee  //////////////////////////
class Employee: public Person {
    string department;
    double salary;
public:
    Employee( string name, string dept, double s )
        : Person( name ), department( dept ), salary( s ) {}
    Employee( const Employee& e ) 
        : Person( e ), department( e.department ), 
          salary( e.salary ) {}
    Employee& operator=( const Employee& e ) {
        if ( this != &e ) {
            Person::operator=( e );
            department = e.department;
            salary = e.salary;
        }
        return *this;
    }
    ~Employee() {}
    friend ostream& operator<<( ostream& os, const Employee& p );
};

//overload << for derived class Employee:
ostream& operator<<( ostream& os, const Employee& e ) {           //(E)
    const Person* ptr = &e;          //upcast
    os << *ptr;    
    os << " " << e.department << " " << e.salary;
    return os;
}

///////////////////////////  class Manager  ///////////////////////////       
class Manager: public Employee {
    string title;
public:
    Manager( string name, string dept, double salary, string atitle ) 
           : Employee( name, dept, salary), 
             title( atitle ) {}
    Manager( const Manager& m ) : Employee( m ), title( m.title ) {}
    Manager& operator=( const Manager& m ){
        if ( this != &m ) {
            Employee::operator=( m );
            title = m.title;
        }
        return *this;
    }
    ~Manager() {}
    friend ostream& operator<<( ostream& os, const Manager& m );
};

//overload << for derived class Manager:
ostream& operator<<( ostream& os, const Manager& m ) {            //(F)
    const Employee* ptr = &m;         //upcast
    os << *ptr;
    os << " " << m.title;
    return os;
}

///////////////////////////////  main  ///////////////////////////////
int main() 
{
    Manager m1( "Zahpod", "assembly", 100, "director" );
    Manager m2( m1 );                   // invokes copy construct
    cout  << m2 << endl;                // Zaphod assembly 100 director
    Manager m3( "Trillion", "sales", 200, "vice_pres" );
    m2 = m3;                            // invokes assignment oper
    cout  << m2 << endl;                // Trillion sales 200 vice_pres
    return 0;
}