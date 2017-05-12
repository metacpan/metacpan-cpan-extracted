// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 5 ---- Using the Container Classes
//
// Section:     Section 5.2.2 ---- Set
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//





//SetOps.java

import java.util.*;

class SetOps {

    public static void main( String[] args )
    {
        Set animals = new TreeSet();                              //(A)

        animals.add( "cheetah" );                                 //(B)
        animals.add( "lion" );                                    //(C)
        animals.add( "cat" );                                     //(D)
        animals.add( "elephant" );                                //(E)
        animals.add( "cat" );                  // duplicate cat   //(F)
        System.out.println( animals );                            //(G)
                                // cat cheetah elephant lion
        System.out.println( animals.size() );  // 4               //(H)

        animals.remove( "lion" );                                 //(I}
        System.out.println( animals );  // cat cheetah elephant   //(J)

        Iterator iter = animals.iterator();                       //(K)
        while ( iter.hasNext() )                                  //(L)
            System.out.println( iter.next() );                    //(M)
                                        // cat cheetah elephant
    }
}