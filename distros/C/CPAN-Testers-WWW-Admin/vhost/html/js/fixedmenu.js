/* Version: 2.11 */

/* Original 'fixedMenu' script by: www.jtricks.com
 * Version: 20071127
 * Latest version:
 * www.jtricks.com/javascript/navigation/fixed_menu.html
 */

var fixedMenuId = 'moreinfo';

var fixedMenu = 
{
    hasInner: typeof(window.innerWidth) == 'number',
    hasElement: document.documentElement != null
       && document.documentElement.clientWidth,

    menu: document.getElementById
        ? document.getElementById(fixedMenuId)
        : document.all
          ? document.all[fixedMenuId]
          : document.layers[fixedMenuId]
};

fixedMenu.computeShifts = function()
{
    fixedMenu.shiftX = fixedMenu.hasInner
        ? pageXOffset
        : fixedMenu.hasElement
          ? document.documentElement.scrollLeft
          : document.body.scrollLeft;
    if (fixedMenu.targetLeft > 0)
        fixedMenu.shiftX += fixedMenu.targetLeft;
    else
    {
        fixedMenu.shiftX += 
            (fixedMenu.hasElement
              ? document.documentElement.clientWidth
              : fixedMenu.hasInner
                ? window.innerWidth - 20
                : document.body.clientWidth)
            - fixedMenu.targetRight
            - fixedMenu.menu.offsetWidth;
    }

    fixedMenu.shiftY = fixedMenu.hasInner
        ? pageYOffset
        : fixedMenu.hasElement
          ? document.documentElement.scrollTop
          : document.body.scrollTop;
    if (fixedMenu.targetTop > 0)
        fixedMenu.shiftY += fixedMenu.targetTop;
    else
    {
        fixedMenu.shiftY += 
            (fixedMenu.hasElement
            ? document.documentElement.clientHeight
            : fixedMenu.hasInner
              ? window.innerHeight - 20
              : document.body.clientHeight)
            - fixedMenu.targetBottom
            - fixedMenu.menu.offsetHeight;
    }

    initPosition();
};

fixedMenu.moveMenu = function()
{
    fixedMenu.computeShifts();

    if (fixedMenu.currentX != fixedMenu.shiftX
        || fixedMenu.currentY != fixedMenu.shiftY)
    {
        fixedMenu.currentX = fixedMenu.shiftX ? fixedMenu.shiftX : 0;
        fixedMenu.currentY = fixedMenu.shiftY ? fixedMenu.shiftY : 0;

        if (document.layers)
        {
            fixedMenu.menu.left = fixedMenu.currentX;
            fixedMenu.menu.top = fixedMenu.currentY;
        }
        else
        {
            fixedMenu.menu.style.left = fixedMenu.currentX + 'px';
            fixedMenu.menu.style.top  = fixedMenu.currentY + 'px';
        }
    }

    fixedMenu.menu.style.right = '';
    fixedMenu.menu.style.bottom = '';
};

fixedMenu.floatMenu = function()
{
    fixedMenu.moveMenu();
    setTimeout('fixedMenu.floatMenu()', 20);
};

// addEvent designed by Aaron Moore
fixedMenu.addEvent = function(element, listener, handler)
{
    if(typeof element[listener] != 'function' || 
       typeof element[listener + '_num'] == 'undefined')
    {
        element[listener + '_num'] = 0;
        if (typeof element[listener] == 'function')
        {
            element[listener + 0] = element[listener];
            element[listener + '_num']++;
        }
        element[listener] = function(e)
        {
            var r = true;
            e = (e) ? e : window.event;
            for(var i = 0; i < element[listener + '_num']; i++)
                if(element[listener + i](e) === false)
                    r = false;
            return r;
        }
    }

    //if handler is not already stored, assign it
    for(var i = 0; i < element[listener + '_num']; i++)
        if(element[listener + i] == handler)
            return;
    element[listener + element[listener + '_num']] = handler;
    element[listener + '_num']++;
};

fixedMenu.supportsFixed = function()
{
    var testDiv = document.createElement("div");
    testDiv.id = "testingPositionFixed";
    testDiv.style.position = "fixed";
    testDiv.style.top = "0px";
    testDiv.style.right = "0px";
    document.body.appendChild(testDiv);
    var offset = 1;
    if (typeof testDiv.offsetTop == "number"
        && testDiv.offsetTop != null 
        && testDiv.offsetTop != "undefined")
    {
        offset = parseInt(testDiv.offsetTop);
    }
    if (offset == 0)
    {
        return true;
    }

    return false;
};

fixedMenu.init = function()
{
    if (fixedMenu.supportsFixed())
        fixedMenu.menu.style.position = "fixed";
    else
    {
        var ob = 
            document.layers 
            ? fixedMenu.menu 
            : fixedMenu.menu.style;

        fixedMenu.targetLeft   = parseInt(ob.left);
        fixedMenu.targetTop    = parseInt(ob.top);
        fixedMenu.targetRight  = parseInt(ob.right);
        fixedMenu.targetBottom = parseInt(ob.bottom);

        if (document.layers)
        {
            menu.left = 0;
            menu.top = 0;
        }
        fixedMenu.addEvent(window, 'onscroll', fixedMenu.moveMenu);
        fixedMenu.floatMenu();
    }
};

fixedMenu.addEvent(window, 'onload', fixedMenu.init);

/* additional code to show/hide popup */

function showMenu() { $(fixedMenuId).style.display = 'block'; initPosition(); }
function hideMenu() { $(fixedMenuId).style.display = 'none';  }
function initPosition() {
    iebody = (document.compatMode=="CSS1Compat") ? document.documentElement : document.body;

    var scroll_top = (isIE) ? iebody.scrollTop   : 0;
    var docwidth   = (isIE) ? iebody.clientWidth : window.innerWidth;
    var docheight  = (isIE) ? iebody.clientHeight: window.innerHeight;

    var objwidth   = $(fixedMenuId).offsetWidth;
    var objheight  = $(fixedMenuId).offsetHeight;

    //alert("scroll_top="+scroll_top+", objwidth="+objwidth+", docwidth="+docwidth+", half="+(docwidth/2 - objwidth/2));

    fixedMenu.currentX = (docwidth/2 - objwidth/2);
    fixedMenu.currentY = scroll_top + 260;

    //alert("currentX="+fixedMenu.currentX+", currentY="+fixedMenu.currentY);

    $(fixedMenuId).style.left = fixedMenu.currentX + "px";
    $(fixedMenuId).style.top  = fixedMenu.currentY + "px";
}

