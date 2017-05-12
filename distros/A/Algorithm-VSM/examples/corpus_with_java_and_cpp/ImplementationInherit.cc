// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.13  Protected And Private Derived Classes In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//ImplementationInherit.cc

#include <iostream>
#include <string>
#include <vector>
using namespace std;

class Employee {
    string firstName, lastName;
    int age, yearsInService;
public:
    Employee( string fnam, string lnam )
        : firstName( fnam ), lastName( lnam ) {}
    virtual void print() const {
        cout << firstName << " " << lastName << endl; 
    }
    void sayEmployeeHello() { 
        cout << "hello from Employee class" << endl; 
    }
};

class ExecutiveRole {
public:
    void sayExecutiveHello(){ 
        cout << "Hello from Executive ranks" << endl; 
    }
};

//class Manager 
//       : public Employee, private ExecutiveRole { // WILL NOT COMPILE
class Manager 
         : public Employee, protected ExecutiveRole {  // WORKS FINE
    short level;
public:
    Manager( string fnam, string lnam, short lvl ) 
        : Employee( fnam, lnam ), level( lvl ) { 
        cout<< "In Manager constructor: "; 
        sayEmployeeHello(); 
        sayExecutiveHello();                                      //(A)
    }
    void print() const {
        Employee::print();
        cout << "level: " << level << endl;
    }
};

class Director : public Manager {
    short grade;
public:
    Director( string fnam, string lnam, short lvl, short gd ) 
           : Manager( fnam, lnam, lvl ), grade( gd ) { 
        cout << "In Director constructor: "; 
        sayEmployeeHello(); 
        sayExecutiveHello();                                      //(B)
    }
    void print() const {
        Manager::print();
        cout << "grade: " << grade << endl << endl;
    }
};

int main() {
    vector<Employee*> empList;

    Employee* e1 = new Employee( "joe", "schmoe" );
    Employee* e2 = (Employee*) new Manager( "ms", "importante", 2 );
    Employee* e3 = 
           (Employee*) new Director("mister", "bigshot", 3, 4);   //(C)
   
    empList.push_back( e1 );
    empList.push_back( e2 );
    empList.push_back( e3 );
  
    vector<Employee*>::iterator p = empList.begin();
    while ( p < empList.end() ) (*p++)->print();
   
    Manager* m = new Manager( "jane", "doe", 2 );
    m->sayEmployeeHello();
 
    Director* d = new Director( "john", "doe", 3, 4 );
    d->sayEmployeeHello();
    return 0;
}