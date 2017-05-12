
// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object-Oriented Programming with C++ and Java
//
// Chapter:     Chapter 6    The Primitive Types and Their Input/Output
//
// Section:     Section 6.7.2  Implicit Type Conversions in Java
//


//Widening.java

class Test {

    static void g1( short x ) { 
        System.out.println( "short version invoked,  x = " + x ); 
    }
    static void g2( int x ) { 
        System.out.println( "int version invoked,  x = " + x ); 
    }
    static float g3( int x ) {
        System.out.println( "widening conversion on return" );
        return x;
    }

    public static void main( String[] args )
    {
        byte b1 = 16;
        byte b2 = 24;
        // char c1 = b1;     // ERROR                             //(A)
        // c1 = b2;          // ERROR                             //(B)

        //widening from byte to short:
        short s = b1;       
        System.out.println( s );     //  output: 16               //(C)

        //widening from char to int:
        char c = 'a';       
        int i1 = c;         
        System.out.println( i1 );    // output: 97                //(D)

        //widening from int to float:
        int i2 = 1234567890;
        float f1 = i2;       
        System.out.println( i2 - (int) f1 );  // output: -46      //(E)

        //widening from float to double:
        float f2 = 1e20f;
        double d1 = f2;      
        System.out.println(d1);  //output: 1.0000000200408773E20  //(F)

        //widening from byte to short in method invocation:
        g1( b1 );     // output: short version invoked,  x = 16   //(G)

        //widening from short to int in method invocation:
        g2( s );      // output: int version invoked,  x =  16    //(H)

        //widening from int to float in method invocation:
        float f3 = g3( i2 );  
                      // output: widening conversion on return    //(I)

        //Error in widening conversion from int to float:
        System.out.println( i2 - (int) f3 );    // output: -46    //(J)
    }    
}
