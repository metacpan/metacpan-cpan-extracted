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




//ConstructorOrder.cc

#include <iostream> 
using namespace std;

class X {
public:
    X() { cout << "X object under construction" << endl; } 
};

class Y {
public:
    Y() { cout << "Y object under construction" << endl; } 
};

class Base { 
    X xobj;                                                       //(A)
    Y yobj;                                                       //(B)
public:
    Base() : xobj( X() ), yobj( Y() ) {}                          //(C)
};

int main() { 
    Base b;                                                       //(D)
    return 0;
}