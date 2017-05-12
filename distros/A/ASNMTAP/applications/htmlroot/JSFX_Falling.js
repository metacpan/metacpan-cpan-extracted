/*******************************************************************
*
* File    : JSFX_Falling.js © JavaScript-FX.com
*
* Created : 2000/05/16
*
* Author  : Roy Whittle www.Roy.Whittle.com
*           
* Purpose : To create animated "Falling" images in the browser window
*
* History
* Date         Version        Description
*
* 2001-03-17	2.0		Converted for javascript-fx
* 2001-12-01	2.1		Remove the need for JSFX.Sprite (Use FallingSprite instead)
* 2001-12-01	2.2		Renamed from "Snow" to "Falling". Why?
*					Because users didn't realize you can use it for leaves
*					or confetti or any other falling object!!!!!!
***********************************************************************/
/*
 * Class FallingSprite extends Layer
 */
JSFX.FallingSprite = function(theHtml)
{
	//Call the superclass constructor
	this.superC	= JSFX.Layer;
	this.superC(theHtml);

	this.x = Math.random() * (JSFX.Browser.getMaxX()-40);
	this.y = -40;
	this.dx = Math.random() * 4 - 2;
	this.dy = Math.random() * 6 + 2;
	this.ang = 0;
	this.angStep = .2;
	this.amp = 10;
	this.state = "FALL";

	this.moveTo(this.x,this.y);
	this.show();
}
JSFX.FallingSprite.prototype = new JSFX.Layer;

JSFX.FallingSprite.prototype.animate = function()
{
	if(this.state == "OFF")
		return;

	this.x += this.dx;
	this.y += this.dy;
	this.ang += this.angStep;

	this.moveTo(this.x + this.amp*Math.sin(this.ang), this.y);

	if( (this.x > JSFX.Browser.getMaxX()-20)
	 || (this.x < JSFX.Browser.getMinX()-0)
	 || (this.y > JSFX.Browser.getMaxY()-40) )
	{
		if(this.state == "STOPPING")
		{
			this.moveTo(-100,-100);
			this.hide();
			this.state = "OFF";
		}
		else
		{
			this.x = Math.random() * (JSFX.Browser.getMaxX()-40);
			this.y = JSFX.Browser.getMinY()-40;
			this.dx = Math.random() * 4 - 2;
			this.dy = Math.random() * 6 + 2;
			this.ang = 0;
		}
	}
}
/*** Class FallingObj extends Object ***/
JSFX.FallingObj = function(numSprites, theImage, stopTime)
{
	this.id = "JSFX_FallingObj_"+JSFX.FallingObj.count++;
	this.sprites = new Array();
	for(i=0 ; i<numSprites; i++)
	{
		this.sprites[i]=new JSFX.FallingSprite(theImage);
	}
	window[this.id]=this;
	this.animate();

	if(stopTime)
		setTimeout("window."+this.id+".stop()", stopTime*1000);

}
JSFX.FallingObj.count = 0;

JSFX.FallingObj.prototype.stop = function()
{
	for(i=0 ; i<this.sprites.length ; i++)
		this.sprites[i].state = "STOPPING";
}

JSFX.FallingObj.prototype.animate = function()
{
	setTimeout("window."+this.id+".animate()", 40);

	for(i=0 ; i<this.sprites.length ; i++)
		this.sprites[i].animate();

}
/*** END Class FallingObj ***/

/*
 * Class Falling extends Object (Static method for creating "Falling" objects
 */
JSFX.Falling = function(n, theImage, stopTime)
{
	myFalling = new JSFX.FallingObj(n, theImage, stopTime);

	return myFalling;
}
