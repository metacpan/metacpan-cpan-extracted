// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 11  Classes, The Rest Of The Story
//
// Section:     Section 11.12.1  Cloning Arrays of Class-Type Objects
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//



//CloneClassTypeArr.java

class X implements Cloneable {
    public int p;
    public X( int q ) { p = q; }
    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }
    public String toString() { return p + ""; }
}

class Y implements Cloneable {
    public X x;
    public Y( X x ) { this.x = x; }
    public Object clone() throws CloneNotSupportedException {
        Y clone = (Y) super.clone();
        clone.x = (X) x.clone();
        return clone;
    }        
    public String toString() { return x + ""; }
}

class Z implements Cloneable {
    public Y[] yarr;
    public Z( Y[] arr ) { this.yarr = arr; }
    public Object clone() throws CloneNotSupportedException {     //(A)
        Z zclone = (Z) super.clone();
        // zclone.yarr = ( Y[] ) yarr.clone();      // WRONG      //(B)     
        Y[] yarrClone = new Y[ yarr.length ];                     //(C)
        for (int i=0; i < yarr.length; i++ )
            yarrClone[i] = (Y) yarr[i].clone();                   //(D)
        zclone.yarr = yarrClone;                                  //(E)
        return zclone;
    }
    public String toString() {
        String superString = "";
        for ( int i = 0; i < yarr.length; i++ ) {
            superString += yarr[i] + "  ";
        }
        return superString;
    }
}


class Test {
    public static void main( String[] args ) throws Exception
    {
        X xobj0 = new X( 5 );
        X xobj1 = new X( 7 );

        Y yobj0 = new Y( xobj0 );
        Y yobj1 = new Y( xobj1 );

        Y[] yarr = new Y[2];
        yarr[0] = yobj0;
        yarr[1] = yobj1;
        
        Z zobj = new Z( yarr );
        System.out.println( zobj );           // 5 7

        Z zclone = (Z) zobj.clone();
        System.out.println( zclone );         // 5 7

        zclone.yarr[0].x.p = 1000;

        System.out.println("\n\nComparing again zobj and its clone:");        
        System.out.println( zobj );           // 5 7
        System.out.println( zclone );         // 1000 7

        if ( zobj.yarr == zclone.yarr )
            System.out.println( 
                          "\n\nThere was no cloning of the Y array" );
        if ( zobj.yarr[0].x == zclone.yarr[0].x )
            System.out.println( "\n\nThe Y array was cloned, "
                 + "but its elements point to the same X objects" );
    }
}