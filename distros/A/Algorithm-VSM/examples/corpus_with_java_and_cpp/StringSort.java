// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 4 ---- Strings
//
// Section:     Section 4.4.3 -- String Comparison
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//StringSort.java

import java.util.*;

class StringSort {
    public static void main( String[] args ) {
        String[] strArr = { "apples", "bananas", "Apricots", "Berries", 
                            "oranges", "Oranges", "APPLES", "peaches" };
        String[] strArr2 = strArr;

        System.out.println("Case sensitive sort :" );
        Arrays.sort( strArr );
        for (int i=0; i<strArr.length; i++)
            System.out.println( strArr[i] );

        System.out.println("\nCase insensitive sort:" );
        Arrays.sort( strArr2, String.CASE_INSENSITIVE_ORDER );
        for (int i=0; i<strArr2.length; i++)
            System.out.println( strArr2[i] );
    }
}