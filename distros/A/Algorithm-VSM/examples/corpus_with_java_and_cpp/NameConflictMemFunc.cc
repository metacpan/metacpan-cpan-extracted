// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 16  Multiple Inheritance In C++
//
// Section:     Section 16.6  Avoiding Name Conflicts For Member Functions
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//NameConflictMemFunc.cc

#include <iostream>
using namespace std;

class X {
public:
    void foo() { cout << "X's foo invoked" << endl; }
};

class Y : virtual public X {
public:
    void foo() { cout << "Y's foo invoked" << endl; }
};

class T : virtual public X {
public:
    void foo() {cout << "T's foo invoked" << endl;}               //(A)
};

class U : public Y, public T {
public:
    void foo() {cout << "U's foo invoked" << endl;}               //(B)
};

int main()
{
    U u;
    u.foo();             // U's foo invoked                       //(C)
    u.X::foo();          // X's foo invoked
    u.Y::foo();          // Y's foo invoked
    u.T::foo();          // T's foo invoked
    return 0;
}