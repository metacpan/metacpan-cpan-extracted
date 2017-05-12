// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.9  Restrictions On Overriding Functions In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//PrivateVirtual.cc

#include <iostream>
using namespace std;

class Base {                           // BASE
    int m;
    virtual void foo(){cout <<"Base's foo invoked"<< endl;}  //(C)
public:
    Base( int mm ) : m( mm ) {}
    void bar() { foo(); }                                    //(D)
    virtual ~Base(){}                                        //(E)
};

class Derived : public Base {          // DERIVED
    int n;
    void foo() { cout << "Derived's foo invoked" << endl; }  //(F)
public:
    Derived( int mm, int nn ) : Base( mm ), n( nn ) {}
    ~Derived(){}                                                     
};

int main() {
    Base* p = new Derived( 10, 20 );                         //(G)
    p->bar();             //output: Derived's foo invoked    //(H)
    delete p;
    return 0;
}