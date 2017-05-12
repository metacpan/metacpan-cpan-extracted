function confirm_n_ary_operation(form, operation) {
  var origin   = // location.origin; // GRR - not supported by MSIE9
                 location.protocol + '//' + location.host;
  var pathname = location.pathname.replace(new RegExp(operation+'$'),
                                           'count_where.json');
  var url      = origin + pathname;

  // async ajax call to ask how many records would be affected
  new Ajax.Request(url, {
    parameters:form.serialize(), 
    onSuccess: function(response) {
      var n_records = response.responseJSON.n_records;
      if (n_records < 0) {
        alert('This operation would ' + operation 
              +' the whole table -- give some "where" criteria');
      }
      else {
        var want_submit = confirm('This operation will simultaneously ' 
                                 + operation + ' *** ' + n_records
                                 + ' *** records '
                                 +"\nDo you really want to continue ?");
        if (want_submit)
          form.submit();
      }
    }
  });
  
  // disallow immediate submit -- waiting for ajax to return
  return false; 
}

