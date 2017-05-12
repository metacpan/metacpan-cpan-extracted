// Title: ISO 8601 Time Parser/Validator
// Version: 1.0
// Date: 12-07-2004 (mm-dd-yyyy)
// Author: Alex Peeters [alex.peeters@citap.be]

function ValidTime(h, m, s) {
   with (new Date(0, 0, 0, h, m, s))
   return ((getHours()==h) && (getMinutes()==m))
}

function ReadISO8601time(Q) {
  var T // adaptable to other layouts

  if ((T = /^(\d\d):(\d\d):(\d\d)$/.exec(Q)) == null) {
    alert('Bad time format');
    return false
  }

  if (!ValidTime(T[1], T[2], T[3])) {
    alert('Bad time value');
    return false
  }

  return true
}
