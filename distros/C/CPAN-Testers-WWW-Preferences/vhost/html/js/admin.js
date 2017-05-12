function toggle(dis) {

    toggler('report',dis);
    toggler('grade',dis);
    toggler('tuple',dis);
    toggler('version',dis);
    toggler('perl',dis);
    toggler('platform',dis);

    document.forms[0].versions.disabled  = dis;
    document.forms[0].perls.disabled     = dis;
    document.forms[0].platforms.disabled = dis;

    if(dis == 0) {
        if(document.getElementsByName('version')[0].checked || document.getElementsByName('version')[1].checked) {
            document.forms[0].versions.disabled = 1;
        }
        if(document.getElementsByName('perl')[0].checked) {
            document.forms[0].perls.disabled = 1;
        }
        if(document.getElementsByName('platform')[0].checked) {
            document.forms[0].platforms.disabled = 1;
        }
    }
}

function toggler(name,dis) {
    var len = document.getElementsByName(name).length;
    for(var i = 0; i < len; i++) {
        document.getElementsByName(name)[i].disabled = dis;
    }
}

function toggled(dis) {
  if(dis == 1) {
    document.forms[0].ignored.disabled = 1;
    toggle(1);
  } else {
    document.forms[0].ignored.disabled = 0;
        if(document.forms[0].ignored.checked) {
      toggle(1);
    } else {
      toggle(0);
    }
  }
}

function doSubmit(act,id) {
  document.forms[0].recordid.value = id;
  document.forms[0].doaction.value = act;
  document.forms[0].submit();
}

function doOnlyOne(act) {
  var checkBoxArr = getSelectedCheckbox(document.forms[0].LISTED);
  if (checkBoxArr.length == 1) { 
    doSubmit(act);
    return;
  }

  if (checkBoxArr.length == 0)  { alert("No check boxes selected"); }
  else                          { alert("Only one check box can be selected"); }
}


