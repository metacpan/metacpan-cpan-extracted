// This code example is from the following source:
//
// Book Title:  Programming with Objects, A Comparative Presentation
//              of Object Oriented Programming with C++ and Java
//
// Chapter:     Chapter 3 ---- The Notion Of A Class And Some Other Ideas
//
// Section:     Section 3.16 - Nested Types
//
// The links to the rest of the code in this book are at
//     
//      http://programming-with-objects.com/pwocode.html
//
// For further information regarding the book, please visit
//
//      http://programming-with-objects.com
//




//NestedInterface.java

interface Drawable {

    class Color {
        private int red;
        private int green;
        private int blue;
        public Color( int r, int g, int b ) {
            red = r;
            green = g;
            blue = b;
        }
    }

    void setColor( Color c );
    void draw();
}

class Rectangle implements Drawable {
    private Color color;  // Color made available by the interface
    private int width;
    private int height;
 
    public Rectangle( int w, int h ) {
        width = w;
        height = h;
    }

    public void setColor( Color c ) { color = c; }

    public void draw() {
        System.out.println( "Invoke code for drawing a rectangle" );
    }

    public static void main( String[] args ) {
        Color col = new Color( 120, 134, 200 );
        Rectangle rect = new Rectangle( 23, 34 );
        rect.setColor( col );
        rect.draw();
    }
}