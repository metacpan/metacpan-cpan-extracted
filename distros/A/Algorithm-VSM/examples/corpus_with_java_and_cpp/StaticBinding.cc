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




//StaticBinding.cc

#include <string>
using namespace std;

class UserProfile {
    string name;
    int age;
    // ...
public:
    UserProfile( string str, int yy ) 
             : name(str), age( yy ) {}                            //(P)
    UserProfile( string str ) 
             : name( str ) { age = averageAge(); }                //(Q)
    int averageAge(){ return 48; }
    // ...
};

int main()
{
    UserProfile user1( "Zaphod", 112 );                           //(R)
    UserProfile user2( "Trillion" );                              //(S)
    //...
    return 0;
}
