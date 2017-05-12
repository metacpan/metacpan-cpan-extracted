// Heavily modified from Allen Day's version, which in turn was stolen from myPHPAdmin

var hiliteColor = 'moccasin';   // mouse over color
var selectColor = 'gold';       // selected row color

function setRowColor(theRow,theColor)
{
  var theCells     = null;
  var domDetect    = null;
  var currentColor = null;
  var c            = null;

  theCells = getCells(theRow);
  if (!theCells) return false;

  if (typeof(window.opera) == 'undefined'
       && typeof(theCells[0].getAttribute) != 'undefined') {
       currentColor = theCells[0].getAttribute('bgcolor');
       domDetect    = true;
   }
   else {
        currentColor = theCells[0].style.backgroundColor;
        domDetect    = false;
   } // end 3


   if (theColor!=null) {
   if (domDetect) {
       for (c = 0; c < theCells.length; c++) {
           theCells[c].setAttribute('bgcolor', theColor, 0);
       } // end for
    }
    else {
        for (c = 0; c < theCells.length; c++) {
            theCells[c].style.backgroundColor = theColor;
        }
    }
    }

    return currentColor;
}
function getCells(theRow) {

    if (typeof(document.getElementsByTagName) != 'undefined') {
        return theRow.getElementsByTagName('td');
    }
    else if (typeof(theRow.cells) != 'undefined') {
        return theRow.cells;
    }
    else {
        return null;
    }
}
function hiliteRow(theRow,hilite)
{
  var theCells    = getCells(theRow);
  var theCheckBox = findCheckbox(theCells);
  var checked     = theCheckBox.checked;

  if (checked) {
     setRowColor(theRow,selectColor);
  }
  else if (hilite) {
      setRowColor(theRow,hiliteColor);
  } else {
     setRowColor(theRow,theRow.style.backgroundColor);
  }
  return true;
}
function findCheckbox (theCells){
  for (var i=0; i < theCells.length; i++) {
    var inputs = theCells[i].getElementsByTagName('input');
    if (inputs[0]) return inputs[0];    
  }
  return null;
}
function toggleRow(theRow)
{
   var theCells=theRow.getElementsByTagName('td');
   var theInput=findCheckbox(theCells);
   theInput.checked = !theInput.checked;
   setRowColor(theRow,theInput.checked ? selectColor : theRow.style.backgroundColor);
   document.form.selectall.checked = false;
   return true;
}
function toggleCheckbox(theCheckbox)
{
    var row = theCheckbox.parentNode.parentNode;
    theCheckbox.checked = !theCheckbox.checked;
    setRowColor(row,theCheckbox.checked ? selectColor : row.style.backgroundColor);
    event.cancelBubble = true;
    return true;
}
function setCheckbox(theCheckbox,state)
{
    var row = theCheckbox.parentNode.parentNode;
    theCheckbox.checked = state;
    setRowColor(row,selectColor);
    setRowColor(row,theCheckbox.checked ? selectColor : row.style.backgroundColor);
    return true;
}
function toggleAll(self,field) {
for (i = 0; i < field.length; i++)
  setCheckbox(field[i],self.checked);
}

