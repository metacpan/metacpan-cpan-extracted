function checkAll(obj) {
   var ss
   var kk
   kk= obj;

   ss=document.form1.checkbox.checked;

   if (ss == false) {
      kk ="no";
   }

   // set the form to look at (your form is called form1)
   var frm = document.form1
   
   // get the form elements
   var el = frm.elements
   
   // loop through the elements...
   for(i=0;i<el.length;i++) {
      // and check if it is a checkbox
      if(el[i].type == "checkbox" ) {
      // if it is a checkbox and you submitted yes to the function
      //alert(kk);
         if(kk == "yes")
            // tick the box
            el[i].checked = true;
         else
           // otherwise untick the box
           el[i].checked = false;
         }
   }
}