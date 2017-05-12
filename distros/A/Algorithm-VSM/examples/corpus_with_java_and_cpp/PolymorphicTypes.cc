// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 16  Multiple Inheritance In C++
//
// Section:     Section 16.11  Run-Time Type Identification In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//PolymorphicTypes.cc

#include <iostream>
using namespace std;

class X { public: virtual ~X(){}; };
class Y : public X {};
class Z : public Y {};

int main()
{
    Y* p = new Z();
    Z* q = dynamic_cast<Z*>( p );
    if ( q != 0 ) cout << "p was actually Z*" << endl;
    return 0;
}