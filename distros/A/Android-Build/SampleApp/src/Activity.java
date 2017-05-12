/*------------------------------------------------------------------------------
Sample Android App
Philip R Brenan at gmail dot com, © Appa Apps Ltd Inc, 2017
------------------------------------------------------------------------------*/
package com.appaapps.genapp;

public class Activity extends android.app.Activity
 {public void onCreate(android.os.Bundle save)
   {super.onCreate(save);
    setContentView(new Display());
   }
  class Paint extends android.graphics.Paint {}

  class Display extends android.view.View
   {Display()                                                                   // Create display
     {super(Activity.this);
     }

    public void onDraw(android.graphics.Canvas c)                               // Draw
     {final Paint p = new Paint();
      final int delta = 100;
      postInvalidateDelayed(1000);                                              // Keep the redraw cycle going
      p.setColor(0xff000000);
      p.setStyle(Paint.Style.FILL);
      c.drawRect(0f, 0f, c.getWidth(), c.getHeight(), p);                       // Clear

      p.setColor(0xffff4488);
      p.setStyle(Paint.Style.FILL);
      p.setTextSize(delta);
      p.setShadowLayer(1, 10,  10,  0xff000080);
      c.drawText("Hello World", delta, delta, p);
      c.drawText("Hello World", delta, 2*delta, p);
     }
   }
 }
