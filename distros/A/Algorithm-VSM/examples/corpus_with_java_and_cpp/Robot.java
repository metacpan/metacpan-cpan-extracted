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



//Robot.java

class Robot {
    public int idNum;
    public static int nextIdNum = 1;                              //(A)
    public String owner;

    public int getIdNum() { return idNum; }
    public String getOwner() { return owner; }

    public Robot() { idNum = nextIdNum++; };                      //(B)
    public Robot( String name) { this(); owner = name; }          //(C)

    public void print() { System.out.println( idNum + " " + owner ); }

    public static void  main( String[] args )
    {
        Robot r1 = new Robot( "ariel" );
        r1.print();                               // 1 ariel
        Robot r2 = new Robot( "mauriel" );
        r2.print();                               // 2 maurial
        Robot r3 = new Robot( "mercurial" );
        r3.print();                               // 3 mercurial
    }
}