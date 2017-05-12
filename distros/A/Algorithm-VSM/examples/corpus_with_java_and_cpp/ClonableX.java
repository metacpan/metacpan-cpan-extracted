// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.12  Object Cloning In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//ClonableX.java

class X implements Cloneable {
    public int n;
    public X() { n = 3; }
  
    public static void main( String[] args )
    {
        X xobj = new X();
        X xobj_clone = null;

        try {
            xobj_clone = (X) xobj.clone();                        //(A)
        } catch (CloneNotSupportedException e){}
    
        System.out.println( xobj.n );                   // 3
        System.out.println( xobj_clone.n );             // 3

        xobj_clone.n = 3000;

        System.out.println( xobj.n );                   // 3
        System.out.println( xobj_clone.n );             // 3000
    }
}