// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 16  Multiple Inheritance In C++
//
// Section:     Section 16.7  Dealing With Name Conflicts For Data Members
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//NameConflictDataMem.cc

#include <iostream>
#include <string>
using namespace std;

class Alien {
protected:
    string name;
public:
    Alien( string nam ) : name( nam ) {}
};

class CatLovingAlien : virtual public Alien  {
protected:
    string name;                  // Cat's name
public:
    CatLovingAlien( string catName, string ownerName ) 
         : Alien( ownerName),  name ( catName ) {}
};

class DogLovingAlien : virtual public Alien {
protected:
    string name;                  // Dog's name
public:
    DogLovingAlien( string dogName, string ownerName ) 
         : Alien( ownerName ), name( dogName ) {}
};

class PetLovingAlien : public CatLovingAlien, public DogLovingAlien {
public:
    PetLovingAlien( string catName, string dogName, string ownerName )
        : CatLovingAlien( catName, ownerName ), 
          DogLovingAlien( dogName, ownerName ),
          Alien( ownerName ) {}
    void print() {
        cout << CatLovingAlien::name << " "                       //(A)
             << DogLovingAlien::name << " "                       //(B)
             << Alien::name << endl;                              //(C)
    }
};

int main()
{
    PetLovingAlien alien( "Tabby", "Pluto", "Zaphod" );
    alien.print();    // Tabby Pluto Zaphod
    return 0;
}