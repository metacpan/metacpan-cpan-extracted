// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.8  Static Versus Dynamic Binding For Functions In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//VtprConcealed.cc

#include <iostream>
using namespace std;

class X {
    int n;
public:
    X( int nn ) : n( nn ) {}
    virtual ~X(){}
};

int main(){
    cout << sizeof( X ) << endl;         // 8

    X xobj( 10 );                        // 8
    cout << sizeof( xobj ) << endl;
}