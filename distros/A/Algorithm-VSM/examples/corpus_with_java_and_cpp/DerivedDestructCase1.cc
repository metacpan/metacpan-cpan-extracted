// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.6  Destructors For Derived Classes In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//DerivedDestructCase1.cc

#include <iostream>
using namespace std;

class X {                             // BASE
public:
    int* x_data;
    int x_size;
    //constructor:
    X( int* ptr, int sz ) : x_size(sz) { 
        cout << "X's constructor invoked" << endl;                //(A)
        x_data = new int[ x_size ];
        int i=0; 
        int* temp = x_data; 
        while (i++<x_size) *temp++ = *ptr++;
    }
    //destructor:
    ~X() {                                                        //(B)
        cout << "X's destructor invoked" << endl;                 //(C)
        delete [] x_data; 
    }
};

//class Y is NOT supplied with a programmer-defined destructor:
class Y : public X {                  // DERIVED
    int y;
public:
    Y( int* xptr, int xsz, int yy) : X( xptr, xsz ), y( yy ) {
        cout << "Y's constructor invoked" << endl;                //(D)
    }
};

int main()
{
    int freshData[100] = {0};
    Y* yptr = new Y( freshData, 100, 1000 );                      //(E)
    delete yptr;                                                  //(F)
    return 0;
}