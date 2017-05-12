/*******************************************************************
*
* File    : JSFX_Fireworks.js © JavaScript-FX.com
*
* Created : 2001/03/16
*
* Author  : Roy Whittle www.Roy.Whittle.com
*           
* Purpose : To create animated fireworks
*
* History
* Date         Version        Description
*
* 2001-03-17	2.0		Converted for javascript-fx
***********************************************************************/
/*
 * Class FireworkDisplay2 (extends Object)
 */
JSFX.FireworkDisplay2 = function(numFireworks)
{
	JSFX.FireworkDisplay2.Fireworks = new Array();
	JSFX.FireworkDisplay2.running = true;

	JSFX.FireworkDisplay2.loadImages();

	var i=0;
	for(i=0 ; i<numFireworks; i++)
		JSFX.FireworkDisplay2.Fireworks[i]=new JSFX.Firework(i, JSFX.FireworkDisplay2.fwImages);

	setTimeout("JSFX.FireworkDisplay2.animate()", 30 );
}
JSFX.FireworkDisplay2.loadImages = function()
{
	var i;
	JSFX.FireworkDisplay2.fwImages = new Array();

	for(i=0 ; i<21 ; i++)
	{
		JSFX.FireworkDisplay2.fwImages[i] = new Image();
		JSFX.FireworkDisplay2.fwImages[i].src = "/asnmtap/img/fw0/"+i+".gif"
	}
}
JSFX.FireworkDisplay2.animate = function()
{
	var i;
	for(i=0 ; i<JSFX.FireworkDisplay2.Fireworks.length ; i++)
		JSFX.FireworkDisplay2.Fireworks[i].animate();

	setTimeout("JSFX.FireworkDisplay2.animate()", 30);
}
/*
 * End Class FireworkDisplay2
 */

/*
 * Class Firework extends Layer
 */
JSFX.Firework = function(fwNo, theImages)
{
	var imgName = "fw"+fwNo;
	var htmlStr = "<IMG SRC='"+theImages[0].src+"' NAME='"+imgName+"'>"

	//Call the superclass constructor
	this.superC = JSFX.Layer;
	this.superC(htmlStr);

	this.frame		= 0;
	this.state		= "OFF";
	this.fwImages	= theImages;
	this.imgName	= imgName;
	this.ay		= 0.2;
	this.resizeTo(2,2);
}
JSFX.Firework.prototype = new JSFX.Layer;

JSFX.Firework.prototype.getMaxDy = function()
{
	var ydiff = JSFX.Browser.getMaxY() - JSFX.Browser.getMinY() - 30;
	var dy    = 1;
	var dist  = 0;
	var ay    = this.ay;
	while(dist<ydiff)
	{
		dist += dy;
		dy+=ay;
	}
	return -dy;
}
JSFX.Firework.prototype.animate = function()
{
	if(this.state == "ON")
	{
		this.frame++
		if(this.frame == this.fwImages.length)
		{
			this.frame = 0;
			this.state = "OFF";
			this.hide();
		}
		else
		{
			this.images[this.imgName].src = this.fwImages[this.frame].src;
		}
	}
	else if(this.state == "OFF")
	{
		this.dy = this.getMaxDy();
		this.dx = Math.random()*-8 + 4;
		this.dy += Math.random()*3;
		this.clip(0,0,3,3);
		this.setBgColor(Math.random()>.33 ? Math.random()>.33 ? "#FF0000" : "#00FF00" : "#0000FF");

		this.x=JSFX.Browser.getMaxX()/2;
		this.y=JSFX.Browser.getMaxY()-10;
		this.moveTo(this.x,this.y);
		this.show();
		this.state="TRAVEL";
	}
	else if(this.state == "TRAVEL")
	{
		this.x += this.dx;
		this.y += this.dy;
		this.dy += this.ay;
		this.moveTo(this.x,this.y);
		if(this.dy > -1 && Math.random()<.05)
		{
			this.state = "ON";
			this.setBgColor(null);
			this.clip(0,0,100,100);
			this.x -=50;
			this.y -=50;
			this.moveTo(this.x, this.y);
		}
	}

}
/*** If no other script has added it yet, add the ns resize fix ***/
if(navigator.appName.indexOf("Netscape") != -1 && !document.getElementById)
{
	if(!JSFX.ns_resize)
	{
		JSFX.ow = outerWidth;
		JSFX.oh = outerHeight;
		JSFX.ns_resize = function()
		{
			if(outerWidth != JSFX.ow || outerHeight != JSFX.oh )
				location.reload();
		}
	}
	window.onresize=JSFX.ns_resize;
}

