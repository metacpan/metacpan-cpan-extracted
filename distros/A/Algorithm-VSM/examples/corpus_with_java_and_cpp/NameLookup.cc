// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.14  Extending Classes In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//NameLookup.cc                  // WILL NOT COMPILE

#include <iostream>
using namespace std;

class Base {
public:
    void foo() {                                                  //(A)
        cout << "Base's foo() invoked" << endl; 
    }
    void foo( int i ) {                                           //(B)
        cout << "Base's foo( int ) invoked" << endl; 
    }
    void foo( int i, int j ) {                                    //(C)
        cout << "Base's foo( int, int ) invoked" << endl; 
    }
};

class Derived : public Base {                                     
public:
    void foo() { cout << "Derived's foo() invoked"  << endl; }    //(D)
};
   
int main()
{
    Derived d;        
    d.foo();                                                      //(E)
    d.foo( 3 );                                                   //(F)
    d.foo( 3, 4 );                                                //(G)
}
