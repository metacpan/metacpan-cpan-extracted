// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.7.2  Virtual Functions in Multilevel Hierarchies
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//VirtualPrint2.cc

#include <iostream>
#include <string>
#include <vector>
using namespace std;

class Person {                            // BASE
    string firstName, lastName;    
public:
    Person( string fnam, string lnam ) 
              : firstName( fnam ), lastName( lnam ) {}
    virtual void print() const { cout << firstName                //(A)
                           << " " << lastName << " "; }
    virtual ~Person(){}                                           //(B)
};

class Employee : public Person {
    string companyName;
public:
    Employee( string fnam, string lnam, string cnam )
        : Person( fnam, lnam ), companyName( cnam ) {}
    void print() const { 
        Person::print();
        cout << companyName << " "; 
    }
    ~Employee(){}                                                 //(C)
};


class Manager : public Employee {         // DERIVED
    short level;
public:
    Manager( string fnam, string lnam, string cnam, short lvl ) 
        : Employee( fnam, lnam, cnam ), level( lvl ) {}
    void print() const {
      Employee::print();
      cout << level;
    }
    ~Manager(){}                                                  //(D)
};

int main()
{
    vector<Employee*> empList;

    Employee* e1 = new Employee( "mister", "bigshot", "megaCorp" );
    Employee* e2 = new Employee( "ms", "importante", "devourCorp" );
    Employee* m3 = new Manager("mister", "biggun", "plunderCorp" , 2);
    Employee* m4 = new Manager("ms", "shiningstar", "globalCorp", 2);  

    empList.push_back( e1 );
    empList.push_back( e2 );
    empList.push_back( m3 );
    empList.push_back( m4 );

    vector<Employee*>::iterator p = empList.begin();
    while ( p < empList.end() ) {                                 //(E)
        (*p++)->print();                                          //(F)
        cout << endl;
    }

    delete e1;
    delete e2;
    delete m3;
    delete m4;

    return 0;
}