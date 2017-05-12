if (! window._OQAjaxQueryLoaded)
(function(){
  window._OQAjaxQueryLoaded = true;

  window.OQnotify = function(thing) {
    var $oqmsg;
    if (thing.responseText) {
      $oqmsg = $("<div class=OQmsg />").html(thing.responseText)
      var $x = $oqmsg.find('.OQmsg');
      if ($x.length > 0) {
        $oqmsg = $x; 
      }
    }
    else {
      $oqmsg = $("<div class=OQmsg />").html(thing);
    }
    var $oqnotify = $("<div class=OQnotify><button type=button class=OQnotifyOkBut>close</button></div>");
    $oqnotify.prepend($oqmsg);
    $("div.OQnotify").remove();
    $oqnotify.appendTo('body').delay(6000).fadeOut(function(){ $(this).remove(); });
  };

  $(document).delegate(".OQnotifyOkBut", "click", function(){
    $(this).closest('.OQnotify').remove();  
  });

  // show column panel when clicked
  $(document).delegate('table.OQdata thead td', 'click', function(e) {
    var $t = $(this);
    var $form = $t.closest('form');
    var $menu = $form.children('.OQColumnCmdPanel');

    var $c = $menu.children().prop('disabled',false);
    var nosel=$t.is('[data-noselect]'),
        nofil=$t.is('[data-nofilter]'),
        nosort=$t.is('[data-nosort]');
    if (nosel && nofil && nosort) return true;
    if (nosel) $c.filter('.OQAddColumnsBut,.OQCloseBut').prop('disabled',true);
    if (nofil) $c.filter('.OQFilterBut').prop('disabled',true);
    if (nosort) $c.filter('.OQSortBut,.OQReverseSortBut').prop('disabled',true);

    var fieldIdx = $t.prevAll().length - 1; // don't count OQdataLCol,..
    var numFields = $t.parent().children().length - 2;
    if (fieldIdx < 0 || fieldIdx >= numFields) return true;
    $menu.data('OQdataFieldIdxCtx', fieldIdx);
    var cmdPanelWidth = $menu.width();
    var pos = $t.offset();
    pos.top += $t.outerHeight();
    
    // ensure the cmd menu is under mouse
    var l = pos.left;
    if (e.pageX && e.pageX > (pos.left + cmdPanelWidth)) {
      l = e.pageX - (cmdPanelWidth / 2);
      if (l + cmdPanelWidth > pos.left + $t.width() ) {
        l = pos.left + $t.width() - cmdPanelWidth;
      }
    }
    pos.left = l;
    var oqoffset = $form.offset();
    pos.top -= oqoffset.top;
    pos.left -= oqoffset.left;
    $menu.css(pos).show();
    $(document).bind('click.OQmenu',function(e){
      if ($(e.target).closest('thead').closest('.OQdata').length == 0) {
        $menu.hide();
        $(document).unbind('click.OQmenu');
      }
    });
    return true;
  });

  $(document).delegate('.OQRemoveSortBut', 'click', function(e) {
    e.preventDefault();
    var $t = $(this);
    var idx = $t.prevAll().length;
    var $form = $(this).closest('form');
    var $sort = $($form[0].sort);
    var sort = $sort.val().split(',');
    sort.splice(idx, 1);
    $sort.val(sort.join(','));
    var f = $form[0];
    $(f.page).val('1');
    if ($(f.rows_page).val()=='All') f.rows_page.selectedIndex=0;
    refreshDataGrid($form); 
    return true;
  });

  $(document).delegate('.OQCloseBut', 'click', function(e) {
    e.preventDefault();
    var $form = $(this).closest('form');
    var $menu = $form.children('.OQColumnCmdPanel');
    var fieldIdx = $menu.data('OQdataFieldIdxCtx');
    var $show = $($form[0].show);
    var show = $show.val().split(',');
    if (show.length > 1) {
      show.splice(fieldIdx, 1);
      $show.val(show.join(','));
      $form.children('.OQdata').find('td:nth-child('+ (fieldIdx+2) +')').remove();
    }
    return true;
  });

  $(document).delegate('.OQLeftBut', 'click', function(e) {
    e.preventDefault();
    var $form = $(this).closest('form');
    var $menu = $form.children('.OQColumnCmdPanel');
    var fieldIdx = $menu.data('OQdataFieldIdxCtx');
    if (fieldIdx == 0) return true;
    var $show = $($form[0].show);
    var show = $show.val().split(',');
    var tmp = show[fieldIdx];
    show[fieldIdx] = show[fieldIdx - 1]
    show[fieldIdx - 1] = tmp;
    $show.val(show.join(','));
    $form.children('.OQdata').find('td:nth-child('+ (fieldIdx+2) +')')
      .each(function(){ $(this).insertBefore($(this).prev()); });
    $menu.data('OQdataFieldIdxCtx',fieldIdx - 1);
    return true;
  });

  $(document).delegate('.OQRightBut', 'click', function(e) {
    e.preventDefault();
    var $form = $(this).closest('form');
    var $menu = $form.children('.OQColumnCmdPanel');
    var fieldIdx = $menu.data('OQdataFieldIdxCtx');
    var $show = $($form[0].show);
    var show = $show.val().split(',');
    if (fieldIdx == (show.length - 1)) return true;
    var tmp = show[fieldIdx];
    show[fieldIdx] = show[fieldIdx + 1]
    show[fieldIdx + 1] = tmp;
    $show.val(show.join(','));
    $form.children('.OQdata').find('td:nth-child('+ (fieldIdx+2) +')')
      .each(function(){ $(this).insertAfter($(this).next()); });
    $menu.data('OQdataFieldIdxCtx',fieldIdx + 1);
    return true;
  });

  $(document).delegate('.OQSortBut,.OQReverseSortBut', 'click', function(e) {
    e.preventDefault();
    var $form = $(this).closest('form');
    var $menu = $form.children('.OQColumnCmdPanel');
    var fieldIdx = $menu.data('OQdataFieldIdxCtx');
    var $show = $($form[0].show);
    var show = $show.val().split(',');
    var colalias = show[fieldIdx];
    var re = new RegExp('\\b'+colalias+'\\b');
    var $sort = $($form[0].sort);
    var sort = ($sort.val()) ? $sort.val().split(',') : [];
    var newsort = [];
    for (var i=0,l=sort.length;i<l;++i) {
      if (! re.test(sort[i]))
        newsort.push(sort[i]);
    }
    newsort.push('['+colalias+']' + (/Reverse/.test(this.className)?' DESC':''));
    $sort.val(newsort.join(','));
    $($form[0].page).val('1');
    refreshDataGrid($form); 
  });

  var downloadCtr = 0;
  $(document).delegate('.OQDownloadCSV,.OQDownloadHTML,.OQDownloadXML,.OQDownloadJSON','click', function(){
    var target = 'download'+(downloadCtr++); 
    var $f = $('.OQform');
    var $panel = $(this).closest('.OQToolsPanel');
    var $newform = $('<form>').css('display','none').attr({
      action: $f.attr('action'), method: 'POST', target: target });
    var dat = buildParamMap($f);
    if (/CSV/.test(this.className)) dat.module = 'CSV';
    else if (/XML/.test(this.className)) dat.module = 'XML';
    else if (/JSON/.test(this.className)) dat.module = 'JSON';
    else dat.module = 'PrinterFriendly';
    if ($panel.find('.OQExportAllResultsInd:checked').length==1) {
      dat.rows_page = 'All';
      dat.page = 1;
    }
    for (var n in dat)
      $('<input>').attr({ name: n, value: dat[n] }).appendTo($newform);
    $('<iframe id='+target+' name='+target+' style="visibility: hidden; height: 1px;">').appendTo(document.body);
    $newform.appendTo(document.body);
    downloadCtr++;
    $newform.submit();
    $panel.find('.OQToolsCancelBut').click();
  });

  $(document).delegate('.OQToolsCancelBut','click', function(){
    $(".OQToolsPanel").hide();
  });

  $(document).delegate('.OQToolsBut','click', function(){
    var $p = $(".OQToolsPanel").toggle();

    // open export by default
    if ($p.is(':visible')) {
      $p.find("li[data-toolkey=export]:not(.opened) > h3").click();
    }
  });

  $(document).delegate('.OQDeleteSavedSearchBut','click', function(){
    var $but = $(this);
    var $tr = $(this).closest('tr');
    var id = $tr.find('[data-id]').attr('data-id');
    var $f = $('.OQform');
    var dat = buildParamMap($f);
    dat.module = 'InteractiveQuery2Tools';
    dat.OQdeleteSavedSearch = id;
    $.ajax({ url: $f[0].action, type: 'POST', dataType: 'json',
      data: dat,
      complete: function(jqXHR) {
        if (/report\ deleted/.test(jqXHR.responseText)) {
          OQnotify("report deleted"); 
          $tr.remove();
        }
        else
          alert('Could not delete report.' + jqXHR.responseText);
      }
    });
    return false;
  });

  var parseHour = function(h) {
    var rv = 0;
    if (/(\d+)/.test(h)) rv = parseInt(RegExp.$1,10);
    if (/AM/i.test(h) && rv == 12) rv = 0;
    else if (/PM/i.test(h) && rv < 12) rv+=12;
    if (rv >= 24) rv = 23;
    return rv;
  };

  $(document).on('click','.OQSaveNewReportBut,.OQSaveReportBut', function(e) {
    var $f = $('.OQform');
    var dat = buildParamMap($f);

    // if request to save new saved search
    if ($(this).hasClass('OQSaveNewReportBut')) dat.OQss='';

    dat.module = 'InteractiveQuery2Tools';
    dat.OQsaveSearchTitle = $("#OQsaveSearchTitle").val();
    if (! dat.OQsaveSearchTitle) {
      alert('Enter a name.');
      return true;
    }
    dat.alert_mask = 0;
    if ($("#OQalertenabled").prop("checked")) {
      dat.alert_mask = 0; $("input[name=OQalert_mask]:checked").each(function(){ dat.alert_mask |= parseInt(this.value,10); });
      dat.alert_interval_min = parseInt($("#OQalert_interval_min").val(),10);

      if (dat.alert_mask==0) {
        alert('Specify when to send the alert.');
        return true;
      }
      if (!(dat.alert_interval_min >= 30)) {
        alert('Enter a "Check Every" minute hour value greater or equal to 30');
        return true;
      }

      dat.alert_dow = '';
      $(".OQalert_dow:checked").each(function(){ dat.alert_dow += this.value; });
      if (dat.alert_dow == '') {
        alert('Select at least one "On Days".');
        return true;
      }

      dat.alert_start_hour = parseHour($("#OQalert_start_hour").val());
      if (! dat.alert_start_hour) {
        alert('Enter a "From" hour between 0 and 23.');
        return true;
      }

      dat.alert_end_hour = parseHour($("#OQalert_end_hour").val());
      if (! dat.alert_end_hour) {
        alert('Enter a "To" hour between 0 and 23.');
        return true;
      }

      if (dat.alert_start_hour > dat.alert_end_hour) {
        alert('"From" hour must be less than "To" hour.');
        return true;
      }
    }
    
    // set this saved search as default
    if($('#OQsave_search_default').length > 0) {
      dat.save_search_default = $('#OQsave_search_default').prop('checked') ? 1 : 0;
    }
    
    $.ajax({ url: $f[0].action, type: 'POST', data: dat, dataType: 'json',
      error: function(){
        OQnotify("Could not save report.");
      },
      success: function(x) {
        if (x.id) {
          $f[0].OQss.value=x.id;    
          $('.OQToolsCancelBut').click();
          OQnotify("report saved");
        }
        else {
          OQnotify("Could not save report. " + x.msg);
        }
      }
    });
    return true;
  });
  $(document).delegate('#OQalertenabled', 'click', function(e) {
    if (this.checked) {
      $("#OQSaveReportEmailAlertOpts").addClass('opened');
    } else {
      $("#OQSaveReportEmailAlertOpts").removeClass('opened');
    }
  });

  $(document).delegate('.OQEmailMergePreviewBut, .OQEmailMergeSendEmailBut', 'click', function(e) {
    var $f = $('.OQform');
    var dat = buildParamMap($f);
    dat.module = 'InteractiveQuery2Tools';
    dat.tool = 'emailmerge';
    dat.rows_page = 'All';
    dat.act = $(this).hasClass('OQEmailMergeSendEmailBut') ? 'execute' : 'preview';
    $(".OQemailmergeform").find('input,textarea').each(function(){
      if (this.name && this.value) dat[this.name] = this.value;
    });
    $.ajax({ url: $f[0].action, type: 'POST', data: dat, dataType: 'html',
      complete: function(jqXHR) {
        var $x = $("<div />").html(jqXHR.responseText).find('.OQemailmergeview');
        if ($x.length == 0) OQnotify(jqXHR);
        else {
          $(".OQemailmergetool").children().hide();
          $(".OQemailmergetool").append($x);
        }
      }
    });
    return true;
  });

  $(document).delegate('.OQRemoveAutoActionBut', 'click', function(e) {
    var $f = $('.OQform');
    var $elem = $(this).closest(".AutoActionSummaryElem");
    var dat = buildParamMap($f);
    dat.module = 'InteractiveQuery2Tools';
    dat.tool = 'autoaction';
    dat.OQRemoveAutoAction = $(this).attr('data-id');
    $.ajax({ url: $f[0].action, type: 'POST', data: dat, dataType: 'html', complete: OQnotify,
      success: function(){ $elem.remove(); }
    });
    return true;
  });

  $(document).delegate('.OQEmailMergeDeleteAutoActionBut', 'click', function(e) {
    var $f = $('.OQform');
    var dat = buildParamMap($f);
    dat.module = 'InteractiveQuery2Tools';
    dat.tool = 'emailmerge';
    dat.act = 'deleteautoaction';
    dat.id = $("input[name=oq_autoaction_id]").val();
    $.ajax({ url: $f[0].action, type: 'POST', data: dat, dataType: 'html', complete: OQnotify });
    return true;
  });

  $(document).delegate('.OQEmailMergeSaveAutoActionBut', 'click', function(e) {
    var $f = $('.OQform');
    var dat = buildParamMap($f);
    dat.module = 'InteractiveQuery2Tools';
    dat.tool = 'emailmerge';
    dat.act = 'saveautoaction';
    dat.filter_descr = $(".OQFilterDescr").children().eq(1).text();
    $(".OQemailmergeform").find('input,textarea').each(function(){
      if (this.name && this.value) dat[this.name] = this.value;
    });
    $.ajax({ url: $f[0].action, type: 'POST', data: dat, dataType: 'html', complete: OQnotify });
    return true;
  });

  $(document).delegate('.OQEmailMergePreviewBackBut', 'click', function(e) {
    $(".OQemailmergeview").siblings().show();
    $(".OQemailmergeview").remove();
    return true;
  });

  $(document).delegate('.OQAddColumnsBut', 'click', function(e) {
    e.preventDefault();
    var $f = $(this).closest('form');
    var $menu = $f.children('.OQColumnCmdPanel');
    var fieldIdx = $menu.data('OQdataFieldIdxCtx');
    var $show = $($f[0].show);
    var show = $show.val().split(',');
    var colalias = show[fieldIdx];
    var dat = buildParamMap($f);
    dat.module = 'ShowColumns';
    $f.addClass('OQAddColumnsMode');
    $.ajax({ url: $f[0].action, type: 'POST', data: dat, dataType: 'html',
      complete: function(jqXHR) {
        try { 
          var $p = $('<div>').append(jqXHR.responseText).find('.OQAddColumnsPanel');
          if ($p.length!=1) throw(1);
          $f.append($p);
        } catch(e) {
          alert('Could not load add fields panel.');
          $f.removeClass('OQAddColumnsMode');
        }
      }
    });
    return true;
  });

  $(document).delegate('.OQAddColumnsCancelBut', 'click', function() {
    var $f = $(this).closest('form');
    $f.children('.OQAddColumnsPanel').remove();
    $f.removeClass('OQAddColumnsMode');
    return true;
  });

  $(document).delegate('.OQAddColumnsOKBut', 'click', function() {
    var $panel = $(this).closest('.OQAddColumnsPanel');
    var $f = $panel.closest('form');
    var $menu = $f.children('.OQColumnCmdPanel');
    var fieldIdx = $menu.data('OQdataFieldIdxCtx');
    var $show = $($f[0].show);
    var show = $show.val().split(',');
    if (fieldIdx === '') fieldIdx = -1;
    var newshow = show.splice(0,fieldIdx + 1);
    $panel.find('input:checked').each(function(){ newshow.push(this.value); });
    $f[0].mode.value=$("#ShowColumnsDisplayAs").val();
    $show.val(newshow.concat(show).join(','));
    $f.children('.OQAddColumnsPanel').remove();
    $f.removeClass('OQAddColumnsMode');
    refreshDataGrid($f);
    return true;
  });

  $(document).delegate('.OQToolExpander h3', 'click', function() {
    var $newli = $(this).closest('li');

    var $oldcontent = $newli.closest('.OQToolsPanel').find('.OQToolContent');
    var $oldli = $oldcontent.closest('li').removeClass('opened');
    $oldcontent.remove();

    // load tool panel content
    if ($newli[0] != $oldli[0]) {
      $newli.addClass('opened'); 
      var $newcontent = $("<div class=OQToolContent />");
      $newli.append($newcontent);
      var $f = $('form.OQform');
      var dat = buildParamMap($f);
      dat.module = 'InteractiveQuery2Tools';
      dat.tool = $newli.attr('data-toolkey');
      $newcontent.load($f[0].action, dat);
    }
  });

  $(document).delegate('.OQFilterDescr', 'click', function() {
    var $f = $(this).closest('form');
    var $menu = $f.children('.OQColumnCmdPanel');
    var fieldIdx = $menu.data('OQdataFieldIdxCtx');
    var $show = $($f[0].show);
    var show = $show.val().split(',');
    var colalias = show[fieldIdx];
    $f.nextAll('.OQFilterPanel').remove();
    var dat = buildParamMap($f);
    delete dat.show; delete dat.sort; delete dat.page; delete dat.rows_page;
    delete dat.on_select; delete dat.queryDescr;
    dat.module = 'InteractiveFilter2';
    $.ajax({ url: $f[0].action, type: 'POST', data: dat, dataType: 'html',
      complete: function(jqXHR) {
        if (jqXHR.status==0) return;
        var $p = $('<div>').append(jqXHR.responseText).find('.OQFilterPanel');
        if ($p.length==0) {
          alert('Could not load add filter panel.');
          $f.removeClass('OQFilterMode');
        } else {
          $f.append($p);
          $p.find('.newfilter').focus(); 
        }
      }
    });
    $f.addClass('OQFilterMode');
    return true;
  });

  $(document).delegate('input.SaveReportNameInp', 'keydown', function(e){
    if (e.which==13)
      $(this).closest('fieldset').find('button').click();
    return true;
  });

  var HELP = [
    '', 'This is the interactive report data viewer. Click the <em>next</em> button to cycle through all the tips. Click the <em>close</em> button when you are finished.',
    '.OQtitle', 'This is the title of the currently opened report.',
    '.OQsummary', 'This is the summary of records currently displayed and the total number of records.',
    '.OQnewBut','Click this button to create a new record.',
    '.OQrefreshBut', 'Click to refresh data in the grid.',
    '.OQToolsBut', 'Click to open options to load, save, or export reports.',
    '.OQFilterDescr td', 'This shows the currently enabled filter. Click to modify.',
    '.OQSortDescr td', 'This shows the currently enabled sort. Click a name to remove.',
    '.OQdata thead td', 'Click to open the columns actions menu allowing you to move, hide, filter, and sort a column. When your mouse is hovering over a column, you can use the left/right arrow keys to move a column, and the delete key to hide a column.',
    '.OQeditBut', 'Click this button to open the record.',
    '.OQPager', 'These buttons allow you change how many records are shown on a page and which page is displayed.',
    '', 'This concludes the help.'
  ];
  var $HelpHilight;
  $(document).delegate('.OQNextHelpBut','click', function(){
    if ($HelpHilight) {
      $HelpHilight.removeClass('OQHelpHilight');
      $HelpHilight = undefined;
    }
    var $panel = $(this).closest('.OQHelpPanel')
    var i = $panel.data('i');
    var $f = $panel.closest('form');
    while (true) {
      if (i >= HELP.length) i = 0; 
      if (HELP[i]) {
        $HelpHilight = $f.find(HELP[i]).addClass('OQHelpHilight');
        if ($HelpHilight.length==0) {
          i+=2;
          continue;
        }
      }
      $panel.children('.OQHelpContent').html(HELP[i + 1]);
      break;
    }
    i+=2;
    $panel.data('i',i);
  });
  $(document).delegate('.OQhelpBut','click', function(){
    var $f = $(this).closest('form');
    $f.addClass('OQHelpMode');
    $('<div class=OQHelpPanel><h3>Help</h3><div class=OQHelpContent></div><button type=button class=OQCloseHelpBut>close</button><button type=button class=OQNextHelpBut>next tip</button></div>').data('i',0).appendTo($f).find('.OQNextHelpBut').click();
  });
  $(document).delegate('.OQCloseHelpBut','click', function(){
    var $f = $(this).closest('form');
    $f.removeClass('OQHelpMode');
    $f.children('.OQHelpPanel').remove();
    if ($HelpHilight)
      $HelpHilight.removeClass('OQHelpHilight');
    $HelpHilight = undefined;
  });




  $(document).delegate('input.rexp', 'keydown', function(e){
    if (e.which==13)
      $(this).closest('.OQFilterPanel').find('button.OKFilterBut').click();
    return true;
  });

  $(document).delegate('.OQFilterBut', 'click', function(e) {
    e.preventDefault();
    var $f = $(this).closest('form');
    var $menu = $f.children('.OQColumnCmdPanel');
    var fieldIdx = $menu.data('OQdataFieldIdxCtx');
    var $show = $($f[0].show);
    var show = $show.val().split(',');
    var colalias = show[fieldIdx];
    $f.nextAll('.OQFilterPanel').remove();
    var dat = buildParamMap($f);
    delete dat.show; delete dat.sort; delete dat.page; delete dat.rows_page;
    delete dat.on_select; delete dat.queryDescr;
    dat.field = colalias;
    dat.module = 'InteractiveFilter2';
    $.ajax({ url: $f[0].action, type: 'POST', data: dat, dataType: 'html',
      context: $f,
      complete: function(jqXHR) {
        if (jqXHR.status==0) return;
        var $p = $('<div>').append(jqXHR.responseText).find('.OQFilterPanel');
        if ($p.length==0) {
          alert('Could not load add filter panel.');
          $f.removeClass('OQFilterMode');
        } else {
          $f.append($p);
          $p.find('input.rexp:last').focus();
        }
      }
    });
    $f.addClass('OQFilterMode');
    return true;
  });

  $(document.body).delegate('.OQeditBut,.OQnewBut', 'click', function(){
    var $t = $(this);
    var href = $t.attr('data-href') || $t.attr('href');
    var target = $t.attr('data-target') || $t.attr('target');
    if (target) OQopwin(href,target);
    else if (window.OQusePopups) OQopwin(href);
    else if ($t.is("button")) location = href;
    else return true;  // follow link as normal 
    return false;
  });

  $(document.body).delegate('.OQselectBut', 'click', function(){
    var f = this.form;
    var args = $(this).attr('data-rv');

    if (args=='') return true;
    var A = args.split('~~~');
    if (! f.on_select.value) {
      alert('no on_select handler');
      return true;
    }
    var wo = window.opener2 || window.opener;

    var funcName = f.on_select.value.replace(/\,.*/,'');
    var funcRef = wo[funcName];
    if (! funcRef) {
      alert('could not update parent form');
    } else {
      var opts = /(\~.*)/.test(f.on_select.value) ? RegExp.$1 : "";
      // Ahhh! can't use funcRef.apply with array args because
      // IE <= 7 can't pass Arrays created in one window to another
      funcRef(A[0],A[1],A[2],A[3],A[4],A[5],A[6],A[7],A[8],A[9]);
      if (/\bnoclose\b/.test(opts)) {
        $(this).fadeOut();
      } else {
        wo.focus();
        var wc = window.close2 || window.close;
        wc();
      }
    }
    return true;
  });

  $(document).delegate('.OQexportBut', 'click', function(e){
    e.preventDefault();
    var $f = $(this.form);
    var $dialog = $f.next().children('.OQExportDialog');
    $dialog.show();
  });
  

  $(document).delegate('.OQrefreshBut', 'click', function(e) {
    e.preventDefault();
    refreshDataGrid($(this.form));
    return true;
  });

  $(document).delegate('.OQPager', 'change', function(e) {
    e.preventDefault();
    var $f = $(this).closest('form');
    refreshDataGrid($f);
    $f[0].scrollIntoView();
    return true;
  });
  $(document).delegate('.OQNextBut', 'click', function(e) {
    e.preventDefault();
    var $f = $(this.form);
    var n = parseInt($f[0].page.value,10);
    $f[0].page.value = n + 1;
    refreshDataGrid($f);
    $f[0].scrollIntoView();
    return true;
  });
  $(document).delegate('.OQPrevBut', 'click', function(e) {
    e.preventDefault();
    var $f = $(this.form);
    var n = parseInt($f[0].page.value,10);
    $f[0].page.value = n - 1;
    refreshDataGrid($f);
    $f[0].scrollIntoView();
    return true;
  });

  $(document).delegate('form.OQform','submit', function(){
    return false;
  });

  $(document).delegate('select.rexp','change', function(){
    var $textbox = $(this).next();
    if (this.selectedIndex==0) {
      $textbox.show().focus();
    } else {
      $textbox.val('').hide();
    }
    return true;
  });

  $(document).delegate('button.DeleteFilterElemBut','click', function(){
    var $tr = $(this).closest('tr');
    if ($tr.next().length==1) $tr.next().remove();
    else if ($tr.prev().length==1) $tr.prev().remove();
    $tr.remove();
    return true;
  });

  $(document).delegate('button.CancelFilterBut','click', function(){
    $(this).closest('form').removeClass('OQFilterMode');
    $(this).closest('.OQFilterPanel').remove();
    return true;
  });

  $(document).delegate('button.OKFilterBut','click', function(){
    var $filterpanel = $(this).closest('.OQFilterPanel');
    var score = 0;
    var err;
    $filterpanel.find('select.lp,select.rp').each(function(){
      var x = this.selectedIndex;
      if (/^r/.test(this.className)) x*=-1;
      score += x;
      if (score < 0) err = "Extra ')' detected.";
    });
    if (score != 0) err = "Total '(' must equal total ')'.";
    if (err) alert(err);
    else {
      var $f = $filterpanel.closest('form');
      var dat = buildParamMap($f);
      dat.filter = createFilterStr($filterpanel);
      delete dat.page; delete dat.rows_page;
      refreshDataGrid($f,dat);
    }
    return true;
  });

  $(document).delegate('button.lp','click', function(){
    $(this).replaceWith('<select class=lp><option></option><option selected>(<option>((<option>((</select>');
    return false;
  });
  $(document).delegate('select.lp','change', function(){
    if (this.selectedIndex==0) $(this).replaceWith('<button class=lp>(</button>');
    return true;
  });
  $(document).delegate('button.rp','click', function(){
    $(this).replaceWith('<select class=rp><option></option><option selected>)<option>))<option>))</select>');
    return false;
  });
  $(document).delegate('select.rp','change', function(){
    if (this.selectedIndex==0) $(this).replaceWith('<button class=rp>)</button>');
    return true;
  });

  var createFilterStr = function($filterpanel){
    var newfilter = '';
    $filterpanel.find('input,select').each(function(){
      if (this.disabled) return true;
      var val = $(this).val();

      if (this.name && /^\_nf\_arg\_(.*)/.test(this.name)) {
        var name = RegExp.$1;

        // if not simple literal, we need to quote it
        if (! /^\w+$/.test(val)) {
          if (! /\'/.test(val)) val = "'"+val+"'";
          else val = '"'+val.replace(/\"/g,'')+'"';
        }

        //if last character of filter string is an open paren don't add a comma
        if (! /\($/.test(newfilter)) newfilter += ',';
        newfilter += name + ',' + val;
      }
      else if ($(this).is('select.rexp')) {
        if (val) newfilter += ' '+val;
      }
      else if ($(this).is('input.rexp') && $(this).is(':visible')) {
        if (! /\'/.test(val)) val = "'"+val+"'";
        else if (! /\"/.test(val)) val = '"'+val+'"';
        else val = '"'+val.replace(/\"/g,'')+'"';
        newfilter += ' '+val;
      }
      else if (val != '') {
        newfilter += ' '+val;
      }

      return true;
    });
    return $.trim(newfilter);
  };

  // when user select new filter element, add filter element to current fiter and
  // repaint filter panel
  $(document).delegate('select.newfilter','change', function(){
    var newexp = $(this).val();
    if (newexp=='') return true;
    this.selectedIndex = 0;
    if (! /\)$/.test(newexp)) newexp += '=""'; 
    var $filterpanel = $(this).closest('.OQFilterPanel');
    var newfilter = createFilterStr($filterpanel);
    if (newfilter != '') newfilter += 'AND '+newexp;
    else newfilter = newexp;
    var $f = $(this).closest('form');
    var dat = buildParamMap($f);
    delete dat.show; delete dat.sort; delete dat.page; delete dat.rows_page;
    delete dat.on_select; delete dat.queryDescr;
    dat.module = 'InteractiveFilter2';
    dat.filter = newfilter;
    req = $.ajax({
      url: $f[0].action, type: 'POST', data: dat, dataType: 'html',
      complete: function(jqXHR) {
        try { 
          var $p = $('<div>').append(jqXHR.responseText).find('.OQFilterPanel');
          if ($p.length!=1) throw(1); 
          $f.children('.OQFilterPanel').replaceWith($p);
          $p.find('.rexp:last').focus();
        } catch(e) {
          alert('Could not load data while processing new filter.');
        }
      }
    });
    return true;
  });
    
  $(document).keyup(function(evt) {
    var b;
    switch (evt.which) {
      case 37: b='.OQLeftBut'; break;
      case 39: b='.OQRightBut'; break;
      case 46: b='.OQCloseBut'; break;
    }
    if (b) {
      var $col = $(':hover[data-col]');
      if ($col.length != 1) return true;
      var idx = $col.prevAll().length - 1;
      var $form = $col.closest('form');
      var $menu = $form.children('.OQColumnCmdPanel');
      $menu.data('OQdataFieldIdxCtx', idx);
      $menu.children(b).click();
    }
    return true;
  });

  var buildParamMap = function($form) {
    var dat={};
    $('input,select',$form[0]).each(function(){
      // ignore named filter arguments
      if (this.name && ! /^\_nf\_arg\_/.test(this.name)) dat[this.name]=$(this).val();
    });
    return dat;
  };

  var refreshDataGrid = function($f,dat) {
    $f.addClass('LoadingData');
    if (! dat) dat = buildParamMap($f);

    // load OQ data using ajax
    if (window.OQuseAjax) {
      dat.dataonly = 1;
      dat.module = 'InteractiveQuery2';
      return $.ajax({
        url: $f[0].action, type: 'POST', data: dat, dataType: 'html',
        error: function() {
          alert('Could not load data for data grid after error.');
          $f.removeClass('LoadingData');
        },
        success: function(d) {
          try {
            var $p = $('<div>').append(d).find('form.OQform');
            if ($p.length!=1) throw(1);
            $f.replaceWith($p);
          } catch(e) {
            alert('Could not load data for data grid after success.');
            $f.removeClass('LoadingData');
          }
        }
      });
    }

    // reload data by reloading entire page
    else {
      // merge form get args
      var urlargs = $f.attr('action').split(/\?/);
      if (urlargs[1]) {
        $.each(urlargs[1].split(/[\&\;]/), function() {
          var kv = this.split(/\=/);
          if (! dat[kv[0]]) dat[kv[0]]=kv[1];
        });
      }
    
      var newUrl = urlargs[0]+'?'+$.param(dat);
      location = newUrl;
    }
  };

  window.OQrefresh = function(updated_uid) {
    var $f = $('form.OQform').eq(0);
    var onSelFun = $f[0].on_select.value;
    var isClosed = false;
    if (updated_uid && onSelFun) {
      try {
        var wo = window.opener2 || window.opener;
        wo[onSelFun](updated_uid);
        wo.focus();
        var wc = window.close2 || window.close;
        wc();
        isClosed = true;
      } catch(e) {}
    }
    if (! isClosed) {
      var dat = buildParamMap($f);
      var $ajax = refreshDataGrid($f,dat);
      if (updated_uid) $ajax.done(function(){
        var $f = $('form.OQform').eq(0);
        $('<div class="OQRecUpdateMsg">')
          .attr('data-uid', updated_uid)
          .text('record '+updated_uid+' saved')
          .insertAfter($f.children('.OQinfo'));
        $f.find('tr[data-uid="'+updated_uid+'"]').addClass('OQupdatedRow');
      });
    }
  };

  

  if (window.opwin) window.OQopwin=window.opwin;
  else window.OQopwin = function(lnk,target,opts,w,h) {
    if (! target) target = '_blank';
    if (! opts) opts = 'resizable,scrollbars';
    if (! w && window.OQWindowWidth) w = window.OQWindowWidth;
    if (! w) w = 800;
    if (! h && window.OQWindowHeight) h = window.OQWindowHeight;
    if (! h) h = 600;
    if (window.screen) {
      var s = window.screen;
      var max_width = s.availWidth - 10;
      var max_height = s.availHeight - 30;
      if (opts.indexOf('toolbar',0) != -1) max_height -= 40;
      if (opts.indexOf('menubar',0) != -1) max_height -= 35;
      if (opts.indexOf('location',0) != -1)max_height -= 35;
      var width  = (w > max_width)?max_width:w;
      var height = (h > max_height)?max_height:h;
      var par_left_offset = (window.screenX == null)?0:window.screenX;
      var par_top_offset  = (window.screenY == null)?0:window.screenY;
      var par_width;
      if (window.outerWidth != null) {
        par_width = window.outerWidth;
        if (par_width < width)
          par_left_offset -= parseInt((width - par_width)/2);
      } else
        par_width = max_width;

      var par_height;
      if (window.outerHeight != null) {
        par_height = window.outerHeight;
        if (par_height < height) {
          par_top_offset -= parseInt((height - par_height)/2);
        }
      } else
        par_height = max_height;

      var left = parseInt(par_width /2 - width /2) + par_left_offset;
      var top  = parseInt(par_height/2 - height/2) + par_top_offset;

      var newopts = 'width='+width+',height='+height+',left='+left+',top='+top;
      opts = (opts && opts != '')?newopts+','+opts:newopts;
    }
    var wndw = window.open(lnk,target,opts);
    if (wndw.focus) wndw.focus();
    return wndw;
  };

})();
