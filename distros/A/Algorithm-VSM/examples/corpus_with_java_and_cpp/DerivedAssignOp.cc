// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.4  Assignment Operators For Derived Classes In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//DerivedAssignOp.cc

#include <iostream>
using namespace std;

class X {                                // BASE
    int m;
public:
    //constructor:
    X( int mm ) : m( mm ) {}
    //copy constructor:
    X( const X& other ) : m( other.m ) {}    
    //assignment op:
    X& operator=( const X& other ) {                              //(A)
        if ( this == &other ) return *this;
        m = other.m;
        return *this;
    }
    void print() { 
        cout << "m of X obj: " << m << endl; 
    }
};

class Y : public X {                     // DERIVED
    int n;
public:
    //constructor:
    Y( int mm, int nn ) : X( mm ), n( nn ) {}
    //copy constructor:
    Y( const Y& other ) : X( other ), n( other.n ) {}  
    //assignment op:
    Y& operator=( const Y& other ) {                              //(B)
        if ( this == &other ) return *this;
        X::operator=( other );
        n = other.n;
        return *this;
    }
    void print() { 
        X::print();  
        cout << "n of Y obj: " << n << endl; }  
};

int main()
{
    X xobj_1( 5 );                // X's constructor
    X xobj_2 = xobj_1;            // X's copy constructor
 
    X xobj_3( 10 );
    xobj_3 = xobj_2;              // X's assignment op 
    xobj_3.print();               // m of X obj: 5
    cout << endl;
  
    Y yobj_1( 100, 110 );         // Y's constructor
    Y yobj_2 = yobj_1;            // Y's copy constructor
 
    Y yobj_3( 200, 220 );
    yobj_3 = yobj_2;              // Y's assignment op
    yobj_3.print();               // m of X obj: 100
                                  // n of Y obj: 110
    cout << endl;
}