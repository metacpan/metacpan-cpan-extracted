// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.9 Restrictions On Overriding Functions In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//OverrideReturnRestrict.cc

#include <iostream>
using namespace std;

class X {};                         // BASE
class Y : public X {};              // DERIVED

class Base {                        // BASE
public:
    virtual X* bar() {                                       //(A)
        cout << "Base's bar invoked" << endl;
        return new X();
    }
    virtual ~Base(){}
};

class Derived : public Base {       // DERIVED
public:
    Y* bar() {                                               //(B)
        cout << "Derived's bar invoked" << endl;
        return new Y();
    }
    ~Derived(){}
};

int main() {
    Base* b = new Derived();
    b->bar();   // program's output: Derived's bar invoked          
    delete b;
    return 0;
}