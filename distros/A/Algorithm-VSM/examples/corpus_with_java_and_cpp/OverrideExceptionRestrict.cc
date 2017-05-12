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




//OverrideExceptionRestrict.cc

#include <iostream>
using namespace std;

class E1 {};                          // BASE exception type
class E2 : public E1 {};              // DERIVED exception type
class E3 {};

class Base {                          // BASE
    int m;
public:
    Base( int mm ) : m( mm ) {}
    virtual void foo() throw( E1 ) {                        //(I) 
        cout << "Base's foo" << endl;  throw E1();
    }
    virtual ~Base() {}
};

class Derived_1 : public Base {       // DERIVED
    int n;
public:
    Derived_1( int mm, int nn ) : Base( mm ), n( nn ) {}
    void foo() throw( E2 ) {                                //(J)
        cout << "Derived_1's foo" << endl;  throw E2();
    }
    ~Derived_1() {}
};

class Derived_2 : public Base {       // DERIVED
    int p;
public:
    Derived_2( int mm, int pp ) : Base( mm ), p( pp ) {}
    // void foo() throw (E3) {}       //ERROR               //(K)
    ~Derived_2() {}
};

int main() {
    Base* p = new Derived_1( 10, 20 );
    try {
        p->foo();                                           //(L)
    } catch( E1 e ) { cout << "caught E1" << endl; }
    delete p;  return 0;
}