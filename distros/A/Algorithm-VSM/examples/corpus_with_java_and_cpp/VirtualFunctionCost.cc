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




//VirtualFunctionCost.cc

class X {                         // BASE
    // ...
public:
    virtual void foo();
};

class Y : public X {              // DERIVED
    // ...
public:
    void foo();
};

int main() {
    X* p;
    // ....
    //   p could be made to point to either 
    //   an X object or a Y object
    // ...
    p->foo();                                                     //(T)
    // ...
}