// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 4 ---- Strings
//
// Section:     Section 4.4 -- Strings In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//StringLiteralUniqueness.java

class X { public static String strX = "hello"; }                  //(A)

class Y { public static String strY = "hello"; }                  //(B)

class Z { public static String strZ = "hell" + "o"; }             //(C)

class Test {
    public static void main( String[] args ) {

        // output: true
        System.out.println( X.strX == Y.strY );                   //(D)

        // output: true
        System.out.println( X.strX == Z.strZ );                   //(E)

        String s1 = "hel";
        String s2 = "lo";

        // output: false
        System.out.println( X.strX == ( s1 + s2 ) );              //(F)

        // output: true
        System.out.println( X.strX == (s1 + s2).intern() );       //(G)
    }
}