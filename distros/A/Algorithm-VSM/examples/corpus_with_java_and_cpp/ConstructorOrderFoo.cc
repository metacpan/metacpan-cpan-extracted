// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.11  Constructor Order Dependencies In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//ConstructorOrderFoo.cc

#include <iostream>
using namespace std;

class Base {
public:
    Base() { foo(); }                                             //(A)
    virtual void foo() {                                          //(B)
        cout << "Base's foo invoked" << endl; 
    }
};

class Derived : public Base {
public:
    Derived() {}                                                  //(C)
    void foo() {                                                  //(D)
        cout << "Derived's foo invoked" << endl; 
    }
};

int main() { 
    Derived d;             // invokes Base's foo()                //(E) 
    return 0;
}