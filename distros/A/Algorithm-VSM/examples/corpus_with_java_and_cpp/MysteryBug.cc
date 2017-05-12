// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.22  Homework
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//MysteryBug.cc

#include <iostream>
using namespace std;

class X {
    int* p;
    int size;
public:
    X() { p = 0; size = 0; }
    X( int* ptr, int sz ) : size( sz ) {
        p = new int[ size ];
        for ( int i=0; i<size; i++ ) p[i] = ptr[i];
    }
    ~X() { delete[] p; }
};

class Y : public X {
    int n;
public:
    Y() {};
    Y( int* ptr, int sz, int nn ) : X( ptr, sz ), n( nn ) {}
    Y( const Y& other ) : X( other ), n( other.n ) {}
    Y& operator=( const Y& other ) {
        if ( this == &other ) return *this;
        X::operator=( other );
        n = other.n;
        return *this;
    }
};

int main() {
    int data[ 3 ] = {3, 2, 1};
    Y y1( data, 3, 10 );
    Y y2;
    y2 = y1;                                                 //(A)
    cout << "hello" << endl;                                 //(B) 
    return 0;
}