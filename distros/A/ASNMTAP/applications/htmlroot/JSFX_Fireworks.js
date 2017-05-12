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
 * Class FireworkDisplay (extends Object)
 */
JSFX.FireworkDisplay = function(numFireworks)
{
	JSFX.FireworkDisplay.Fireworks = new Array();
	JSFX.FireworkDisplay.running = true;

	JSFX.FireworkDisplay.loadImages();

	var i=0;
	for(i=0 ; i<numFireworks; i++)
		JSFX.FireworkDisplay.Fireworks[i]=new JSFX.Firework(i, JSFX.FireworkDisplay.fwImages);

	setTimeout("JSFX.FireworkDisplay.animate()", 30 );
}
JSFX.FireworkDisplay.loadImages = function()
{
	var i;
	JSFX.FireworkDisplay.fwImages = new Array();

	for(i=0 ; i<21 ; i++)
	{
		JSFX.FireworkDisplay.fwImages[i] = new Image();
		JSFX.FireworkDisplay.fwImages[i].src = "/asnmtap/img/fw0/"+i+".gif"
	}
}
JSFX.FireworkDisplay.animate = function()
{
	var i;
	for(i=0 ; i<JSFX.FireworkDisplay.Fireworks.length ; i++)
		JSFX.FireworkDisplay.Fireworks[i].animate();

	setTimeout("JSFX.FireworkDisplay.animate()", 30);
}
/*
 * End Class FireworkDisplay
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
}
JSFX.Firework.prototype = new JSFX.Layer;

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
		if(Math.random() > 0.95)
		{
			var x=Math.floor(Math.random()*(JSFX.Browser.getMaxX()-100) );
			var y=Math.floor(Math.random()*(JSFX.Browser.getMaxY()-100) );
			this.moveTo(x,y);
			this.show();
			this.state="ON";
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

