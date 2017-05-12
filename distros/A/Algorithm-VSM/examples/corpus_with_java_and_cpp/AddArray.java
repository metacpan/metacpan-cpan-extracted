// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 2 -- Baby Steps
//
// Section:     Section 2.1 --- Simple Programs: Summing An Array Of Integers
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//AddArray.java       

public class AddArray {                                           //(A)

    public static void main( String[] args )                      //(B)
    {
        int[] data = { 0, 1, 2, 3, 4, 5, 9, 8, 7, 6 };            //(C)
        System.out.println( "The sum is: "                        //(D)
                                 + addArray(data) );  
    }

    public static int addArray( int[] a ) {                       //(E)
        int sum = 0;                               
        for ( int i=0; i < a.length; i++ )            
            sum += a[i];                             
        return sum;                                
    }
}          
