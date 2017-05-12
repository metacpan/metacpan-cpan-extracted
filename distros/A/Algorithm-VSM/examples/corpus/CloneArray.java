// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.12  Object Clooning In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//CloneArray.java

import java.util.*;                           // for Random

class X implements Cloneable {

    public int[] arr = new int[5];

    public X() { 
        Random ran = new Random(); 
        int i=0; 
        while ( i < 5 ) 
            arr[i++] = (ran.nextInt() & 0xffff)%10;               //(A)
    }

    public Object clone() throws CloneNotSupportedException {     //(B)
        X xob = null;
        xob = (X) super.clone();
        //now clone the array separately:
        xob.arr = (int[]) arr.clone();                            //(C)
        return xob;
    }

    public String toString() {
        String printstring = "";
        for (int i=0; i<arr.length; i++) printstring += " " + arr[i];
        return printstring;
    }

    public static void main( String[] args ) throws Exception {
        X xobj = new X();
        X xobj_clone = (X) xobj.clone();                          //(D)       

        System.out.println( xobj );           // 0 4 5 2 5
        System.out.println( xobj_clone );     // 0 4 5 2 5

        xobj.arr[0] = 1000;                                       //(E)

        System.out.println( xobj );           // 1000 4 5 2 5
        System.out.println( xobj_clone );     // 0 4 5 2 5 
    }
}