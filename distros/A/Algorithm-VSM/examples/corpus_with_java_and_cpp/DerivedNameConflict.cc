// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 15  Extending Classes
//
// Section:     Section 15.1  Public Derivation Of A Subclass In C++
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//DerivedNameConflict.cc

#include <iostream>
#include <string>
using namespace std;

class User {                        //BASE
    string name;                    // given name
    int age;                        // actual age
public:
    User( string nam, int yy) : name( nam ), age( yy ) {}
    string getName() { return name; }
};

class StudentUser : public User {   //DERIVED
    string name;                    // nickname used at school
    int age;                        // assumed age for partying
public:
    StudentUser( string str1, int yy1, string str2, int yy2 ) 
        : User( str1, yy1 ), name( str2 ), age( yy2 ) {}
    string getName() { return name; }
};

int main()
{
    StudentUser student( "maryjo", 19, "jojo", 21 );
    cout << student.getName() << endl;          // jojo             (D)
    cout << student.User::getName() << endl;    // maryjo           (E)
    return 0;
}