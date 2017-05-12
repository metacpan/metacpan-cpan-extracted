// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 5 ---- Using the Container Classes
//
// Section:     Section 5.2.1 ---- List
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//





//ListOps.java

import java.util.*;

class ListOps {
    public static void main( String[] args )
    {
        List animals = new ArrayList();                           //(A)
        animals.add( "cheetah" );                                 //(B)
        animals.add( "lion" );                            
        animals.add( "cat" );           
        animals.add( "fox" );           
        animals.add( "cat" );           //duplicate cat           //(C)
        System.out.println( animals );  //cheetah, lion, cat, fox, 
                                        //cat

        animals.remove( "lion" );                                 //(D)
        System.out.println( animals );  //cheetah, cat, fox, cat

        animals.add( 0, "lion" );                                 //(E)
        System.out.println( animals );  //lion, cheetah, cat, fox, 
                                        //cat

        animals.add( 3, "racoon" );                               //(F)
        System.out.println( animals );  //lion, cheetah, cat, 
                                        //racoon, fox, cat

        animals.remove(3);                                        //(G)
        System.out.println( animals );  //lion, cheetah, cat, 
                                        //fox, cat

        Collections.sort( animals );                              //(H)
        System.out.println( animals );  //cat, cat, cheetah, 
                                        //fox, lion

        List pets = new LinkedList();                             //(I)
        pets.add( "cat" );                                        //(J)
        pets.add( "dog" );
        pets.add( "bird" );
        System.out.println( pets );     //cat, dog, bird

        animals.addAll( 3, pets );                                //(K)
        System.out.println( animals );  //cat, cat, cheetah, 
                                        //cat, dog, bird, fox, 
                                        //lion

        ListIterator iter = animals.listIterator();               //(L)
        while ( iter.hasNext() ) {                                //(M)
            System.out.println( iter.next()  );                   //(N)
        }
    }
}
