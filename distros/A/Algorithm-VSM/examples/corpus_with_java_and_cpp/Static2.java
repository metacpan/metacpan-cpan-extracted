// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.4  Static Members In Java
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//Static2.java

class X {
    private static int n = 100;                                   //(A)
    public int m;                                          
    public X( int mm ) { m = mm; }                 
    public static int getn() {return n;}                          //(B)
    public static void setn( int nn ) { n = nn; }                 //(C)
}

class Test {
    public static void main(String[] args)
    {
        System.out.println( X.getn() );        // 100             //(D)

        X xobj_1 = new X( 20 );                         
        System.out.println(xobj_1.m + " " + xobj_1.getn()); //20 100  
                                                           
        X xobj_2 = new X( 40 );                         
        System.out.println(xobj_2.m + " " + xobj_2.getn()); //40 100   
                                                           
        X.setn( 1000 );                                           //(E)
  
        System.out.println(xobj_1.m + " " + xobj_1.getn()); //20 1000
                                                          
        System.out.println(xobj_2.m + " " + xobj_2.getn()); //40 1000 
    }
}